import '../../domain/entities/workspace_metrics.dart';

enum WorkspaceMetricsStatus { initial, loading, loaded, failure }

class WorkspaceMetricsState {
  const WorkspaceMetricsState({
    this.metrics = const WorkspaceMetrics.empty(),
    this.status = WorkspaceMetricsStatus.initial,
    this.errorMessage,
  });

  final WorkspaceMetrics metrics;
  final WorkspaceMetricsStatus status;
  final String? errorMessage;
}
