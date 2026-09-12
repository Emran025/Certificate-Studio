import '../entities/imported_table.dart';
import '../repositories/data_import_repository.dart';

class ImportExcel {
  ImportExcel(this._repository);

  final DataImportRepository _repository;

  Future<ImportedTable> call({
    required String projectId,
    required List<int> bytes,
  }) async {
    final table = _repository.parseExcel(bytes);
    if (table.columns.isEmpty) {
      throw const FormatException('The workbook does not contain a header row.');
    }
    if (table.rows.isEmpty) {
      throw const FormatException('The workbook does not contain any recipient rows.');
    }
    return _repository.saveForProject(projectId, table);
  }
}
***
