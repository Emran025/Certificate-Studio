import 'package:flutter/material.dart';

import '../../../../shared/themes/app_colors.dart';

enum AppThemeMode { system, light, dark }

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.accentColorValue = AppColors.primaryValue,
    this.languageCode = 'ar',
  });

  final AppThemeMode themeMode;
  final int accentColorValue;
  final String languageCode;

  Color get accentColor => Color(accentColorValue);

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? accentColorValue,
    String? languageCode,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    accentColorValue: accentColorValue ?? this.accentColorValue,
    languageCode: languageCode ?? this.languageCode,
  );

  Map<String, Object?> toJson() => {
    'theme_mode': themeMode.name,
    'accent_color': accentColorValue,
    'language': languageCode,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final mode = AppThemeMode.values.where(
      (value) => value.name == json['theme_mode'],
    );
    return AppSettings(
      themeMode: mode.isEmpty ? AppThemeMode.system : mode.first,
      accentColorValue: _accentColorFromJson(json['accent_color']),
      languageCode: json['language'] as String? ?? 'ar',
    );
  }

  static int _accentColorFromJson(Object? value) {
    final stored = (value as num?)?.toInt();
    // Migrate the former hard-coded default so theme changes apply to
    // existing installations as well as new ones.
    if (stored == 0xFF176B87 || stored == null) {
      return AppColors.primaryValue;
    }
    return stored;
  }
}
