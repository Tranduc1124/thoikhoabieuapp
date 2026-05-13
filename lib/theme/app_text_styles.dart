import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(Color primary, Color secondary, Color hint) {
    return TextTheme(
      headlineSmall: TextStyle(
        color: primary,
        fontSize: 25,
        height: 1.12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 20,
        height: 1.18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 15,
        height: 1.28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(color: secondary, fontSize: 14, height: 1.42),
      bodySmall: TextStyle(color: secondary, fontSize: 12.5, height: 1.35),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        color: hint,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
