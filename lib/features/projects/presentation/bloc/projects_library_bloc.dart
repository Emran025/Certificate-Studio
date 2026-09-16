import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/delete_project.dart';

sealed class ProjectsLibraryEvent { const ProjectsLibraryEvent(); }
final class ProjectsRequested extends ProjectsLibraryEvent { const ProjectsRequested(); }
final class ProjectDeleted extends ProjectsLibraryEvent { const ProjectDeleted(this.project); final Project project; }

enum ProjectsLibraryStatus { initial, loading, loaded, deleting, failure }

class ProjectsLibraryState {
  const ProjectsLibraryState({
    this.status = ProjectsLibraryStatus.initial,
    this.projects = const [],
    this.errorMessage,
    this.deletedProjectName,
  });
  final ProjectsLibraryStatus status;
  final List<Project> projects;
  final String? errorMessage;
  final String? deletedProjectName;
}

class ProjectsLibraryBloc extends Bloc<ProjectsLibraryEvent, ProjectsLibraryState> {
  ProjectsLibraryBloc(this._repository, this._deleteProject, this._institutionId)
      : super(const ProjectsLibraryState()) {
    on<ProjectsRequested>(_load);
    on<ProjectDeleted>(_delete);
  }
  final ProjectRepository _repository;
  final DeleteProject _deleteProject;
  final String _institutionId;

  Future<void> _load(ProjectsRequested event, Emitter<ProjectsLibraryState> emit) async {
    emit(ProjectsLibraryState(status: ProjectsLibraryStatus.loading, projects: state.projects));
    try {
      emit(ProjectsLibraryState(
        status: ProjectsLibraryStatus.loaded,
        projects: await _repository.getAll(institutionId: _institutionId),
      ));
    } catch (error) {
      emit(ProjectsLibraryState(status: ProjectsLibraryStatus.failure, projects: state.projects, errorMessage: error.toString()));
    }
  }

  Future<void> _delete(ProjectDeleted event, Emitter<ProjectsLibraryState> emit) async {
    emit(ProjectsLibraryState(status: ProjectsLibraryStatus.deleting, projects: state.projects));
    try {
      await _deleteProject(event.project.id);
      emit(ProjectsLibraryState(
        status: ProjectsLibraryStatus.loaded,
        projects: state.projects.where((item) => item.id != event.project.id).toList(growable: false),
        deletedProjectName: event.project.name,
      ));
    } catch (error) {
      emit(ProjectsLibraryState(status: ProjectsLibraryStatus.failure, projects: state.projects, errorMessage: error.toString()));
    }
  }
}
