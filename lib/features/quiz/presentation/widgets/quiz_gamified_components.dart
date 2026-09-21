import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../domain/models/quiz_models.dart';

// ============================================================================
// 1. SOFT 3D VECTOR ILLUSTRATIONS (Trophy, Lightbulb, Challenge Icons)
// ============================================================================

/// Soft 3D Golden Trophy with star emblem, dual handles, purple pedestal, and sparkles.
class Soft3DTrophyWidget extends StatelessWidget {
  const Soft3DTrophyWidget({super.key, this.size = 84});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrophyPainter(),
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw floating sparkles in background
    _drawSparkle(canvas, Offset(w * 0.14, h * 0.28), w * 0.09, const Color(0xFFFBBF24));
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.32), w * 0.08, const Color(0xFFF59E0B));
    _drawSparkle(canvas, Offset(w * 0.82, h * 0.68), w * 0.07, const Color(0xFF60A5FA));
    _drawSparkle(canvas, Offset(w * 0.20, h * 0.72), w * 0.06, const Color(0xFFA78BFA));

    // Pedestal base shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.88),
        width: w * 0.58,
        height: h * 0.16,
      ),
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Pedestal Bottom Tier (Soft Lavender / Purple 3D disk)
    final baseRect1 = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.82),
      width: w * 0.52,
      height: h * 0.16,
    );
    final baseRRect1 = RRect.fromRectAndRadius(baseRect1, Radius.circular(h * 0.08));
    final basePaint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      ).createShader(baseRect1);
    canvas.drawRRect(baseRRect1, basePaint1);

    // Pedestal Top Tier
    final baseRect2 = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.76),
      width: w * 0.38,
      height: h * 0.11,
    );
    final baseRRect2 = RRect.fromRectAndRadius(baseRect2, Radius.circular(h * 0.05));
    final basePaint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      ).createShader(baseRect2);
    canvas.drawRRect(baseRRect2, basePaint2);

    // Trophy Stem
    final stemPath = Path()
      ..moveTo(w * 0.44, h * 0.73)
      ..lineTo(w * 0.56, h * 0.73)
      ..lineTo(w * 0.53, h * 0.58)
      ..lineTo(w * 0.47, h * 0.58)
      ..close();
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(Rect.fromLTWH(w * 0.44, h * 0.58, w * 0.12, h * 0.15));
    canvas.drawPath(stemPath, stemPaint);

    // Left Trophy Handle
    final leftHandlePath = Path()
      ..moveTo(w * 0.35, h * 0.28)
      ..cubicTo(w * 0.12, h * 0.26, w * 0.12, h * 0.52, w * 0.37, h * 0.50)
      ..lineTo(w * 0.37, h * 0.43)
      ..cubicTo(w * 0.22, h * 0.44, w * 0.22, h * 0.33, w * 0.35, h * 0.33)
      ..close();
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(w * 0.12, h * 0.25, w * 0.76, h * 0.30));
    canvas.drawPath(leftHandlePath, handlePaint);

    // Right Trophy Handle
    final rightHandlePath = Path()
      ..moveTo(w * 0.65, h * 0.28)
      ..cubicTo(w * 0.88, h * 0.26, w * 0.88, h * 0.52, w * 0.63, h * 0.50)
      ..lineTo(w * 0.63, h * 0.43)
      ..cubicTo(w * 0.78, h * 0.44, w * 0.78, h * 0.33, w * 0.65, h * 0.33)
      ..close();
    canvas.drawPath(rightHandlePath, handlePaint);

    // Trophy Cup Body
    final cupPath = Path()
      ..moveTo(w * 0.28, h * 0.24)
      ..cubicTo(w * 0.29, h * 0.46, w * 0.40, h * 0.60, w * 0.50, h * 0.60)
      ..cubicTo(w * 0.60, h * 0.60, w * 0.71, h * 0.46, w * 0.72, h * 0.24)
      ..close();
    final cupPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFBEB),
          Color(0xFFFDE047),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(w * 0.28, h * 0.24, w * 0.44, h * 0.36));
    canvas.drawPath(cupPath, cupPaint);

    // Trophy Rim Lip (3D Torus Bevel)
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.24),
      width: w * 0.45,
      height: h * 0.085,
    );
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFEF08A), Color(0xFFEAB308)],
      ).createShader(rimRect);
    canvas.drawOval(rimRect, rimPaint);

    // Inner rim depth
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.24),
        width: w * 0.38,
        height: h * 0.05,
      ),
      Paint()..color = const Color(0xFFCA8A04),
    );

    // Cup Highlight curve
    final highlightPath = Path()
      ..moveTo(w * 0.34, h * 0.30)
      ..cubicTo(w * 0.35, h * 0.44, w * 0.42, h * 0.52, w * 0.48, h * 0.54);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Embossed Star on Cup Center
    _drawStar(canvas, Offset(w * 0.50, h * 0.40), w * 0.075, const Color(0xFFFEF08A));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.42;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Star shadow
    canvas.drawPath(
      path.shift(const Offset(0.5, 1.2)),
      Paint()..color = const Color(0xFFB45309).withValues(alpha: 0.4),
    );

    // Star fill
    final starPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFFDE047), Color(0xFFEAB308)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, starPaint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx + size, center.dy)
      ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx, center.dy + size)
      ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx - size, center.dy)
      ..cubicTo(center.dx, center.dy, center.dx, center.dy, center.dx, center.dy - size)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, size * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 3D Glowing Lightbulb Widget for Motivational CTA card.
