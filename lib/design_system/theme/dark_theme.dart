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
        onPrimary: AppColors.darkTextPrimary,
        primaryContainer: AppColors.darkPrimarySoft,
        onPrimaryContainer: AppColors.darkTextPrimary,
        secondary: AppColors.darkAccentMint,
        onSecondary: AppColors.darkTextInverse,
        secondaryContainer: Color(0xFF123B42),
        onSecondaryContainer: AppColors.darkTextPrimary,
        tertiary: AppColors.darkAccentPink,
        onTertiary: AppColors.darkTextInverse,
        tertiaryContainer: Color(0xFF48203A),
        onTertiaryContainer: AppColors.darkTextPrimary,
        surface: AppColors.darkSurfacePrimary,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        error: AppColors.danger,
        onError: AppColors.darkTextPrimary,
        outline: AppColors.darkBorderStrong,
        outlineVariant: AppColors.darkBorderSubtle,
        surfaceTint: AppColors.darkPrimary,
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
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkTextSecondary,
        textColor: AppColors.darkTextPrimary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfacePrimary,
        modalBackgroundColor: AppColors.darkSurfacePrimary,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfacePrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.darkPrimary,
        linearTrackColor: AppColors.darkBorderSubtle,
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
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? AppColors.darkSurfaceSecondary
            : AppColors.darkSurfacePrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      hintStyle: text.bodyMedium?.copyWith(color: AppColors.darkTextMuted),
      labelStyle: text.bodyMedium?.copyWith(color: AppColors.darkTextSecondary),
      errorStyle: text.bodySmall?.copyWith(color: AppColors.danger),
      enabledBorder: border(AppColors.darkBorderSubtle),
      focusedBorder: border(AppColors.darkPrimary, 1.4),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger),
      disabledBorder: border(AppColors.darkBorderSubtle),
    );
  }
}
