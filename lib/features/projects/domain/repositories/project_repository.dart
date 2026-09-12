import '../entities/project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> getAll({String? institutionId});
  Future<Project?> getById(String id);
  Future<Project> save(Project project);
  Future<void> delete(String id);
}
