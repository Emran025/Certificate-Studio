import 'dart:convert';
import 'dart:io';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/certificates/data/services/certificate_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'generates with a non-sendable native database outside the image isolate',
    () async {
      final database = _DatabaseWithNativeHandle();
      await database.open();
      final now = DateTime.now().toUtc().toIso8601String();
      final templatePath =
          '${Directory.current.path}/assets/images/certificate_studio_logo.png';
      final artifacts = InMemoryCertificateArtifactStore();

      try {
        await database.insert(DatabaseTables.templates, {
          'id': 'template-1',
          'name': 'Test background',
          'file_path': templatePath,
          'width': 512,
          'height': 512,
          'dpi': 96,
          'format': 'png',
          'created_at': now,
          'updated_at': now,
        });
        await database.insert(DatabaseTables.projects, {
          'id': 'project-1',
          'institution_id': 'institution-1',
          'name': 'Test project',
          'template_id': 'template-1',
          'project_key_reference': 'project-1',
          'version': 1,
          'created_at': now,
          'updated_at': now,
        });
        await database.insert(DatabaseTables.records, {
          'id': 'record-1',
          'project_id': 'project-1',
          'class_name': 'A001',
          'data_json': jsonEncode({'name': 'Test Recipient'}),
          'row_number': 1,
          'created_at': now,
          'updated_at': now,
        });

        final result = await CertificateGenerationService(
          database,
          InMemoryKeyStorage(),
          artifactStore: artifacts,
          canvasCapture:
              ({
                required values,
                required fields,
                required record,
                required templateBytes,
                required template,
                required fontBytesByFamily,
              }) async => templateBytes ?? [],
        ).generate(projectId: 'project-1', institutionId: 'institution-1');

        expect(result.status, 'completed');
        expect(result.generated, 1);
        final certificate = (await database.query(
          DatabaseTables.certificates,
        )).single;
        expect(
          await artifacts.read(certificate['image_path']! as String),
          isNotNull,
        );
      } finally {
        await database.close();
        database.closeNativeHandle();
      }
    },
  );
}

class _DatabaseWithNativeHandle extends InMemoryAppDatabase {
  final sqlite.Database _nativeHandle = sqlite.sqlite3.openInMemory();

  void closeNativeHandle() => _nativeHandle.close();
}
