import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:certificate_crypto/certificate_crypto.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:zxing2/qrcode.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/files/certificate_artifact_store.dart';
import '../../../core/security/keys/institution_key_manager.dart';
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
  Future<pw.Font>? _arabicFont;
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
        'generation-${projectId}-${DateTime.now().microsecondsSinceEpoch}';
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
          final className = field['class_name'] as String?;
          if (source != null && className != null) {
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
        final renderedArtifacts = await _renderArtifactsInIsolate(
          values,
          fields,
          signedRecord['document_hash'] as String,
          signedRecord,
          templateBytes,
          template,
        );
        final savedArtifacts = await Future.wait([
          artifactStore.save(
            certificateId: certificateId,
            extension: 'pdf',
            bytes: renderedArtifacts[0],
          ),
          artifactStore.save(
            certificateId: certificateId,
            extension: 'png',
            bytes: renderedArtifacts[1],
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

  Future<List<List<int>>> _renderArtifactsInIsolate(
    Map<String, dynamic> values,
    List<Map<String, Object?>> fields,
    String hash,
    Map<String, dynamic> record,
    List<int>? templateBytes,
    Map<String, Object?> template,
  ) async {
    final fontBytes = await _loadArabicFontBytes();
    return Isolate.run(
      () async => [
        await CertificateArtifactRenderer.renderPdf(
          values: values,
          fields: fields,
          hash: hash,
          record: record,
          templateBytes: templateBytes,
          template: template,
          fontBytes: fontBytes,
        ),
        CertificateArtifactRenderer.renderPng(
          values: values,
          fields: fields,
          hash: hash,
          record: record,
          templateBytes: templateBytes,
          template: template,
        ),
      ],
    );
  }

  Future<List<int>> _loadArabicFontBytes() async {
    return _arabicFontBytes ??= () async {
      final bytes = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    }();
  }

  Future<List<int>> _renderPdf(
    Map<String, dynamic> values,
    List<Map<String, Object?>> fields,
    String hash,
    Map<String, dynamic> record,
    List<int>? templateBytes,
    Map<String, Object?> template, {
    bool embedMarker = true,
  }) async {
    final document = pw.Document(title: 'Certificate');
    final arabicFont = await _loadArabicFont();
    final canvasWidth = _number(template['width'], 1000);
    final canvasHeight = _number(template['height'], 700);
    final dpi = _number(template['dpi'], 96);
    final background = templateBytes == null
        ? null
        : pw.MemoryImage(Uint8List.fromList(templateBytes));
    final pageWidth = canvasWidth / dpi * 72;
    final pageHeight = canvasHeight / dpi * 72;
    final qr = _qrWidget(encodeVerificationQrPayload(record), 220);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(
          children: [
            if (background != null)
              pw.Positioned.fill(
                child: pw.Image(background, fit: pw.BoxFit.fill),
              ),
            for (final field in fields)
              if (_fieldIsVisible(field))
                _pdfField(
                  values,
                  field,
                  canvasWidth,
                  canvasHeight,
                  pageWidth,
                  pageHeight,
                  arabicFont,
                ),
            pw.Positioned(
              left: 8,
              bottom: 6,
              child: pw.Text(hash, style: const pw.TextStyle(fontSize: 5)),
            ),
            pw.Positioned(right: 12, bottom: 12, child: qr),
          ],
        ),
      ),
    );
    final bytes = await document.save();
    return embedMarker
        ? [...bytes, ...utf8.encode(_embeddedMarker(record))]
        : bytes;
  }

  Future<pw.Font> _loadArabicFont() async {
    return _arabicFont ??= () async {
      final bytes = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      return pw.Font.ttf(bytes);
    }();
  }

  List<int> _renderPng(
    Map<String, dynamic> values,
    List<Map<String, Object?>> fields,
    String hash,
    Map<String, dynamic> record,
    List<int>? templateBytes,
    Map<String, Object?> template, {
    bool embedMarker = true,
  }) {
    final fallbackWidth = _number(template['width'], 1600).round();
    final fallbackHeight = _number(template['height'], 1100).round();
    final canvas = templateBytes == null
        ? img.Image(width: fallbackWidth, height: fallbackHeight)
        : img.decodeImage(Uint8List.fromList(templateBytes)) ??
              img.Image(width: fallbackWidth, height: fallbackHeight);
    if (templateBytes == null) {
      img.fill(canvas, color: img.ColorRgb8(250, 247, 240));
      img.drawRect(
        canvas,
        x1: 35,
        y1: 35,
        x2: canvas.width - 35,
        y2: canvas.height - 35,
        color: img.ColorRgb8(45, 93, 73),
        thickness: 8,
      );
    }
    final designWidth = _number(template['width'], 1000);
    final designHeight = _number(template['height'], 700);
    for (final field in fields) {
      if (!_fieldIsVisible(field)) continue;
      final position = _jsonMap(field['position_json']);
      final style = _jsonMap(field['style_json']);
      final className = field['class_name'] as String? ?? '';
      final text = '${values[className] ?? ''}';
      if (text.isEmpty) continue;
      final x = (_number(position['x'], 0) / designWidth * canvas.width)
          .round();
      final y = (_number(position['y'], 0) / designHeight * canvas.height)
          .round();
      img.drawString(
        canvas,
        text,
        font: _bitmapFont(_number(style['font_size'], 24)),
        x: x,
        y: y,
        color: _imageColor(style['color'] as String?),
      );
    }
    img.drawString(
      canvas,
      'Verification hash: $hash',
      font: img.arial14,
      x: 180,
      y: canvas.height - 40,
      color: img.ColorRgb8(90, 90, 90),
    );
    _drawQr(
      canvas,
      encodeVerificationQrPayload(record),
      x: canvas.width - 540,
      y: canvas.height - 540,
      size: 520,
    );
    final bytes = img.encodePng(canvas);
    return embedMarker
        ? [...bytes, ...utf8.encode(_embeddedMarker(record))]
        : bytes;
  }

  String _embeddedMarker(Map<String, dynamic> record) =>
      'CSTUDIO_RECORD_V1:${base64UrlEncodeNoPadding(utf8.encode(canonicalJson(record)))}';

  pw.Widget _qrWidget(String payload, double size) {
    final matrix = Encoder.encode(payload, ErrorCorrectionLevel.m).matrix!;
    final count = matrix.width;
    const quietModules = 4;
    final module = size / (count + quietModules * 2);
    final totalSize = module * (count + quietModules * 2);
    return pw.Container(
      width: totalSize,
      height: totalSize,
      color: PdfColors.white,
      padding: pw.EdgeInsets.all(module * quietModules),
      child: pw.CustomPaint(
        size: PdfPoint(module * count, module * count),
        painter: (canvas, size) {
          canvas.setFillColor(PdfColors.black);
          for (var x = 0; x < count; x++) {
            for (var y = 0; y < count; y++) {
              if (matrix.get(x, y) == 1) {
                canvas.drawRect(
                  x * module,
                  size.y - (y + 1) * module,
                  module,
                  module,
                );
                canvas.fillPath();
              }
            }
          }
        },
      ),
    );
  }

  void _drawQr(
    img.Image canvas,
    String payload, {
    required int x,
    required int y,
    required int size,
  }) {
    final matrix = Encoder.encode(payload, ErrorCorrectionLevel.m).matrix!;
    const quietModules = 4;
    final module =
        (size / (matrix.width + quietModules * 2)).floor().clamp(2, 20) as int;
    final totalSize = (matrix.width + quietModules * 2) * module;
    final originX = x.clamp(0, canvas.width - totalSize) as int;
    final originY = y.clamp(0, canvas.height - totalSize) as int;
    img.fillRect(
      canvas,
      x1: originX,
      y1: originY,
      x2: originX + totalSize - 1,
      y2: originY + totalSize - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
    for (var row = 0; row < matrix.height; row++) {
      for (var col = 0; col < matrix.width; col++) {
        if (matrix.get(col, row) == 1) {
          final left = originX + (quietModules + col) * module;
          final top = originY + (quietModules + row) * module;
          final right = left + module - 1;
          final bottom = top + module - 1;
          img.fillRect(
            canvas,
            x1: left,
            y1: top,
            x2: right,
            y2: bottom,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }
  }

  pw.Widget _pdfField(
    Map<String, dynamic> values,
    Map<String, Object?> field,
    double canvasWidth,
    double canvasHeight,
    double pageWidth,
    double pageHeight,
    pw.Font font,
  ) {
    final position = _jsonMap(field['position_json']);
    final style = _jsonMap(field['style_json']);
    final x = _number(position['x'], 0) / canvasWidth * pageWidth;
    final y = _number(position['y'], 0) / canvasHeight * pageHeight;
    final width = _number(position['width'], 420) / canvasWidth * pageWidth;
    final height = _number(position['height'], 64) / canvasHeight * pageHeight;
    final className = field['class_name'] as String? ?? '';
    final alignment = switch (style['alignment']) {
      'center' => pw.TextAlign.center,
      'right' => pw.TextAlign.right,
      _ => pw.TextAlign.left,
    };
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Text(
          '${values[className] ?? ''}',
          textAlign: alignment,
          style: pw.TextStyle(
            font: font,
            fontFallback: [font],
            fontSize: _number(style['font_size'], 24),
          ),
        ),
      ),
    );
  }

  bool _fieldIsVisible(Map<String, Object?> field) =>
      _jsonMap(field['style_json'])['visible'] != false;

  Map<String, dynamic> _jsonMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

  Future<void> _yieldToUi() => Future<void>.delayed(Duration.zero);

  img.BitmapFont _bitmapFont(double size) {
    if (size >= 40) return img.arial48;
    if (size >= 28) return img.arial24;
    return img.arial14;
  }

  img.Color _imageColor(String? value) {
    final hex = (value ?? '#20332B').replaceFirst('#', '');
    final normalized = hex.length == 6 ? hex : '20332B';
    return img.ColorRgb8(
      int.parse(normalized.substring(0, 2), radix: 16),
      int.parse(normalized.substring(2, 4), radix: 16),
      int.parse(normalized.substring(4, 6), radix: 16),
    );
  }

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
