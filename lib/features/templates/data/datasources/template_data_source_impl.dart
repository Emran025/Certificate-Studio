import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import 'template_data_source.dart';

class TemplateDataSourceImpl implements TemplateDataSource {
  TemplateDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<List<Map<String, Object?>>> getTemplates() =>
      _database.query(DatabaseTables.templates);
  @override
  Future<String?> selectedForProject(String projectId) async {
    final rows = await _database.query(
      DatabaseTables.projects,
      where: {'id': projectId},
    );
    return rows.isEmpty ? null : rows.first['template_id'] as String?;
  }

  @override
  Future<void> insertTemplate(Map<String, Object?> row) =>
      _database.insert(DatabaseTables.templates, row);
  @override
  Future<void> updateTemplate(String id, Map<String, Object?> values) =>
      _database.update(DatabaseTables.templates, id, values);
  @override
  Future<void> selectForProject(String projectId, String templateId) =>
      _database.update(DatabaseTables.projects, projectId, {
        'template_id': templateId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
  @override
  Future<bool> isUsedByProject(String templateId) async =>
      (await _database.query(
        DatabaseTables.projects,
        where: {'template_id': templateId},
      )).isNotEmpty;
  @override
  Future<void> deleteTemplate(String id) =>
      _database.delete(DatabaseTables.templates, id);
}
