import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Text theme folder.
///
/// Build Material text themes here so features consume typography through
/// `Theme.of(context).textTheme`.
///
/// The font families are referenced by name. Until the `.ttf` files are
/// added under `assets/fonts/` and declared in `pubspec.yaml`, Flutter
/// falls back to the platform default — no error, just the system face.
abstract final class AppTextTheme {
  static TextTheme english = _build(AppTypography.englishFontFamily);
  static TextTheme khmer = _build(AppTypography.khmerFontFamily);

  /// Resolve the text theme for a locale code (`en` / `km`).
  static TextTheme forLanguageCode(String code) =>
      code == 'km' ? khmer : english;

  static TextTheme _build(String family) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: family,
        fontSize: 40,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: family,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineLarge: TextStyle(
        fontFamily: family,
        fontSize: 28,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}