class Soft3DLightbulbWidget extends StatelessWidget {
  const Soft3DLightbulbWidget({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LightbulbPainter(),
      ),
    );
  }
}

class _LightbulbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.50, h * 0.42);

    // Warm radial ambient glow
    canvas.drawCircle(
      center,
      w * 0.44,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE047).withValues(alpha: 0.45),
            const Color(0xFFFBBF24).withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: w * 0.44)),
    );

    // Screw Base
    final baseWidth = w * 0.28;
    final baseTop = h * 0.65;
    final baseRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, baseTop + h * 0.08),
        width: baseWidth,
        height: h * 0.16,
      ),
      Radius.circular(w * 0.05),
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCBD5E1), Color(0xFF64748B), Color(0xFF334155)],
      ).createShader(Rect.fromLTWH(w * 0.35, baseTop, baseWidth, h * 0.16));
    canvas.drawRRect(baseRRect, basePaint);

    // Base contact point
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, baseTop + h * 0.17),
        width: baseWidth * 0.55,
        height: h * 0.05,
      ),
      Paint()..color = const Color(0xFF1E293B),
    );

    // Glass Bulb Path
    final bulbPath = Path()
      ..moveTo(w * 0.38, baseTop)
      ..cubicTo(w * 0.35, h * 0.56, w * 0.20, h * 0.50, w * 0.20, h * 0.36)
      ..cubicTo(w * 0.20, h * 0.16, w * 0.80, h * 0.16, w * 0.80, h * 0.36)
      ..cubicTo(w * 0.80, h * 0.50, w * 0.65, h * 0.56, w * 0.62, baseTop)
      ..close();

    final bulbPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFEF9C3),
          Color(0xFFFDE047),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
      ).createShader(Rect.fromLTWH(w * 0.20, h * 0.16, w * 0.60, h * 0.52));
    canvas.drawPath(bulbPath, bulbPaint);

    // Specular glass shine
    final shinePath = Path()
      ..moveTo(w * 0.32, h * 0.25)
      ..cubicTo(w * 0.32, h * 0.20, w * 0.40, h * 0.18, w * 0.48, h * 0.18);
    canvas.drawPath(
      shinePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Little ray sparkles
    _drawSparkleMini(canvas, Offset(w * 0.88, h * 0.22), w * 0.06);
    _drawSparkleMini(canvas, Offset(w * 0.12, h * 0.26), w * 0.05);
  }

  void _drawSparkleMini(Canvas canvas, Offset c, double s) {
    final p = Path()
      ..moveTo(c.dx, c.dy - s)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx, c.dy + s)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx - s, c.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(c, s * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Vector Icon for Single Quiz (Mint / Green learner bust + star).
class Soft3DSingleQuizIcon extends StatelessWidget {
  const Soft3DSingleQuizIcon({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SingleQuizIconPainter(),
      ),
    );
  }
}

