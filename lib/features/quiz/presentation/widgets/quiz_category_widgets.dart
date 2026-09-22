import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/models/quiz_models.dart';

// ============================================================================
// 1. SOFT 3D VECTOR ILLUSTRATIONS (HEADER & ICONS)
// ============================================================================

/// Helper for drawing smooth 4-pointed golden sparkle stars.
void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy - size)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx + size, center.dy)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx, center.dy + size)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx - size, center.dy)
    ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx, center.dy - size)
    ..close();

  final paint = Paint()
    ..shader = RadialGradient(
      colors: [Colors.white, color],
      stops: const [0.2, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size));
  canvas.drawPath(path, paint);
}

/// Header 3D Illustration: Stacked books + Graduation Cap + Golden Sparkles.
class GraduationBooksIllustration extends StatelessWidget {
  const GraduationBooksIllustration({super.key, this.width = 76, this.height = 62});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GraduationBooksPainter(),
      ),
    );
  }
}

class _GraduationBooksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden Sparkles floating around
    _drawSparkle(canvas, Offset(w * 0.12, h * 0.28), w * 0.07, const Color(0xFFFBBF24));
    _drawSparkle(canvas, Offset(w * 0.90, h * 0.22), w * 0.09, const Color(0xFFF59E0B));
    _drawSparkle(canvas, Offset(w * 0.94, h * 0.62), w * 0.06, const Color(0xFFFBBF24));

    // Bottom Book: Deep Purple
    final bottomBookRect = Rect.fromCenter(
      center: Offset(w * 0.54, h * 0.74),
      width: w * 0.64,
      height: h * 0.26,
    );
    final bottomBookRRect = RRect.fromRectAndRadius(bottomBookRect, Radius.circular(w * 0.05));
    // Soft shadow
    canvas.drawRRect(
      bottomBookRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF6B21A8).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Cover
    canvas.drawRRect(
      bottomBookRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ).createShader(bottomBookRect),
    );
    // Page block
    final bPagesRect = Rect.fromLTWH(
      bottomBookRect.left + w * 0.05,
      bottomBookRect.top + h * 0.04,
      bottomBookRect.width - w * 0.06,
      bottomBookRect.height - h * 0.08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bPagesRect, Radius.circular(w * 0.03)),
      Paint()..color = const Color(0xFFEDE9FE),
    );

    // Top Book: Sky / Royal Blue
    final topBookRect = Rect.fromCenter(
      center: Offset(w * 0.52, h * 0.53),
      width: w * 0.58,
      height: h * 0.24,
    );
    final topBookRRect = RRect.fromRectAndRadius(topBookRect, Radius.circular(w * 0.05));
    // Soft shadow
    canvas.drawRRect(
      topBookRRect.shift(const Offset(0, 2.5)),
      Paint()
        ..color = const Color(0xFF1D4ED8).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Cover
    canvas.drawRRect(
      topBookRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        ).createShader(topBookRect),
    );
    // Page block
    final tPagesRect = Rect.fromLTWH(
      topBookRect.left + w * 0.05,
      topBookRect.top + h * 0.04,
      topBookRect.width - w * 0.06,
      topBookRect.height - h * 0.08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tPagesRect, Radius.circular(w * 0.03)),
      Paint()..color = const Color(0xFFDBEAFE),
    );

    // Graduation Cap / Mortarboard
    final capCenterX = w * 0.52;
    final capCenterY = h * 0.28;

    // Skullcap base
    final skullcapPath = Path()
      ..moveTo(capCenterX - w * 0.16, capCenterY + h * 0.06)
      ..cubicTo(
        capCenterX - w * 0.16,
        capCenterY + h * 0.18,
        capCenterX + w * 0.16,
        capCenterY + h * 0.18,
        capCenterX + w * 0.16,
        capCenterY + h * 0.06,
      )
      ..close();
    canvas.drawPath(
      skullcapPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF27272A), Color(0xFF09090B)],
        ).createShader(Rect.fromLTWH(capCenterX - w * 0.2, capCenterY, w * 0.4, h * 0.2)),
    );

    // Diamond Mortarboard Top
    final diamondPath = Path()
      ..moveTo(capCenterX, capCenterY - h * 0.14) // Top
      ..lineTo(capCenterX + w * 0.28, capCenterY) // Right
      ..lineTo(capCenterX, capCenterY + h * 0.07) // Bottom
      ..lineTo(capCenterX - w * 0.28, capCenterY) // Left
      ..close();

    // Cap drop shadow
    canvas.drawPath(
      diamondPath.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Cap surface
    canvas.drawPath(
      diamondPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F3F46), Color(0xFF18181B)],
        ).createShader(diamondPath.getBounds()),
    );

    // Top Button
    canvas.drawCircle(
      Offset(capCenterX, capCenterY - h * 0.03),
      w * 0.03,
      Paint()..color = const Color(0xFFFBBF24),
    );

    // Golden Tassel (curves down right side)
    final tasselPath = Path()
      ..moveTo(capCenterX, capCenterY - h * 0.03)
      ..quadraticBezierTo(
        capCenterX + w * 0.18,
        capCenterY - h * 0.02,
        capCenterX + w * 0.24,
        capCenterY + h * 0.16,
      );
    canvas.drawPath(
      tasselPath,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Tassel pompom
    canvas.drawCircle(
      Offset(capCenterX + w * 0.24, capCenterY + h * 0.16),
      w * 0.032,
      Paint()..color = const Color(0xFFFBBF24),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. CATEGORY 3D ICONS COMPONENT
// ============================================================================

/// Renders a dedicated Soft 3D vector illustration for each quiz category.
class CategorySoft3DIcon extends StatelessWidget {
  const CategorySoft3DIcon({
    super.key,
    required this.categoryType,
    this.size = 44,
  });

  final String categoryType;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CategoryIconPainter(categoryType: categoryType),
      ),
    );
  }
}

