class ImportedTable {
  const ImportedTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<Map<String, String>> rows;

  int get rowCount => rows.length;

  ImportedTable copyWith({List<String>? columns, List<Map<String, String>>? rows}) =>
      ImportedTable(columns: columns ?? this.columns, rows: rows ?? this.rows);
}
