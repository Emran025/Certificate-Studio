import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';

abstract interface class FontDataSource {
  Future<List<Map<String, Object?>>> getFonts();
  Future<String?> selectedForProject(String projectId);
  Future<void> insertFont(Map<String, Object?> row);
  Future<void> selectForProject(String projectId, String fontId);
  Future<void> deleteFont(String id);
}

class FontDataSourceImpl implements FontDataSource {
  FontDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<List<Map<String, Object?>>> getFonts() => _database.query(DatabaseTables.fonts);
  @override
  Future<String?> selectedForProject(String projectId) async {
    final rows = await _database.query(DatabaseTables.projects, where: {'id': projectId});
    if (rows.isEmpty) return null;
    final raw = rows.first['settings_json'];
    if (raw is! String || raw.isEmpty) return null;
    return (jsonDecode(raw) as Map)['font_id']?.toString();
  }
  @override
  Future<void> insertFont(Map<String, Object?> row) => _database.insert(DatabaseTables.fonts, row);
  @override
  Future<void> selectForProject(String projectId, String fontId) async {
    final rows = await _database.query(DatabaseTables.projects, where: {'id': projectId});
    if (rows.isEmpty) return;
    final raw = rows.first['settings_json'];
    final settings = raw is String && raw.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : <String, dynamic>{};
    settings['font_id'] = fontId;
    await _database.update(DatabaseTables.projects, projectId, {'settings_json': jsonEncode(settings), 'updated_at': DateTime.now().toUtc().toIso8601String()});
  }
  @override
  Future<void> deleteFont(String id) => _database.delete(DatabaseTables.fonts, id);
}
