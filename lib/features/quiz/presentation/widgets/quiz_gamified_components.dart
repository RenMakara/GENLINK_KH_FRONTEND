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
  const Soft3DStatsCheckIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StatsCheckPainter(),
      ),
    );
  }
}

class _StatsCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sparkle top-right
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.16), w * 0.08, Colors.white);

    // Drop shadow
    final badgeRect = Rect.fromCenter(
      center: Offset(w * 0.48, h * 0.52),
      width: w * 0.76,
      height: h * 0.76,
    );
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, Radius.circular(w * 0.24));
    canvas.drawRRect(
      badgeRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF044E2E).withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Badge Base: Frosted White-to-Mint Pearlescent Gradient
    final badgePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFE6FAF0),
          Color(0xFFC7F3DE),
        ],
      ).createShader(badgeRect);
    canvas.drawRRect(badgeRRect, badgePaint);

    // Inner rim stroke
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3D Dimensional Emerald Checkmark
    final checkPath = Path()
      ..moveTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.44, h * 0.66)
      ..lineTo(w * 0.68, h * 0.38);

    // Checkmark drop shadow
    canvas.drawPath(
      checkPath.shift(const Offset(0.5, 1.5)),
      Paint()
        ..color = const Color(0xFF047857).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Checkmark gradient fill
    final checkPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF10B981),
          Color(0xFF059669),
          Color(0xFF047857),
        ],
      ).createShader(badgeRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(checkPath, checkPaint);

    // Highlight on top corner of checkmark
    final highlightPath = Path()
      ..moveTo(w * 0.30, h * 0.51)
      ..lineTo(w * 0.44, h * 0.65)
      ..lineTo(w * 0.68, h * 0.37);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Soft3DStatsDocIcon extends StatelessWidget {
  const Soft3DStatsDocIcon({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StatsDocPainter(),
      ),
    );
  }
}

