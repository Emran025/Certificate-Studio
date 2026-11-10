import '../../domain/entities/imported_table.dart';
import '../../domain/entities/field_rule.dart';

abstract interface class DataImportDataSource {
  Future<void> replaceRecords(String projectId, ImportedTable table);
  Future<List<Map<String, Object?>>> getRecordRows(String projectId);
  Future<List<String>> getRecordColumns(String projectId);
  Future<Map<String, FieldRule>> getRecordFieldRules(String projectId);
}
