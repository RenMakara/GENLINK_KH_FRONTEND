import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../radius/app_radius.dart';
import '../spacing/app_spacing.dart';
import '../typography/app_text_theme.dart';

/// Light-mode Material tokens, built from design system values only.
abstract final class LightTheme {
  static ThemeData data({TextTheme? textTheme}) {
    final text = textTheme ?? AppTextTheme.english;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBgPrimary,
      canvasColor: AppColors.lightBgPrimary,
      cardColor: AppColors.lightSurfacePrimary,
      dividerColor: AppColors.lightBorderSubtle,
      textTheme: text.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightTextInverse,
        secondary: AppColors.accentPremium,
        onSecondary: AppColors.lightTextPrimary,
        surface: AppColors.lightSurfacePrimary,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.danger,
        onError: AppColors.lightTextInverse,
        outline: AppColors.lightBorderStrong,
        outlineVariant: AppColors.lightBorderSubtle,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBgPrimary,
        foregroundColor: AppColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.lightBorderSubtle),
        ),
      ),
      inputDecorationTheme: _inputTheme(text),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: AppColors.lightTextInverse,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(TextTheme text) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? AppColors.lightBgSecondary
            : AppColors.lightSurfacePrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      hintStyle: text.bodyMedium?.copyWith(color: AppColors.lightTextMuted),
      labelStyle: text.bodyMedium?.copyWith(
        color: AppColors.lightTextSecondary,
      ),
      errorStyle: text.bodySmall?.copyWith(color: AppColors.danger),
      enabledBorder: border(AppColors.lightBorderSubtle),
      // Focus is signalled by the fill, not the outline — the border stays
      // identical so the field does not appear to grow on tap.
      focusedBorder: border(AppColors.lightBorderSubtle),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger),
      disabledBorder: border(AppColors.lightBorderSubtle),
    );
  }
}
