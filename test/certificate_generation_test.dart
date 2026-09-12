import 'dart:convert';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/certificate_generation/domain/certificate_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tracks a generation job and updates the same certificate on rerun', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final storage = InMemoryKeyStorage();
    await database.insert(DatabaseTables.students, {
      'id': 'student-1',
      'project_id': 'project-1',
      'class_name': 'A001',
      'data_json': jsonEncode({'name': 'Ahmed Ali', 'course': 'Flutter'}),
      'row_number': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final service = CertificateGenerationService(database, storage);
    final first = await service.generate(projectId: 'project-1', institutionId: 'institution-1');
    final second = await service.generate(projectId: 'project-1', institutionId: 'institution-1');

    expect(first.status, 'completed');
    expect(first.generated, 1);
    expect(second.generated, 1);
    expect(await database.query(DatabaseTables.certificates), hasLength(1));
    expect(await database.query(DatabaseTables.verificationRecords), hasLength(1));
    expect(await database.query(DatabaseTables.generationJobs), hasLength(2));
    expect(await database.query(DatabaseTables.generationItems, where: {'status': 'completed'}), hasLength(2));
  });

  test('records an empty generation job instead of silently succeeding', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final result = await CertificateGenerationService(database, InMemoryKeyStorage()).generate(
      projectId: 'project-empty',
      institutionId: 'institution-1',
    );

    expect(result.status, 'empty');
    expect(result.failed, 0);
    expect(result.errors, isNotEmpty);
    expect((await database.query(DatabaseTables.generationJobs)).single['status'], 'empty');
  });

  test('applies persisted column mappings to generated certificate fields', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    await database.insert(DatabaseTables.students, {
      'id': 'student-mapped',
      'project_id': 'project-mapped',
      'class_name': 'fallback',
      'data_json': jsonEncode({'اسم الطالب': 'سارة', 'الدورة': 'Flutter'}),
      'row_number': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await database.insert(DatabaseTables.settings, {
      'key': 'mapping:project-mapped',
      'value_json': jsonEncode({
        'اسم الطالب': 'student_name',
        'الدورة': 'course_name',
      }),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final result = await CertificateGenerationService(
      database,
      InMemoryKeyStorage(),
    ).generate(projectId: 'project-mapped', institutionId: 'institution-1');

    expect(result.status, 'completed');
    final certificate = (await database.query(DatabaseTables.certificates)).single;
    final document = jsonDecode(certificate['document_json']! as String) as Map;
    final fields = document['fields'] as Map;
    expect(fields['student_name'], 'سارة');
    expect(fields['course_name'], 'Flutter');
  });
}
