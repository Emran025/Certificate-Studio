export 'startup_event.dart';
export 'startup_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'startup_event.dart';
import 'startup_state.dart';
import '../../../institution/domain/repositories/institution_repository.dart';

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
