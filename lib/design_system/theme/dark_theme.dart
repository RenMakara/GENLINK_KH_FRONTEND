import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../radius/app_radius.dart';
import '../spacing/app_spacing.dart';
import '../typography/app_text_theme.dart';

/// Dark-mode Material tokens, built from design system values only.
abstract final class DarkTheme {
  static ThemeData data({TextTheme? textTheme}) {
    final text = textTheme ?? AppTextTheme.english;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBgPrimary,
      canvasColor: AppColors.darkBgPrimary,
      cardColor: AppColors.darkSurfacePrimary,
      dividerColor: AppColors.darkBorderSubtle,
      textTheme: text.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkTextInverse,
        secondary: AppColors.accentPremium,
        onSecondary: AppColors.darkTextInverse,
        surface: AppColors.darkSurfacePrimary,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.danger,
        onError: AppColors.darkTextPrimary,
        outline: AppColors.darkBorderStrong,
        outlineVariant: AppColors.darkBorderSubtle,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBgPrimary,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfacePrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.darkBorderSubtle),
        ),
      ),
      inputDecorationTheme: _inputTheme(text),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: AppColors.darkTextPrimary,
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
      fillColor: AppColors.darkSurfacePrimary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      hintStyle: text.bodyMedium?.copyWith(color: AppColors.darkTextMuted),
      labelStyle: text.bodyMedium?.copyWith(color: AppColors.darkTextSecondary),
      errorStyle: text.bodySmall?.copyWith(color: AppColors.danger),
      enabledBorder: border(AppColors.darkBorderSubtle),
      focusedBorder: border(AppColors.darkPrimary, 1.5),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.5),
      disabledBorder: border(AppColors.darkBorderSubtle),
    );
  }
}
