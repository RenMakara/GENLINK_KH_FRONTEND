import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../notification/domain/models/notification_model.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../domain/models/quiz_models.dart';

// ============================================================================
// 1. SOFT 3D VECTOR ILLUSTRATIONS
// ============================================================================

/// Helper for drawing smooth 4-pointed golden sparkles.
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
  canvas.drawCircle(center, size * 0.28, Paint()..color = Colors.white);
}

/// Helper for drawing 5-pointed star.
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
    Paint()..color = const Color(0xFFB45309).withValues(alpha: 0.35),
  );

  final starPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFFDE047), Color(0xFFEAB308)],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
  canvas.drawPath(path, starPaint);
}

// ----------------------------------------------------------------------------
// A. Soft 3D Golden Trophy
// ----------------------------------------------------------------------------
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

    // Floating sparkles in background
    _drawSparkle(canvas, Offset(w * 0.12, h * 0.26), w * 0.09, const Color(0xFFFBBF24));
    _drawSparkle(canvas, Offset(w * 0.90, h * 0.28), w * 0.08, const Color(0xFFF59E0B));
    _drawSparkle(canvas, Offset(w * 0.84, h * 0.68), w * 0.07, const Color(0xFFFBBF24));
    _drawSparkle(canvas, Offset(w * 0.16, h * 0.74), w * 0.06, const Color(0xFFA78BFA));

    // Pedestal base contact shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.90),
        width: w * 0.62,
        height: h * 0.16,
      ),
      Paint()
        ..color = const Color(0xFF6D28D9).withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Pedestal Bottom Tier (Lavender / Purple 3D disk)
    final baseRect1 = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.83),
      width: w * 0.54,
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
      width: w * 0.40,
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
      ..moveTo(w * 0.43, h * 0.73)
      ..lineTo(w * 0.57, h * 0.73)
      ..lineTo(w * 0.53, h * 0.58)
      ..lineTo(w * 0.47, h * 0.58)
      ..close();
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
      ).createShader(Rect.fromLTWH(w * 0.43, h * 0.58, w * 0.14, h * 0.15));
    canvas.drawPath(stemPath, stemPaint);

    // Left Trophy Handle
    final leftHandlePath = Path()
      ..moveTo(w * 0.35, h * 0.28)
      ..cubicTo(w * 0.10, h * 0.26, w * 0.10, h * 0.54, w * 0.37, h * 0.51)
      ..lineTo(w * 0.37, h * 0.43)
      ..cubicTo(w * 0.22, h * 0.44, w * 0.22, h * 0.34, w * 0.35, h * 0.34)
      ..close();
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(w * 0.10, h * 0.25, w * 0.80, h * 0.30));
    canvas.drawPath(leftHandlePath, handlePaint);

    // Right Trophy Handle
    final rightHandlePath = Path()
      ..moveTo(w * 0.65, h * 0.28)
      ..cubicTo(w * 0.90, h * 0.26, w * 0.90, h * 0.54, w * 0.63, h * 0.51)
      ..lineTo(w * 0.63, h * 0.43)
      ..cubicTo(w * 0.78, h * 0.44, w * 0.78, h * 0.34, w * 0.65, h * 0.34)
      ..close();
    canvas.drawPath(rightHandlePath, handlePaint);

    // Trophy Cup Body
    final cupPath = Path()
      ..moveTo(w * 0.27, h * 0.24)
      ..cubicTo(w * 0.28, h * 0.47, w * 0.40, h * 0.61, w * 0.50, h * 0.61)
      ..cubicTo(w * 0.60, h * 0.61, w * 0.72, h * 0.47, w * 0.73, h * 0.24)
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
      ).createShader(Rect.fromLTWH(w * 0.27, h * 0.24, w * 0.46, h * 0.37));
    canvas.drawPath(cupPath, cupPaint);

    // Trophy Rim Lip
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.24),
      width: w * 0.47,
      height: h * 0.09,
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
        width: w * 0.39,
        height: h * 0.05,
      ),
      Paint()..color = const Color(0xFFCA8A04),
    );

    // Cup Highlight curve
    final highlightPath = Path()
      ..moveTo(w * 0.33, h * 0.30)
      ..cubicTo(w * 0.34, h * 0.45, w * 0.41, h * 0.53, w * 0.48, h * 0.55);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Embossed Star on Cup Center
    _drawStar(canvas, Offset(w * 0.50, h * 0.41), w * 0.08, const Color(0xFFFEF08A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// B. Soft 3D Single Quiz Icon (Mint Checklist Clipboard with Yellow Pencil)
// ----------------------------------------------------------------------------
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
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.20), w * 0.08, const Color(0xFF10B981));

    // 1. Mint / Cyan Clipboard Board
    final boardRect = Rect.fromCenter(
      center: Offset(w * 0.44, h * 0.52),
      width: w * 0.62,
      height: h * 0.72,
    );
    final boardRRect = RRect.fromRectAndRadius(boardRect, Radius.circular(w * 0.14));

    // Board Drop Shadow
    canvas.drawRRect(
      boardRRect.shift(const Offset(0, 3.5)),
      Paint()
        ..color = const Color(0xFF059669).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Board Fill
    final boardPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF67E8F9), Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(boardRect);
    canvas.drawRRect(boardRRect, boardPaint);

    // 2. Top Silver Clamp
    final clampRect = Rect.fromCenter(
      center: Offset(w * 0.44, h * 0.19),
      width: w * 0.32,
      height: h * 0.11,
    );
    final clampRRect = RRect.fromRectAndRadius(clampRect, Radius.circular(w * 0.05));
    final clampPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      ).createShader(clampRect);
    canvas.drawRRect(clampRRect, clampPaint);

    // Clamp rivet hole
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.19),
      w * 0.035,
      Paint()..color = const Color(0xFF64748B),
    );

    // 3. Crisp White Paper Sheet
    final paperRect = Rect.fromCenter(
      center: Offset(w * 0.44, h * 0.54),
      width: w * 0.48,
      height: h * 0.56,
    );
    final paperRRect = RRect.fromRectAndRadius(paperRect, Radius.circular(w * 0.08));
    canvas.drawRRect(paperRRect, Paint()..color = Colors.white);

    // 4. Checklist Lines & Checkmarks
    final checkPaint = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Row 1
    final c1 = Path()
      ..moveTo(w * 0.25, h * 0.39)
      ..lineTo(w * 0.29, h * 0.43)
      ..lineTo(w * 0.36, h * 0.35);
    canvas.drawPath(c1, checkPaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.39), Offset(w * 0.62, h * 0.39), linePaint);

    // Row 2
    final c2 = Path()
      ..moveTo(w * 0.25, h * 0.51)
      ..lineTo(w * 0.29, h * 0.55)
      ..lineTo(w * 0.36, h * 0.47);
    canvas.drawPath(c2, checkPaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.51), Offset(w * 0.58, h * 0.51), linePaint);

    // Row 3
    final c3 = Path()
      ..moveTo(w * 0.25, h * 0.63)
      ..lineTo(w * 0.29, h * 0.67)
      ..lineTo(w * 0.36, h * 0.59);
    canvas.drawPath(c3, checkPaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.63), Offset(w * 0.52, h * 0.63), linePaint);

    // 5. Soft 3D Yellow Pencil (lying diagonally across bottom right)
    canvas.save();
    canvas.translate(w * 0.68, h * 0.62);
    canvas.rotate(-math.pi / 4);

    // Pencil shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.06, -h * 0.20 + 2, w * 0.12, h * 0.36),
        Radius.circular(w * 0.03),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Pencil body (yellow)
    final pBodyRect = Rect.fromLTWH(-w * 0.05, -h * 0.18, w * 0.10, h * 0.26);
    final pBodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFFD97706)],
      ).createShader(pBodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(pBodyRect, Radius.circular(w * 0.02)), pBodyPaint);

    // Pencil ferrule (silver ring)
    final ferruleRect = Rect.fromLTWH(-w * 0.05, -h * 0.22, w * 0.10, h * 0.045);
    canvas.drawRect(ferruleRect, Paint()..color = const Color(0xFFCBD5E1));

    // Pencil eraser (pink/coral)
    final eraserRect = Rect.fromLTWH(-w * 0.05, -h * 0.27, w * 0.10, h * 0.055);
    final eraserRRect = RRect.fromRectAndCorners(
      eraserRect,
      topLeft: Radius.circular(w * 0.03),
      topRight: Radius.circular(w * 0.03),
    );
    canvas.drawRRect(eraserRRect, Paint()..color = const Color(0xFFFB7185));

    // Sharpened cone (wood beige)
    final conePath = Path()
      ..moveTo(-w * 0.05, h * 0.08)
      ..lineTo(w * 0.05, h * 0.08)
      ..lineTo(0, h * 0.18)
      ..close();
    canvas.drawPath(conePath, Paint()..color = const Color(0xFFFED7AA));

    // Graphite lead tip
    final leadPath = Path()
      ..moveTo(-w * 0.02, h * 0.14)
      ..lineTo(w * 0.02, h * 0.14)
      ..lineTo(0, h * 0.18)
      ..close();
    canvas.drawPath(leadPath, Paint()..color = const Color(0xFF334155));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// C. Soft 3D 1v1 Multiplayer Icon (Two Players with VS Badge)
