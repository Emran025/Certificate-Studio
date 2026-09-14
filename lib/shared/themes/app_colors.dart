import 'package:flutter/material.dart';

/// Semantic color tokens for Certificate Studio.
///
/// Keep feature screens dependent on these semantic values rather than raw
/// colors so the visual language can evolve consistently.
abstract final class AppColors {
  static const primary = Color(0xFF2F6B4F);
  static const primaryDark = Color(0xFF1F4A37);
  static const primaryLight = Color(0xFFE5F0E9);
  static const accent = Color(0xFFB77945);

  static const background = Color(0xFFF3EDE3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFECE4D8);
  static const surfaceSubtle = Color(0xFFF8F3EB);

  static const textPrimary = Color(0xFF24332D);
  static const textSecondary = Color(0xFF66736C);
  static const textTertiary = Color(0xFF8B968F);
  static const textOnPrimary = Color(0xFFFFFFFF);

  static const border = Color(0xFFDED4C7);
  static const borderStrong = Color(0xFFC8BBAA);
  static const divider = Color(0xFFE6DDD1);

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
    colors: [Color(0xFFF5EFE6), Color(0xFFECE3D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
