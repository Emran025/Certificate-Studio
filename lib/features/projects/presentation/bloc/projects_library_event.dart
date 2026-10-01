import '../../domain/entities/project.dart';

sealed class ProjectsLibraryEvent {
  const ProjectsLibraryEvent();
}

final class ProjectsRequested extends ProjectsLibraryEvent {
  const ProjectsRequested();
}

final class ProjectDeleted extends ProjectsLibraryEvent {
  const ProjectDeleted(this.project);
  final Project project;
}
