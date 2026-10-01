import '../../domain/entities/imported_table.dart';

abstract interface class DataImportDataSource {
  Future<void> replaceRecords(String projectId, ImportedTable table);
  Future<List<Map<String, Object?>>> getRecordRows(String projectId);
}
