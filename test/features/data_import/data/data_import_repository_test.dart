import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/features/data_import/data/datasources/data_import_data_source_impl.dart';
import 'package:certificate_studio/features/data_import/data/repositories/data_import_repository_impl.dart';
import 'package:certificate_studio/features/data_import/domain/entities/field_rule.dart';
import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses pasted tab-separated data and reports duplicate headers', () {
    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(InMemoryAppDatabase()),
    );
    final table = repository.parseTable('Name\tName\tGrade\nAhmed\tA. Ali\t95');

    expect(table.columns, ['Name', 'Name 2', 'Grade']);
    expect(table.headerConflicts, ['Name']);
    expect(table.rows.single['Name'], 'Ahmed');
    expect(table.rows.single['Name 2'], 'A. Ali');
  });

  test('persists and reloads imported rows for a project', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(database),
    );
    final table = repository.parseTable(
      'class\tname\tgrade\nA001\tAhmed Ali\t95',
    );

    await repository.saveForProject('project-1', table);
    final restored = await repository.getForProject('project-1');

    expect(restored.columns, ['class', 'name', 'grade']);
    expect(restored.rows, [
      {'class': 'A001', 'name': 'Ahmed Ali', 'grade': '95'},
    ]);
    expect(restored.recordIds, hasLength(1));
  });

  test('appends rows, reuses matching columns, and adds new fields', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(database),
    );

    await repository.saveForProject(
      'project-1',
      repository.parseTable('Name\tGrade\nAhmed\t95'),
    );
    final restored = await repository.saveForProject(
      'project-1',
      repository.parseTable('name\tSchool\tGrade\nSara\tNorth\t91'),
    );

    expect(restored.columns, ['Name', 'Grade', 'School']);
    expect(restored.rows, [
      {'Name': 'Ahmed', 'Grade': '95', 'School': ''},
      {'Name': 'Sara', 'Grade': '91', 'School': 'North'},
    ]);
    expect(restored.recordIds, hasLength(2));
    expect(restored.recordIds.toSet(), hasLength(2));
  });

  test(
    'duplicate spreadsheet headers are disambiguated and saved safely',
    () async {
      final database = InMemoryAppDatabase();
      await database.open();
      final repository = DataImportRepositoryImpl(
        DataImportDataSourceImpl(database),
      );
      final table = repository.parseTable('Name\tName\nAhmed\tA. Ali');

      final restored = await repository.saveForProject('project-1', table);

      expect(restored.columns, ['Name', 'Name 2']);
      expect(restored.rows, [
        {'Name': 'Ahmed', 'Name 2': 'A. Ali'},
      ]);
    },
  );

  test('re-import works after all rows were deleted', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(database),
    );

    await repository.saveForProject(
      'project-1',
      repository.parseTable('Name\tGrade\nAhmed\t95'),
    );
    final existing = await repository.getForProject('project-1');
    await repository.updateForProject(
      'project-1',
      existing.copyWith(rows: const [], recordIds: const []),
    );

    final restored = await repository.saveForProject(
      'project-1',
      repository.parseTable('name\tGrade\nSara\t91'),
    );

    expect(restored.columns, ['Name', 'Grade']);
    expect(restored.rows, [
      {'Name': 'Sara', 'Grade': '91'},
    ]);
  });

  test(
    'repairs legacy duplicate column definitions instead of failing',
    () async {
      final database = InMemoryAppDatabase();
      await database.open();
      final repository = DataImportRepositoryImpl(
        DataImportDataSourceImpl(database),
      );

      await database.upsert('settings', {
        'key': 'records-columns:project-1',
        'value_json': '["Name", "name", "Grade"]',
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictColumn: 'key');

      final restored = await repository.saveForProject(
        'project-1',
        repository.parseTable('NAME\tGrade\nSara\t91'),
      );

      expect(restored.columns, ['Name', 'Grade']);
      expect(restored.rows, [
        {'Name': 'Sara', 'Grade': '91'},
      ]);
    },
  );

  test('persists and reloads field rules for a project', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(database),
    );
    final table = ImportedTable(
      columns: ['grade', 'status'],
      rows: [
        {'grade': '85', 'status': 'pass'},
      ],
      fieldRules: {
        'grade': const FieldRule(kind: FieldRuleKind.number, min: 70, max: 95),
        'status': const FieldRule(
          kind: FieldRuleKind.choice,
          choices: ['pass', 'fail'],
        ),
      },
    );

    await repository.saveForProject('project-1', table);
    final restored = await repository.getForProject('project-1');

    expect(restored.fieldRules.keys, containsAll(['grade', 'status']));
    expect(restored.fieldRules['grade']?.kind, FieldRuleKind.number);
    expect(restored.fieldRules['grade']?.min, 70);
    expect(restored.fieldRules['grade']?.max, 95);
    expect(restored.fieldRules['status']?.kind, FieldRuleKind.choice);
    expect(restored.fieldRules['status']?.choices, ['pass', 'fail']);
  });

  test(
    'persists newly added fields even when there are no student rows',
    () async {
      final database = InMemoryAppDatabase();
      await database.open();
      final repository = DataImportRepositoryImpl(
        DataImportDataSourceImpl(database),
      );

      await repository.saveForProject(
        'project-1',
        const ImportedTable(columns: ['name', 'email'], rows: []),
      );

      final restored = await repository.getForProject('project-1');
      expect(restored.columns, ['name', 'email']);
      expect(restored.rows, isEmpty);
    },
  );

  test('updates records in place and invalidates stale certificates', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final artifacts = InMemoryCertificateArtifactStore();
    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(database, artifactStore: artifacts),
    );
    await repository.saveForProject(
      'project-1',
      repository.parseTable('name\tgrade\nAhmed\t95'),
    );
    final original = await repository.getForProject('project-1');
    final recordId = original.recordIds.single!;
    final pdfPath = await artifacts.save(
      certificateId: 'certificate-1',
      extension: 'pdf',
      bytes: [1, 2, 3],
    );
    final imagePath = await artifacts.save(
      certificateId: 'certificate-1',
      extension: 'png',
      bytes: [4, 5, 6],
    );
    await database.insert('certificates', {
      'id': 'certificate-1',
      'project_id': 'project-1',
      'record_id': recordId,
      'file_path': pdfPath,
      'image_path': imagePath,
      'status': 'signed',
    });
    await database.insert('verification_records', {
      'id': 'verification-1',
      'certificate_id': 'certificate-1',
    });

    await repository.updateForProject(
      'project-1',
      original.copyWith(
        rows: [
          {'name': 'Ahmed Updated', 'grade': '95'},
        ],
      ),
    );

    expect(
      (await repository.getForProject('project-1')).recordIds.single,
      recordId,
    );
    expect(await database.query('certificates'), isEmpty);
    expect(await database.query('verification_records'), isEmpty);
    expect(await artifacts.read(pdfPath), isNull);
    expect(await artifacts.read(imagePath), isNull);
    final storedRecord = await database.query('records');
    expect(
      storedRecord.single['data_json'],
      '{"name":"Ahmed Updated","grade":"95"}',
    );
  });

  test(
    'deleting a row removes dependent certificate files and records safely',
    () async {
      final database = InMemoryAppDatabase();
      await database.open();
      final artifacts = InMemoryCertificateArtifactStore();
      final repository = DataImportRepositoryImpl(
        DataImportDataSourceImpl(database, artifactStore: artifacts),
      );
      await repository.saveForProject(
        'project-1',
        repository.parseTable('name\nAhmed'),
      );
      final original = await repository.getForProject('project-1');
      final recordId = original.recordIds.single!;
      final pdfPath = await artifacts.save(
        certificateId: 'certificate-1',
        extension: 'pdf',
        bytes: [1, 2, 3],
      );
      final imagePath = await artifacts.save(
        certificateId: 'certificate-1',
        extension: 'png',
        bytes: [4, 5, 6],
      );
      await database.insert('certificates', {
        'id': 'certificate-1',
        'project_id': 'project-1',
        'record_id': recordId,
        'file_path': pdfPath,
        'image_path': imagePath,
        'status': 'signed',
      });
      await database.insert('verification_records', {
        'id': 'verification-1',
        'certificate_id': 'certificate-1',
      });

      await repository.updateForProject(
        'project-1',
        original.copyWith(rows: const [], recordIds: const []),
      );

      expect(await database.query('records'), isEmpty);
      expect(await database.query('certificates'), isEmpty);
      expect(await database.query('verification_records'), isEmpty);
      expect(await artifacts.read(pdfPath), isNull);
      expect(await artifacts.read(imagePath), isNull);
    },
  );

  test('parses the first worksheet from an XLSX workbook', () {
    final workbook = Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet()!];
    sheet.appendRow([
      TextCellValue('class'),
      TextCellValue('name'),
      TextCellValue('grade'),
    ]);
    sheet.appendRow([
      TextCellValue('A001'),
      TextCellValue('Ahmed Ali'),
      IntCellValue(95),
    ]);

    final repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(InMemoryAppDatabase()),
    );
    final table = repository.parseExcel(workbook.encode()!);

    expect(table.columns, ['class', 'name', 'grade']);
    expect(table.rows, [
      {'class': 'A001', 'name': 'Ahmed Ali', 'grade': '95'},
    ]);
  });
}
