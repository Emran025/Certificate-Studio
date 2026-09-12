import '../entities/imported_table.dart';

abstract interface class DataImportRepository {
  ImportedTable parseTable(String rawText);
  ImportedTable parseExcel(List<int> bytes);
  Future<ImportedTable> saveForProject(String projectId, ImportedTable table);
  Future<ImportedTable> getForProject(String projectId);
}