// ----------------------------------------------------------------------------
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
    _drawSparkle(canvas, Offset(w * 0.14, h * 0.18), w * 0.08, const Color(0xFFFBBF24));

    // 1. Player 1 (Left, Cyan/Sky Blue Learner)
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
        colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.5, h));
    canvas.drawRRect(p1Body, p1Paint);
    canvas.drawCircle(p1Head, p1R, p1Paint);
    // Head specular glint
    canvas.drawCircle(
      Offset(p1Head.dx - p1R * 0.30, p1Head.dy - p1R * 0.30),
      p1R * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // 2. Player 2 (Right, Warm Orange/Amber Learner)
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
        colors: [Color(0xFFFDBA74), Color(0xFFFB923C), Color(0xFFEA580C)],
      ).createShader(Rect.fromLTWH(w * 0.5, 0, w * 0.5, h));
    canvas.drawRRect(p2Body, p2Paint);
    canvas.drawCircle(p2Head, p2R, p2Paint);
    // Head specular glint
    canvas.drawCircle(
      Offset(p2Head.dx - p2R * 0.30, p2Head.dy - p2R * 0.30),
      p2R * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // 3. Center 3D VS Badge
    final vsCenter = Offset(w * 0.50, h * 0.54);
    final vsR = w * 0.17;

    // Badge shadow
    canvas.drawCircle(
      Offset(vsCenter.dx, vsCenter.dy + 2.5),
      vsR,
      Paint()..color = const Color(0xFFBE123C).withValues(alpha: 0.36),
    );

    // Badge fill gradient
    final vsPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDA4AF), Color(0xFFF43F5E), Color(0xFFBE123C)],
      ).createShader(Rect.fromCircle(center: vsCenter, radius: vsR));
    canvas.drawCircle(vsCenter, vsR, vsPaint);

    // Inner rim highlight
    canvas.drawCircle(
      vsCenter,
      vsR * 0.88,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // "VS" Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'VS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// D. Soft 3D Short Content Icon (Sky-Blue Screen with Play Button)
// ----------------------------------------------------------------------------
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
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.22), w * 0.09, const Color(
        0xFF0365DF));

    // Monitor stand / base
    final standRect = Rect.fromCenter(
      center: Offset(w * 0.46, h * 0.78),
      width: w * 0.28,
      height: h * 0.10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(standRect, Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFF1D4ED8),
    );

    // 3D Screen Bezel Box
    final center = Offset(w * 0.46, h * 0.48);
    final boxW = w * 0.68;
    final boxH = h * 0.58;
    final boxRect = Rect.fromCenter(center: center, width: boxW, height: boxH);
    final boxRRect = RRect.fromRectAndRadius(boxRect, Radius.circular(w * 0.18));

    // Ambient drop shadow
    canvas.drawRRect(
      boxRRect.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xFF1D4ED8).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Bezel gradient
    final boxPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF93C5FD), Color(0xFF0639DF), Color(0xFF1D4ED8)],
      ).createShader(boxRect);
    canvas.drawRRect(boxRRect, boxPaint);

    // Inner Screen Recess
    final innerW = boxW * 0.84;
    final innerH = boxH * 0.80;
    final innerRect = Rect.fromCenter(center: center, width: innerW, height: innerH);
    final innerRRect = RRect.fromRectAndRadius(innerRect, Radius.circular(w * 0.12));
    final innerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A52F4), Color(0xFF0631AA)],
      ).createShader(innerRect);
    canvas.drawRRect(innerRRect, innerPaint);

    // White 3D Play Triangle
    final triPath = Path()
      ..moveTo(center.dx - w * 0.08, center.dy - h * 0.13)
      ..lineTo(center.dx + w * 0.14, center.dy)
      ..lineTo(center.dx - w * 0.08, center.dy + h * 0.13)
      ..close();

    // Triangle drop shadow
    canvas.drawPath(
      triPath.shift(const Offset(0.5, 1.8)),
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.4),
    );

    // Triangle fill
    canvas.drawPath(triPath, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// E. Soft 3D Learning Progress Icon (Purple Bar Chart + Golden Ascending Arrow)
// ----------------------------------------------------------------------------
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

    // Sparkle top-right
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.18), w * 0.08, const Color(0xFFFBBF24));

    // 3 Vertical Rising Bar Pills
    // Bar 1 (Left - Short, Blue/Cyan)
    _drawPillBar(
      canvas: canvas,
      rect: Rect.fromLTWH(w * 0.15, h * 0.44, w * 0.18, h * 0.40),
      colors: const [Color(0xFF7DD3FC), Color(0xFF0284C7)],
    );

    // Bar 2 (Center - Medium, Lavender)
    _drawPillBar(
      canvas: canvas,
      rect: Rect.fromLTWH(w * 0.39, h * 0.30, w * 0.18, h * 0.54),
      colors: const [Color(0xFFC084FC), Color(0xFF7C3AED)],
    );

    // Bar 3 (Right - Tall, Deep Violet)
    _drawPillBar(
      canvas: canvas,
      rect: Rect.fromLTWH(w * 0.63, h * 0.18, w * 0.18, h * 0.66),
      colors: const [Color(0xFFE879F9), Color(0xFF9333EA)],
    );

    // 3D Golden Ascending Arrow (Curving up from bottom-left to top-right)
    final arrowPath = Path()
      ..moveTo(w * 0.16, h * 0.48)
      ..cubicTo(w * 0.38, h * 0.42, w * 0.55, h * 0.28, w * 0.80, h * 0.15);

    // Arrow shadow
    canvas.drawPath(
      arrowPath.shift(const Offset(0.5, 2.0)),
      Paint()
        ..color = const Color(0xFF6D28D9).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Arrow stroke
    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFDE047), Color(0xFFF59E0B)],
      ).createShader(Rect.fromLTWH(w * 0.15, h * 0.10, w * 0.70, h * 0.40))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(arrowPath, arrowPaint);

    // Arrowhead
    final headPath = Path()
      ..moveTo(w * 0.84, h * 0.12)
      ..lineTo(w * 0.68, h * 0.14)
      ..lineTo(w * 0.78, h * 0.24)
      ..close();
    canvas.drawPath(
      headPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B)],
        ).createShader(Rect.fromLTWH(w * 0.68, h * 0.12, w * 0.16, h * 0.12)),
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
        ..color = colors.last.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);

    // Cap specular gloss
    canvas.drawCircle(
      Offset(rect.center.dx, rect.top + rect.width * 0.5),
      rect.width * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// F. Soft 3D Lightbulb Widget (Motivational CTA)
// ----------------------------------------------------------------------------
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

    // Ambient radial glow
    canvas.drawCircle(
      center,
      w * 0.45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE047).withValues(alpha: 0.50),
            const Color(0xFFFBBF24).withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: w * 0.45)),
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

    // Screw base contact point
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
      ..cubicTo(w * 0.35, h * 0.56, w * 0.18, h * 0.50, w * 0.18, h * 0.36)
      ..cubicTo(w * 0.18, h * 0.14, w * 0.82, h * 0.14, w * 0.82, h * 0.36)
      ..cubicTo(w * 0.82, h * 0.50, w * 0.65, h * 0.56, w * 0.62, baseTop)
      ..close();

    final bulbPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFBEB),
          Color(0xFFFDE047),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
      ).createShader(Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.64, h * 0.54));
    canvas.drawPath(bulbPath, bulbPaint);

    // Specular glass shine
    final shinePath = Path()
      ..moveTo(w * 0.30, h * 0.25)
      ..cubicTo(w * 0.30, h * 0.18, w * 0.40, h * 0.16, w * 0.48, h * 0.16);
    canvas.drawPath(
      shinePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Little ray sparkles
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.20), w * 0.06, const Color(0xFFF59E0B));
    _drawSparkle(canvas, Offset(w * 0.12, h * 0.24), w * 0.05, const Color(0xFFFBBF24));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// G. Soft 3D Statistics Squircle Icons (Checkmark & Document)
