import 'dart:convert';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/certificates/data/services/certificate_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const runNativeGenerationTests = bool.fromEnvironment(
    'RUN_NATIVE_GENERATION_TESTS',
  );

  if (runNativeGenerationTests) {
    test(
      'regenerates and updates the same certificate without history tables',
      () async {
        final database = InMemoryAppDatabase();
        await database.open();
        final storage = InMemoryKeyStorage();
        final artifacts = InMemoryCertificateArtifactStore();
        await database.insert(DatabaseTables.records, {
          'id': 'record-1',
          'project_id': 'project-1',
          'class_name': 'A001',
          'data_json': jsonEncode({'name': 'Ahmed Ali', 'course': 'Flutter'}),
          'row_number': 1,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        final service = CertificateGenerationService(
          database,
          storage,
          artifactStore: artifacts,
        );
        final first = await service.generate(
          projectId: 'project-1',
          institutionId: 'institution-1',
        );
        final second = await service.generate(
          projectId: 'project-1',
          institutionId: 'institution-1',
        );

        expect(first.status, 'completed');
        expect(first.generated, 1);
        expect(second.generated, 1);
        expect(await database.query(DatabaseTables.certificates), hasLength(1));
        expect(
          await database.query(DatabaseTables.verificationRecords),
          hasLength(1),
        );
        final certificate = (await database.query(
          DatabaseTables.certificates,
        )).single;
        expect(
          certificate['file_path'],
          startsWith('artifact://certificates/'),
        );
        expect(certificate['image_path'], endsWith('.png'));
        expect(
          (await artifacts.read(
            certificate['file_path']! as String,
          ))!.sublist(0, 4),
          [37, 80, 68, 70],
        );
        expect(
          (await artifacts.read(
            certificate['image_path']! as String,
          ))!.sublist(0, 8),
          [137, 80, 78, 71, 13, 10, 26, 10],
        );
      },
    );
  }

  test('returns an empty result instead of silently succeeding', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final result = await CertificateGenerationService(
      database,
      InMemoryKeyStorage(),
    ).generate(projectId: 'project-empty', institutionId: 'institution-1');

    expect(result.status, 'empty');
    expect(result.failed, 0);
    expect(result.errors, isNotEmpty);
  });

  if (runNativeGenerationTests) {
    test(
      'applies persisted column mappings to generated certificate fields',
      () async {
        final database = InMemoryAppDatabase();
        await database.open();
        await database.insert(DatabaseTables.records, {
          'id': 'record-mapped',
          'project_id': 'project-mapped',
          'class_name': 'fallback',
          'data_json': jsonEncode({'اسم الطالب': 'سارة', 'الدورة': 'Flutter'}),
          'row_number': 1,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        await database.insert(DatabaseTables.projects, {
          'id': 'project-mapped',
          'institution_id': 'institution-1',
          'name': 'Mapped project',
          'settings_json': jsonEncode({
            'mapping': {'اسم المستلم': 'recipient', 'الدورة': 'course'},
          }),
          'project_key_reference': 'project-mapped',
          'version': 1,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        final result = await CertificateGenerationService(
          database,
          InMemoryKeyStorage(),
        ).generate(projectId: 'project-mapped', institutionId: 'institution-1');

        expect(result.status, 'completed');
        final certificate = (await database.query(
          DatabaseTables.certificates,
        )).single;
        final document =
            jsonDecode(certificate['document_json']! as String) as Map;
        final fields = document['fields'] as Map;
        expect(fields['recipient'], 'سارة');
        expect(fields['course'], 'Flutter');
      },
    );
  }
}
