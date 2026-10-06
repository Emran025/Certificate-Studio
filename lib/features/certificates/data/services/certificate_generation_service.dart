import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/utils/field_identifier.dart';
import 'template_bytes.dart';
import 'certificate_artifact_renderer.dart';
import 'certificate_pdf_render_worker.dart';

class CertificateGenerationResult {
  const CertificateGenerationResult({
    required this.jobId,
    required this.status,
    required this.total,
    required this.generated,
    required this.failed,
    required this.errors,
  });
  final String jobId;
  final String status;
  final int total;
  final int generated;
  final int failed;
  final List<String> errors;
}

/// Generates signed certificate metadata plus portable PDF and high-resolution PNG artifacts.
abstract interface class CertificateGenerationServiceContract {
  Future<CertificateGenerationResult> generate({
    required String projectId,
    required String institutionId,
    void Function(int completed, int total)? onProgress,
  });
}

class CertificateGenerationService
    implements CertificateGenerationServiceContract {
  CertificateGenerationService(
    this.database,
    this.keyStorage, {
    CertificateArtifactStore? artifactStore,
  }) : artifactStore =
           artifactStore ?? SharedPreferencesCertificateArtifactStore();
  final AppDatabase database;
  final KeyStorage keyStorage;
  final CertificateArtifactStore artifactStore;
  Future<List<int>>? _arabicFontBytes;
  final Map<String, Future<List<int>?>> _templateBytesCache = {};
  Future<Map<String, List<int>>>? _projectFontBytes;
  PdfRenderWorker? _pdfWorker;

  @override
  Future<CertificateGenerationResult> generate({
    required String projectId,
    required String institutionId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final records = await database.query(
      DatabaseTables.records,
      where: {'project_id': projectId},
      columns: ['id', 'class_name', 'data_json'],
    );
    final rawFields = await database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': projectId},
      columns: [
        'class_name',
        'source',
        'font_id',
        'position_json',
        'style_json',
      ],
    );
    final fontRows = await database.query(
      DatabaseTables.fonts,
      columns: ['id', 'family'],
    );
    final fontFamiliesById = <String, String>{
      for (final font in fontRows)
        if (font['id'] != null && font['family'] != null)
          font['id'].toString(): font['family'].toString(),
    };
    final fields = rawFields.map((field) {
      final style = _decodeJsonMap(field['style_json']);
      final fontId = field['font_id']?.toString();
      final family = fontId == null ? null : fontFamiliesById[fontId];
      if (family != null && family.isNotEmpty) {
        style['font_family'] = family;
      }
      return <String, Object?>{...field, 'style_json': jsonEncode(style)};
    }).toList();
    final projects = await database.query(
      DatabaseTables.projects,
      where: {'id': projectId},
      columns: ['template_id', 'settings_json'],
    );
    final project = projects.isEmpty
        ? const <String, Object?>{}
        : projects.first;
    final templateId = project['template_id'] as String?;
    final templates = templateId == null
        ? const <Map<String, Object?>>[]
        : await database.query(
            DatabaseTables.templates,
            where: {'id': templateId},
            columns: ['file_path', 'width', 'height', 'dpi', 'format'],
          );
    final template = templates.isEmpty
        ? const <String, Object?>{}
        : templates.first;
    final templatePath = template['file_path'] as String? ?? '';
    final templateBytes = await _cachedTemplateBytes(templatePath);
    final projectSettings = _decodeProjectSettings(project['settings_json']);
    final mapping = _decodeMapping(projectSettings['mapping']);
    final issueDate = DateTime.now().toUtc().toIso8601String().split('T').first;
    final jobId =
        'generation-$projectId-${DateTime.now().microsecondsSinceEpoch}';
    if (records.isEmpty) {
      return CertificateGenerationResult(
        jobId: jobId,
        status: 'empty',
        total: 0,
        generated: 0,
        failed: 0,
        errors: const [
          'Import at least one recipient before generating certificates.',
        ],
      );
    }

    final errors = <String>[];
    var generated = 0;
    final keyPair = await _keyPair(projectId);
    for (var index = 0; index < records.length; index++) {
      await _yieldToUi();
      final record = records[index];
      final recordId = record['id']! as String;
      final completed = index + 1;
      try {
        try {
          final data = _decodeData(record['data_json']);
          final values = <String, dynamic>{
            'record_class':
                _mappedValue(data, mapping, 'record_class') ??
                record['class_name'] ??
                '${index + 1}',
            'issue_date': issueDate,
            ...data,
          };
          for (final entry in mapping.entries) {
            final value = _valueForKey(data, entry.key);
            if (value != null && entry.value != 'custom') {
              values[entry.value] = value;
            }
          }
          for (final field in fields) {
            final source = field['source'] as String?;
            final rawClassName = field['class_name'] as String?;
            final className = canonicalFieldClassId(
              rawClassName?.trim().isNotEmpty == true
                  ? rawClassName!
                  : source ?? '',
            );
            if (source != null && source.trim().isNotEmpty) {
              final value = _valueForKey(data, source) ?? '';
              values[className] = value;
              values[source] = value;
            }
          }
          final certificateId = 'certificate-$projectId-$recordId';
          final document = canonicalJsonBytes({
            'project_id': projectId,
            'record_id': recordId,
            'fields': values,
          });
          // Sign the unsigned verification record exactly once. Signing an
          // already signed record makes verification fail after regeneration.
          final signedRecord = await createVerificationRecord(
            {
              'institution_id': institutionId,
              'project_id': projectId,
              'certificate_id': certificateId,
              'record_id': recordId,
              'public_key': keyPair.publicRecord(),
              'fields': values,
            },
            document,
            keyPair.privateKey,
          );
          // The QR payload is rendered into the artifact itself. Including an
          // artifact hash inside that payload would create a circular hash, so
          // the signed document record is intentionally the QR source of truth.
          final pdfBytes = await _renderPdfInIsolate(
            values,
            fields,
            signedRecord['document_hash'] as String,
            signedRecord,
            templateBytes,
            template,
          );
          final pngBytes = CertificateArtifactRenderer.appendEmbeddedRecord(
            await _rasterizePdf(pdfBytes),
            signedRecord,
          );
          final savedArtifacts = await Future.wait([
            artifactStore.save(
              certificateId: certificateId,
              extension: 'pdf',
              bytes: pdfBytes,
            ),
            artifactStore.save(
              certificateId: certificateId,
              extension: 'png',
              bytes: pngBytes,
            ),
          ]);
          final pdfPath = savedArtifacts[0];
          final imagePath = savedArtifacts[1];
          final now = DateTime.now().toUtc().toIso8601String();
          final certificateValues = {
            'id': certificateId,
            'project_id': projectId,
            'record_id': recordId,
            'file_path': pdfPath,
            'image_path': imagePath,
            'document_json': utf8.decode(document),
            'status': 'signed',
            'document_hash': signedRecord['document_hash'],
            'created_at': now,
            'updated_at': now,
          };
          // Keep rendering and artifact I/O outside the SQLCipher transaction;
          // only the related certificate records are committed atomically.
          database.beginBatch();
          await database.upsert(DatabaseTables.certificates, certificateValues);
          final verificationId = 'verification-$certificateId';
          final verificationValues = {
            'id': verificationId,
            'certificate_id': certificateId,
            'institution_id': institutionId,
            'project_id': projectId,
            'payload_json': jsonEncode(signedRecord),
            'signature': signedRecord['signature'],
            'created_at': now,
          };
          await database.upsert(
            DatabaseTables.verificationRecords,
            verificationValues,
          );
          generated++;
        } catch (error) {
          final message = 'Row ${index + 1}: $error';
          errors.add(message);
          // Roll back the row's atomic certificate writes before recording
          // the failure outside the failed transaction.
          await database.endBatch();
        }
      } finally {
        await database.endBatch();
      }
      onProgress?.call(completed, records.length);
      await _yieldToUi();
    }
    final status = generated == records.length
        ? 'completed'
        : generated == 0
        ? 'failed'
        : 'partial';
    return CertificateGenerationResult(
      jobId: jobId,
      status: status,
      total: records.length,
      generated: generated,
      failed: records.length - generated,
      errors: errors,
    );
  }

  Future<List<int>> _renderPdfInIsolate(
    Map<String, dynamic> values,
    List<Map<String, Object?>> fields,
    String hash,
    Map<String, dynamic> record,
    List<int>? templateBytes,
    Map<String, Object?> template,
  ) async {
    final fontBytes = await _loadArabicFontBytes();
    final fontBytesByFamily = await (_projectFontBytes ??=
        _loadProjectFontBytes(fontBytes));
    final worker = _pdfWorker ??= await PdfRenderWorker.start(
      fontBytesByFamily: fontBytesByFamily,
      templateBytes: templateBytes,
      template: template,
    );
    return worker.render({
      'values': values,
      'fields': fields,
      'hash': hash,
      'record': record,
      // The worker owns the decoded/enhanced background. Keeping this null
      // prevents every certificate from decoding and transferring it again.
      'templateBytes': null,
      'template': template,
      'preparedBackgroundBytes': null,
      'preparedImageWidth': null,
      'preparedImageHeight': null,
    });
  }

  Future<Map<String, List<int>>> _loadProjectFontBytes(
    List<int> defaultFontBytes,
  ) async {
    final result = <String, List<int>>{'Cairo': defaultFontBytes};
    final rows = await database.query(DatabaseTables.fonts);
    for (final row in rows) {
      final family = row['family']?.toString().trim();
      final path = row['file_path']?.toString().trim();
      if (family == null || family.isEmpty || path == null || path.isEmpty) {
        continue;
      }
      final storedBytes = row['font_bytes'];
      final bytes = storedBytes is List
          ? List<int>.from(storedBytes)
          : await readTemplateBytes(path);
      if (bytes != null && bytes.isNotEmpty) result[family] = bytes;
    }
    return result;
  }

  Future<List<int>?> _cachedTemplateBytes(String path) async {
    if (path.isEmpty) return null;
    return (_templateBytesCache[path] ??= readTemplateBytes(
      path,
    )).then((bytes) => bytes == null ? null : List<int>.unmodifiable(bytes));
  }

  Future<List<int>> _rasterizePdf(List<int> pdfBytes) async {
    final raster = await Printing.raster(
      Uint8List.fromList(pdfBytes),
      dpi: 300,
    ).first;
    final pngBytes = await raster.toPng();
    return pngBytes;
  }

  Future<List<int>> _loadArabicFontBytes() async {
    return _arabicFontBytes ??= () async {
      final bytes = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    }();
  }

  Future<void> _yieldToUi() => Future<void>.delayed(Duration.zero);

  Future<CertificateKeyPair> _keyPair(String projectId) async {
    final stored = await keyStorage.read('project.$projectId.key');
    final seed = stored == null ? generateMasterKey() : _hexDecode(stored);
    if (stored == null) {
      await keyStorage.write(
        'project.$projectId.key',
        seed.map((value) => value.toRadixString(16).padLeft(2, '0')).join(),
      );
    }
    return CertificateKeyPair.fromSeed(seed);
  }

  List<int> _hexDecode(String value) => [
    for (var i = 0; i < value.length; i += 2)
      int.parse(value.substring(i, i + 2), radix: 16),
  ];
  Map<String, dynamic> _decodeData(Object? raw) {
    if (raw is! String) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  Map<String, dynamic> _decodeProjectSettings(Object? raw) {
    if (raw is! String || raw.isEmpty) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  Map<String, dynamic> _decodeJsonMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  Map<String, String> _decodeMapping(Object? raw) {
    if (raw is! String) return {};
    final value = jsonDecode(raw);
    if (value is! Map) return {};
    return value.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  String? _mappedValue(
    Map<String, dynamic> data,
    Map<String, String> mapping,
    String target,
  ) {
    for (final entry in mapping.entries) {
      if (entry.value == target) {
        final value = _valueForKey(data, entry.key);
        if (value != null) return value.toString();
      }
    }
    return null;
  }

  dynamic _valueForKey(Map<String, dynamic> data, String key) {
    final exact = data[key];
    if (exact != null) return exact;
    final normalizedKey = _normalizeKey(key);
    for (final entry in data.entries) {
      if (_normalizeKey(entry.key) == normalizedKey) return entry.value;
    }
    return null;
  }

  String _normalizeKey(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}
