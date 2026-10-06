import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/settings/data/services/workspace_transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAppDatabase database;

  setUp(() async {
    database = InMemoryAppDatabase();
    await database.open();
  });

  tearDown(() => database.close());

  test('rejects profile export when secure storage is unavailable', () async {
    final service = WorkspaceTransferService(database);

    expect(
      () => service.exportProfile('institution-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects profile export when the institution key is empty', () async {
    final storage = InMemoryKeyStorage();
    await storage.write('institution.master_key', '');
    final service = WorkspaceTransferService(database, keyStorage: storage);

    expect(
      () => service.exportProfile('institution-1'),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'rejects profile export when the institution key is malformed',
    () async {
      final storage = InMemoryKeyStorage();
      await storage.write('institution.master_key', 'not-hex');
      final service = WorkspaceTransferService(database, keyStorage: storage);

      expect(
        () => service.exportProfile('institution-1'),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('rejects profile export when the institution does not exist', () async {
    final storage = InMemoryKeyStorage();
    await storage.write('institution.master_key', '00' * 32);
    final service = WorkspaceTransferService(database, keyStorage: storage);

    expect(
      () => service.exportProfile('missing-institution'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects project export when the project does not exist', () async {
    final service = WorkspaceTransferService(database);

    expect(
      () => service.exportProject('missing-project'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects project export when the background is unreadable', () async {
    await database.insert(DatabaseTables.projects, {
      'id': 'project-1',
      'institution_id': 'institution-1',
      'name': 'Project',
      'template_id': 'template-1',
    });
    await database.insert(DatabaseTables.templates, {
      'id': 'template-1',
      'file_path': '/missing/background.png',
      'format': 'png',
    });
    final service = WorkspaceTransferService(database);

    expect(
      () => service.exportProject('project-1'),
      throwsA(isA<StateError>()),
    );
  });
}
