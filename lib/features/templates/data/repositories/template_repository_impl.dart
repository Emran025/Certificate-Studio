import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/template_asset.dart';
import '../../domain/repositories/template_repository.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  TemplateRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<List<TemplateAsset>> getAll() async {
    final rows = await _database.query(DatabaseTables.templates);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<String?> selectedForProject(String projectId) async {
    final rows = await _database.query(
      DatabaseTables.projects,
      where: {'id': projectId},
    );
    return rows.isEmpty ? null : rows.first['template_id'] as String?;
  }

  @override
  Future<TemplateAsset> add(TemplateAsset template) async {
    await _database.insert(DatabaseTables.templates, {
      'id': template.id,
      'name': template.name,
      'file_path': template.filePath,
      'width': template.width,
      'height': template.height,
      'dpi': template.dpi,
      'format': template.format,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return template;
  }

  @override
  Future<void> selectForProject(String projectId, String templateId) =>
      _database.update(DatabaseTables.projects, projectId, {
        'template_id': templateId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

  @override
  Future<bool> isUsedByProject(String templateId) async => (await _database
          .query(DatabaseTables.projects, where: {'template_id': templateId}))
      .isNotEmpty;

  @override
  Future<void> delete(String id) => _database.delete(DatabaseTables.templates, id);

  TemplateAsset _fromRow(Map<String, Object?> row) => TemplateAsset(
        id: row['id']! as String,
        name: row['name']! as String,
        filePath: row['file_path']! as String,
        width: row['width']! as int,
        height: row['height']! as int,
        dpi: (row['dpi']! as num).toDouble(),
        format: row['format']! as String,
      );
}
