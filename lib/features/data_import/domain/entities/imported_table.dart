import 'field_rule.dart';

class ImportedTable {
  const ImportedTable({
    required this.columns,
    required this.rows,
    this.fieldRules = const {},
    this.recordIds = const [],
    this.headerConflicts = const [],
  });

  final List<String> columns;
  final List<Map<String, String>> rows;
  final Map<String, FieldRule> fieldRules;

  /// Persisted record IDs in row order. Newly added/imported rows use null.
  final List<String?> recordIds;

  /// Duplicate spreadsheet headers that were disambiguated for preview.
  final List<String> headerConflicts;

  int get rowCount => rows.length;

  ImportedTable copyWith({
    List<String>? columns,
    List<Map<String, String>>? rows,
    Map<String, FieldRule>? fieldRules,
    List<String?>? recordIds,
    List<String>? headerConflicts,
  }) => ImportedTable(
    columns: columns ?? this.columns,
    rows: rows ?? this.rows,
    fieldRules: fieldRules ?? this.fieldRules,
    recordIds: recordIds ?? this.recordIds,
    headerConflicts: headerConflicts ?? this.headerConflicts,
  );
}
