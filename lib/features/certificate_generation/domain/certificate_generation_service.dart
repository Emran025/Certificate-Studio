import 'dart:convert';
import 'dart:isolate';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/files/certificate_artifact_store.dart';
import '../../../core/security/keys/institution_key_manager.dart';
import '../../../shared/utils/field_identifier.dart';
import 'template_bytes.dart';
import 'certificate_artifact_renderer.dart';

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
class CertificateGenerationService {
  CertificateGenerationService(
    this.database,
    this.keyStorage, {
    CertificateArtifactStore? artifactStore,
  }) : artifactStore = artifactStore ?? CertificateArtifactStore();
  final AppDatabase database;
  final KeyStorage keyStorage;
  final CertificateArtifactStore artifactStore;
  Future<List<int>>? _arabicFontBytes;

  Future<CertificateGenerationResult> generate({
    required String projectId,
    required String institutionId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final students = await database.query(
      DatabaseTables.students,
      where: {'project_id': projectId},
    );
    final fields = await database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': projectId},
    );
    final projects = await database.query(
      DatabaseTables.projects,
      where: {'id': projectId},
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
          );
    final template = templates.isEmpty
        ? const <String, Object?>{}
        : templates.first;
    final templateBytes = await readTemplateBytes(
      template['file_path'] as String? ?? '',
    );
    final mappingRows = await database.query(
      DatabaseTables.settings,
      where: {'key': 'mapping:$projectId'},
    );
    final mapping = _decodeMapping(
      mappingRows.isEmpty ? null : mappingRows.first['value_json'],
    );
    final jobId =
        'generation-$projectId-${DateTime.now().microsecondsSinceEpoch}';
    final startedAt = DateTime.now().toUtc().toIso8601String();
    await database.insert(DatabaseTables.generationJobs, {
      'id': jobId,
      'project_id': projectId,
      'status': students.isEmpty ? 'empty' : 'running',
      'total_count': students.length,
      'completed_count': 0,
      'failed_count': 0,
      'started_at': startedAt,
      'completed_at': students.isEmpty ? startedAt : null,
      'error_message': students.isEmpty
          ? 'No recipient data was imported.'
          : null,
    });
    if (students.isEmpty) {
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
    database.beginBatch();
    try {
    for (var index = 0; index < students.length; index++) {
      await _yieldToUi();
      final student = students[index];
      final studentId = student['id']! as String;
      final itemId = '$jobId-item-$index';
      await database.insert(DatabaseTables.generationItems, {
        'id': itemId,
        'job_id': jobId,
        'student_id': studentId,
        'status': 'running',
      });
      try {
        final data = _decodeData(student['data_json']);
        final values = <String, dynamic>{
          'student_class':
              _mappedValue(data, mapping, 'student_class') ??
              student['class_name'] ??
              '${index + 1}',
          'issue_date': DateTime.now()
              .toUtc()
              .toIso8601String()
              .split('T')
              .first,
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
        final certificateId = 'certificate-$projectId-$studentId';
        final document = canonicalJsonBytes({
          'project_id': projectId,
          'student_id': studentId,
          'fields': values,
        });
        // Sign the unsigned verification record exactly once. Signing an
        // already signed record makes verification fail after regeneration.
        final signedRecord = await createVerificationRecord(
          {
            'institution_id': institutionId,
            'project_id': projectId,
            'certificate_id': certificateId,
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
        final pngBytes = await _rasterizePdf(pdfBytes);
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
          'student_id': studentId,
          'file_path': pdfPath,
          'image_path': imagePath,
          'document_json': utf8.decode(document),
          'status': 'signed',
          'document_hash': signedRecord['document_hash'],
          'created_at': now,
          'updated_at': now,
        };
        final existing = await database.query(
          DatabaseTables.certificates,
          where: {'id': certificateId},
        );
        if (existing.isEmpty) {
          await database.insert(DatabaseTables.certificates, certificateValues);
        } else {
          await database.update(
            DatabaseTables.certificates,
            certificateId,
            certificateValues,
          );
        }
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
        final existingVerification = await database.query(
          DatabaseTables.verificationRecords,
          where: {'certificate_id': certificateId},
        );
        if (existingVerification.isEmpty) {
          await database.insert(
            DatabaseTables.verificationRecords,
            verificationValues,
          );
        } else {
          await database.update(
            DatabaseTables.verificationRecords,
            verificationId,
            verificationValues,
          );
        }
        await database.update(DatabaseTables.generationItems, itemId, {
          'certificate_id': certificateId,
          'status': 'completed',
          'completed_at': now,
        });
        generated++;
      } catch (error) {
        final message = 'Row ${index + 1}: $error';
        errors.add(message);
        await database.update(DatabaseTables.generationItems, itemId, {
          'status': 'failed',
          'error_message': message,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      final completed = index + 1;
      await database.update(DatabaseTables.generationJobs, jobId, {
        'completed_count': completed,
        'failed_count': completed - generated,
      });
      onProgress?.call(completed, students.length);
      await _yieldToUi();
    }
    } finally {
      await database.endBatch();
    }
    final status = generated == students.length
        ? 'completed'
        : generated == 0
        ? 'failed'
        : 'partial';
    await database.update(DatabaseTables.generationJobs, jobId, {
      'status': status,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'error_message': errors.isEmpty ? null : errors.join('\n'),
    });
    return CertificateGenerationResult(
      jobId: jobId,
      status: status,
      total: students.length,
      generated: generated,
      failed: students.length - generated,
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
    final fontBytesByFamily = await _loadProjectFontBytes(fontBytes);
    return Isolate.run(
      () => CertificateArtifactRenderer.renderPdf(
        values: values,
        fields: fields,
        hash: hash,
        record: record,
        templateBytes: templateBytes,
        template: template,
        fontBytesByFamily: fontBytesByFamily,
      ),
    );
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
      final bytes = await readTemplateBytes(path);
      if (bytes != null && bytes.isNotEmpty) result[family] = bytes;
    }
    return result;
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
