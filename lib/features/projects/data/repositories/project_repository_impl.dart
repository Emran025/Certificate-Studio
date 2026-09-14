import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<Project>> getAll({String? institutionId}) async {
    final rows = await _database.query(
      DatabaseTables.projects,
      where: institutionId == null ? const {} : {'institution_id': institutionId},
    );
    return rows.map(ProjectModel.fromRow).toList(growable: false);
  }

  @override
  Future<Project?> getById(String id) async {
    final rows = await _database.query(DatabaseTables.projects, where: {'id': id});
    return rows.isEmpty ? null : ProjectModel.fromRow(rows.first);
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
    await _database.upsert(DatabaseTables.projects, model.toRow());
    return model;
  }

  @override
  Future<void> delete(String id) => _database.delete(DatabaseTables.projects, id);
}
