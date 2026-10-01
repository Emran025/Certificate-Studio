export 'projects_library_event.dart';
export 'projects_library_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'projects_library_event.dart';
import 'projects_library_state.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/delete_project.dart';

class ProjectsLibraryBloc
    extends Bloc<ProjectsLibraryEvent, ProjectsLibraryState> {
  ProjectsLibraryBloc(
    this._repository,
    this._deleteProject,
    this._institutionId,
  ) : super(const ProjectsLibraryState()) {
    on<ProjectsRequested>(_load);
    on<ProjectDeleted>(_delete);
  }
  final ProjectRepository _repository;
  final DeleteProject _deleteProject;
  final String _institutionId;

  Future<void> _load(
    ProjectsRequested event,
    Emitter<ProjectsLibraryState> emit,
  ) async {
    emit(
      ProjectsLibraryState(
        status: ProjectsLibraryStatus.loading,
        projects: state.projects,
      ),
    );
    try {
      emit(
        ProjectsLibraryState(
          status: ProjectsLibraryStatus.loaded,
          projects: await _repository.getAll(institutionId: _institutionId),
        ),
      );
    } catch (error) {
      emit(
        ProjectsLibraryState(
          status: ProjectsLibraryStatus.failure,
          projects: state.projects,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _delete(
    ProjectDeleted event,
    Emitter<ProjectsLibraryState> emit,
  ) async {
    emit(
      ProjectsLibraryState(
        status: ProjectsLibraryStatus.deleting,
        projects: state.projects,
      ),
    );
    try {
      await _deleteProject(event.project.id);
      emit(
        ProjectsLibraryState(
          status: ProjectsLibraryStatus.loaded,
          projects: state.projects
              .where((item) => item.id != event.project.id)
              .toList(growable: false),
          deletedProjectName: event.project.name,
        ),
      );
    } catch (error) {
      emit(
        ProjectsLibraryState(
          status: ProjectsLibraryStatus.failure,
          projects: state.projects,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