class _SingleQuizIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sparkle top-right
    _drawStarSparkle(canvas, Offset(w * 0.86, h * 0.24), w * 0.10, const Color(0xFFF59E0B));

    // Person Shoulders / Body
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.44, h * 0.72),
      width: w * 0.62,
      height: h * 0.38,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.20));
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6EE7B7), Color(0xFF10B981), Color(0xFF047857)],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Person Head
    final headCenter = Offset(w * 0.44, h * 0.36);
    final headRadius = w * 0.22;
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA7F3D0), Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Head specular highlight
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.32, headCenter.dy - headRadius * 0.32),
      headRadius * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  void _drawStarSparkle(Canvas canvas, Offset c, double s, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - s)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx - s, c.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawCircle(c, s * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Vector Icon for 1v1 Multiplayer Quiz (Peach/Coral two players with VS badge).
class Soft3DMultiplayerIcon extends StatelessWidget {
  const Soft3DMultiplayerIcon({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MultiplayerIconPainter(),
      ),
    );
  }
}

class _MultiplayerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sparkle top-left
    _drawStarSparkle(canvas, Offset(w * 0.16, h * 0.22), w * 0.08, const Color(0xFFFBBF24));

    // Player 1 (Left, Warm Gold/Amber)
    final p1Head = Offset(w * 0.32, h * 0.38);
    final p1R = w * 0.17;
    final p1Body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.32, h * 0.72), width: w * 0.44, height: h * 0.34),
      Radius.circular(w * 0.16),
    );
    final p1Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFD97706)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(p1Body, p1Paint);
    canvas.drawCircle(p1Head, p1R, p1Paint);

    // Player 2 (Right, Coral/Orange)
    final p2Head = Offset(w * 0.68, h * 0.38);
    final p2R = w * 0.17;
    final p2Body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.68, h * 0.72), width: w * 0.44, height: h * 0.34),
      Radius.circular(w * 0.16),
    );
    final p2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFEDD5), Color(0xFFFB923C), Color(0xFFEA580C)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(p2Body, p2Paint);
    canvas.drawCircle(p2Head, p2R, p2Paint);

    // Red / Coral "VS" Badge in center
    final vsCenter = Offset(w * 0.52, h * 0.54);
    final vsR = w * 0.16;

    // Shadow
    canvas.drawCircle(
      Offset(vsCenter.dx, vsCenter.dy + 2),
      vsR,
      Paint()..color = const Color(0xFFE11D48).withValues(alpha: 0.35),
    );

    // VS Circle
    final vsPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDA4AF), Color(0xFFF43F5E), Color(0xFFBE123C)],
      ).createShader(Rect.fromCircle(center: vsCenter, radius: vsR));
    canvas.drawCircle(vsCenter, vsR, vsPaint);

    // "VS" Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'VS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(vsCenter.dx - textPainter.width / 2, vsCenter.dy - textPainter.height / 2),
    );
  }

  void _drawStarSparkle(Canvas canvas, Offset c, double s, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - s)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx - s, c.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawCircle(c, s * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Vector Icon for Short Content (Cyan/Blue video play box).
class Soft3DShortContentIcon extends StatelessWidget {
  const Soft3DShortContentIcon({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShortContentIconPainter(),
      ),
    );
  }
}

