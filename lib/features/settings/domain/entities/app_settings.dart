enum AppThemeMode { system, light, dark }

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.accentColorValue = 0xFF2F6B4F,
    this.languageCode = 'ar',
  });

  final AppThemeMode themeMode;
  final int accentColorValue;
  final String languageCode;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? accentColorValue,
    String? languageCode,
  }) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        accentColorValue: accentColorValue ?? this.accentColorValue,
        languageCode: languageCode ?? this.languageCode,
      );
}
