import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workspace_metrics.dart';
import '../../domain/usecases/get_workspace_metrics.dart';

sealed class WorkspaceMetricsEvent {
  const WorkspaceMetricsEvent();
}

final class WorkspaceMetricsRequested extends WorkspaceMetricsEvent {
  const WorkspaceMetricsRequested();
}

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
