import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/certificates/data/services/certificate_generation_service.dart';
import 'package:certificate_studio/features/certificates/presentation/widgets/certificate_canvas_visual.dart';
import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';

const _projectId = 'windows-release-smoke';
const _institutionId = 'windows-release-smoke-institution';
const _expectedRows = 9;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reportPath =
      Platform.environment['CERTIFICATE_STUDIO_SMOKE_REPORT'] ??
      'certificate-generation-release-smoke.json';
  final database = InMemoryAppDatabase();

  try {
    await database.open();
    await _seed(database);
    runApp(
      _ReleaseGenerationSmokeApp(database: database, reportPath: reportPath),
    );
  } on Object catch (error, stackTrace) {
    await _writeReport(reportPath, {
      'passed': false,
      'operatingSystem': Platform.operatingSystem,
      'releaseMode': kReleaseMode,
      'profileMode': kProfileMode,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
    exit(2);
  }
}

Future<void> _seed(InMemoryAppDatabase database) async {
  final now = DateTime.now().toUtc().toIso8601String();
  await database.insert(DatabaseTables.projects, {
    'id': _projectId,
    'institution_id': _institutionId,
    'name': 'Windows Release Smoke Test',
    'project_key_reference': _projectId,
    'version': 1,
    'created_at': now,
    'updated_at': now,
  });
  await database.insert(DatabaseTables.certificateFields, {
    'id': 'field-recipient-name',
    'project_id': _projectId,
    'class_name': 'recipient_name',
    'source': 'recipient_name',
    'position_json': jsonEncode({'x': 20, 'y': 20, 'width': 280, 'height': 70}),
    'style_json': jsonEncode({
      'font_family': 'Cairo',
      'font_size': 28,
      'color': '#20332B',
      'alignment': 'center',
      'direction': 'ltr',
      'visible': true,
    }),
    'created_at': now,
    'updated_at': now,
  });

  for (var row = 1; row <= _expectedRows; row++) {
    final recordId = 'record-${row.toString().padLeft(2, '0')}';
    await database.insert(DatabaseTables.records, {
      'id': recordId,
      'project_id': _projectId,
      'class_name': 'A${row.toString().padLeft(3, '0')}',
      'data_json': jsonEncode({'recipient_name': 'Recipient $row'}),
      'row_number': row,
      'created_at': now,
      'updated_at': now,
    });
  }
}

class _ReleaseGenerationSmokeApp extends StatefulWidget {
  const _ReleaseGenerationSmokeApp({
    required this.database,
    required this.reportPath,
  });

  final InMemoryAppDatabase database;
  final String reportPath;

  @override
  State<_ReleaseGenerationSmokeApp> createState() =>
      _ReleaseGenerationSmokeAppState();
}

class _ReleaseGenerationSmokeAppState
    extends State<_ReleaseGenerationSmokeApp> {
  final _canvasKey = GlobalKey<CertificateCanvasSnapshotHostState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(child: CertificateCanvasSnapshotHost(key: _canvasKey)),
    ),
  );

  Future<void> _run() async {
    try {
      final result = await CertificateGenerationService(
        widget.database,
        InMemoryKeyStorage(),
        canvasCapture: _capture,
      ).generate(projectId: _projectId, institutionId: _institutionId);
      final passed =
          result.status == 'completed' &&
          result.total == _expectedRows &&
          result.generated == _expectedRows &&
          result.failed == 0;
      await widget.database.close();
      await _writeReport(widget.reportPath, {
        'passed': passed,
        'operatingSystem': Platform.operatingSystem,
        'releaseMode': kReleaseMode,
        'profileMode': kProfileMode,
        'expected': _expectedRows,
        'status': result.status,
        'total': result.total,
        'generated': result.generated,
        'failed': result.failed,
        'errors': result.errors,
      });
      exit(passed ? 0 : 1);
    } on Object catch (error, stackTrace) {
      if (widget.database.isOpen) await widget.database.close();
      await _writeReport(widget.reportPath, {
        'passed': false,
        'operatingSystem': Platform.operatingSystem,
        'releaseMode': kReleaseMode,
        'profileMode': kProfileMode,
        'expected': _expectedRows,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });
      exit(2);
    }
  }

  Future<List<int>> _capture({
    required Map<String, dynamic> values,
    required List<Map<String, Object?>> fields,
    required Map<String, dynamic> record,
    required List<int>? templateBytes,
    required Map<String, Object?> template,
    required Map<String, List<int>> fontBytesByFamily,
  }) {
    final canvas = _canvasKey.currentState;
    if (canvas == null) {
      throw StateError('The smoke-test certificate canvas did not mount.');
    }
    return canvas.capture(
      values: values,
      fields: fields,
      record: record,
      templateBytes: templateBytes,
      template: {...template, 'width': 320, 'height': 224, 'dpi': 96},
      fontBytesByFamily: fontBytesByFamily,
    );
  }
}

Future<void> _writeReport(String path, Map<String, Object?> report) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(report), flush: true);
}
