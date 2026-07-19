import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../typography/app_text_theme.dart';

/// Dark theme placeholder.
///
/// Define dark-mode Material tokens here using design system values only.
abstract final class DarkTheme {
  static ThemeData get data => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppColors.brandPrimary,
    ),
    textTheme: AppTextTheme.english,
    useMaterial3: true,
  );
}
