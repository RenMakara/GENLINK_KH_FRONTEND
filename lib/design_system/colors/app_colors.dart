import 'package:flutter/material.dart';

/// Color token folder.
///
/// The single source of truth for colour in the app.
/// Strict monochrome visual identity with limited semantic accent colors.
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
  static const lightTextSecondary = Color(0xFF666666);
  static const lightTextMuted = Color(0xFF9A9A92);
  static const lightTextInverse = Color(0xFFFFFFFF);

  // Border
  static const lightBorderSubtle = Color.fromRGBO(17, 17, 17, 0.08);
  static const lightBorderStrong = Color.fromRGBO(17, 17, 17, 0.16);

  // Brand
  static const lightPrimary = Color(0xFF111111);
  static const lightPrimarySoft = Color(0xFFE8E8E3);

  // =========================================================
  // DARK THEME (PRIMARY GENLINK KH PALETTE)
  // =========================================================

  // Background
  static const darkBgPrimary = Color(0xFF131313); // #000000
  static const darkBgSecondary = Color(0xFF111111); // #111111

  // Surface
  static const darkSurfacePrimary = Color(0xFF181818); // #181818
  static const darkSurfaceSecondary = Color(0xFF111111); // #111111
  static const darkSurfaceGlass = Color.fromRGBO(24, 24, 24, 0.75);

  // Text
  static const darkTextPrimary = Color(0xFFFFFFFF); // #FFFFFF
  static const darkTextSecondary = Color(0xFFA0A0A0); // #A0A0A0
  static const darkTextMuted = Color(0xFF666666); // #666666
  static const darkTextInverse = Color(0xFF000000);

  // Border
  static const darkBorderSubtle = Color(0xFF303030); // #303030
  static const darkBorderStrong = Color(0xFF444444);

  // Brand
  static const darkPrimary = Color(0xFFFFFFFF);
  static const darkPrimarySoft = Color(0xFF242424);

  // =========================================================
  // Shared & Semantic Accent Colors
  // =========================================================

  static const accentPremium = Color(0xFFC8BFAE);

  /// Social Liked state accent (#FF4D6D) - ONLY for active like/reaction
  static const likedAccent = Color(0xFFFF1640);
  static const likePink = Color(0xFFFF1640);

  /// Status colours (used strictly for meaningful semantic states)
  static const danger = Color(
    0xFFE41414,
  ); // Red: Validation errors / Failed / Destructive
  static const success = Color(
    0xFF22C55E,
  ); // Green: Successful creation / RSVP / Save / Confirm
  static const warning = Color(0xFFF59E0B); // Amber: Genuine warnings
  static const info = Color(0xFFA0A0A0); // Grayscale / Neutral

  // Feature accents
  static const brandPrimary = Color(0xFF1F6FEB);
  static const communityAccent = Color(0xFF5DADEC);
  static const productivityAccent = Color(0xFF8B7CF6);
  static const financeAccent = Color(0xFF4BAE73);
  static const growthAccent = Color(0xFFF2B84B);
  static const profileAccent = Color(0xFFC8BFAE);
}
