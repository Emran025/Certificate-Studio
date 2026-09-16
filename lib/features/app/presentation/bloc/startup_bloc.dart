import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../institution/domain/entities/institution.dart';
import '../../../institution/domain/repositories/institution_repository.dart';

sealed class StartupEvent {
  const StartupEvent();
}

final class StartupRequested extends StartupEvent {
  const StartupRequested();
}

enum StartupStatus { loading, loaded, failure }

class StartupState {
  const StartupState({
    this.status = StartupStatus.loading,
    this.institution,
    this.errorMessage,
  });

  final StartupStatus status;
  final Institution? institution;
  final Object? errorMessage;
}

class StartupBloc extends Bloc<StartupEvent, StartupState> {
  StartupBloc(this._repository) : super(const StartupState()) {
    on<StartupRequested>(_onRequested);
  }

  final InstitutionRepository _repository;

  Future<void> _onRequested(
    StartupRequested event,
    Emitter<StartupState> emit,
  ) async {
    emit(
      StartupState(
        status: StartupStatus.loading,
        institution: state.institution,
      ),
    );
    try {
      emit(
        StartupState(
          status: StartupStatus.loaded,
          institution: await _repository.getCurrent(),
        ),
      );
    } catch (error) {
      emit(
        StartupState(
          status: StartupStatus.failure,
          institution: state.institution,
          errorMessage: error,
        ),
      );
    }
  }
}
