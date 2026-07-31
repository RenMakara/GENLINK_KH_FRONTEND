import 'package:flutter/material.dart';

/// Color token folder.
///
/// The single source of truth for colour in the app. Semantic light/dark
/// tokens drive the themes; feature accents decorate states and highlights,
/// not page backgrounds.
abstract final class AppColors {
  // =========================================================
  // LIGHT THEME
  // =========================================================

  // Background
  static const lightBgPrimary = Color(0xFFF7F7F5);
  static const lightBgSecondary = Color(0xFFEFEFEB);

  // Surface
  static const lightSurfacePrimary = Color(0xFFFFFFFF);
  static const lightSurfaceSecondary = Color(0xFFF2F2EF);
  static const lightSurfaceGlass = Color.fromRGBO(255, 255, 255, 0.72);

  // Text
  static const lightTextPrimary = Color(0xFF111111);
  static const lightTextSecondary = Color(0xFF6B6B63);
  static const lightTextMuted = Color(0xFF9A9A92);
  static const lightTextInverse = Color(0xFFFFFFFF);

  // Border
  static const lightBorderSubtle = Color.fromRGBO(17, 17, 17, 0.08);
  static const lightBorderStrong = Color.fromRGBO(17, 17, 17, 0.16);

  // Brand
  static const lightPrimary = Color(0xFF111111);
  static const lightPrimarySoft = Color(0xFFE8E8E3);

  // =========================================================
  // DARK THEME
  // =========================================================

  // Background
  static const darkBgPrimary = Color(0xFF080808);
  static const darkBgSecondary = Color(0xFF0E0E0E);

  // Surface
  static const darkSurfacePrimary = Color(0xFF111111);
  static const darkSurfaceSecondary = Color(0xFF1A1A1A);
  static const darkSurfaceGlass = Color.fromRGBO(17, 17, 17, 0.68);

  // Text
  static const darkTextPrimary = Color(0xFFF5F5F0);
  static const darkTextSecondary = Color(0xFFA6A6A0);
  static const darkTextMuted = Color(0xFF6F6F69);
  static const darkTextInverse = Color(0xFF111111);

  // Border
  static const darkBorderSubtle = Color.fromRGBO(255, 255, 255, 0.10);
  static const darkBorderStrong = Color.fromRGBO(255, 255, 255, 0.18);

  // Brand
  static const darkPrimary = Color(0xFFFFFFFF);
  static const darkPrimarySoft = Color(0xFF262626);

  // =========================================================
  // Shared
  // =========================================================

  static const accentPremium = Color(0xFFC8BFAE);

  /// Status colours, shared by both themes.
  static const danger = Color(0xFFEF6A6A);
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFF5B84B);
  static const info = Color(0xFF5DADEC);


  // Feature accents — highlights and badges only, never page backgrounds.
  static const brandPrimary = Color(0xFF1F6FEB);
  static const communityAccent = Color(0xFF5DADEC);
  static const productivityAccent = Color(0xFF8B7CF6);
  static const financeAccent = Color(0xFF4BAE73);
  static const growthAccent = Color(0xFFF2B84B);
  static const profileAccent = Color(0xFFC8BFAE);
}
