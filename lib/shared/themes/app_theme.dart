import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData withAccent({
    required Brightness brightness,
    Color? accentColor,
  }) => _build(brightness, accentColor: accentColor);

  static ThemeData _build(Brightness brightness, {Color? accentColor}) {
    final isDark = brightness == Brightness.dark;
    final primary = accentColor ?? AppColors.primary;
    final border = (isDark ? const Color(0xFF2D3945) : AppColors.border);
    final surface = isDark ? const Color(0xFF17202A) : AppColors.surface;
    final background = isDark ? const Color(0xFF101820) : AppColors.background;
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    final colorScheme = generatedScheme.copyWith(
      primary: primary,
      onPrimary: _onColor(primary),
      primaryContainer: _primaryContainer(primary, brightness),
      onPrimaryContainer: _onColor(_primaryContainer(primary, brightness)),
      surface: surface,
      onSurface: isDark ? Colors.white : AppColors.textPrimary,
      error: AppColors.error,
      onError: _onColor(AppColors.error),
    );

    final textTheme = _textTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      fontFamily: 'Cairo',
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(primary, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? const Color(0xFF202B36)
            : AppColors.surfaceSubtle,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: AppColors.borderStrong.withValues(alpha: 0.7),
          ),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: isDark ? Colors.white : AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          textTheme: textTheme,
          backgroundColor: primary,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          textTheme: textTheme,
          backgroundColor: primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          textTheme: textTheme,
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.62)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(textTheme: textTheme, foregroundColor: primary),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final foreground = brightness == Brightness.dark
        ? Colors.white
        : AppColors.textPrimary;
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
    ).apply(
      bodyColor: foreground,
      displayColor: foreground,
      fontFamily: 'Cairo',
    );
  }

  static Color _onColor(Color color) =>
      color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  static Color _primaryContainer(Color primary, Brightness brightness) {
    final hsl = HSLColor.fromColor(primary);
    return hsl
        .withLightness(brightness == Brightness.light ? 0.9 : 0.25)
        .toColor();
  }

  static ButtonStyle _buttonStyle({
    required TextTheme textTheme,
    Color? backgroundColor,
    Color? foregroundColor,
    BorderSide? side,
    double? elevation,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        textTheme.labelLarge?.copyWith(inherit: false),
      ),
      backgroundColor: backgroundColor != null
          ? WidgetStatePropertyAll(backgroundColor)
          : null,
      foregroundColor: foregroundColor != null
          ? WidgetStatePropertyAll(foregroundColor)
          : null,
      side: side != null ? WidgetStatePropertyAll(side) : null,
      elevation: elevation != null ? WidgetStatePropertyAll(elevation) : null,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
