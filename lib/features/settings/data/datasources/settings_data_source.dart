abstract interface class SettingsDataSource {
  Future<String?> loadValue(String key);
  Future<void> saveValue(String key, String value);
}
