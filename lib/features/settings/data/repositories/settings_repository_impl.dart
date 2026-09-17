import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _appSettingsKey = 'app.settings';

  @override
  Future<AppSettings> loadAppSettings() async {
    final rows = await _database.query(
      DatabaseTables.settings,
      where: {'key': _appSettingsKey},
    );
    if (rows.isEmpty) return const AppSettings();
    final value = jsonDecode(rows.first['value_json']! as String);
    return AppSettings.fromJson(Map<String, Object?>.from(value as Map));
  }

  @override
  Future<void> saveAppSettings(AppSettings settings) async {
    await _database.upsert(
      DatabaseTables.settings,
      {
        'key': _appSettingsKey,
        'value_json': jsonEncode(settings.toJson()),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictColumn: 'key',
    );
  }
}
