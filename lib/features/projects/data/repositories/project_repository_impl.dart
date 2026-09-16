import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
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
      where: institutionId == null
          ? const {}
          : {'institution_id': institutionId},
    );
    return rows.map(ProjectModel.fromRow).toList(growable: false);
  }

  @override
  Future<Project?> getById(String id) async {
    final rows = await _database.query(
      DatabaseTables.projects,
      where: {'id': id},
    );
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
  Future<void> delete(String id) =>
      _database.delete(DatabaseTables.projects, id);

  @override
  Future<void> deleteCascade(String id) async {
    final certificates = await _database.query(
      DatabaseTables.certificates,
      where: {'project_id': id},
      columns: ['file_path', 'image_path'],
    );
    final artifacts = CertificateArtifactStore();
    await Future.wait([
      for (final certificate in certificates)
        for (final key in ['file_path', 'image_path'])
          if ((certificate[key] as String?)?.isNotEmpty == true)
            artifacts.delete(certificate[key]! as String),
    ]);
    _database.beginBatch();
    try {
      await _database.deleteWhere(DatabaseTables.verificationRecords, {
        'project_id': id,
      });
      await _database.deleteWhere(DatabaseTables.certificates, {
        'project_id': id,
      });
      final jobs = await _database.query(
        DatabaseTables.generationJobs,
        where: {'project_id': id},
        columns: ['id'],
      );
      await _database.deleteWhereIn(
        DatabaseTables.generationItems,
        'job_id',
        jobs.map((job) => job['id']),
      );
      await _database.deleteWhere(DatabaseTables.generationJobs, {
        'project_id': id,
      });
      for (final table in [
        DatabaseTables.certificateFields,
        DatabaseTables.certificateLayouts,
        DatabaseTables.students,
        DatabaseTables.signatures,
      ]) {
        await _database.deleteWhere(table, {'project_id': id});
      }
      await _database.delete(DatabaseTables.settings, 'mapping:$id');
      await delete(id);
    } finally {
      await _database.endBatch();
    }
  }
}
