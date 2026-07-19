import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  scaffoldBackgroundColor: AppColors.lightBgPrimary,
  cardColor: AppColors.lightSurfacePrimary,
  dividerColor: AppColors.lightBorderSubtle,

  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.accentPremium,
    surface: AppColors.lightSurfacePrimary,
    onPrimary: AppColors.lightTextInverse,
    onSurface: AppColors.lightTextPrimary,
  ),
);
