import '../../domain/entities/project.dart';

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