// ----------------------------------------------------------------------------
class Soft3DStatsCheckIcon extends StatelessWidget {
  const Soft3DStatsCheckIcon({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EE7B7), Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.58,
        color: Colors.white,
      ),
    );
  }
}

class Soft3DStatsDocIcon extends StatelessWidget {
  const Soft3DStatsDocIcon({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF93C5FD), Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        Icons.feed_rounded,
        size: size * 0.54,
        color: Colors.white,
      ),
    );
  }
}

// ============================================================================
// 2. BACKGROUND DECORATIVE SHAPE PAINTERS FOR CHALLENGE CARDS
// ============================================================================

class SingleQuizBgPainter extends CustomPainter {
  const SingleQuizBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final leafPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Soft floating leaf 1
    final p1 = Path()
      ..moveTo(w * 0.78, h * 0.60)
      ..cubicTo(w * 0.95, h * 0.62, w * 0.95, h * 0.85, w * 0.78, h * 0.88)
      ..cubicTo(w * 0.65, h * 0.85, w * 0.65, h * 0.62, w * 0.78, h * 0.60);
    canvas.drawPath(p1, leafPaint);

    // Soft floating leaf 2
    final p2 = Path()
      ..moveTo(w * 0.92, h * 0.38)
      ..cubicTo(w * 1.05, h * 0.40, w * 1.05, h * 0.58, w * 0.92, h * 0.60)
      ..cubicTo(w * 0.82, h * 0.58, w * 0.82, h * 0.40, w * 0.92, h * 0.38);
    canvas.drawPath(p2, leafPaint);

