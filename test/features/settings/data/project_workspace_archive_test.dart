import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/core/files/project_asset_store.dart';
import 'package:certificate_studio/core/files/project_workspace_storage.dart';
import 'package:certificate_studio/features/settings/data/services/workspace_transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.supportPath);

  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

void main() {
  late Directory supportDirectory;
  late PathProviderPlatform previousPathProvider;
  late InMemoryAppDatabase sourceDatabase;
  late InMemoryAppDatabase targetDatabase;
  late InMemoryCertificateArtifactStore sourceArtifacts;
  late InMemoryCertificateArtifactStore targetArtifacts;

  Future<void> addInstitution(InMemoryAppDatabase database, String id) =>
      database.insert(DatabaseTables.institutions, {
        'id': id,
        'institution_id': 'school-$id',
        'name': 'Institution $id',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

  setUp(() async {
    supportDirectory = Directory.systemTemp.createTempSync(
      'cstudio-workspace-test-',
    );
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(supportDirectory.path);
    sourceDatabase = InMemoryAppDatabase()..open();
    targetDatabase = InMemoryAppDatabase()..open();
    await addInstitution(sourceDatabase, 'source-institution');
    await addInstitution(targetDatabase, 'target-institution');
    sourceArtifacts = InMemoryCertificateArtifactStore();
    targetArtifacts = InMemoryCertificateArtifactStore();

    final templatePath = await saveProjectBackground(
      projectId: 'template-library',
      fileName: 'roundtrip-template.png',
      bytes: [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3],
    );
    const now = '2026-01-02T03:04:05.000Z';
    await sourceDatabase.insert(DatabaseTables.templates, {
      'id': 'template-roundtrip',
      'name': 'Template',
      'file_path': templatePath,
      'width': 1920,
      'height': 1080,
      'dpi': 300.0,
      'format': 'png',
      'created_at': now,
      'updated_at': now,
    });
    await sourceDatabase.insert(DatabaseTables.fonts, {
      'id': 'font-roundtrip',
      'name': 'Custom Font',
      'family': 'CustomFont',
      'file_path': '/old-device/fonts/custom.ttf',
      'format': 'ttf',
      'font_bytes': Uint8List.fromList([0, 1, 2, 3, 4]),
      'created_at': now,
      'updated_at': now,
    });
    await sourceDatabase.insert(DatabaseTables.projects, {
      'id': 'project-roundtrip',
      'institution_id': 'source-institution',
      'name': 'Arabic course',
      'course_name': 'Portable data',
      'description': 'round trip test',
      'organization_name': 'Academy',
      'template_id': 'template-roundtrip',
      'settings_json': jsonEncode({'font_id': 'font-roundtrip'}),
      'project_key_reference': 'project:project-roundtrip',
      'version': 1,
      'created_at': now,
      'updated_at': now,
    });
    await sourceDatabase.insert(DatabaseTables.records, {
      'id': 'record-roundtrip',
      'project_id': 'project-roundtrip',
      'class_name': 'A',
      'data_json': jsonEncode({'Name': 'ليلى', 'Score': '98'}),
      'columns_json': jsonEncode(['Name', 'Score']),
      'row_number': 1,
      'created_at': now,
      'updated_at': now,
    });
    await sourceDatabase.insert(DatabaseTables.certificateFields, {
      'id': 'field-roundtrip',
      'project_id': 'project-roundtrip',
      'font_id': 'font-roundtrip',
      'class_name': 'recipient-name',
      'source': 'Name',
      'position_json': jsonEncode({'x': 10.5, 'y': 20.25, 'width': 300.0}),
      'style_json': jsonEncode({'fontSize': 18, 'color': '#123456'}),
      'created_at': now,
      'updated_at': now,
    });
    await sourceDatabase.upsert(DatabaseTables.settings, {
      'key': 'records-columns:project-roundtrip',
      'value_json': jsonEncode(['Name', 'Score']),
      'updated_at': now,
    }, conflictColumn: 'key');

    final pdfReference = await sourceArtifacts.save(
      projectId: 'project-roundtrip',
      certificateId: 'certificate-roundtrip',
      extension: 'pdf',
      bytes: [37, 80, 68, 70, 1],
    );
    final pngReference = await sourceArtifacts.save(
      projectId: 'project-roundtrip',
      certificateId: 'certificate-roundtrip',
      extension: 'png',
      bytes: [137, 80, 78, 71, 1],
    );
    await sourceDatabase.insert(DatabaseTables.certificates, {
      'id': 'certificate-roundtrip',
      'project_id': 'project-roundtrip',
      'record_id': 'record-roundtrip',
      'file_path': pdfReference,
      'image_path': pngReference,
      'document_json': '{}',
      'status': 'signed',
      'document_hash': 'hash',
      'created_at': now,
      'updated_at': now,
    });
    await sourceDatabase.insert(DatabaseTables.verificationRecords, {
      'id': 'verification-roundtrip',
      'certificate_id': 'certificate-roundtrip',
      'institution_id': 'source-institution',
      'project_id': 'project-roundtrip',
      'payload_json': '{"signature":"signed"}',
      'signature': 'signed',
      'created_at': now,
    });
  });

  tearDown(() async {
    PathProviderPlatform.instance = previousPathProvider;
    await sourceDatabase.close();
    await targetDatabase.close();
    if (supportDirectory.existsSync()) {
      supportDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'exports a structured, checksummed and portable project workspace',
    () async {
      final service = WorkspaceTransferService(
        sourceDatabase,
        artifactStore: sourceArtifacts,
      );
      final bytes = await service.buildProjectArchiveBytes('project-roundtrip');
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = {
        for (final entry in archive.files)
          if (entry.isFile) entry.name: entry.content,
      };
      final manifest =
          jsonDecode(
                utf8.decode(entries[ProjectWorkspaceArchiveManifest.path]!),
              )
              as Map;

      expect(manifest['format'], 'cstudio-project-workspace');
      expect(manifest['version'], 1);
      expect(entries, contains('workspace/data/records.json'));
      expect(entries, contains('workspace/design/fields.json'));
      expect(
        entries,
        contains('workspace/assets/templates/dGVtcGxhdGUtcm91bmR0cmlw.png'),
      );
      expect(
        entries,
        contains('workspace/assets/fonts/Zm9udC1yb3VuZHRyaXA.ttf'),
      );
      expect(
        entries,
        contains(
          'workspace/outputs/certificates/Y2VydGlmaWNhdGUtcm91bmR0cmlw/certificate.pdf',
        ),
      );
      expect(entries, contains('data_rows.csv'));
      expect(
        utf8.decode(entries['workspace/data/project.json']!),
        isNot(contains('/old-device/')),
      );

      final workspaceRoot = await readProjectWorkspaceFile(
        projectId: 'project-roundtrip',
        relativePath: 'manifest.json',
      );
      expect(workspaceRoot, isNotNull);
    },
  );

  test(
    'round-trips layout, recipient columns, fonts, signed outputs and assets',
    () async {
      final source = WorkspaceTransferService(
        sourceDatabase,
        artifactStore: sourceArtifacts,
      );
      final archive = await source.buildProjectArchiveBytes(
        'project-roundtrip',
      );
      final destination = WorkspaceTransferService(
        targetDatabase,
        artifactStore: targetArtifacts,
      );
      final importedId = await destination.importWorkspaceArchiveBytes(
        institutionId: 'target-institution',
        bytes: archive,
      );

      expect(importedId, 'project-roundtrip');
      final project = (await targetDatabase.query(
        DatabaseTables.projects,
      )).single;
      expect(project['institution_id'], 'target-institution');
      expect(project['name'], 'Arabic course');
      final record = (await targetDatabase.query(
        DatabaseTables.records,
      )).single;
      expect(jsonDecode(record['data_json']! as String), {
        'Name': 'ليلى',
        'Score': '98',
      });
      expect(jsonDecode(record['columns_json']! as String), ['Name', 'Score']);
      final field = (await targetDatabase.query(
        DatabaseTables.certificateFields,
      )).single;
      expect(field['font_id'], 'font-roundtrip');
      expect(jsonDecode(field['position_json']! as String)['x'], 10.5);
      final font = (await targetDatabase.query(DatabaseTables.fonts)).single;
      expect(font['font_bytes'], [0, 1, 2, 3, 4]);
      final template = (await targetDatabase.query(
        DatabaseTables.templates,
      )).single;
      expect(
        template['file_path'],
        isNot('/old-device/templates/background.png'),
      );
      expect(
        await targetArtifacts.read(
          (await targetDatabase.query(
                DatabaseTables.certificates,
              )).single['file_path']!
              as String,
        ),
        [37, 80, 68, 70, 1],
      );
      final verification = (await targetDatabase.query(
        DatabaseTables.verificationRecords,
      )).single;
      expect(verification['institution_id'], 'target-institution');
      expect(verification['signature'], 'signed');
    },
  );

  test(
    'remaps shared template and font IDs instead of overwriting library rows',
    () async {
      await targetDatabase.insert(DatabaseTables.templates, {
        'id': 'template-roundtrip',
        'name': 'Existing template',
      });
      await targetDatabase.insert(DatabaseTables.fonts, {
        'id': 'font-roundtrip',
        'name': 'Existing font',
      });
      final archive = await WorkspaceTransferService(
        sourceDatabase,
        artifactStore: sourceArtifacts,
      ).buildProjectArchiveBytes('project-roundtrip');
      await WorkspaceTransferService(
        targetDatabase,
        artifactStore: targetArtifacts,
      ).importWorkspaceArchiveBytes(
        institutionId: 'target-institution',
        bytes: archive,
      );

      final project = (await targetDatabase.query(
        DatabaseTables.projects,
      )).single;
      expect(project['template_id'], isNot('template-roundtrip'));
      final field = (await targetDatabase.query(
        DatabaseTables.certificateFields,
      )).single;
      expect(field['font_id'], isNot('font-roundtrip'));
      expect(
        await targetDatabase.query(DatabaseTables.templates),
        hasLength(2),
      );
      expect(await targetDatabase.query(DatabaseTables.fonts), hasLength(2));
      expect(
        jsonDecode(project['settings_json']! as String)['font_id'],
        field['font_id'],
      );
    },
  );

  test('rejects malformed archives without inserting project rows', () async {
    final destination = WorkspaceTransferService(
      targetDatabase,
      artifactStore: targetArtifacts,
    );
    await expectLater(
      destination.importWorkspaceArchiveBytes(
        institutionId: 'target-institution',
        bytes: [1, 2, 3],
      ),
      throwsA(anything),
    );
    expect(await targetDatabase.query(DatabaseTables.projects), isEmpty);
  });

  test(
    'rejects duplicate project IDs without changing the existing project',
    () async {
      final archive = await WorkspaceTransferService(
        sourceDatabase,
        artifactStore: sourceArtifacts,
      ).buildProjectArchiveBytes('project-roundtrip');
      final destination = WorkspaceTransferService(
        targetDatabase,
        artifactStore: targetArtifacts,
      );
      await destination.importWorkspaceArchiveBytes(
        institutionId: 'target-institution',
        bytes: archive,
      );
      await expectLater(
        destination.importWorkspaceArchiveBytes(
          institutionId: 'target-institution',
          bytes: archive,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await targetDatabase.query(DatabaseTables.projects), hasLength(1));
      expect(await targetDatabase.query(DatabaseTables.records), hasLength(1));
    },
  );
}

abstract final class ProjectWorkspaceArchiveManifest {
  static const path = 'workspace/manifest.json';
}
