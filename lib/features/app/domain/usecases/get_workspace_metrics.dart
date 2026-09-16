import '../entities/workspace_metrics.dart';
import '../repositories/workspace_repository.dart';

class GetWorkspaceMetrics {
  GetWorkspaceMetrics(this._repository);

  final WorkspaceRepository _repository;

  Future<WorkspaceMetrics> call() => _repository.getMetrics();
}
