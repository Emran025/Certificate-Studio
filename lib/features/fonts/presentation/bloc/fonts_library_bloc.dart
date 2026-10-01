export 'fonts_library_event.dart';
export 'fonts_library_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'fonts_library_event.dart';
import 'fonts_library_state.dart';
import '../../domain/repositories/font_repository.dart';

class FontsLibraryBloc extends Bloc<FontsLibraryEvent, FontsLibraryState> {
  FontsLibraryBloc(this._repository, this._projectId)
    : super(const FontsLibraryState()) {
    on<FontsRequested>(_load);
    on<FontAdded>(_add);
    on<FontSelected>(_select);
    on<FontDeleted>(_delete);
  }
  final FontRepository _repository;
  final String? _projectId;
  Future<void> _load(
    FontsRequested event,
    Emitter<FontsLibraryState> emit,
  ) async {
    emit(
      FontsLibraryState(status: FontsLibraryStatus.loading, fonts: state.fonts),
    );
    try {
      emit(
        FontsLibraryState(
          status: FontsLibraryStatus.loaded,
          fonts: (await _repository.getAll()).reversed.toList(growable: false),
          selectedId: _projectId == null
              ? null
              : await _repository.selectedForProject(_projectId),
        ),
      );
    } catch (error) {
      emit(
        FontsLibraryState(
          status: FontsLibraryStatus.failure,
          fonts: state.fonts,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _add(FontAdded event, Emitter<FontsLibraryState> emit) =>
      _save(emit, () => _repository.add(event.font, event.bytes));
  Future<void> _select(
    FontSelected event,
    Emitter<FontsLibraryState> emit,
  ) async {
    if (_projectId != null) {
      await _repository.selectForProject(_projectId, event.id);
    }
    emit(
      FontsLibraryState(
        status: FontsLibraryStatus.loaded,
        fonts: state.fonts,
        selectedId: event.id,
      ),
    );
  }

  Future<void> _delete(FontDeleted event, Emitter<FontsLibraryState> emit) =>
      _save(emit, () => _repository.delete(event.id));
  Future<void> _save(
    Emitter<FontsLibraryState> emit,
    Future<Object?> Function() action,
  ) async {
    emit(
      FontsLibraryState(
        status: FontsLibraryStatus.saving,
        fonts: state.fonts,
        selectedId: state.selectedId,
      ),
    );
    try {
      await action();
      emit(
        FontsLibraryState(
          status: FontsLibraryStatus.loaded,
          fonts: (await _repository.getAll()).reversed.toList(growable: false),
          selectedId: state.selectedId,
        ),
      );
    } catch (error) {
      emit(
        FontsLibraryState(
          status: FontsLibraryStatus.failure,
          fonts: state.fonts,
          selectedId: state.selectedId,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