class _ShortContentIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sparkle top-right
    _drawStarSparkle(canvas, Offset(w * 0.88, h * 0.28), w * 0.09, const Color(0xFFFBBF24));

    // 3D Play Squircle Box
    final center = Offset(w * 0.44, h * 0.50);
    final boxSize = w * 0.64;
    final boxRect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);
    final boxRRect = RRect.fromRectAndRadius(boxRect, Radius.circular(w * 0.20));

    // Ambient drop shadow
    canvas.drawRRect(
      boxRRect.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Box fill gradient
    final boxPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF93C5FD), Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      ).createShader(boxRect);
    canvas.drawRRect(boxRRect, boxPaint);

    // Inner bevel highlight
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - 1, center.dy - 1),
        width: boxSize * 0.88,
        height: boxSize * 0.88,
      ),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // White 3D Play Triangle
    final triPath = Path()
      ..moveTo(center.dx - w * 0.08, center.dy - h * 0.14)
      ..lineTo(center.dx + w * 0.14, center.dy)
      ..lineTo(center.dx - w * 0.08, center.dy + h * 0.14)
      ..close();

    // Triangle drop shadow
    canvas.drawPath(
      triPath.shift(const Offset(0.5, 1.5)),
      Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.4),
    );

    // Triangle white fill
    canvas.drawPath(triPath, Paint()..color = Colors.white);
  }

  void _drawStarSparkle(Canvas canvas, Offset c, double s, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - s)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx + s, c.dy)
      ..cubicTo(c.dx, c.dy, c.dx, c.dy, c.dx - s, c.dy)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawCircle(c, s * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Vector Icon for Learning Progress (Lavender/Purple rounded bar chart).
class Soft3DLearningProgressIcon extends StatelessWidget {
  const Soft3DLearningProgressIcon({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LearningProgressIconPainter(),
      ),
    );
  }
}

