import 'dart:convert';

import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_migrations.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/entities/operation_result.dart';
import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/core/security/keys/project_key_manager.dart';
import 'package:certificate_studio/features/app/data/datasources/workspace_data_source_impl.dart';
import 'package:certificate_studio/features/app/data/repositories/workspace_repository_impl.dart';
import 'package:certificate_studio/features/app/domain/usecases/get_workspace_metrics.dart';
import 'package:certificate_studio/features/certificates/data/datasources/certificate_data_source_impl.dart';
import 'package:certificate_studio/features/certificates/data/repositories/certificate_repository_impl.dart';
import 'package:certificate_studio/features/certificates/domain/usecases/get_certificates.dart';
import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:certificate_studio/features/data_import/domain/repositories/data_import_repository.dart';
import 'package:certificate_studio/features/data_import/domain/usecases/import_excel.dart';
import 'package:certificate_studio/features/data_import/domain/usecases/paste_table.dart';
import 'package:certificate_studio/features/fonts/data/datasources/font_data_source_impl.dart';
import 'package:certificate_studio/features/fonts/data/repositories/font_repository_impl.dart';
import 'package:certificate_studio/features/fonts/domain/entities/font_asset.dart';
import 'package:certificate_studio/features/institution/data/datasources/institution_data_source_impl.dart';
import 'package:certificate_studio/features/institution/data/repositories/institution_repository_impl.dart';
import 'package:certificate_studio/features/institution/domain/entities/institution.dart';
import 'package:certificate_studio/features/projects/data/datasources/project_data_source_impl.dart';
import 'package:certificate_studio/features/projects/data/repositories/project_repository_impl.dart';
import 'package:certificate_studio/features/projects/domain/entities/project.dart';
import 'package:certificate_studio/features/projects/domain/repositories/project_repository.dart';
import 'package:certificate_studio/features/projects/domain/services/project_key_service.dart';
import 'package:certificate_studio/features/projects/domain/usecases/create_project.dart';
import 'package:certificate_studio/features/projects/domain/usecases/delete_project.dart';
import 'package:certificate_studio/features/settings/data/datasources/settings_data_source_impl.dart';
import 'package:certificate_studio/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:certificate_studio/features/settings/domain/entities/app_settings.dart';
import 'package:certificate_studio/features/templates/data/datasources/template_data_source_impl.dart';
import 'package:certificate_studio/features/templates/data/repositories/template_repository_impl.dart';
import 'package:certificate_studio/features/templates/domain/entities/template_asset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAppDatabase database;

  setUp(() async {
    database = InMemoryAppDatabase();
    await database.open();
  });

  tearDown(() => database.close());

  test(
    'in-memory database supports CRUD, projections, upsert and deleteWhereIn',
    () async {
      await database.insert(DatabaseTables.settings, {
        'key': 'one',
        'value_json': '1',
        'updated_at': 'now',
      });
      expect(await database.query(DatabaseTables.settings, columns: ['key']), [
        {'key': 'one'},
      ]);
      await database.upsert(DatabaseTables.settings, {
        'key': 'one',
        'value_json': '2',
        'updated_at': 'later',
      }, conflictColumn: 'key');
      expect(
        (await database.query(DatabaseTables.settings)).single['value_json'],
        '2',
      );
      await database.insert(DatabaseTables.settings, {
        'key': 'two',
        'value_json': '2',
        'updated_at': 'now',
      });
      await database.deleteWhereIn(DatabaseTables.settings, 'key', [
        'one',
        'two',
      ]);
      expect(await database.query(DatabaseTables.settings), isEmpty);
      expect(() => database.query('missing'), throwsArgumentError);
    },
  );

  test(
    'database migration list is contiguous and rejects invalid versions',
    () {
      final migrations = DatabaseMigrations.migrations;
      expect(migrations.first.fromVersion, 0);
      for (var i = 1; i < migrations.length; i++) {
        expect(migrations[i].fromVersion, migrations[i - 1].toVersion);
      }
      expect(migrations.last.toVersion, DatabaseSchema.version);
      expect(
        DatabaseMigrations.statementsForUpgrade(9),
        anyElement(contains('columns_json')),
      );
      expect(
        () => DatabaseMigrations.statementsForUpgrade(-1),
        throwsArgumentError,
      );
      expect(
        () =>
            DatabaseMigrations.statementsForUpgrade(DatabaseSchema.version + 1),
        throwsArgumentError,
      );
    },
  );

  test(
    'institution and settings repositories handle empty, save and reload paths',
    () async {
      final institutions = InstitutionRepositoryImpl(
        InstitutionDataSourceImpl(database),
      );
      expect(await institutions.getCurrent(), isNull);
      final now = DateTime.utc(2026);
      final saved = await institutions.save(InstitutionForTest().value(now));
      expect(saved.name, 'Test Academy');
      expect((await institutions.getCurrent())?.institutionId, 'academy-test');
      await institutions.delete(saved.id);
      expect(await institutions.getCurrent(), isNull);

      final settings = SettingsRepositoryImpl(SettingsDataSourceImpl(database));
      expect((await settings.loadAppSettings()).languageCode, 'ar');
      const custom = AppSettings(
        themeMode: AppThemeMode.dark,
        languageCode: 'en',
        accentColorValue: 0xFF123456,
      );
      await settings.saveAppSettings(custom);
      final restored = await settings.loadAppSettings();
      expect(restored.themeMode, AppThemeMode.dark);
      expect(restored.languageCode, 'en');
      expect(restored.accentColorValue, 0xFF123456);
    },
  );

  test(
    'template repository covers add, update, selection, usage and delete',
    () async {
      final repository = TemplateRepositoryImpl(
        TemplateDataSourceImpl(database),
      );
      final project = projectRow('project-template');
      await database.insert(DatabaseTables.projects, project);
      const template = TemplateAsset(
        id: 'template-1',
        name: 'Original',
        filePath: '/tmp/a.png',
        width: 100,
        height: 80,
        dpi: 96,
        format: 'png',
      );
      await repository.add(template);
      expect((await repository.getAll()).single.name, 'Original');
      await repository.update(
        const TemplateAsset(
          id: 'template-1',
          name: 'Updated',
          filePath: '/tmp/b.png',
          width: 200,
          height: 160,
          dpi: 144,
          format: 'jpg',
        ),
      );
      expect((await repository.getAll()).single.format, 'jpg');
      await repository.selectForProject('project-template', 'template-1');
      expect(
        await repository.selectedForProject('project-template'),
        'template-1',
      );
      expect(await repository.isUsedByProject('template-1'), isTrue);
      await repository.delete('template-1');
      expect(await repository.getAll(), isEmpty);
    },
  );

  test(
    'font repository persists bytes and project selection settings',
    () async {
      final repository = FontRepositoryImpl(FontDataSourceImpl(database));
      await database.insert(
        DatabaseTables.projects,
        projectRow('project-font'),
      );
      const font = FontAsset(
        id: 'font-1',
        name: 'Cairo',
        family: 'Cairo',
        filePath: '/tmp/cairo.ttf',
        format: 'ttf',
      );
      await repository.add(font, const [1, 2, 3]);
      final rows = await database.query(DatabaseTables.fonts);
      expect(rows.single['font_bytes'], [1, 2, 3]);
      await repository.selectForProject('project-font', 'font-1');
      expect(await repository.selectedForProject('project-font'), 'font-1');
      await repository.delete('font-1');
      expect(await repository.getAll(), isEmpty);
    },
  );

  test(
    'project repository and cascade delete remove all project-owned data',
    () async {
      final artifacts = InMemoryCertificateArtifactStore();
      final repository = ProjectRepositoryImpl(
        ProjectDataSourceImpl(database, artifactStore: artifacts),
      );
      final project = Project(
        id: 'project-cascade',
        institutionId: 'institution-1',
        name: 'Cascade',
        projectKeyReference: 'key',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      await repository.save(project);
      expect(await repository.getById(project.id), isNotNull);
      await database.insert(
        DatabaseTables.records,
        recordRow(project.id, 'record-1'),
      );
      await database.insert(
        DatabaseTables.certificateFields,
        fieldRow(project.id, 'field-1'),
      );
      await database.insert(DatabaseTables.certificates, {
        'id': 'certificate-1',
        'project_id': project.id,
        'record_id': 'record-1',
        'file_path': await artifacts.save(
          certificateId: 'certificate-1',
          extension: 'pdf',
          bytes: [1],
        ),
        'image_path': await artifacts.save(
          certificateId: 'certificate-1',
          extension: 'png',
          bytes: [2],
        ),
        'status': 'generated',
        'created_at': 'now',
        'updated_at': 'now',
      });
      await database.insert(DatabaseTables.verificationRecords, {
        'id': 'verification-1',
        'certificate_id': 'certificate-1',
        'institution_id': 'institution-1',
        'project_id': project.id,
        'payload_json': '{}',
        'signature': 'sig',
        'created_at': 'now',
      });
      final keyStorage = InMemoryKeyStorage();
      await keyStorage.write('project.${project.id}.key', 'secret');
      await repository.deleteCascade(project.id);
      expect(await repository.getById(project.id), isNull);
      expect(await database.query(DatabaseTables.records), isEmpty);
      expect(await database.query(DatabaseTables.certificates), isEmpty);
      expect(
        await artifacts.read('artifact://certificates/certificate-1.pdf'),
        isNull,
      );
      await DeleteProject(repository, keyStorage).call(project.id);
      expect(await keyStorage.read('project.${project.id}.key'), isNull);
    },
  );

  test('workspace metrics count templates, fonts and certificates', () async {
    await database.insert(DatabaseTables.templates, {'id': 't', 'name': 't'});
    await database.insert(DatabaseTables.fonts, {'id': 'f', 'name': 'f'});
    await database.insert(DatabaseTables.certificates, {
      'id': 'c',
      'project_id': 'p',
    });
    final metrics = await GetWorkspaceMetrics(
      WorkspaceRepositoryImpl(WorkspaceDataSourceImpl(database)),
    )();
    expect(metrics.templates, 1);
    expect(metrics.fonts, 1);
    expect(metrics.certificates, 1);
  });

  test(
    'certificate repository filters by project and maps recipient data',
    () async {
      await database.insert(
        DatabaseTables.records,
        recordRow('project-a', 'record-a', name: 'Sara'),
      );
      await database.insert(
        DatabaseTables.records,
        recordRow('project-b', 'record-b', name: 'Omar'),
      );
      await database.insert(DatabaseTables.certificates, {
        'id': 'certificate-a',
        'project_id': 'project-a',
        'record_id': 'record-a',
        'status': 'generated',
        'document_json': jsonEncode({'course': 'Flutter'}),
      });
      final repository = CertificateRepositoryImpl(
        CertificateDataSourceImpl(database),
      );
      expect(
        (await repository.getAll(projectId: 'project-a')).single.recipient,
        'Sara',
      );
      expect(await repository.getAll(projectId: 'missing'), isEmpty);
      expect((await GetCertificates(repository)()).single.id, 'certificate-a');
    },
  );

  test('paste and Excel use cases reject missing headers and rows', () async {
    final repository = UseCaseImportRepository();
    final paste = PasteTable(repository);
    final excel = ImportExcel(repository);
    repository.table = const ImportedTable(columns: [], rows: []);
    await expectLater(
      paste(projectId: 'p', rawText: ''),
      throwsFormatException,
    );
    await expectLater(
      excel(projectId: 'p', bytes: const []),
      throwsFormatException,
    );
    repository.table = const ImportedTable(columns: ['name'], rows: []);
    await expectLater(
      paste(projectId: 'p', rawText: 'name'),
      throwsFormatException,
    );
    await expectLater(
      excel(projectId: 'p', bytes: const []),
      throwsFormatException,
    );
    repository.table = const ImportedTable(
      columns: ['name'],
      rows: [
        {'name': 'Sara'},
      ],
    );
    expect(
      (await paste(projectId: 'p', rawText: 'name\nSara')).rows,
      hasLength(1),
    );
  });

  test('key managers are idempotent and rotate keys', () async {
    final storage = InMemoryKeyStorage();
    final institution = InstitutionKeyManager(storage);
    expect(await institution.hasKey(), isFalse);
    await institution.initialize();
    final first = await storage.read('institution.master_key');
    await institution.initialize();
    expect(await storage.read('institution.master_key'), first);
    await institution.rotate();
    expect(await storage.read('institution.master_key'), isNot(first));
    final project = ProjectKeyManager(storage);
    await project.initialize('p');
    final projectKey = await storage.read('project.p.key');
    await project.initialize('p');
    expect(await storage.read('project.p.key'), projectKey);
    await project.rotate('p');
    expect(await project.hasKey('p'), isTrue);
  });

  test('artifact store saves, reads and deletes bytes', () async {
    final store = InMemoryCertificateArtifactStore();
    final reference = await store.save(
      certificateId: 'c',
      extension: 'pdf',
      bytes: [1, 2, 3],
    );
    expect(reference, 'artifact://certificates/c.pdf');
    expect(await store.read(reference), [1, 2, 3]);
    await store.delete(reference);
    expect(await store.read(reference), isNull);
  });

  test('OperationResult dispatches success and failure branches', () {
    const success = OperationSuccess<int>(7);
    const failure = OperationFailure<int>('failed');
    expect(success.fold(success: (value) => value, failure: (_) => 0), 7);
    expect(
      failure.fold(success: (_) => 0, failure: (message) => message),
      'failed',
    );
  });

  test('CreateProject validates inputs and trims optional fields', () async {
    final repository = ProjectRepositoryForCreate();
    final keys = FakeProjectKeyService();
    final create = CreateProject(repository, keys);
    await expectLater(
      create(const CreateProjectParams(name: '  ', institutionId: 'i')),
      throwsArgumentError,
    );
    await expectLater(
      create(const CreateProjectParams(name: 'Name', institutionId: '  ')),
      throwsArgumentError,
    );
    final project = await create(
      const CreateProjectParams(
        name: '  Name  ',
        institutionId: 'institution',
        courseName: '  Course  ',
        description: ' ',
      ),
    );
    expect(project.name, 'Name');
    expect(project.courseName, 'Course');
    expect(project.description, isNull);
    expect(keys.initializedId, project.id);
  });
}

