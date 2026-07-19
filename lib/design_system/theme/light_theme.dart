import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../typography/app_text_theme.dart';

/// Light theme placeholder.
///
/// Define light-mode Material tokens here using design system values only.
abstract final class LightTheme {
  static ThemeData get data => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandPrimary),
    textTheme: AppTextTheme.english,
    useMaterial3: true,
  );
}
