export 'workspace_metrics_event.dart';
export 'workspace_metrics_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'workspace_metrics_event.dart';
import 'workspace_metrics_state.dart';
import '../../domain/usecases/get_workspace_metrics.dart';

class WorkspaceMetricsBloc
    extends Bloc<WorkspaceMetricsEvent, WorkspaceMetricsState> {
  WorkspaceMetricsBloc(this._getWorkspaceMetrics)
    : super(const WorkspaceMetricsState()) {
    on<WorkspaceMetricsRequested>(_onRequested);
  }

  final GetWorkspaceMetrics _getWorkspaceMetrics;

  Future<void> _onRequested(
    WorkspaceMetricsRequested event,
    Emitter<WorkspaceMetricsState> emit,
  ) async {
    emit(
      WorkspaceMetricsState(
        metrics: state.metrics,
        status: WorkspaceMetricsStatus.loading,
      ),
    );

    try {
      final metrics = await _getWorkspaceMetrics();
      emit(
        WorkspaceMetricsState(
          metrics: metrics,
          status: WorkspaceMetricsStatus.loaded,
        ),
      );
    } catch (error) {
      emit(
        WorkspaceMetricsState(
          metrics: state.metrics,
          status: WorkspaceMetricsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