    // Soft translucent bubble
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.25),
      w * 0.10,
      Paint()..color = const Color(0xFF34D399).withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MultiplayerBgPainter extends CustomPainter {
  const MultiplayerBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final arrowPaint = Paint()
      ..color = const Color(0xFFEA580C).withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;

    // Upward chevron 1
    final p1 = Path()
      ..moveTo(w * 0.82, h * 0.82)
      ..lineTo(w * 0.92, h * 0.68)
      ..lineTo(w * 1.02, h * 0.82)
      ..lineTo(w * 0.92, h * 0.76)
      ..close();
    canvas.drawPath(p1, arrowPaint);

    // Upward chevron 2
    final p2 = Path()
      ..moveTo(w * 0.74, h * 0.58)
      ..lineTo(w * 0.82, h * 0.46)
      ..lineTo(w * 0.90, h * 0.58)
      ..lineTo(w * 0.82, h * 0.53)
      ..close();
    canvas.drawPath(p2, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShortContentBgPainter extends CustomPainter {
  const ShortContentBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cloudPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Puffy cloud shape at bottom-right
    canvas.drawCircle(Offset(w * 0.88, h * 0.76), w * 0.16, cloudPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.82), w * 0.12, cloudPaint);
    canvas.drawCircle(Offset(w * 0.96, h * 0.82), w * 0.12, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LearningProgressBgPainter extends CustomPainter {
  const LearningProgressBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final growthPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    // Translucent ascending step bars
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.74, h * 0.70, w * 0.08, h * 0.22),
        Radius.circular(w * 0.04),
      ),
      growthPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.85, h * 0.55, w * 0.08, h * 0.37),
        Radius.circular(w * 0.04),
      ),
      growthPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 3. HEADER COMPONENT
