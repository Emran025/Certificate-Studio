import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/template_asset.dart';
import '../../domain/repositories/template_repository.dart';

sealed class TemplatePickerEvent {
  const TemplatePickerEvent();
}

final class TemplatesRequested extends TemplatePickerEvent {
  const TemplatesRequested();
}

final class TemplateAdded extends TemplatePickerEvent {
  const TemplateAdded(this.template);
  final TemplateAsset template;
}

final class TemplateSelected extends TemplatePickerEvent {
  const TemplateSelected(this.id);
  final String id;
}

final class TemplateUpdated extends TemplatePickerEvent {
  const TemplateUpdated(this.template);
  final TemplateAsset template;
}

final class TemplateDeleted extends TemplatePickerEvent {
  const TemplateDeleted(this.id);
  final String id;
}

enum TemplatePickerStatus { initial, loading, loaded, saving, failure }

class TemplatePickerState {
  const TemplatePickerState({
    this.status = TemplatePickerStatus.initial,
    this.templates = const [],
    this.selectedId,
    this.errorMessage,
  });
  final TemplatePickerStatus status;
  final List<TemplateAsset> templates;
  final String? selectedId;
  final String? errorMessage;
}

class TemplatePickerBloc
    extends Bloc<TemplatePickerEvent, TemplatePickerState> {
  TemplatePickerBloc(this._repository, this._projectId)
    : super(const TemplatePickerState()) {
    on<TemplatesRequested>(_load);
    on<TemplateAdded>(_add);
    on<TemplateSelected>(_select);
    on<TemplateUpdated>(_update);
    on<TemplateDeleted>(_delete);
  }
  final TemplateRepository _repository;
  final String? _projectId;

  Future<void> _load(
    TemplatesRequested event,
    Emitter<TemplatePickerState> emit,
  ) async {
    emit(
      TemplatePickerState(
        status: TemplatePickerStatus.loading,
        templates: state.templates,
      ),
    );
    try {
      final templates = await _repository.getAll();
      emit(
        TemplatePickerState(
          status: TemplatePickerStatus.loaded,
          templates: templates,
          selectedId: _projectId == null
              ? null
              : await _repository.selectedForProject(_projectId),
        ),
      );
    } catch (error) {
      emit(
        TemplatePickerState(
          status: TemplatePickerStatus.failure,
          templates: state.templates,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _add(
    TemplateAdded event,
    Emitter<TemplatePickerState> emit,
  ) async {
    await _perform(emit, () => _repository.add(event.template));
  }

  Future<void> _select(
    TemplateSelected event,
    Emitter<TemplatePickerState> emit,
  ) async {
    if (_projectId != null) {
      await _repository.selectForProject(_projectId, event.id);
    }

    emit(
      TemplatePickerState(
        status: TemplatePickerStatus.loaded,
        templates: state.templates,
        selectedId: event.id,
      ),
    );
  }

  Future<void> _update(
    TemplateUpdated event,
    Emitter<TemplatePickerState> emit,
  ) async {
    await _perform(emit, () => _repository.update(event.template));
  }

  Future<void> _delete(
    TemplateDeleted event,
    Emitter<TemplatePickerState> emit,
  ) async {
    if (await _repository.isUsedByProject(event.id)) {
      emit(
        TemplatePickerState(
          status: TemplatePickerStatus.failure,
          templates: state.templates,
          selectedId: state.selectedId,
          errorMessage:
              'This template is used by a project and cannot be deleted.',
        ),
      );
      return;
    }
    await _perform(emit, () => _repository.delete(event.id));
  }

  Future<void> _perform(
    Emitter<TemplatePickerState> emit,
    Future<void> Function() action,
  ) async {
    emit(
      TemplatePickerState(
        status: TemplatePickerStatus.saving,
        templates: state.templates,
        selectedId: state.selectedId,
      ),
    );
    try {
      await action();
      final templates = await _repository.getAll();
      emit(
        TemplatePickerState(
          status: TemplatePickerStatus.loaded,
          templates: templates,
          selectedId: state.selectedId,
        ),
      );
    } catch (error) {
      emit(
        TemplatePickerState(
          status: TemplatePickerStatus.failure,
          templates: state.templates,
          selectedId: state.selectedId,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
