import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../design_system/colors/app_colors.dart';

/// Theme bridge for the Quiz feature.
///
/// Quiz screens historically consumed a second purple palette. These semantic
/// values now resolve from the app's active Material theme so the existing
/// Quiz layout follows Light/Dark mode without changing Quiz behavior.
abstract final class QuizThemeColors {
  static BuildContext? get _context => Get.context;

  static ColorScheme get _scheme {
    final context = _context;
    if (context != null) return Theme.of(context).colorScheme;
    return const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightTextInverse,
      surface: AppColors.lightSurfacePrimary,
      onSurface: AppColors.lightTextPrimary,
      outline: AppColors.lightBorderStrong,
      outlineVariant: AppColors.lightBorderSubtle,
    );
  }

  static Color get background => _context == null
      ? AppColors.lightBgPrimary
      : Theme.of(_context!).scaffoldBackgroundColor;

  static Color get backgroundAlt => _scheme.surfaceContainerLow;
  static Color get primary => _scheme.primary;
  static Color get primaryDark => _scheme.primary;
  static Color get primaryLight =>
      _scheme.primary.withValues(alpha: _isDark ? 0.16 : 0.08);
  static Color get surface => _scheme.surface;
  static Color get border => _scheme.outlineVariant;

  // Semantic colors remain stable across themes because their meaning does.
  static const correct = AppColors.success;
  static const incorrect = AppColors.danger;
  static const gold = AppColors.warning;
  static const medalSilver = Color(0xFF9E9E9E);
  static const medalBronze = Color(0xFFCD7F32);

  static Color get correctSoft =>
      correct.withValues(alpha: _isDark ? 0.22 : 0.12);
  static Color get incorrectSoft =>
      incorrect.withValues(alpha: _isDark ? 0.22 : 0.12);
  static Color get warningSoft => gold.withValues(alpha: _isDark ? 0.22 : 0.12);
  static Color get primarySoft =>
      primary.withValues(alpha: _isDark ? 0.18 : 0.08);
  static Color get muted => _scheme.onSurfaceVariant;
  static Color get disabled => _scheme.onSurface.withValues(alpha: 0.38);
  static Color get shadow => _scheme.shadow.withValues(alpha: 0.05);

  static Color get heading => _scheme.onSurface;
  static Color get body => _scheme.onSurfaceVariant;
  static Color get onPrimary => _scheme.onPrimary;
  static Color get darkOverlay => _isDark ? _scheme.surface : _scheme.onSurface;
  static Color get rewardForeground =>
      _isDark ? _scheme.onSurface : _scheme.surface;

  static bool get _isDark => _scheme.brightness == Brightness.dark;

  static List<BoxShadow> get cardShadow => _isDark
      ? const []
      : [
          BoxShadow(
            color: _scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

  static LinearGradient get gradient => LinearGradient(
    colors: [
      primary,
      primary.withValues(alpha: _isDark ? 0.78 : 0.86),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get statGradient => LinearGradient(
    colors: [_scheme.surfaceContainerHighest, _scheme.surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> get categoryColors => [
    _scheme.surfaceContainerHighest,
    _scheme.surfaceContainerHigh,
    primaryLight,
    _scheme.secondaryContainer,
  ];

  static List<Color> get categoryIconColors => [
    primary,
    _scheme.secondary,
    _scheme.onSurfaceVariant,
    _scheme.tertiary,
  ];
}