// ============================================================================

class QuizGamifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  const QuizGamifiedHeader({super.key, this.onBackPressed});

  final VoidCallback? onBackPressed;

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
                onTap: onBackPressed ??
                    () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
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

            // Title & Subtitle with Crown
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'quiz.title'.tr,
                          style: textTheme.headlineSmall?.copyWith(
                            color: semantic.primaryText,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '👑',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'quiz.headerSubtitle'.tr,
                    style: textTheme.bodySmall?.copyWith(
                      color: semantic.secondaryText,
                      fontSize: 12,
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
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: semantic.primaryText,
                      ),
                      _buildNotificationBadge(semantic.surface, isDark),
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

  Widget _buildNotificationBadge(Color surfaceColor, bool isDark) {
    if (!Get.isRegistered<NotificationController>()) {
      return const SizedBox.shrink();
    }

    final notifController = Get.find<NotificationController>();
    return Obx(() {
      final serverUnread = notifController.totalUnreadCount.value;
      final localUnread = notifController.notifications
          .where((n) => !n.isRead && n.type != NotificationType.chat)
          .length;
      final unreadChatCount = notifController.notifications
          .where((n) => !n.isRead && n.type == NotificationType.chat)
          .length;
      final adjustedServerUnread = serverUnread > unreadChatCount
          ? serverUnread - unreadChatCount
          : localUnread;
      final unread = adjustedServerUnread > localUnread
          ? adjustedServerUnread
          : localUnread;

      if (unread <= 0) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 10,
        right: 10,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? surfaceColor : Colors.white,
              width: 1.5,
            ),
          ),
        ),
      );
    });
  }
}

