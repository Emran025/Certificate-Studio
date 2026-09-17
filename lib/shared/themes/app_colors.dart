import 'package:flutter/material.dart';

extension AppThemeColors on BuildContext {
  Color get themeSurface => Theme.of(this).colorScheme.surface;
  Color get themeBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get themePrimary => Theme.of(this).colorScheme.primary;
  Color get themeOnPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get themeBorder =>
      Theme.of(this).dividerTheme.color ??
      Theme.of(this).colorScheme.outlineVariant;
  Color get themeMutedText => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get themeError => Theme.of(this).colorScheme.error;
  Color get themeSelection => Theme.of(this).colorScheme.primaryContainer;
  LinearGradient get themePageGradient => LinearGradient(
    colors: [
      Theme.of(this).colorScheme.surface,
      Theme.of(this).scaffoldBackgroundColor,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  LinearGradient get themeSidebarGradient => LinearGradient(
    colors: [
      Theme.of(this).colorScheme.surface,
      Theme.of(this).scaffoldBackgroundColor,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Semantic color tokens for Certificate Studio.
///
/// Keep feature screens dependent on these semantic values rather than raw
/// colors so the visual language can evolve consistently.
abstract final class AppColors {
  static const primaryValue = 0xFF2F6B4F;
  static const primary = Color(primaryValue);
  static const primaryDark = Color(0xFF1F4A37);
  static const primaryLight = Color(0xFFE5F0E9);
  static const accent = Color(0xFFB77945);

  // GitHub-inspired light neutrals keep the workspace clean and technical.
  static const background = Color(0xFFF6F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F2F4);
  static const surfaceSubtle = Color(0xFFF6F8FA);

  static const textPrimary = Color(0xFF1F2328);
  static const textSecondary = Color(0xFF59636E);
  static const textTertiary = Color(0xFF818B98);
  static const textOnPrimary = Color(0xFFFFFFFF);

  static const border = Color(0xFFE1E5E9);
  static const borderStrong = Color(0xFFD8DEE4);
  static const divider = Color(0xFFEBEEF1);

  static const success = Color(0xFF2E7D5B);
  static const successSurface = Color(0xFFE8F4EC);
  static const warning = Color(0xFFB7791F);
  static const warningSurface = Color(0xFFFFF4D8);
  static const error = Color(0xFFC24A4A);
  static const errorSurface = Color(0xFFFCEAEA);
  static const info = Color(0xFF477A93);
  static const infoSurface = Color(0xFFEAF3F7);

  static const shadow = Color(0x140F241A);
}

abstract final class AppGradients {
  static const page = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
