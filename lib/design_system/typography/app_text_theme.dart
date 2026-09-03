import 'package:flutter/material.dart';

import 'app_typography.dart';

abstract final class AppTextTheme {
  static TextTheme english = _build(AppTypography.englishFontFamily, isKhmer: false);
  static TextTheme khmer = _build(AppTypography.khmerFontFamily, isKhmer: true);

  /// Resolve the text theme for a locale code (`en` / `km`).
  static TextTheme forLanguageCode(String code) =>
      code == 'km' ? khmer : english;

  static TextTheme _build(String family, {required bool isKhmer}) {
    // Khmer characters are visually heavier and smaller than Latin ones.
    // We increase size, increase line height, and reduce weight for Khmer.
    double size(double s) => isKhmer ? s + 2.0 : s;
    double height(double h) => isKhmer ? h + 0.15 : h;
    
    FontWeight weight(FontWeight w) {
      if (!isKhmer) return w;
      if (w == FontWeight.w700) return FontWeight.w600;
      if (w == FontWeight.w600) return FontWeight.w500;
      if (w == FontWeight.w500) return FontWeight.w400;
      return w;
    }

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: family,
        fontSize: size(40),
        height: height(1.15),
        fontWeight: weight(FontWeight.w700),
        letterSpacing: isKhmer ? 0 : -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: family,
        fontSize: size(32),
        height: height(1.2),
        fontWeight: weight(FontWeight.w700),
        letterSpacing: isKhmer ? 0 : -0.4,
      ),
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: size(24),
        height: height(1.2),
        fontWeight: weight(FontWeight.w700),
      ),
      headlineLarge: TextStyle(
        fontFamily: family,
        fontSize: size(28),
        height: height(1.25),
        fontWeight: weight(FontWeight.w600),
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: size(24),
        height: height(1.3),
        fontWeight: weight(FontWeight.w600),
      ),
      headlineSmall: TextStyle(
        fontFamily: family,
        fontSize: size(20),
        height: height(1.3),
        fontWeight: weight(FontWeight.w600),
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: size(20),
        height: height(1.3),
        fontWeight: weight(FontWeight.w600),
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: size(16),
        height: height(1.4),
        fontWeight: weight(FontWeight.w600),
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: size(14),
        height: height(1.4),
        fontWeight: weight(FontWeight.w600),
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: size(16),
        height: height(1.5),
        fontWeight: weight(FontWeight.w400),
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: size(14),
        height: height(1.5),
        fontWeight: weight(FontWeight.w400),
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: size(12),
        height: height(1.45),
        fontWeight: weight(FontWeight.w400),
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: size(15),
        height: height(1.2),
        fontWeight: weight(FontWeight.w600),
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: size(13),
        height: height(1.2),
        fontWeight: weight(FontWeight.w500),
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: size(11),
        height: height(1.2),
        fontWeight: weight(FontWeight.w500),
        letterSpacing: isKhmer ? 0 : 0.3,
      ),
    );
  }
}
