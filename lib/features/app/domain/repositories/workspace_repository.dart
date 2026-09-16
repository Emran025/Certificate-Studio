import '../entities/workspace_metrics.dart';

abstract interface class WorkspaceRepository {
  Future<WorkspaceMetrics> getMetrics();
}
