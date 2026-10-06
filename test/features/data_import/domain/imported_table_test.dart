import 'package:certificate_studio/features/data_import/domain/entities/imported_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports row count and copies selected values', () {
    const table = ImportedTable(
      columns: ['name'],
      rows: [
        {'name': 'Sara'},
      ],
    );
    final copy = table.copyWith(columns: ['full_name']);

    expect(table.rowCount, 1);
    expect(copy.columns, ['full_name']);
    expect(copy.rows, table.rows);
    expect(table.columns, ['name']);
  });
}
