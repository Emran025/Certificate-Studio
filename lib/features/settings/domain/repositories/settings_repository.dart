import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> loadAppSettings();
  Future<void> saveAppSettings(AppSettings settings);
}
