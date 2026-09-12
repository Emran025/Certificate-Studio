import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/features/data_import/data/repositories/data_import_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses pasted tab-separated data and normalizes duplicate headers', () {
    final repository = DataImportRepositoryImpl(InMemoryAppDatabase());
    final table = repository.parseTable('Name\tName\tGrade\nAhmed\tA. Ali\t95');

    expect(table.columns, ['Name', 'Name 2', 'Grade']);
    expect(table.rows.single['Name'], 'Ahmed');
    expect(table.rows.single['Name 2'], 'A. Ali');
  });

  test('persists and reloads imported rows for a project', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final repository = DataImportRepositoryImpl(database);
    final table = repository.parseTable('class\tname\tgrade\nA001\tAhmed Ali\t95');

    await repository.saveForProject('project-1', table);
    final restored = await repository.getForProject('project-1');

    expect(restored.columns, ['class', 'name', 'grade']);
    expect(restored.rows, [
      {'class': 'A001', 'name': 'Ahmed Ali', 'grade': '95'},
    ]);
  });
}