class _StatsDocPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sparkle top-right
    _drawSparkle(canvas, Offset(w * 0.88, h * 0.16), w * 0.08, Colors.white);

    // Document Paper Body
    final docRect = Rect.fromCenter(
      center: Offset(w * 0.48, h * 0.52),
      width: w * 0.64,
      height: h * 0.74,
    );
    final docRRect = RRect.fromRectAndRadius(docRect, Radius.circular(w * 0.12));

    // Drop shadow under document
    canvas.drawRRect(
      docRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Document fill: Crisp White-to-Cyan Pearlescent
    final docPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color(0xFFF0F9FF),
          Color(0xFFE0F2FE),
        ],
      ).createShader(docRect);
    canvas.drawRRect(docRRect, docPaint);

    // Document border
    canvas.drawRRect(
      docRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 3 Content Lines on document (Blue tones)
    final linePaint1 = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final linePaint2 = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final linePaint3 = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Top primary header line
    canvas.drawLine(Offset(w * 0.30, h * 0.35), Offset(w * 0.66, h * 0.35), linePaint1);
    // Middle line
    canvas.drawLine(Offset(w * 0.30, h * 0.48), Offset(w * 0.62, h * 0.48), linePaint2);
    // Bottom line
    canvas.drawLine(Offset(w * 0.30, h * 0.61), Offset(w * 0.50, h * 0.61), linePaint3);

    // Small decorative blue tag at top-left
    canvas.drawCircle(
      Offset(w * 0.24, h * 0.22),
      w * 0.05,
      Paint()..color = const Color(0xFF38BDF8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
// 3. BACKGROUND WATERMARK PAINTERS
// ============================================================================

/// Faint upward bar chart watermark for the Completed Quizzes stat card.
class StatsGreenBarWatermarkPainter extends CustomPainter {
  const StatsGreenBarWatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final barW = w * 0.07;
    final r = Radius.circular(barW * 0.5);

    // 4 vertical bar pills rising from right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.62, h * 0.74, barW, h * 0.26),
        r,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72, h * 0.62, barW, h * 0.38),
        r,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.82, h * 0.50, barW, h * 0.50),
        r,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.92, h * 0.36, barW, h * 0.64),
        r,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Faint flowing curve / document wave watermark for the Available Quizzes stat card.
class StatsBlueWaveWatermarkPainter extends CustomPainter {
  const StatsBlueWaveWatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.13)
      ..style = PaintingStyle.fill;

    // Soft concentric circular wave arcs in the bottom right corner
    canvas.drawCircle(Offset(w * 0.98, h * 0.90), w * 0.30, paint);
    canvas.drawCircle(Offset(w * 0.86, h * 0.98), w * 0.20, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Faint golden stars & sparkles floating in the hero card background.
class HeroCardSparklesPainter extends CustomPainter {
  const HeroCardSparklesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden stars in background
    _drawStar(canvas, Offset(w * 0.66, h * 0.16), 6.5, const Color(0xFFFBBF24).withValues(alpha: 0.65));
    _drawStar(canvas, Offset(w * 0.94, h * 0.20), 5.5, const Color(0xFFF59E0B).withValues(alpha: 0.55));
    _drawStar(canvas, Offset(w * 0.88, h * 0.38), 7.5, const Color(0xFFFBBF24).withValues(alpha: 0.60));
    _drawStar(canvas, Offset(w * 0.62, h * 0.34), 5.0, const Color(0xFFFDE047).withValues(alpha: 0.70));
    _drawSparkle(canvas, Offset(w * 0.74, h * 0.10), 4.5, const Color(0xFFF59E0B).withValues(alpha: 0.65));
    _drawSparkle(canvas, Offset(w * 0.96, h * 0.56), 5.5, const Color(0xFFFBBF24).withValues(alpha: 0.55));

    // Soft background glow circle behind trophy
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.28),
      w * 0.24,
      Paint()
        ..color = const Color(0xFFFDE047).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Faint golden stars & sparkles floating in the motivation CTA card background.
class MotivationCardSparklesPainter extends CustomPainter {
  const MotivationCardSparklesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawStar(canvas, Offset(w * 0.60, h * 0.28), 6.0, const Color(0xFFFBBF24).withValues(alpha: 0.6));
    _drawStar(canvas, Offset(w * 0.67, h * 0.74), 5.0, const Color(0xFFF59E0B).withValues(alpha: 0.55));
    _drawSparkle(canvas, Offset(w * 0.64, h * 0.82), 4.5, const Color(0xFFFBBF24).withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// Grow-Consistent Watermarks (Wave, Leaf, Mountain, Rings, Star, BarChart)
// ----------------------------------------------------------------------------

/// Soft wave curve watermark (matches Grow Tasks)
class QuizWaveWatermark extends StatelessWidget {
  const QuizWaveWatermark({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QuizWaveWatermarkPainter(),
      ),
    );
  }
}

class _QuizWaveWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(size.width * 0.35, size.height * 0.45, size.width * 0.65,
          size.height * 0.85, size.width, size.height * 0.65);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.95)
      ..cubicTo(size.width * 0.35, size.height * 0.75, size.width * 0.65,
          size.height * 1.15, size.width, size.height * 0.95);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft curved leaf / botanical watermark (matches Grow Habits)
class QuizLeafWatermark extends StatelessWidget {
  const QuizLeafWatermark({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QuizLeafWatermarkPainter(),
      ),
    );
  }
}

class _QuizLeafWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..cubicTo(size.width * 0.15, size.height * 0.30, size.width * 0.50,
          size.height * 0.15, size.width * 0.85, size.height * 0.15)
      ..cubicTo(size.width * 0.85, size.height * 0.70, size.width * 0.50,
          size.height * 0.85, size.width * 0.15, size.height * 0.85);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mountain terrain silhouette watermark (matches Grow Goals)
class QuizMountainWatermark extends StatelessWidget {
  const QuizMountainWatermark({super.key, this.size = 58});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.8,
      child: CustomPaint(
        painter: _QuizMountainWatermarkPainter(),
      ),
    );
  }
}

