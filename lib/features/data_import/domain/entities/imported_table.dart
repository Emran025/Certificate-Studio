import 'field_rule.dart';

class ImportedTable {
  const ImportedTable({
    required this.columns,
    required this.rows,
    this.fieldRules = const {},
  });

  final List<String> columns;
  final List<Map<String, String>> rows;
  final Map<String, FieldRule> fieldRules;

  int get rowCount => rows.length;

  ImportedTable copyWith({
    List<String>? columns,
    List<Map<String, String>>? rows,
    Map<String, FieldRule>? fieldRules,
  }) => ImportedTable(
    columns: columns ?? this.columns,
    rows: rows ?? this.rows,
    fieldRules: fieldRules ?? this.fieldRules,
  );
}
