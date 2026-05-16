import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const fontFallback = [
      'Be Vietnam Pro',
      'Inter',
      '.SF Pro Text',
      'SF Pro Text',
      'Roboto',
      'Arial',
    ];
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFF7BA7FF) : const Color(0xFF5B7CFA),
          onPrimary: Colors.white,
          secondary: isDark ? const Color(0xFFA78BFA) : const Color(0xFF67D7B0),
          tertiary: isDark ? const Color(0xFF8ED8FF) : const Color(0xFFFFB397),
          surface: isDark ? const Color(0xFF101827) : const Color(0xFFFFFFFF),
          onSurface: isDark ? AppColors.darkText : AppColors.lightText,
          onSurfaceVariant: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          surfaceContainer: isDark
              ? const Color(0xFF111A2B)
              : const Color(0xFFF8FBFF),
          surfaceContainerHigh: isDark
              ? const Color(0xFF151F32)
              : const Color(0xFFF2F6FF),
          surfaceContainerHighest: isDark
              ? const Color(0xFF1C2940)
              : const Color(0xFFEAF0FD),
          outline: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFD7E1F2),
          outlineVariant: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE5ECF7),
          error: AppColors.error,
          onError: Colors.white,
        );

    final textTheme = AppTextStyles.textTheme(
      colorScheme.textPrimary,
      colorScheme.textSecondary,
      colorScheme.textHint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamilyFallback: fontFallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBgMid
          : AppColors.lightBgTop,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colorScheme.textSecondary, size: 22),
      dividerColor: colorScheme.outlineVariant,
      splashColor: colorScheme.primary.withValues(alpha: 0.10),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.cardGlassColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.tileSurface,
        labelStyle: TextStyle(color: colorScheme.textSecondary),
        hintStyle: TextStyle(color: colorScheme.textHint),
        prefixIconColor: colorScheme.textSecondary,
        suffixIconColor: colorScheme.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.glassStrokeSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.65),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(colorScheme.tileSurface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.textHint, fontWeight: FontWeight.w600),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: colorScheme.glassStrokeSubtle),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          animationDuration: AppMotion.tap,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          animationDuration: AppMotion.tap,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: BorderSide(color: colorScheme.glassStroke),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceColor.withValues(
          alpha: isDark ? 0.98 : 0.99,
        ),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colorScheme.glassStroke),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.textPrimary,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.tileSurface,
        selectedColor: colorScheme.primary.withValues(
          alpha: isDark ? 0.22 : 0.16,
        ),
        disabledColor: colorScheme.tileSurface.withValues(alpha: 0.70),
        secondarySelectedColor: colorScheme.primary.withValues(
          alpha: isDark ? 0.22 : 0.16,
        ),
        side: BorderSide(color: colorScheme.glassStrokeSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.textSecondary,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(
                alpha: isDark ? 0.22 : 0.14,
              );
            }
            return colorScheme.tileSurface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.textPrimary;
            }
            return colorScheme.textSecondary;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.glassStrokeSubtle),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.surfaceColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.75);
          }
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStatePropertyAll(colorScheme.glassStroke),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surfaceColor,
        hourMinuteColor: colorScheme.tileSurface,
        hourMinuteTextColor: colorScheme.textPrimary,
        dialBackgroundColor: colorScheme.surfaceContainer,
        dialHandColor: colorScheme.primary,
        dialTextColor: colorScheme.textPrimary,
        dayPeriodColor: colorScheme.tileSurface,
        dayPeriodTextColor: colorScheme.textSecondary,
        entryModeIconColor: colorScheme.textSecondary,
        helpTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.textSecondary,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colorScheme.glassStroke),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF151F32)
            : const Color(0xFFFFFFFF),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }
}