// ============================================================================
// 4. QUIZ XP HERO CARD
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
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFCA8A04)
                            : const Color(0xFFF59E0B),
                        width: 1.8,
                      ),
                    ),
                    child: ClipOval(
                      child: AppAvatar(
                        imageUrl: stats.avatarUrl,
                        name: stats.name,
                        size: 50,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 13,
                      height: 13,
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
                              Flexible(
                                child: Text(
                                  'quiz.explorer'.tr,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
              const Soft3DTrophyWidget(size: 74),
            ],
          ),
          const SizedBox(height: 14),

          // XP Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
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

          // XP Details Row
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
// 5. QUIZ STATISTICS SECTION (Completed Quizzes & Available Quizzes)
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          // 1. Completed Section
          Expanded(
            child: Row(
              children: [
                const Soft3DStatsCheckIcon(size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completedCount',
                        style: textTheme.titleLarge?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'quiz.completedQuizzes'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 11,
                            color: Color(0xFF15803D),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'quiz.plusOneThisWeek'.tr,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFF15803D),
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: isDark
                ? semantic.borderSubtle
                : semantic.borderSubtle.withValues(alpha: 0.8),
          ),
          // 2. Available Section
          Expanded(
            child: Row(
              children: [
                const Soft3DStatsDocIcon(size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$availableCount',
                        style: textTheme.titleLarge?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'quiz.availableQuizzes'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 11,
                            color: Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'quiz.keepLearning'.tr,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1D4ED8),
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
// 6. CHOOSE YOUR CHALLENGE CARD (2x2 Grid Item with Background Painter & Badge)
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
    this.badgeText,
    this.badgeIcon,
    this.bgPainter,
  });

  final String title;
  final String description;
  final Widget icon;
  final List<Color> gradientColors;
  final List<Color> darkGradientColors;
  final Color borderColor;
  final Color darkBorderColor;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;
  final CustomPainter? bgPainter;

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
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Background artistic shapes if provided
                if (bgPainter != null)
                  Positioned.fill(
                    child: CustomPaint(painter: bgPainter!),
                  ),

                // Main card content
                Padding(
                  padding: const EdgeInsets.all(14),
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

                      // Middle: Title & Description
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Bottom: CTA Pill Badge if provided
                      if (badgeText != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? semantic.surface.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeIcon != null) ...[
                                Icon(
                                  badgeIcon,
                                  size: 13,
                                  color: isDark
                                      ? semantic.primaryText
                                      : const Color(0xFF1E293B),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  badgeText!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? semantic.primaryText
                                        : const Color(0xFF1E293B),
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
// 7. CATEGORY CARD (Horizontal Chips)
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
      width: 90,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.22 : 0.08)
                  : (isDark ? semantic.surface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isDark
                        ? semantic.borderSubtle
                        : semantic.borderSubtle.withValues(alpha: 0.7)),
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
                // Icon Squircle Container
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: isDark ? 0.35 : 0.14)
                        : (isDark
                            ? semantic.surfaceElevated
                            : accentColor.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? accentColor : accentColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
// 8. MOTIVATIONAL QUIZ CTA CARD
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
              const Soft3DLightbulbWidget(size: 50),
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

              // Pill CTA Button (Dark pill matching reference image)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: const ShapeDecoration(
                  color: Color(0xFF18191B),
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
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
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
