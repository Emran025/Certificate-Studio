import 'dart:convert';
import 'dart:async';
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
  final Map<String, Future<List<int>?>> _templateBytesCache = {};
  Future<Map<String, List<int>>>? _projectFontBytes;
  _PdfRenderWorker? _pdfWorker;

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
    final templatePath = template['file_path'] as String? ?? '';
    final templateBytes = await _cachedTemplateBytes(templatePath);
    final mappingRows = await database.query(
      DatabaseTables.settings,
      where: {'key': 'mapping:$projectId'},
    );
    final mapping = _decodeMapping(
      mappingRows.isEmpty ? null : mappingRows.first['value_json'],
    );
    final existingCertificates = {
      for (final row in await database.query(
        DatabaseTables.certificates,
        where: {'project_id': projectId},
      ))
        row['id']!.toString(): row,
    };
    final existingVerifications = {
      for (final row in await database.query(
        DatabaseTables.verificationRecords,
        where: {'project_id': projectId},
      ))
        row['certificate_id']!.toString(): row,
    };
    final issueDate = DateTime.now().toUtc().toIso8601String().split('T').first;
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
            'student_id': studentId,
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
          'student_id': studentId,
          'file_path': pdfPath,
          'image_path': imagePath,
          'document_json': utf8.decode(document),
          'status': 'signed',
          'document_hash': signedRecord['document_hash'],
          'created_at': now,
          'updated_at': now,
        };
        if (!existingCertificates.containsKey(certificateId)) {
          await database.insert(DatabaseTables.certificates, certificateValues);
        } else {
          await database.update(
            DatabaseTables.certificates,
            certificateId,
            certificateValues,
          );
        }
        existingCertificates[certificateId] = certificateValues;
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
        if (!existingVerifications.containsKey(certificateId)) {
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
        existingVerifications[certificateId] = verificationValues;
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
    final fontBytesByFamily = await (_projectFontBytes ??= _loadProjectFontBytes(fontBytes));
    final worker = _pdfWorker ??= await _PdfRenderWorker.start(
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
      final bytes = await readTemplateBytes(path);
      if (bytes != null && bytes.isNotEmpty) result[family] = bytes;
    }
    return result;
  }

  Future<List<int>?> _cachedTemplateBytes(String path) async {
    if (path.isEmpty) return null;
    return (_templateBytesCache[path] ??= readTemplateBytes(path)).then(
      (bytes) => bytes == null ? null : List<int>.unmodifiable(bytes),
    );
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

class _PdfRenderWorker {
  _PdfRenderWorker._(this._isolate, this._sendPort, this._receivePort);

  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  int _nextId = 0;
  final Map<int, Completer<List<int>>> _pending = {};

  static Future<_PdfRenderWorker> start({
    required Map<String, List<int>> fontBytesByFamily,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
  }) async {
    final handshake = ReceivePort();
    final responsePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _pdfRenderWorkerEntry,
      <String, Object?>{
        'reply': handshake.sendPort,
        'responses': responsePort.sendPort,
        'fonts': fontBytesByFamily,
        'templateBytes': templateBytes,
        'template': template,
      },
    );
    final sendPort = await handshake.first as SendPort;
    final worker = _PdfRenderWorker._(isolate, sendPort, responsePort);
    responsePort.listen(worker._handleResponse);
    return worker;
  }

  Future<List<int>> render(Map<String, Object?> args) {
    final id = _nextId++;
    final completer = Completer<List<int>>();
    _pending[id] = completer;
    _sendPort.send(<Object?>[id, args]);
    return completer.future;
  }

  void _handleResponse(dynamic message) {
    if (message is! List || message.length < 2) return;
    final completer = _pending.remove(message[0] as int);
    if (completer == null) return;
    final error = message[1];
    if (error is String) {
      completer.completeError(StateError(error));
    } else {
      completer.complete(List<int>.from(error as List));
    }
  }
}

void _pdfRenderWorkerEntry(Map<String, Object?> init) {
  final commands = ReceivePort();
  (init['reply'] as SendPort).send(commands.sendPort);
  final fonts = Map<String, List<int>>.from(
    (init['fonts'] as Map).map(
      (key, value) => MapEntry(key.toString(), List<int>.from(value as List)),
    ),
  );
  final prepared = CertificateArtifactRenderer.preparePdfBackground(
    init['templateBytes'] == null
        ? null
        : List<int>.from(init['templateBytes'] as List),
    Map<String, Object?>.from(init['template'] as Map),
  );
  final background = prepared?.bytes;
  final backgroundWidth = prepared?.width;
  final backgroundHeight = prepared?.height;
  commands.listen((message) async {
    if (message is! List || message.length < 2) return;
    final id = message[0];
    try {
      final args = Map<String, Object?>.from(message[1] as Map);
      final bytes = await CertificateArtifactRenderer.renderPdf(
        values: Map<String, dynamic>.from(args['values'] as Map),
        fields: [
          for (final field in args['fields'] as List)
            Map<String, Object?>.from(field as Map),
        ],
        hash: args['hash'] as String,
        record: Map<String, dynamic>.from(args['record'] as Map),
        templateBytes: null,
        template: Map<String, Object?>.from(args['template'] as Map),
        fontBytesByFamily: fonts,
        preparedBackgroundBytes: background,
        preparedImageWidth: backgroundWidth,
        preparedImageHeight: backgroundHeight,
      );
      (init['responses'] as SendPort).send(<Object?>[id, bytes]);
    } catch (error, stack) {
      (init['responses'] as SendPort).send(<Object?>[id, '$error\n$stack']);
    }
  });
}
