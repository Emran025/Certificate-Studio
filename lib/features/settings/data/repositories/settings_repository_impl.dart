import 'dart:convert';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_data_source.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dataSource);
  final SettingsDataSource _dataSource;
  static const _appSettingsKey = 'app.settings';
  @override
  Future<AppSettings> loadAppSettings() async {
    final raw = await _dataSource.loadValue(_appSettingsKey);
    if (raw == null) return const AppSettings();
    final value = jsonDecode(raw);
    return AppSettingsModel.fromJson(Map<String, Object?>.from(value as Map));
  }
  @override
  Future<void> saveAppSettings(AppSettings settings) => _dataSource.saveValue(
        _appSettingsKey,
        jsonEncode(AppSettingsModel(
          themeMode: settings.themeMode,
          accentColorValue: settings.accentColorValue,
          languageCode: settings.languageCode,
        ).toJson()),
      );
}
