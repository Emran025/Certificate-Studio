import '../../../../core/entities/operation_result.dart';
import '../entities/imported_table.dart';
import '../repositories/data_import_repository.dart';

class GetImportedTable {
  const GetImportedTable(this._repository);

  final DataImportRepository _repository;

  Future<OperationResult<ImportedTable>> call(String projectId) async {
    try {
      return OperationSuccess(await _repository.getForProject(projectId));
    } catch (_) {
      return const OperationFailure<ImportedTable>(
        'Unable to load the imported table.',
      );
    }
  }
}