Map<String, Object?> projectRow(String id) => {
  'id': id,
  'institution_id': 'institution-1',
  'name': 'Project',
  'project_key_reference': 'key',
  'version': 1,
  'created_at': 'now',
  'updated_at': 'now',
};

Map<String, Object?> recordRow(
  String projectId,
  String id, {
  String name = 'Name',
}) => {
  'id': id,
  'project_id': projectId,
  'class_name': 'A001',
  'data_json': jsonEncode({'name': name}),
  'columns_json': '["name"]',
  'row_number': 1,
  'created_at': 'now',
  'updated_at': 'now',
};

Map<String, Object?> fieldRow(String projectId, String id) => {
  'id': id,
  'project_id': projectId,
  'class_name': 'name',
  'source': 'name',
  'position_json': '{}',
  'style_json': '{}',
  'created_at': 'now',
  'updated_at': 'now',
};

class InstitutionForTest {
  const InstitutionForTest();
  Institution value(DateTime now) => Institution(
    id: 'institution-1',
    institutionId: 'academy-test',
    name: 'Test Academy',
    createdAt: now,
    updatedAt: now,
  );
}

class UseCaseImportRepository implements DataImportRepository {
  ImportedTable table = const ImportedTable(columns: [], rows: []);
  @override
  ImportedTable parseTable(String rawText) => table;
  @override
  ImportedTable parseExcel(List<int> bytes) => table;
  @override
  Future<ImportedTable> saveForProject(
    String projectId,
    ImportedTable value,
  ) async => value;
  @override
  Future<ImportedTable> getForProject(String projectId) async => table;
}

class ProjectRepositoryForCreate implements ProjectRepository {
  Project? saved;
  @override
  Future<List<Project>> getAll({String? institutionId}) async =>
      saved == null ? [] : [saved!];
  @override
  Future<Project?> getById(String id) async => saved;
  @override
  Future<Project> save(Project value) async {
    saved = value;
    return value;
  }

  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteCascade(String id) async {}
}

class FakeProjectKeyService implements ProjectKeyService {
  String? initializedId;
  @override
  Future<bool> hasKey(String projectId) async => initializedId == projectId;
  @override
  Future<void> initialize(String projectId) async => initializedId = projectId;
  @override
  Future<void> rotate(String projectId) async => initializedId = projectId;
}
