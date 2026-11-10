import 'package:certificate_studio/features/data_import/domain/entities/field_rule.dart';
import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:certificate_studio/features/data_import/domain/repositories/data_import_repository.dart';
import 'package:certificate_studio/features/data_import/domain/usecases/update_imported_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves the supplied table for the requested project', () async {
    final repository = _RecordingDataImportRepository();
    const table = ImportedTable(
      columns: ['grade'],
      rows: [],
      fieldRules: {
        'grade': FieldRule(kind: FieldRuleKind.number, min: 0, max: 100),
      },
    );

    final result = await UpdateImportedTable(repository)(
      projectId: 'project-1',
      table: table,
    );

    expect(repository.savedProjectId, 'project-1');
    expect(repository.savedTable, same(table));
    expect(result, same(table));
  });
}

class _RecordingDataImportRepository implements DataImportRepository {
  String? savedProjectId;
  ImportedTable? savedTable;

  @override
  ImportedTable parseTable(String rawText) => throw UnimplementedError();

  @override
  ImportedTable parseExcel(List<int> bytes) => throw UnimplementedError();

  @override
  Future<ImportedTable> saveForProject(
    String projectId,
    ImportedTable table,
  ) async {
    savedProjectId = projectId;
    savedTable = table;
    return table;
  }

  @override
  Future<ImportedTable> getForProject(String projectId) =>
      throw UnimplementedError();
}
