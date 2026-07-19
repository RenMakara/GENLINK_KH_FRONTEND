import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  scaffoldBackgroundColor: AppColors.darkBgPrimary,
  cardColor: AppColors.darkSurfacePrimary,
  dividerColor: AppColors.darkBorderSubtle,

  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.accentPremium,
    surface: AppColors.darkSurfacePrimary,
    onPrimary: AppColors.darkTextInverse,
    onSurface: AppColors.darkTextPrimary,
  ),
);
