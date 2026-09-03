import 'package:flutter/material.dart';

abstract final class QuizColors {
  static const background = Color(0xFFF5F3FF);
  static const backgroundAlt = Color(0xFFF4F0FF);

  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFFF3E8FF);
  static const primaryGradientStart = Color(0xFF8B5CF6);
  static const primaryGradientEnd = Color(0xFF6D28D9);

  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);

  static const correct = Color(0xFF10B981);
  static const incorrect = Color(0xFFEF4444);
  static const gold = Color(0xFFFFC107);

  static const heading = Color(0xFF1E1B4B);
  static const body = Color(0xFF6B7280);
  static const white = Color(0xFFFFFFFF);

  static const darkOverlay = Color(0xFF1E1B4B);

  static const cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const gradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const statGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF374151)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const categoryColors = [
    Color(0xFFDBEAFE),
    Color(0xFFFEF3C7),
    Color(0xFFF3E8FF),
    Color(0xFFFCE7F3),
  ];

  static const categoryIconColors = [
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
}