class _LearningProgressIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bar 1 (Left - medium height)
    _drawPillBar(
      canvas: canvas,
      rect: Rect.fromLTWH(w * 0.12, h * 0.38, w * 0.19, h * 0.46),
      colors: const [Color(0xFFDDD6FE), Color(0xFFA78BFA), Color(0xFF7C3AED)],
    );

    // Bar 2 (Center - tall height)
    _drawPillBar(
      canvas: canvas,
      rect: Rect.fromLTWH(w * 0.38, h * 0.20, w * 0.21, h * 0.64),
      colors: const [Color(0xFFEDE9FE), Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    );

    // Bar 3 (Right - medium-low height)
    _drawPillBar(
      canvas: canvas,
      rect: Rect.fromLTWH(w * 0.66, h * 0.32, w * 0.19, h * 0.52),
      colors: const [Color(0xFFDDD6FE), Color(0xFFA78BFA), Color(0xFF7C3AED)],
    );
  }

  void _drawPillBar({
    required Canvas canvas,
    required Rect rect,
    required List<Color> colors,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.5));

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF6D28D9).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);

    // Cap highlight
    canvas.drawCircle(
      Offset(rect.center.dx, rect.top + rect.width * 0.5),
      rect.width * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. HEADER COMPONENT
// ============================================================================

class QuizGamifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  const QuizGamifiedHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        child: Row(
          children: [
            // Circular Back Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (Get.previousRoute.isNotEmpty) {
                    Get.back();
                  } else {
                    Get.offAllNamed(AppRoutes.home);
                  }
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? semantic.surface : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? semantic.borderSubtle
                          : semantic.borderSubtle.withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                    boxShadow: isDark
                        ? const []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 26,
                    color: semantic.primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'quiz.title'.tr,
                    style: textTheme.headlineSmall?.copyWith(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'quiz.headerSubtitle'.tr,
                    style: textTheme.bodySmall?.copyWith(
                      color: semantic.secondaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Circular Notification Button with red dot
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.toNamed(AppRoutes.notifications),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? semantic.surface : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? semantic.borderSubtle
                          : semantic.borderSubtle.withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                    boxShadow: isDark
                        ? const []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 22,
                        color: semantic.primaryText,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. PROFILE / XP HERO CARD
// ============================================================================

class QuizXpHeroCard extends StatelessWidget {
  const QuizXpHeroCard({
    super.key,
    required this.stats,
  });

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final xpRemaining =
        (stats.xpToNextLevel - stats.xp).clamp(0, stats.xpToNextLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF2E2616),
                  const Color(0xFF231C10),
                ]
              : [
                  const Color(0xFFFFFBEB),
                  const Color(0xFFFEF3C7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF785918)
              : const Color(0xFFFDE68A),
          width: 1.2,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Online Status Dot
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFCA8A04)
                            : const Color(0xFFF59E0B),
                        width: 1.6,
                      ),
                    ),
                    child: ClipOval(
                      child: AppAvatar(
                        imageUrl: stats.avatarUrl,
                        name: stats.name,
                        size: 48,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF231C10) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // User Greeting & Level Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'quiz.dashboardGreeting'.trParams({'name': stats.name}),
                      style: textTheme.titleMedium?.copyWith(
                        color: semantic.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Level Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'quiz.level'.trParams({'level': '${stats.level}'}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                        // Explorer Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF86EFAC),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🌱 ', style: TextStyle(fontSize: 10)),
                              Text(
                                'quiz.explorer'.tr,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF15803D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Soft 3D Golden Trophy
              const Soft3DTrophyWidget(size: 76),
            ],
          ),
          const SizedBox(height: 14),
          // XP Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B3322)
                    : const Color(0xFFFDE68A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: stats.levelProgress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // XP Details with Flexible text to accommodate long localized strings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.xp} / ${stats.xpToNextLevel} XP',
                style: textTheme.bodySmall?.copyWith(
                  color: semantic.primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'quiz.xpToNextLevel'.trParams({'xp': '$xpRemaining'}),
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.secondaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. QUIZ STATISTICS CARD (Completed | Available)
// ============================================================================

class QuizStatsCard extends StatelessWidget {
  const QuizStatsCard({
    super.key,
    required this.completedCount,
    required this.availableCount,
  });

  final int completedCount;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? semantic.surface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? semantic.borderSubtle
              : semantic.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Completed Stat
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF059669)
                          : const Color(0xFF86EFAC),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 24,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completedCount',
                        style: textTheme.titleLarge?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'quiz.completedQuizzes'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            height: 38,
            color: isDark
                ? semantic.borderSubtle
                : semantic.borderSubtle.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          // Available Stat
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF93C5FD),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    size: 22,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$availableCount',
                        style: textTheme.titleLarge?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'quiz.availableQuizzes'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
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

// ============================================================================
// 5. CHOOSE YOUR CHALLENGE CARD (2x2 Grid Item)
// ============================================================================

class QuizChallengeCard extends StatelessWidget {
  const QuizChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.darkGradientColors,
    required this.borderColor,
    required this.darkBorderColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final Widget icon;
  final List<Color> gradientColors;
  final List<Color> darkGradientColors;
  final Color borderColor;
  final Color darkBorderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? darkGradientColors : gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? darkBorderColor : borderColor,
              width: 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: 3D Icon & Circular Arrow Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? semantic.surfaceElevated : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: semantic.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom: Title & Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: semantic.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
// 6. CATEGORY CARD (Horizontal Chips)
// ============================================================================

class QuizCategoryCard extends StatelessWidget {
  const QuizCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 92,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.22 : 0.08)
                  : (isDark ? semantic.surface : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isDark
                        ? semantic.borderSubtle
                        : semantic.borderSubtle.withValues(alpha: 0.8)),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isDark || !isSelected
                  ? const []
                  : [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: isDark ? 0.30 : 0.14)
                        : (isDark
                            ? semantic.surfaceElevated
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? accentColor : semantic.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? accentColor : semantic.primaryText,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7. MOTIVATIONAL QUIZ CTA CARD
// ============================================================================

class QuizMotivationCard extends StatelessWidget {
  const QuizMotivationCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF2E2616),
                      const Color(0xFF231C10),
                    ]
                  : [
                      const Color(0xFFFFFBEB),
                      const Color(0xFFFEF3C7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF785918)
                  : const Color(0xFFFDE68A),
              width: 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // 3D Lightbulb
              const Soft3DLightbulbWidget(size: 48),
              const SizedBox(width: 10),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'quiz.motivationTitle'.tr,
                      style: textTheme.titleSmall?.copyWith(
                        color: semantic.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quiz.motivationSubtitle'.tr,
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.secondaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Pill CTA Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: const ShapeDecoration(
                  color: Color(0xFFF59E0B),
                  shape: StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'quiz.takeAQuiz'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.white,
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
}