class _QuizMountainWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.22)
      ..lineTo(size.width * 0.65, size.height * 0.58)
      ..lineTo(size.width * 0.85, size.height * 0.34)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Concentric rings watermark (matches Grow Focus)
class QuizRingsWatermark extends StatelessWidget {
  const QuizRingsWatermark({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QuizRingsWatermarkPainter(),
      ),
    );
  }
}

class _QuizRingsWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width, size.height);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawCircle(center, size.width * 0.40, paint);
    canvas.drawCircle(center, size.width * 0.70, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 5-point star watermark (matches Grow Quiz)
class QuizStarWatermark extends StatelessWidget {
  const QuizStarWatermark({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _QuizStarWatermarkPainter(),
      ),
    );
  }
}

class _QuizStarWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.60, size.height * 0.60);
    final outerR = size.width * 0.38;
    final innerR = size.width * 0.18;

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double outerAngle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final double innerAngle = outerAngle + (math.pi / 5);

      final double ox = center.dx + outerR * math.cos(outerAngle);
      final double oy = center.dy + outerR * math.sin(outerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }

      final double ix = center.dx + innerR * math.cos(innerAngle);
      final double iy = center.dy + innerR * math.sin(innerAngle);
      path.lineTo(ix, iy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft rising bar chart watermark (matches Grow Leaderboard)
class QuizBarChartWatermark extends StatelessWidget {
  const QuizBarChartWatermark({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.92,
      child: CustomPaint(
        painter: _QuizBarChartWatermarkPainter(),
      ),
    );
  }
}

class _QuizBarChartWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.60, size.width * 0.20,
            size.height * 0.40),
        const Radius.circular(3),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.44, size.height * 0.25, size.width * 0.20,
            size.height * 0.75),
        const Radius.circular(3),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.70, size.height * 0.42, size.width * 0.20,
            size.height * 0.58),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 4. HEADER COMPONENT
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
            // Circular iOS-style Back Button
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
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
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

            // Circular Notification Button with red dot badge
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
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
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
// 5. QUIZ XP HERO CARD (With Inner XP Progress Container & Floating Sparkles)
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
    final percent = (stats.levelProgress.clamp(0.0, 1.0) * 100).toInt();
    final displayName = stats.name.trim().isNotEmpty ? stats.name.trim() : 'Learner';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF3B2E15),
                  const Color(0xFF231A0B),
                ]
              : [
                  const Color(0xFFFED766),
                  const Color(0xFFFBBF24),
                  const Color(0xFFF59E0B),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.20 : 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.30 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Top-left ambient radial highlight (Grow signature highlight)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -0.8),
                    radius: 1.1,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Subtle corner star watermark
            const Positioned(
              right: -4,
              bottom: -4,
              child: Opacity(
                opacity: 0.16,
                child: QuizStarWatermark(size: 64),
              ),
            ),

            // Faint floating stars & background sparkles
            const Positioned.fill(
              child: CustomPaint(painter: HeroCardSparklesPainter()),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section: Avatar, Greeting, Badges, 3D Trophy
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with Online Status Indicator Dot
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
                              'quiz.dashboardGreeting'.trParams({'name': displayName}),
                              style: textTheme.titleMedium?.copyWith(
                                color: semantic.primaryText,
                                fontWeight: FontWeight.w800,
                                fontSize: 17.5,
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
                                // Level Pill: 👑 Level X
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('👑 ', style: TextStyle(fontSize: 10)),
                                      Text(
                                        'quiz.level'.trParams({'level': '${stats.level}'}),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Explorer Rank Pill: 🌱 Explorer
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
                                            fontWeight: FontWeight.w800,
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
                      const Soft3DTrophyWidget(size: 82),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Inner XP Progress Card Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? semantic.surface.withValues(alpha: 0.70)
                          : Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? semantic.borderSubtle : Colors.white,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB45309).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: XP fraction & Progress percent
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${stats.xp} / ${stats.xpToNextLevel} XP',
                              style: textTheme.bodyMedium?.copyWith(
                                color: semantic.primaryText,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rounded XP Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: stats.levelProgress.clamp(0.02, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFBBF24),
                                      Color(0xFFF59E0B),
                                      Color(0xFFEA580C),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle: "Only 51 XP to Level 24"
                        Text(
                          'quiz.xpToNextLevel'.trParams({'xp': '$xpRemaining'}),
                          style: textTheme.bodySmall?.copyWith(
                            color: semantic.secondaryText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

// ============================================================================
// 6. QUIZ STATISTICS SECTION (Two Distinct Side-by-Side Gamified Mini Cards)
// ============================================================================

class QuizStatsCard extends StatelessWidget {
  const QuizStatsCard({
    super.key,
    required this.completedCount,
    required this.availableCount,
    this.onCompletedTap,
    this.onAvailableTap,
  });

  final int completedCount;
  final int availableCount;
  final VoidCallback? onCompletedTap;
  final VoidCallback? onAvailableTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Completed Quizzes Card (Goals Green)
          Expanded(
            child: QuizStatMiniCard(
              icon: const Soft3DStatsCheckIcon(size: 38),
              count: '$completedCount',
              title: 'quiz.completedQuizzes'.tr,
              supportingIcon: Icons.trending_up_rounded,
              supportingText: 'quiz.plusOneThisWeek'.tr,
              supportingColor: const Color(0xFF10B981),
              darkSupportingColor: const Color(0xFF86EFAC),
              gradient: const [
                Color(0xFF55E59B),
                Color(0xFF13AF6A),
              ],
              darkGradient: const [
                Color(0xFF107347),
                Color(0xFF094C2E),
              ],
              shadowColor: const Color(0xFF13AF6A),
              watermark: const QuizBarChartWatermark(),
              bgWatermark: const StatsGreenBarWatermarkPainter(),
              onTap: onCompletedTap,
            ),
          ),
          const SizedBox(width: 12),

          // 2. Available Quizzes Card (Tasks Blue)
          Expanded(
            child: QuizStatMiniCard(
              icon: const Soft3DStatsDocIcon(size: 38),
              count: '$availableCount',
              title: 'quiz.availableQuizzes'.tr,
              supportingIcon: Icons.menu_book_rounded,
              supportingText: 'quiz.keepLearning'.tr,
              supportingColor: const Color(0xFF2563EB),
              darkSupportingColor: const Color(0xFF93C5FD),
              gradient: const [
                Color(0xFF5292F7),
                Color(0xFF2563EB),
              ],
              darkGradient: const [
                Color(0xFF1E40AF),
                Color(0xFF172554),
              ],
              shadowColor: const Color(0xFF2563EB),
              watermark: const QuizWaveWatermark(),
              bgWatermark: const StatsBlueWaveWatermarkPainter(),
              onTap: onAvailableTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single gamified mini statistics card with 3D icon, bold number, label,
/// trend pill, ambient radial highlight, and decorative Grow watermark.
class QuizStatMiniCard extends StatefulWidget {
  const QuizStatMiniCard({
    super.key,
    required this.icon,
    required this.count,
    required this.title,
    required this.supportingIcon,
    required this.supportingText,
    required this.supportingColor,
    required this.darkSupportingColor,
    this.bgWatermark,
    this.gradient,
    this.darkGradient,
    this.shadowColor,
    this.watermark,
    this.onTap,
  });

  final Widget icon;
  final String count;
  final String title;
  final IconData supportingIcon;
  final String supportingText;
  final Color supportingColor;
  final Color darkSupportingColor;
  final CustomPainter? bgWatermark;
  final List<Color>? gradient;
  final List<Color>? darkGradient;
  final Color? shadowColor;
  final Widget? watermark;
  final VoidCallback? onTap;

  @override
  State<QuizStatMiniCard> createState() => _QuizStatMiniCardState();
}

class _QuizStatMiniCardState extends State<QuizStatMiniCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final gradientColors = widget.gradient ??
        (isDark
            ? const [Color(0xFF107347), Color(0xFF094C2E)]
            : const [Color(0xFF55E59B), Color(0xFF13AF6A)]);
    final darkGrad = widget.darkGradient ?? gradientColors;
    final effectiveGradient = isDark ? darkGrad : gradientColors;
    final effectiveShadow = widget.shadowColor ?? effectiveGradient.last;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: effectiveGradient,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveShadow.withValues(alpha: isDark ? 0.38 : 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Bottom-right watermark
                if (widget.watermark != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Opacity(
                      opacity: 0.16,
                      child: widget.watermark!,
                    ),
                  )
                else if (widget.bgWatermark != null)
                  Positioned.fill(
                    child: CustomPaint(painter: widget.bgWatermark!),
                  ),

                // Top-left ambient radial highlight (Grow signature highlight)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.8, -0.8),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: 3D Squircle Icon & Translucent Circular Arrow Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          widget.icon,
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Large Number (White high contrast)
                      Text(
                        widget.count,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Label (White 92% opacity)
                      Text(
                        widget.title,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Supporting trend / subtext capsule
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.supportingIcon,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.supportingText,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
// 7. CHOOSE YOUR CHALLENGE CARD (Vibrant 3D Gradient Card with White Pill)
// ============================================================================

class QuizChallengeCard extends StatefulWidget {
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
    this.glowColor,
    this.badgeText,
    this.badgeIcon,
    this.badgeIconColor,
    this.watermark,
    this.bgPainter,
  });

  final String title;
  final String description;
  final Widget icon;
  final List<Color> gradientColors;
  final List<Color> darkGradientColors;
  final Color? glowColor;
  final Color borderColor;
  final Color darkBorderColor;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;
  final Color? badgeIconColor;
  final Widget? watermark;
  final CustomPainter? bgPainter;

  @override
  State<QuizChallengeCard> createState() => _QuizChallengeCardState();
}

class _QuizChallengeCardState extends State<QuizChallengeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = widget.glowColor ?? widget.gradientColors.first;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? widget.darkGradientColors : widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? widget.darkBorderColor : widget.borderColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withValues(alpha: isDark ? 0.38 : 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Corner Watermark or background shape
                if (widget.watermark != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Opacity(
                      opacity: 0.16,
                      child: widget.watermark!,
                    ),
                  )
                else if (widget.bgPainter != null)
                  Positioned.fill(
                    child: CustomPaint(painter: widget.bgPainter!),
                  ),

                // Top-left ambient radial highlight (Grow signature highlight)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.8, -0.8),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Card Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: 3D Illustration & Translucent White Circular Arrow Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.icon,
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Middle: Title & Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Bottom: Action Pill Badge
                      if (widget.badgeText != null) ...[
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.badgeIcon != null) ...[
                                Icon(
                                  widget.badgeIcon,
                                  size: 12.5,
                                  color: widget.badgeIconColor ?? const Color(0xFF0F172A),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  widget.badgeText!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
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
// 8. CATEGORY CARD (Horizontal Chips with 3D Squircle Icons)
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
      width: 78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? accentColor.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.10))
                  : (isDark ? semantic.surface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isDark
                        ? semantic.borderSubtle
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isDark || !isSelected
                  ? (isDark
                      ? const []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ])
                  : [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.16),
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
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? accentColor.withValues(alpha: 0.35) : accentColor.withValues(alpha: 0.18))
                        : (isDark
                            ? accentColor.withValues(alpha: 0.18)
                            : accentColor.withValues(alpha: 0.10)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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
// 9. MOTIVATIONAL QUIZ CTA CARD (Warm Gold with 3D Lightbulb & Dark Pill Button)
// ============================================================================

class QuizMotivationCard extends StatefulWidget {
  const QuizMotivationCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<QuizMotivationCard> createState() => _QuizMotivationCardState();
}

class _QuizMotivationCardState extends State<QuizMotivationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
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
                      const Color(0xFFFDE68A),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Floating sparkles background
                const Positioned.fill(
                  child: CustomPaint(painter: MotivationCardSparklesPainter()),
                ),
                Row(
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
                              fontSize: 11,
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
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
