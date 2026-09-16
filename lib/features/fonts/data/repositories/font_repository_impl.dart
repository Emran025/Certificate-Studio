import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/font_asset.dart';
import '../../domain/repositories/font_repository.dart';

class FontRepositoryImpl implements FontRepository {
  FontRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<List<FontAsset>> getAll() async =>
      (await _database.query(DatabaseTables.fonts))
          .map((row) => FontAsset(
                id: row['id']! as String,
                name: row['name']! as String,
                family: row['family']! as String,
                filePath: row['file_path']! as String,
                format: row['format']! as String,
              ))
          .toList(growable: false);

  @override
  Future<String?> selectedForProject(String projectId) async {
    final rows = await _database.query(DatabaseTables.projects, where: {'id': projectId});
    if (rows.isEmpty) return null;
    final raw = rows.first['settings_json'];
    if (raw is! String || raw.isEmpty) return null;
    return (jsonDecode(raw) as Map)['font_id']?.toString();
  }

  @override
  Future<FontAsset> add(FontAsset font, List<int> bytes) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _database.insert(DatabaseTables.fonts, {
      'id': font.id, 'name': font.name, 'family': font.family,
      'file_path': font.filePath, 'format': font.format, 'font_bytes': bytes,
      'created_at': now, 'updated_at': now,
    });
    return font;
  }

  @override
  Future<void> selectForProject(String projectId, String fontId) async {
    final rows = await _database.query(DatabaseTables.projects, where: {'id': projectId});
    if (rows.isEmpty) return;
    final raw = rows.first['settings_json'];
    final settings = raw is String && raw.isNotEmpty
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    settings['font_id'] = fontId;
    await _database.update(DatabaseTables.projects, projectId, {
      'settings_json': jsonEncode(settings),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> delete(String id) => _database.delete(DatabaseTables.fonts, id);
}
