import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_data_source.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this._dataSource);
  final ProjectDataSource _dataSource;
  @override
  Future<List<Project>> getAll({String? institutionId}) async =>
      (await _dataSource.getProjects(institutionId: institutionId))
          .map(ProjectModel.fromRow)
          .toList(growable: false);
  @override
  Future<Project?> getById(String id) async {
    final row = await _dataSource.getProject(id);
    return row == null ? null : ProjectModel.fromRow(row);
  }
  @override
  Future<Project> save(Project project) async {
    final model = ProjectModel(
      id: project.id,
      institutionId: project.institutionId,
      name: project.name,
      courseName: project.courseName,
      description: project.description,
      startDate: project.startDate,
      endDate: project.endDate,
      trainerName: project.trainerName,
      organizationName: project.organizationName,
      logoPath: project.logoPath,
      templateId: project.templateId,
      settings: project.settings,
      projectKeyReference: project.projectKeyReference,
      version: project.version,
      createdAt: project.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dataSource.saveProject(model.toRow());
    return model;
  }
  @override
  Future<void> delete(String id) => _dataSource.deleteProject(id);
  @override
  Future<void> deleteCascade(String id) => _dataSource.deleteProjectCascade(id);
}