class _CategoryIconPainter extends CustomPainter {
  _CategoryIconPainter({required this.categoryType});

  final String categoryType;

  @override
  void paint(Canvas canvas, Size size) {
    switch (categoryType) {
      case 'general':
        _paintBook(canvas, size);
        break;
      case 'business':
        _paintBriefcase(canvas, size);
        break;
      case 'food':
        _paintBurger(canvas, size);
        break;
      case 'culture':
        _paintTheaterMasks(canvas, size);
        break;
      case 'science':
        _paintMicroscope(canvas, size);
        break;
      case 'history':
        _paintTemple(canvas, size);
        break;
      case 'geography':
        _paintGlobe(canvas, size);
        break;
      case 'technology':
        _paintLaptop(canvas, size);
        break;
      case 'sports':
        _paintBasketball(canvas, size);
        break;
      case 'entertainment':
        _paintGameController(canvas, size, const Color(0xFF8B5CF6));
        break;
      case 'games':
        _paintRetroGamepad(canvas, size);
        break;
      case 'movies':
        _paintClapperboard(canvas, size);
        break;
      case 'music':
        _paintMusicNote(canvas, size);
        break;
      case 'health':
        _paintHeartPulse(canvas, size);
        break;
      case 'finance':
        _paintWallet(canvas, size);
        break;
      default:
        _paintDefaultIcon(canvas, size);
        break;
    }
  }

