import '../entities/imported_table.dart';
import '../repositories/data_import_repository.dart';

class UpdateImportedTable {
  const UpdateImportedTable(this._repository);

  final DataImportRepository _repository;

  Future<ImportedTable> call({
    required String projectId,
    required ImportedTable table,
  }) => _repository.saveForProject(projectId, table);
}
