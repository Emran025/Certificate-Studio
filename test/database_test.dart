import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_migrations.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/features/institution/data/repositories/institution_repository_impl.dart';
import 'package:certificate_studio/features/institution/domain/entities/institution.dart';
import 'package:certificate_studio/features/projects/data/repositories/project_repository_impl.dart';
import 'package:certificate_studio/features/projects/domain/entities/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAppDatabase database;

  setUp(() async {
    database = InMemoryAppDatabase();
    await database.open();
  });

  tearDown(() => database.close());

  test('opens at the latest schema version and exposes all tables', () async {
    expect(database.version, DatabaseSchema.version);
    await database.insert(DatabaseTables.settings, {
      'key': 'locale',
      'value_json': '"en"',
      'updated_at': DateTime.now().toIso8601String(),
    });
    expect(await database.query(DatabaseTables.settings), hasLength(1));
    expect(DatabaseMigrations.statementsForUpgrade(0), isNotEmpty);
  });

  test('persists and updates an institution', () async {
    final repository = InstitutionRepositoryImpl(database);
    final now = DateTime.utc(2026, 9, 12);
    final institution = Institution(
      id: 'institution-1',
      institutionId: 'academy-001',
      name: 'Certificate Academy',
      nameEn: 'Certificate Academy',
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(institution);
    expect((await repository.getCurrent())?.name, 'Certificate Academy');

    await repository.save(Institution(
      id: institution.id,
      institutionId: institution.institutionId,
      name: 'Updated Academy',
      createdAt: now,
      updatedAt: now,
    ));
    expect((await repository.getCurrent())?.name, 'Updated Academy');
  });

  test('filters projects by institution', () async {
    final repository = ProjectRepositoryImpl(database);
    final now = DateTime.utc(2026, 9, 12);

    for (final project in [
      Project(id: 'p1', institutionId: 'academy-001', name: 'Flutter', projectKeyReference: 'key-1', createdAt: now, updatedAt: now),
      Project(id: 'p2', institutionId: 'academy-002', name: 'English', projectKeyReference: 'key-2', createdAt: now, updatedAt: now),
    ]) {
      await repository.save(project);
    }

    expect(await repository.getAll(institutionId: 'academy-001'), hasLength(1));
    expect((await repository.getById('p2'))?.name, 'English');
  });
}