  // 1. General (Open Book)
  void _paintBook(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    // Book Cover drop shadow
    final coverRect = Rect.fromCenter(center: center.translate(0, 2), width: w * 0.82, height: h * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(coverRect, Radius.circular(w * 0.12)),
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Open Book Left & Right Pages
    final leftPage = Path()
      ..moveTo(w * 0.5, h * 0.28)
      ..cubicTo(w * 0.35, h * 0.20, w * 0.15, h * 0.24, w * 0.12, h * 0.32)
      ..lineTo(w * 0.12, h * 0.74)
      ..cubicTo(w * 0.22, h * 0.68, w * 0.38, h * 0.70, w * 0.5, h * 0.78)
      ..close();

    final rightPage = Path()
      ..moveTo(w * 0.5, h * 0.28)
      ..cubicTo(w * 0.65, h * 0.20, w * 0.85, h * 0.24, w * 0.88, h * 0.32)
      ..lineTo(w * 0.88, h * 0.74)
      ..cubicTo(w * 0.78, h * 0.68, w * 0.62, h * 0.70, w * 0.5, h * 0.78)
      ..close();

    // Purple Covers underneath
    canvas.drawPath(
      leftPage.shift(const Offset(-2, 2)),
      Paint()..color = const Color(0xFF6D28D9),
    );
    canvas.drawPath(
      rightPage.shift(const Offset(2, 2)),
      Paint()..color = const Color(0xFF5B21B6),
    );

    // Pages Surface
    canvas.drawPath(
      leftPage,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFFFFFFF)],
        ).createShader(coverRect),
    );
    canvas.drawPath(
      rightPage,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFDDD6FE)],
        ).createShader(coverRect),
    );

    // Spine Divider
    canvas.drawLine(
      Offset(w * 0.5, h * 0.26),
      Offset(w * 0.5, h * 0.80),
      Paint()
        ..color = const Color(0xFF8B5CF6)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  // 2. Business (Briefcase)
  void _paintBriefcase(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Handle
    final handleRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.22), width: w * 0.28, height: h * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, Radius.circular(w * 0.08)),
      Paint()
        ..color = const Color(0xFF1D4ED8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Briefcase Body
    final boxRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.58), width: w * 0.78, height: h * 0.54);
    final boxRRect = RRect.fromRectAndRadius(boxRect, Radius.circular(w * 0.14));

    canvas.drawRRect(
      boxRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF1D4ED8).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawRRect(
      boxRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1E40AF)],
        ).createShader(boxRect),
    );

    // Center Gold Latch
    final latchRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.50), width: w * 0.16, height: h * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(latchRect, Radius.circular(w * 0.03)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
        ).createShader(latchRect),
    );
  }

  // 3. Food (Burger)
  void _paintBurger(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top Bun (Golden rounded dome)
    final topBunPath = Path()
      ..moveTo(w * 0.14, h * 0.44)
      ..cubicTo(w * 0.14, h * 0.18, w * 0.86, h * 0.18, w * 0.86, h * 0.44)
      ..close();
    canvas.drawPath(
      topBunPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Sesame Seeds
    final dotPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawCircle(Offset(w * 0.38, h * 0.28), w * 0.024, dotPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.24), w * 0.024, dotPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.30), w * 0.024, dotPaint);

    // Lettuce Wave (Green)
    final lettuceRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.48), width: w * 0.82, height: h * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lettuceRect, Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFF22C55E),
    );

    // Tomato & Cheese Slice (Red + Yellow)
    final tomatoRect = Rect.fromCenter(center: Offset(w * 0.44, h * 0.56), width: w * 0.70, height: h * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tomatoRect, Radius.circular(w * 0.03)),
      Paint()..color = const Color(0xFFEF4444),
    );

    // Cheese Triangle
    final cheesePath = Path()
      ..moveTo(w * 0.48, h * 0.54)
      ..lineTo(w * 0.74, h * 0.54)
      ..lineTo(w * 0.60, h * 0.66)
      ..close();
    canvas.drawPath(cheesePath, Paint()..color = const Color(0xFFFBBF24));

    // Patty (Brown)
    final pattyRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.76, height: h * 0.10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pattyRect, Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFF78350F),
    );

    // Bottom Bun
    final bottomBunRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.75), width: w * 0.74, height: h * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottomBunRect, Radius.circular(w * 0.06)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
        ).createShader(bottomBunRect),
    );
  }

  // 4. Culture (Theater Masks)
  void _paintTheaterMasks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Comedy Mask (Pink)
    final comedyCenter = Offset(w * 0.38, h * 0.50);
    final comedyRect = Rect.fromCenter(center: comedyCenter, width: w * 0.48, height: h * 0.58);
    canvas.drawRRect(
      RRect.fromRectAndRadius(comedyRect, Radius.circular(w * 0.18)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF472B6), Color(0xFFDB2777)],
        ).createShader(comedyRect),
    );
    // Eyes & Smile
    final darkPaint = Paint()..color = const Color(0xFF831843);
    canvas.drawCircle(comedyCenter.translate(-w * 0.10, -h * 0.08), w * 0.035, darkPaint);
    canvas.drawCircle(comedyCenter.translate(w * 0.10, -h * 0.08), w * 0.035, darkPaint);
    canvas.drawArc(
      Rect.fromCenter(center: comedyCenter.translate(0, h * 0.06), width: w * 0.20, height: h * 0.16),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF831843)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Tragedy Mask (Magenta, partially behind right)
    final tragCenter = Offset(w * 0.68, h * 0.56);
    final tragRect = Rect.fromCenter(center: tragCenter, width: w * 0.42, height: h * 0.52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tragRect, Radius.circular(w * 0.16)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF9D174D)],
        ).createShader(tragRect),
    );
    canvas.drawCircle(tragCenter.translate(-w * 0.08, -h * 0.06), w * 0.03, darkPaint);
    canvas.drawCircle(tragCenter.translate(w * 0.08, -h * 0.06), w * 0.03, darkPaint);
    canvas.drawArc(
      Rect.fromCenter(center: tragCenter.translate(0, h * 0.10), width: w * 0.18, height: h * 0.14),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF500724)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  // 5. Science (Microscope)
  void _paintMicroscope(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Eyepiece Tube
    final tubePath = Path()
      ..moveTo(w * 0.38, h * 0.16)
      ..lineTo(w * 0.62, h * 0.40)
      ..lineTo(w * 0.54, h * 0.48)
      ..lineTo(w * 0.30, h * 0.24)
      ..close();
    canvas.drawPath(
      tubePath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Curved Arm
    final armPath = Path()
      ..moveTo(w * 0.58, h * 0.38)
      ..cubicTo(w * 0.84, h * 0.45, w * 0.82, h * 0.72, w * 0.56, h * 0.75)
      ..lineTo(w * 0.56, h * 0.65)
      ..cubicTo(w * 0.72, h * 0.63, w * 0.72, h * 0.48, w * 0.54, h * 0.42)
      ..close();
    canvas.drawPath(
      armPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Stage
    final stageRect = Rect.fromCenter(center: Offset(w * 0.42, h * 0.62), width: w * 0.38, height: h * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stageRect, Radius.circular(w * 0.03)),
      Paint()..color = const Color(0xFF065F46),
    );

    // Base
    final baseRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.82), width: w * 0.68, height: h * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(w * 0.06)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ).createShader(baseRect),
    );
  }

  // 6. History (Temple)
  void _paintTemple(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Roof Triangle Pediment
    final roofPath = Path()
      ..moveTo(w * 0.5, h * 0.20)
      ..lineTo(w * 0.85, h * 0.40)
      ..lineTo(w * 0.15, h * 0.40)
      ..close();
    canvas.drawPath(
      roofPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
        ).createShader(roofPath.getBounds()),
    );

    // Architrave Bar
    final archRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.43), width: w * 0.76, height: h * 0.06);
    canvas.drawRRect(RRect.fromRectAndRadius(archRect, Radius.circular(w * 0.02)), Paint()..color = const Color(0xFF6D28D9));

    // 3 Columns
    final colPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDDD6FE), Color(0xFF8B5CF6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    for (final cx in [w * 0.28, w * 0.50, w * 0.72]) {
      final colRect = Rect.fromCenter(center: Offset(cx, h * 0.60), width: w * 0.12, height: h * 0.28);
      canvas.drawRRect(RRect.fromRectAndRadius(colRect, Radius.circular(w * 0.03)), colPaint);
    }

    // Tiered Base
    final b1 = Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: w * 0.76, height: h * 0.06);
    final b2 = Rect.fromCenter(center: Offset(w * 0.5, h * 0.84), width: w * 0.84, height: h * 0.06);
    canvas.drawRRect(RRect.fromRectAndRadius(b1, Radius.circular(w * 0.02)), Paint()..color = const Color(0xFF6D28D9));
    canvas.drawRRect(RRect.fromRectAndRadius(b2, Radius.circular(w * 0.03)), Paint()..color = const Color(0xFF5B21B6));
  }

  // 7. Geography (Globe)
  void _paintGlobe(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.46);
    final r = w * 0.32;

    // Stand & Meridian Ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 1.18),
      -math.pi * 0.3,
      math.pi * 1.2,
      false,
      Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Stand Base
    final baseRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.84), width: w * 0.44, height: h * 0.10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(w * 0.05)),
      Paint()..color = const Color(0xFF0369A1),
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.74),
      Offset(w * 0.5, h * 0.84),
      Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 3.5,
    );

    // Sphere (Ocean Blue)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Continents (Green)
    final contPaint = Paint()..color = const Color(0xFF22C55E);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - r * 0.7, center.dy - r * 0.6, r * 0.8, r * 0.6), Radius.circular(r * 0.3)), contPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - r * 0.4, center.dy + r * 0.1, r * 0.7, r * 0.7), Radius.circular(r * 0.3)), contPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx + r * 0.2, center.dy - r * 0.4, r * 0.6, r * 0.8), Radius.circular(r * 0.3)), contPaint);
    canvas.restore();
  }

  // 8. Technology (Laptop)
  void _paintLaptop(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Screen Bezel
    final screenRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.40), width: w * 0.68, height: h * 0.46);
    final screenRRect = RRect.fromRectAndRadius(screenRect, Radius.circular(w * 0.08));
    canvas.drawRRect(
      screenRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ).createShader(screenRect),
    );

    // Screen Inner Glow
    final innerRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.39), width: w * 0.54, height: h * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.05)),
      Paint()..color = const Color(0xFFBFDBFE),
    );

    // Laptop Base
    final baseRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.84, height: h * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(w * 0.06)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
        ).createShader(baseRect),
    );
  }

  // 9. Sports (Basketball)
  void _paintBasketball(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final r = w * 0.36;

    // Ball Sphere (Orange Gradient)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [Color(0xFFFDBA74), Color(0xFFEA580C)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Black Seams
    final seamPaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), seamPaint);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), seamPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(center.dx - r * 0.8, center.dy), radius: r * 0.85), -math.pi * 0.45, math.pi * 0.9, false, seamPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(center.dx + r * 0.8, center.dy), radius: r * 0.85), math.pi * 0.55, math.pi * 0.9, false, seamPaint);
  }

  // 10. Entertainment / Games Controller
  void _paintGameController(Canvas canvas, Size size, Color accent) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);

    final bodyRect = Rect.fromCenter(center: center, width: w * 0.78, height: h * 0.52);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.22));

    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = accent.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = LinearGradient(
          colors: [accent.withValues(alpha: 0.9), accent],
        ).createShader(bodyRect),
    );

    // D-pad Cross
    final dpadCenter = Offset(center.dx - w * 0.20, center.dy);
    final crossPaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: dpadCenter, width: w * 0.16, height: h * 0.06), Radius.circular(w * 0.02)), crossPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: dpadCenter, width: w * 0.06, height: h * 0.16), Radius.circular(w * 0.02)), crossPaint);

    // Action Buttons
    final btnCenter = Offset(center.dx + w * 0.20, center.dy);
    canvas.drawCircle(btnCenter.translate(0, -h * 0.07), w * 0.035, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawCircle(btnCenter.translate(-w * 0.07, 0), w * 0.035, Paint()..color = const Color(0xFF60A5FA));
    canvas.drawCircle(btnCenter.translate(w * 0.07, 0), w * 0.035, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(btnCenter.translate(0, h * 0.07), w * 0.035, Paint()..color = const Color(0xFF22C55E));
  }

  // 11. Games (Retro Gamepad)
  void _paintRetroGamepad(Canvas canvas, Size size) {
    _paintGameController(canvas, size, const Color(0xFFF43F5E));
  }

  // 12. Movies (Clapperboard)
  void _paintClapperboard(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body
    final bodyRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.60), width: w * 0.74, height: h * 0.44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.08)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF6B21A8)],
        ).createShader(bodyRect),
    );

    // Film Star on body
    _drawSparkle(canvas, Offset(w * 0.5, h * 0.60), w * 0.08, const Color(0xFFFDE047));

    // Angled Clapstick Top
    final stickRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.32), width: w * 0.74, height: h * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stickRect, Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFF581C87),
    );

    // Diagonal White Stripes
    final stripePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0;
    for (final sx in [w * 0.28, w * 0.44, w * 0.60, w * 0.76]) {
      canvas.drawLine(Offset(sx - w * 0.06, h * 0.38), Offset(sx, h * 0.26), stripePaint);
    }
  }

  // 13. Music (Note)
  void _paintMusicNote(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final notePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Double Eighth Note
    final leftHead = Offset(w * 0.34, h * 0.70);
    final rightHead = Offset(w * 0.66, h * 0.60);

    canvas.drawOval(Rect.fromCenter(center: leftHead, width: w * 0.24, height: h * 0.18), notePaint);
    canvas.drawOval(Rect.fromCenter(center: rightHead, width: w * 0.24, height: h * 0.18), notePaint);

    final stemPaint = Paint()
      ..color = const Color(0xFFB45309)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(leftHead.translate(w * 0.08, 0), Offset(w * 0.42, h * 0.26), stemPaint);
    canvas.drawLine(rightHead.translate(w * 0.08, 0), Offset(w * 0.74, h * 0.18), stemPaint);

    // Crossbar Beam
    final beamPath = Path()
      ..moveTo(w * 0.42, h * 0.26)
      ..lineTo(w * 0.74, h * 0.18)
      ..lineTo(w * 0.74, h * 0.28)
      ..lineTo(w * 0.42, h * 0.36)
      ..close();
    canvas.drawPath(beamPath, notePaint);
  }

  // 14. Health (Heart with Pulse)
  void _paintHeartPulse(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.48);

    // 3D Heart Shape
    final heartPath = Path()
      ..moveTo(center.dx, center.dy + h * 0.32)
      ..cubicTo(center.dx - w * 0.44, center.dy + h * 0.10, center.dx - w * 0.44, center.dy - h * 0.26, center.dx, center.dy - h * 0.10)
      ..cubicTo(center.dx + w * 0.44, center.dy - h * 0.26, center.dx + w * 0.44, center.dy + h * 0.10, center.dx, center.dy + h * 0.32)
      ..close();

    canvas.drawPath(
      heartPath.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF15803D).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawPath(
      heartPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
        ).createShader(heartPath.getBounds()),
    );

    // White ECG Pulse Line
    final pulsePath = Path()
      ..moveTo(center.dx - w * 0.30, center.dy)
      ..lineTo(center.dx - w * 0.10, center.dy)
      ..lineTo(center.dx - w * 0.04, center.dy - h * 0.16)
      ..lineTo(center.dx + w * 0.04, center.dy + h * 0.16)
      ..lineTo(center.dx + w * 0.10, center.dy)
      ..lineTo(center.dx + w * 0.30, center.dy);

    canvas.drawPath(
      pulsePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // 15. Finance (Wallet)
  void _paintWallet(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Credit Card peeking out
    final cardRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.36), width: w * 0.62, height: h * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFFFBBF24),
    );

    // Leather Wallet Body
    final walletRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.58), width: w * 0.78, height: h * 0.50);
    final walletRRect = RRect.fromRectAndRadius(walletRect, Radius.circular(w * 0.14));

    canvas.drawRRect(
      walletRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF047857).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawRRect(
      walletRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34D399), Color(0xFF059669)],
        ).createShader(walletRect),
    );

    // Flap & Gold Snap
    final flapRect = Rect.fromCenter(center: Offset(w * 0.74, h * 0.58), width: w * 0.26, height: h * 0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(flapRect, Radius.circular(w * 0.06)),
      Paint()..color = const Color(0xFF065F46),
    );
    canvas.drawCircle(Offset(w * 0.74, h * 0.58), w * 0.045, Paint()..color = const Color(0xFFFBBF24));
  }

  // Default Star Fallback
  void _paintDefaultIcon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final boxRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.78, height: h * 0.78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, Radius.circular(w * 0.18)),
      Paint()..color = const Color(0xFF8B5CF6),
    );
    _drawSparkle(canvas, Offset(w * 0.5, h * 0.5), w * 0.22, Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 3. BACKGROUND WATERMARK PAINTER
// ============================================================================

class _CategoryWatermarkPainter extends CustomPainter {
  const _CategoryWatermarkPainter({
    required this.categoryType,
    required this.accentColor,
  });

  final String categoryType;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    switch (categoryType) {
      case 'general':
      case 'geography':
        // Soft mountain peaks / wave
        final path = Path()
          ..moveTo(w * 0.55, h)
          ..quadraticBezierTo(w * 0.70, h * 0.65, w * 0.85, h)
          ..quadraticBezierTo(w * 0.92, h * 0.80, w, h)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'business':
      case 'finance':
        // Vertical growth chart bars
        for (int i = 0; i < 3; i++) {
          final barH = h * (0.24 + i * 0.14);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.74 + i * (w * 0.08), h - barH, w * 0.06, barH),
              Radius.circular(w * 0.02),
            ),
            paint,
          );
        }
        break;
      case 'food':
        // Fork & Spoon silhouette
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.78, h * 0.50, w * 0.04, h * 0.40), Radius.circular(2)),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.86, h * 0.50, w * 0.04, h * 0.40), Radius.circular(2)),
          paint,
        );
        break;
      case 'sports':
        // Trophy silhouette
        canvas.drawCircle(Offset(w * 0.84, h * 0.75), w * 0.12, paint);
        break;
      case 'entertainment':
        // Star silhouette
        canvas.drawCircle(Offset(w * 0.84, h * 0.75), w * 0.12, paint);
        break;
      case 'health':
        // Sprout leaves
        canvas.drawOval(
          Rect.fromCenter(center: Offset(w * 0.84, h * 0.75), width: w * 0.18, height: h * 0.28),
          paint,
        );
        break;
      default:
        // Soft circle bubble
        canvas.drawCircle(Offset(w * 0.84, h * 0.76), w * 0.12, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 4. METADATA RESOLVERS
// ============================================================================

String _resolveCategoryType(QuizCategory cat) {
  final id = cat.id.toUpperCase();
  final name = cat.name.toUpperCase();

  if (id.contains('FINANCE') || name.contains('FINANCE') || name.contains('ហិរញ្ញ')) return 'finance';
  if (id.contains('FOOD') || name.contains('FOOD') || name.contains('ម្ហូប') || name.contains('អាហារ')) return 'food';
  if (id.contains('BUSINESS') || name.contains('BUSINESS') || name.contains('អាជីវកម្ម')) return 'business';
  if (id.contains('CULTURE') || name.contains('CULTURE') || name.contains('វប្បធម៌')) return 'culture';
  if (id.contains('SCIENCE') || name.contains('SCIENCE') || name.contains('វិទ្យាសាស្ត្រ')) return 'science';
  if (id.contains('HIST') || name.contains('HIST') || name.contains('ប្រវត្តិ')) return 'history';
  if (id.contains('GEO') || name.contains('GEO') || name.contains('ភូមិ')) return 'geography';
  if (id.contains('TECH') || name.contains('TECH') || name.contains('បច្ចេកវិទ្យា')) return 'technology';
  if (id.contains('SPORT') || name.contains('SPORT') || name.contains('កីឡា')) return 'sports';
  if (id.contains('ENTERTAINMENT') || name.contains('ENTERTAINMENT') || name.contains('កម្សាន្ត')) return 'entertainment';
  if (id.contains('GAME') || name.contains('GAME') || name.contains('ហ្គេម')) return 'games';
  if (id.contains('MOVIE') || name.contains('MOVIE') || name.contains('ភាពយន្ត')) return 'movies';
  if (id.contains('MUSIC') || name.contains('MUSIC') || name.contains('តន្ត្រី')) return 'music';
  if (id.contains('HEALTH') || name.contains('HEALTH') || name.contains('សុខភាព')) return 'health';
  if (id.contains('GENERAL') || name.contains('KNOWLEDGE') || name.contains('ទូទៅ')) return 'general';

  return switch (cat.colorIndex % 4) {
    0 => 'general',
    1 => 'technology',
    2 => 'science',
    _ => 'sports',
  };
}

Color _resolveCategoryAccent(String type) {
  return switch (type) {
    'general' => const Color(0xFF8B5CF6), // Productivity Purple
    'business' => const Color(0xFF2563EB), // Brand Blue
    'food' => const Color(0xFFF59E0B), // Growth Amber
    'culture' => const Color(0xFFEC4899), // Pink Rose
    'science' => const Color(0xFF10B981), // Emerald Success
    'history' => const Color(0xFF7C3AED), // Violet
    'geography' => const Color(0xFF0EA5E9), // Sky Blue
    'technology' => const Color(0xFF3B82F6), // Tech Blue
    'sports' => const Color(0xFFF97316), // Orange
    'entertainment' => const Color(0xFF8B5CF6), // Purple
    'games' => const Color(0xFFF43F5E), // Coral Red
    'movies' => const Color(0xFFA855F7), // Violet
    'music' => const Color(0xFFD97706), // Tan/Gold
    'health' => const Color(0xFF22C55E), // Green
    'finance' => const Color(0xFF059669), // Finance Green
    _ => const Color(0xFF8B5CF6),
  };
}

List<Color> _resolveCategoryGradient(String type, bool isDark) {
  if (isDark) {
    final accent = _resolveCategoryAccent(type);
    return [
      accent.withValues(alpha: 0.22),
      accent.withValues(alpha: 0.10),
    ];
  }

  return switch (type) {
    'general' => const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
    'business' => const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
    'food' => const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
    'culture' => const [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
    'science' => const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
    'history' => const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
    'geography' => const [Color(0xFFF0FDF4), Color(0xFFE0F2FE)],
    'technology' => const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
    'sports' => const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
    'entertainment' => const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
    'games' => const [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
    'movies' => const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
    'music' => const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
    'health' => const [Color(0xFFECFDF5), Color(0xFFDCFCE7)],
    'finance' => const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
    _ => const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
  };
}

String _resolveCategoryDescription(String type) {
  return switch (type) {
    'general' => 'quiz.catDescGeneral'.tr,
    'business' => 'quiz.catDescBusiness'.tr,
    'food' => 'quiz.catDescFood'.tr,
    'culture' => 'quiz.catDescCulture'.tr,
    'science' => 'quiz.catDescScience'.tr,
    'history' => 'quiz.catDescHistory'.tr,
    'geography' => 'quiz.catDescGeography'.tr,
    'technology' => 'quiz.catDescTechnology'.tr,
    'sports' => 'quiz.catDescSports'.tr,
    'entertainment' => 'quiz.catDescEntertainment'.tr,
    'games' => 'quiz.catDescGames'.tr,
    'movies' => 'quiz.catDescMovies'.tr,
    'music' => 'quiz.catDescMusic'.tr,
    'health' => 'quiz.catDescHealth'.tr,
    'finance' => 'quiz.catDescFinance'.tr,
    _ => 'quiz.catDescDefault'.tr,
  };
}

// ============================================================================
// 5. REDESIGNED SEARCH BAR
// ============================================================================

class QuizCategorySearchBar extends StatefulWidget {
  const QuizCategorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.onFilterTap,
    this.focusNode,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onFilterTap;
  final FocusNode? focusNode;

  @override
  State<QuizCategorySearchBar> createState() =>
      _QuizCategorySearchBarState();
}

class _QuizCategorySearchBarState extends State<QuizCategorySearchBar> {
  late final FocusNode _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();

    _internalFocusNode = FocusNode();

    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);

    // Only dispose the internally created node.
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFocused = _focusNode.hasFocus;

    final borderColor = isFocused
        ? AppColors.productivityAccent
        : semantic.borderSubtle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 58,
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 1.4 : 1,
        ),
        boxShadow: isDark
            ? const []
            : [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isFocused ? 0.07 : 0.035,
            ),
            blurRadius: isFocused ? 18 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),

          // ------------------------------------------------------------
          // Search icon
          // ------------------------------------------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isFocused
                  ? AppColors.productivityAccent.withValues(alpha: 0.12)
                  : semantic.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: isFocused
                  ? AppColors.productivityAccent
                  : semantic.textMuted,
            ),
          ),

          const SizedBox(width: 10),

          // ------------------------------------------------------------
          // Search input
          // ------------------------------------------------------------
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              maxLines: 1,
              textInputAction: TextInputAction.search,
              cursorColor: semantic.primaryText,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: semantic.primaryText,
                height: 1.2,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 17,
                ),
                hintText: 'quiz.searchCategories'.tr,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: semantic.textMuted,
                  height: 1.2,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ------------------------------------------------------------
          // Clear / Filter button
          // ------------------------------------------------------------
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return _SearchActionButton(
                icon: hasText
                    ? Icons.close_rounded
                    : Icons.tune_rounded,
                onPressed: hasText
                    ? widget.onClear
                    : (widget.onFilterTap ?? () {}),
                semantic: semantic,
                highlighted: hasText,
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  const _SearchActionButton({
    required this.icon,
    required this.onPressed,
    required this.semantic,
    required this.highlighted,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final AppSemanticColors semantic;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 19,
            color: highlighted
                ? semantic.primaryText
                : semantic.secondaryText,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 6. CATEGORY FILTER CHIPS ROW
// ============================================================================

/// Compact filter chips row: [All] [Popular] [New] [Favorites].
class QuizCategoryFilterChips extends StatelessWidget {
  const QuizCategoryFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = [
      (
        id: 'all',
        label: 'quiz.filterAll'.tr,
        icon: Icons.grid_view_rounded,
        iconColor: Colors.black,
      ),
      (
        id: 'popular',
        label: 'quiz.filterPopular'.tr,
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFEF4444),
      ),
      (
        id: 'new',
        label: 'quiz.filterNew'.tr,
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF8B5CF6),
      ),
      (
        id: 'favorites',
        label: 'quiz.filterFavorites'.tr,
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFF43F5E),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: chips.map((chip) {
          final isSelected = selectedFilter == chip.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onFilterSelected(chip.id),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? semantic.surface : Colors.white),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark
                              ? semantic.borderSubtle
                              : semantic.borderSubtle.withValues(alpha: 0.8)),
                      width: 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : (isDark
                            ? const []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chip.icon,
                        size: 15,
                        color: isSelected ? Colors.white : chip.iconColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chip.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : semantic.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// 7. SOFT 3D CATEGORY CARD
// ============================================================================

/// Redesigned Soft 3D Category Card supporting both standard 2-column layout,
/// full-width bottom banner layout (e.g. Finance), and compact fallback for
/// constrained heights (preventing any test regressions).
class QuizCategoryCard extends StatelessWidget {
  const QuizCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.tagline,
    this.isFullWidth = false,
  });

  final QuizCategory category;
  final VoidCallback onTap;
  final String? tagline;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryType = _resolveCategoryType(category);
    final accentColor = _resolveCategoryAccent(categoryType);
    final gradientColors = _resolveCategoryGradient(categoryType, isDark);
    final description = tagline ?? _resolveCategoryDescription(categoryType);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight > 0 && constraints.maxHeight < 110;

        // 1. Compact mode (preserves existing 84px height unit tests)
        if (isCompact) {
          return _buildCompactLayout(
            context: context,
            accentColor: accentColor,
            gradientColors: gradientColors,
            isDark: isDark,
            semantic: semantic,
          );
        }

        // 2. Full-width horizontal banner (e.g. Finance at bottom)
        if (isFullWidth) {
          return _buildFullWidthLayout(
            context: context,
            categoryType: categoryType,
            accentColor: accentColor,
            gradientColors: gradientColors,
            description: description,
            isDark: isDark,
            semantic: semantic,
          );
        }

        // 3. Modern Gamified Soft 3D Vertical Card (2-column grid from reference)
        return _buildSoft3DVerticalCard(
          context: context,
          categoryType: categoryType,
          accentColor: accentColor,
          gradientColors: gradientColors,
          description: description,
          isDark: isDark,
          semantic: semantic,
        );
      },
    );
  }

  /// Compact horizontal layout for narrow height constraints (e.g. 84px in tests)
  Widget _buildCompactLayout({
    required BuildContext context,
    required Color accentColor,
    required List<Color> gradientColors,
    required bool isDark,
    required dynamic semantic,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? semantic.borderSubtle
                  : accentColor.withValues(alpha: 0.20),
              width: 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategorySoft3DIcon(
                categoryType: _resolveCategoryType(category),
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: semantic.primaryText,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: semantic.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quiz.questionsCount'.trParams({
                        'count': '${category.questionCount}',
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full-width horizontal banner card (e.g. Finance at bottom of screen)
  Widget _buildFullWidthLayout({
    required BuildContext context,
    required String categoryType,
    required Color accentColor,
    required List<Color> gradientColors,
    required String description,
    required bool isDark,
    required dynamic semantic,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? semantic.borderSubtle
                  : accentColor.withValues(alpha: 0.22),
              width: 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.09),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Background Watermark
              Positioned.fill(
                child: CustomPaint(
                  painter: _CategoryWatermarkPainter(
                    categoryType: categoryType,
                    accentColor: accentColor,
                  ),
                ),
              ),

              // Content Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CategorySoft3DIcon(categoryType: categoryType, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: semantic.primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'quiz.questionsCount'.trParams({
                            'count': '${category.questionCount}',
                          }),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: semantic.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: semantic.secondaryText.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Circular Forward Button
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? semantic.surfaceElevated : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? semantic.borderSubtle
                            : semantic.borderSubtle.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                      boxShadow: isDark
                          ? const []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: semantic.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2-column vertical Soft 3D card layout directly matching the reference image
  Widget _buildSoft3DVerticalCard({
    required BuildContext context,
    required String categoryType,
    required Color accentColor,
    required List<Color> gradientColors,
    required String description,
    required bool isDark,
    required dynamic semantic,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? semantic.borderSubtle
                  : accentColor.withValues(alpha: 0.20),
              width: 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Background decorative watermark
              Positioned.fill(
                child: CustomPaint(
                  painter: _CategoryWatermarkPainter(
                    categoryType: categoryType,
                    accentColor: accentColor,
                  ),
                ),
              ),

              // Foreground Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: 3D Icon + Circular Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategorySoft3DIcon(
                        categoryType: categoryType,
                        size: 42,
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? semantic.surfaceElevated : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? semantic.borderSubtle
                                : semantic.borderSubtle.withValues(alpha: 0.7),
                            width: 0.8,
                          ),
                          boxShadow: isDark
                              ? const []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: semantic.primaryText,
                        ),
                      ),
                    ],
                  ),

                  // Middle: Title & Questions Count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: semantic.primaryText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'quiz.questionsCount'.trParams({
                          'count': '${category.questionCount}',
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: semantic.secondaryText,
                        ),
                      ),
                    ],
                  ),

                  // Bottom: Short supporting description
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      color: semantic.secondaryText.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 8. RECENTLY PLAYED & MULTIPLAYER COMPONENTS (PRESERVED)
// ============================================================================

