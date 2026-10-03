import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import 'project_data_source.dart';

class ProjectDataSourceImpl implements ProjectDataSource {
  ProjectDataSourceImpl(
    this._database, {
    CertificateArtifactStore? artifactStore,
  }) : _artifactStore =
           artifactStore ?? SharedPreferencesCertificateArtifactStore();

  final AppDatabase _database;
  final CertificateArtifactStore _artifactStore;

  @override
  Future<List<Map<String, Object?>>> getProjects({String? institutionId}) =>
      _database.query(
        DatabaseTables.projects,
        where: institutionId == null
            ? const {}
            : {'institution_id': institutionId},
      );

  @override
  Future<Map<String, Object?>?> getProject(String id) async {
    final rows = await _database.query(
      DatabaseTables.projects,
      where: {'id': id},
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> saveProject(Map<String, Object?> row) =>
      _database.upsert(DatabaseTables.projects, row);

  @override
  Future<void> deleteProject(String id) =>
      _database.delete(DatabaseTables.projects, id);

  @override
  Future<void> deleteProjectCascade(String id) async {
    final certificates = await _database.query(
      DatabaseTables.certificates,
      where: {'project_id': id},
      columns: ['file_path', 'image_path'],
    );
    await Future.wait([
      for (final certificate in certificates)
        for (final key in ['file_path', 'image_path'])
          if ((certificate[key] as String?)?.isNotEmpty == true)
            _artifactStore.delete(certificate[key]! as String),
    ]);

    _database.beginBatch();
    try {
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
      await _database.deleteWhere(DatabaseTables.verificationRecords, {
        'project_id': id,
      });
      await _database.deleteWhere(DatabaseTables.certificates, {
        'project_id': id,
      });
      await _database.deleteWhere(DatabaseTables.generationJobs, {
        'project_id': id,
      });
      for (final table in [
        DatabaseTables.certificateFields,
        DatabaseTables.certificateLayouts,
        DatabaseTables.records,
      ]) {
        await _database.deleteWhere(table, {'project_id': id});
      }
      await _database.delete(DatabaseTables.settings, 'mapping:$id');
      await deleteProject(id);
    } finally {
      await _database.endBatch();
    }
  }
}
