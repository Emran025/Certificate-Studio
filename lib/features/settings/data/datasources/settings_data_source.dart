import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';

abstract interface class SettingsDataSource {
  Future<String?> loadValue(String key);
  Future<void> saveValue(String key, String value);
}

class SettingsDataSourceImpl implements SettingsDataSource {
  SettingsDataSourceImpl(this._database);
  final AppDatabase _database;
  @override
  Future<String?> loadValue(String key) async {
    final rows = await _database.query(DatabaseTables.settings, where: {'key': key});
    return rows.isEmpty ? null : rows.first['value_json'] as String?;
  }
  @override
  Future<void> saveValue(String key, String value) => _database.upsert(DatabaseTables.settings, {'key': key, 'value_json': value, 'updated_at': DateTime.now().toUtc().toIso8601String()}, conflictColumn: 'key');
}