/// Recently Played card with prominent "Continue" button.
class QuizRecentlyPlayedCard extends StatelessWidget {
  const QuizRecentlyPlayedCard({
    super.key,
    required this.category,
    required this.onContinue,
  });

  final QuizCategory category;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? semantic.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.growthAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.growthAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'quiz.questionsCount'.trParams({
                    'count': '${category.questionCount}',
                  }),
                  style: TextStyle(
                    fontSize: 12,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onContinue,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: semantic.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 17,
                      color: semantic.textInverse,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'common.continue'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: semantic.textInverse,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no recently played quizzes exist.
class QuizEmptyRecentlyPlayedCard extends StatelessWidget {
  const QuizEmptyRecentlyPlayedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.backgroundSecondary,
            ),
            child: Icon(
              Icons.history_rounded,
              color: semantic.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'quiz.noRecentQuizzes'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'quiz.noRecentQuizzesSubtitle'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 1v1 multiplayer challenge promotional card navigating to [AppRoutes.quizMultiplayer].
class QuizMultiplayerChallengeCard extends StatelessWidget {
  const QuizMultiplayerChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semantic = context.semanticColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.quizMultiplayer),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? semantic.surface : const Color(0xFFFAF7FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? semantic.borderSubtle
                  : AppColors.productivityAccent.withValues(alpha: 0.3),
            ),
            boxShadow: semantic.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.growthAccent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.growthAccent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'quiz.challengeFriendsTitle'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: semantic.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quiz.challengeFriendsSubtitle'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: semantic.backgroundSecondary,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: semantic.primaryText,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
