import '../entities/imported_table.dart';
import '../repositories/data_import_repository.dart';

class PasteTable {
  PasteTable(this._repository);

  final DataImportRepository _repository;

  Future<ImportedTable> call({required String projectId, required String rawText}) async {
    final table = _repository.parseTable(rawText);
    if (table.columns.isEmpty) {
      throw const FormatException('Paste a table with a header row and at least one column.');
    }
    if (table.rows.isEmpty) {
      throw const FormatException('The table does not contain any recipient rows.');
    }
    return _repository.saveForProject(projectId, table);
  }
}
