import '../../../../shared/themes/app_colors.dart';
import '../../domain/entities/app_settings.dart';

/// Persistence DTO for [AppSettings].
class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    super.themeMode,
    super.accentColorValue,
    super.languageCode,
  });

  factory AppSettingsModel.fromJson(Map<String, Object?> json) {
    final mode = AppThemeMode.values.where(
      (value) => value.name == json['theme_mode'],
    );
    return AppSettingsModel(
      themeMode: mode.isEmpty ? AppThemeMode.system : mode.first,
      accentColorValue: _accentColorFromJson(json['accent_color']),
      languageCode: json['language'] as String? ?? 'ar',
    );
  }

  Map<String, Object?> toJson() => {
        'theme_mode': themeMode.name,
        'accent_color': accentColorValue,
        'language': languageCode,
      };

  static int _accentColorFromJson(Object? value) {
    final stored = (value as num?)?.toInt();
    // Migrate the former hard-coded default for existing installations.
    if (stored == 0xFF176B87 || stored == null) {
      return AppColors.primaryValue;
    }
    return stored;
  }
}
