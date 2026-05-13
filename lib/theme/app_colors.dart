import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const lightPrimary = Color(0xFF5B7CFA);
  static const darkPrimary = Color(0xFFAFC0FF);
  static const mint = Color(0xFF67D7B0);
  static const peach = Color(0xFFFFB397);
  static const lavender = Color(0xFFC9B6FF);
  static const sky = Color(0xFF8ED8FF);

  static const darkBgTop = Color(0xFF070B16);
  static const darkBgMid = Color(0xFF0B1020);
  static const darkBgBottom = Color(0xFF111827);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFFCBD5E1);
  static const darkTextHint = Color(0xFF94A3B8);

  static const lightBgTop = Color(0xFFFAFCFF);
  static const lightBgMid = Color(0xFFF2F6FF);
  static const lightBgBottom = Color(0xFFFFF7F2);
  static const lightText = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextHint = Color(0xFF64748B);

  static const success = Color(0xFF2ECC9B);
  static const warning = Color(0xFFFFC66D);
  static const error = Color(0xFFFF7A8A);
  static const info = Color(0xFF8ED8FF);
}

extension AppColorTokens on ColorScheme {
  bool get isDark => brightness == Brightness.dark;

  List<Color> get appBackgroundGradient => isDark
      ? const [AppColors.darkBgTop, AppColors.darkBgMid, AppColors.darkBgBottom]
      : const [
          AppColors.lightBgTop,
          AppColors.lightBgMid,
          AppColors.lightBgBottom,
        ];

  Color get glassSurface => isDark
      ? Colors.white.withValues(alpha: 0.095)
      : Colors.white.withValues(alpha: 0.72);

  Color get glassSurfaceStrong => isDark
      ? Colors.white.withValues(alpha: 0.13)
      : Colors.white.withValues(alpha: 0.84);

  Color get glassStroke => isDark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.78);

  Color get glassStrokeSubtle => isDark
      ? Colors.white.withValues(alpha: 0.09)
      : Colors.white.withValues(alpha: 0.50);

  Color get tileSurface => isDark
      ? Colors.white.withValues(alpha: 0.075)
      : Colors.white.withValues(alpha: 0.58);

  Color get softShadow => isDark
      ? Colors.black.withValues(alpha: 0.34)
      : primary.withValues(alpha: 0.11);

  Color get textPrimary => isDark ? AppColors.darkText : AppColors.lightText;

  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  Color get textHint =>
      isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
}
