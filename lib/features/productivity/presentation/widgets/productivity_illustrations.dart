import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Soft 3D Target Dartboard with an arrow/dart in the bullseye.
/// Displayed prominently in the Today Summary Card.
class Soft3DTargetDartboardWidget extends StatelessWidget {
  const Soft3DTargetDartboardWidget({super.key, this.size = 78});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TargetDartboardPainter(),
      ),
    );
  }
}

class _TargetDartboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Target center slightly shifted to bottom-left to give room for the incoming dart
    final center = Offset(w * 0.44, h * 0.54);
    final outerR = w * 0.38;

    // Target shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 4, center.dy + 6),
        width: outerR * 2.1,
        height: outerR * 2.1,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Outer 3D Bezel / Ring (Deep violet with top-left specular highlight)
    final outerRingRect = Rect.fromCircle(center: center, radius: outerR);
    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE9D5FF),
          Color(0xFFA855F7),
          Color(0xFF6B21A8),
        ],
      ).createShader(outerRingRect);
    canvas.drawCircle(center, outerR, outerPaint);

    // Ring 2: White/Cream ring with inner bevel
    final ring2R = outerR * 0.78;
    final ring2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFF3E8FF)],
      ).createShader(Rect.fromCircle(center: center, radius: ring2R));
    canvas.drawCircle(center, ring2R, ring2Paint);

    // Ring 3: Purple ring
    final ring3R = outerR * 0.52;
    final ring3Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC084FC), Color(0xFF7E22CE)],
      ).createShader(Rect.fromCircle(center: center, radius: ring3R));
    canvas.drawCircle(center, ring3R, ring3Paint);

    // Ring 4: White center ring
    final ring4R = outerR * 0.32;
    final ring4Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFEDE9FE)],
      ).createShader(Rect.fromCircle(center: center, radius: ring4R));
    canvas.drawCircle(center, ring4R, ring4Paint);

    // Bullseye center (Deep purple/indigo)
    final bullseyeR = outerR * 0.16;
    final bullseyePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9333EA), Color(0xFF581C87)],
      ).createShader(Rect.fromCircle(center: center, radius: bullseyeR));
    canvas.drawCircle(center, bullseyeR, bullseyePaint);

    // ─────────────────────────────────────────────────────────────────────────
    // DART / ARROW STRIKING BULLSEYE (angled at -40 degrees from top-right)
    // ─────────────────────────────────────────────────────────────────────────
    final dartAngle = -math.pi / 4.2; // approx -43 degrees
    final dartLength = w * 0.44;

    final tip = center; // hitting the bullseye!
    final endShaft = Offset(
      tip.dx - dartLength * math.cos(dartAngle),
      tip.dy - dartLength * math.sin(dartAngle),
    );

    // Dart shaft line
    final shaftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFE2E8F0), Color(0xFF38BDF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromPoints(tip, endShaft))
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, endShaft, shaftPaint);

    // Arrow tip highlight at impact point
    canvas.drawCircle(
      tip,
      bullseyeR * 0.7,
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      tip,
      bullseyeR * 0.35,
      Paint()..color = Colors.white,
    );

    // Dart Flights / Fletching (Cyan / Blue 3D fins at back of shaft)
    final flightLength = w * 0.14;
    final flightWing = w * 0.10;

    // Left fin
    final leftFin = Path()
      ..moveTo(endShaft.dx, endShaft.dy)
      ..lineTo(
        endShaft.dx + flightLength * 0.6 * math.cos(dartAngle) - flightWing * math.sin(dartAngle),
        endShaft.dy + flightLength * 0.6 * math.sin(dartAngle) + flightWing * math.cos(dartAngle),
      )
      ..lineTo(
        endShaft.dx + flightLength * math.cos(dartAngle),
        endShaft.dy + flightLength * math.sin(dartAngle),
      )
      ..close();

    final finPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF67E8F9), Color(0xFF0284C7)],
      ).createShader(Rect.fromCircle(center: endShaft, radius: flightLength));
    canvas.drawPath(leftFin, finPaint);

    // Right fin
    final rightFin = Path()
      ..moveTo(endShaft.dx, endShaft.dy)
      ..lineTo(
        endShaft.dx + flightLength * 0.6 * math.cos(dartAngle) + flightWing * math.sin(dartAngle),
        endShaft.dy + flightLength * 0.6 * math.sin(dartAngle) - flightWing * math.cos(dartAngle),
      )
      ..lineTo(
        endShaft.dx + flightLength * math.cos(dartAngle),
        endShaft.dy + flightLength * math.sin(dartAngle),
      )
      ..close();
    canvas.drawPath(rightFin, finPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 3D Goal Mound with billowing green flag and floating clouds.
/// Displayed in the Goal Progress Empty State.
class Soft3DGoalMoundWidget extends StatelessWidget {
  const Soft3DGoalMoundWidget({super.key, this.width = 72, this.height = 54});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GoalMoundPainter(),
      ),
    );
  }
}

class _GoalMoundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft base platform / shadow
    canvas.drawOval(
      Rect.fromLTWH(w * 0.08, h * 0.72, w * 0.84, h * 0.24),
      Paint()
        ..color = const Color(0xFFBFDBFE).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Pedestal disk
    final baseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.74, w * 0.76, h * 0.18),
      Radius.circular(h * 0.09),
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
      ).createShader(Rect.fromLTWH(w * 0.12, h * 0.74, w * 0.76, h * 0.18));
    canvas.drawRRect(baseRRect, basePaint);

    // Green hill mound
    final moundPath = Path()
      ..moveTo(w * 0.16, h * 0.76)
      ..cubicTo(w * 0.20, h * 0.44, w * 0.44, h * 0.38, w * 0.52, h * 0.38)
      ..cubicTo(w * 0.60, h * 0.38, w * 0.82, h * 0.44, w * 0.86, h * 0.76)
      ..close();

    final moundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4ADE80),
          Color(0xFF22C55E),
          Color(0xFF16A34A),
        ],
      ).createShader(Rect.fromLTWH(w * 0.16, h * 0.38, w * 0.70, h * 0.38));
    canvas.drawPath(moundPath, moundPaint);

    // Mound highlight curve
    final highlightPath = Path()
      ..moveTo(w * 0.24, h * 0.65)
      ..cubicTo(w * 0.32, h * 0.46, w * 0.50, h * 0.42, w * 0.60, h * 0.44);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Flagpole planted on hill summit
    final poleRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.48, h * 0.10, w * 0.05, h * 0.40),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(poleRRect, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawCircle(
      Offset(w * 0.505, h * 0.10),
      w * 0.035,
      Paint()..color = const Color(0xFFCBD5E1),
    );

    // Green Flag waving to right
    final flagPath = Path()
      ..moveTo(w * 0.53, h * 0.12)
      ..cubicTo(w * 0.64, h * 0.08, w * 0.74, h * 0.18, w * 0.88, h * 0.14)
      ..lineTo(w * 0.88, h * 0.34)
      ..cubicTo(w * 0.74, h * 0.38, w * 0.64, h * 0.28, w * 0.53, h * 0.32)
      ..close();

    final flagPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF86EFAC),
          Color(0xFF22C55E),
          Color(0xFF15803D),
        ],
      ).createShader(Rect.fromLTWH(w * 0.53, h * 0.08, w * 0.35, h * 0.30));
    canvas.drawPath(flagPath, flagPaint);

    // Small floating cloud on left
    _drawCloud(canvas, Offset(w * 0.16, h * 0.38), w * 0.12);
  }

  void _drawCloud(Canvas canvas, Offset center, double cloudR) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, cloudR * 0.55, cloudPaint);
    canvas.drawCircle(Offset(center.dx + cloudR * 0.45, center.dy), cloudR * 0.40, cloudPaint);
    canvas.drawCircle(Offset(center.dx - cloudR * 0.40, center.dy + 1), cloudR * 0.35, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 3D Mountain Peak with a golden summit flag.
/// Displayed on the right of the Motivation / Daily Tip Card.
class Soft3DMountainPeakWidget extends StatelessWidget {
  const Soft3DMountainPeakWidget({super.key, this.width = 76, this.height = 56});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MountainPeakPainter(),
      ),
    );
  }
}

class _MountainPeakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient shadow
    canvas.drawOval(
      Rect.fromLTWH(w * 0.10, h * 0.80, w * 0.80, h * 0.20),
      Paint()
        ..color = const Color(0xFF818CF8).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main Mountain (3D faceted low-poly style)
    // Left facet (lit)
    final leftFacet = Path()
      ..moveTo(w * 0.52, h * 0.18)
      ..lineTo(w * 0.14, h * 0.88)
      ..lineTo(w * 0.52, h * 0.88)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC7D2FE), Color(0xFF818CF8)],
      ).createShader(Rect.fromLTWH(w * 0.14, h * 0.18, w * 0.38, h * 0.70));
    canvas.drawPath(leftFacet, leftPaint);

    // Right facet (shadow)
    final rightFacet = Path()
      ..moveTo(w * 0.52, h * 0.18)
      ..lineTo(w * 0.52, h * 0.88)
      ..lineTo(w * 0.88, h * 0.88)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      ).createShader(Rect.fromLTWH(w * 0.52, h * 0.18, w * 0.36, h * 0.70));
    canvas.drawPath(rightFacet, rightPaint);

    // Snow cap on peak
    final snowCap = Path()
      ..moveTo(w * 0.52, h * 0.18)
      ..lineTo(w * 0.40, h * 0.40)
      ..lineTo(w * 0.48, h * 0.36)
      ..lineTo(w * 0.52, h * 0.42)
      ..lineTo(w * 0.58, h * 0.36)
      ..lineTo(w * 0.64, h * 0.40)
      ..close();
    canvas.drawPath(snowCap, Paint()..color = Colors.white.withValues(alpha: 0.95));

    // Summit Flagpole & Golden Flag
    final poleRect = Rect.fromLTWH(w * 0.51, h * 0.05, w * 0.035, h * 0.15);
    canvas.drawRect(poleRect, Paint()..color = const Color(0xFFE2E8F0));

    final flagPath = Path()
      ..moveTo(w * 0.54, h * 0.06)
      ..lineTo(w * 0.72, h * 0.10)
      ..lineTo(w * 0.54, h * 0.15)
      ..close();

    final flagPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
      ).createShader(Rect.fromLTWH(w * 0.54, h * 0.06, w * 0.18, h * 0.10));
    canvas.drawPath(flagPath, flagPaint);

    // Floating Clouds
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Cloud on left
    canvas.drawCircle(Offset(w * 0.18, h * 0.74), w * 0.07, cloudPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.76), w * 0.06, cloudPaint);

    // Cloud on right
    canvas.drawCircle(Offset(w * 0.82, h * 0.74), w * 0.08, cloudPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.76), w * 0.06, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 3D 4-pointed Sparkle (`✦`) with specular highlight.
class Soft3DSparkleWidget extends StatelessWidget {
  const Soft3DSparkleWidget({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparklePainter(),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final outerR = w * 0.48;
    final innerR = w * 0.12;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final double outerAngle = -math.pi / 2 + (i * math.pi / 2);
      final double innerAngle = outerAngle + (math.pi / 4);

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

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC084FC), Color(0xFF7C3AED)],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));
    canvas.drawPath(path, paint);

    // Center specular white dot
    canvas.drawCircle(center, w * 0.08, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 3D Gamified Fire / Flame icon with multi-layered glow.
/// Displayed on the Habits Hero Banner and Streak Card.
class Soft3DFireWidget extends StatelessWidget {
  const Soft3DFireWidget({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Soft3DFirePainter(),
      ),
    );
  }
}

class _Soft3DFirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient warm glow shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.65),
        width: w * 0.75,
        height: h * 0.65,
      ),
      Paint()
        ..color = const Color(0xFFEA580C).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Outer flame body
    final outerPath = Path()
      ..moveTo(w * 0.50, h * 0.08) // flame tip
      ..cubicTo(w * 0.68, h * 0.26, w * 0.88, h * 0.44, w * 0.88, h * 0.66)
      ..cubicTo(w * 0.88, h * 0.86, w * 0.70, h * 0.94, w * 0.50, h * 0.94)
      ..cubicTo(w * 0.30, h * 0.94, w * 0.12, h * 0.86, w * 0.12, h * 0.66)
      ..cubicTo(w * 0.12, h * 0.48, w * 0.28, h * 0.34, w * 0.38, h * 0.38)
      ..cubicTo(w * 0.36, h * 0.30, w * 0.44, h * 0.18, w * 0.50, h * 0.08)
      ..close();

    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFA500),
          Color(0xFFF97316),
          Color(0xFFEF4444),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(outerPath, outerPaint);

    // Specular highlight along the left side
    final highlightPath = Path()
      ..moveTo(w * 0.48, h * 0.16)
      ..cubicTo(w * 0.36, h * 0.26, w * 0.20, h * 0.48, w * 0.20, h * 0.66)
      ..cubicTo(w * 0.20, h * 0.76, w * 0.26, h * 0.84, w * 0.36, h * 0.88);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Middle flame tongue (Vibrant yellow/orange)
    final midFlamePath = Path()
      ..moveTo(w * 0.54, h * 0.36)
      ..cubicTo(w * 0.70, h * 0.52, w * 0.74, h * 0.68, w * 0.72, h * 0.78)
      ..cubicTo(w * 0.70, h * 0.90, w * 0.58, h * 0.93, w * 0.50, h * 0.93)
      ..cubicTo(w * 0.40, h * 0.93, w * 0.30, h * 0.86, w * 0.30, h * 0.74)
      ..cubicTo(w * 0.30, h * 0.60, w * 0.44, h * 0.48, w * 0.54, h * 0.36)
      ..close();

    final midPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFFBBF24),
          Color(0xFFF59E0B),
        ],
      ).createShader(Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.50, h * 0.60));
    canvas.drawPath(midFlamePath, midPaint);

    // Inner bright core (Warm white-yellow drop)
    final innerPath = Path()
      ..moveTo(w * 0.52, h * 0.58)
      ..cubicTo(w * 0.62, h * 0.70, w * 0.62, h * 0.82, w * 0.52, h * 0.88)
      ..cubicTo(w * 0.44, h * 0.88, w * 0.40, h * 0.80, w * 0.42, h * 0.72)
      ..cubicTo(w * 0.44, h * 0.64, w * 0.50, h * 0.62, w * 0.52, h * 0.58)
      ..close();

    final innerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFEF9C3),
          Color(0xFFFDE047),
        ],
      ).createShader(Rect.fromLTWH(w * 0.38, h * 0.55, w * 0.25, h * 0.35));
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft 3D Gamified Clipboard with checklist illustration.
/// Displayed on the Tasks Hero Banner and Empty / Caught Up Card.
class Soft3DClipboardWidget extends StatelessWidget {
  const Soft3DClipboardWidget({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _Soft3DClipboardPainter(),
      ),
    );
  }
}

class _Soft3DClipboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.54),
          width: w * 0.76,
          height: h * 0.84,
        ),
        Radius.circular(w * 0.20),
      ),
      Paint()
        ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // 1. Board Backing (Soft Royal Blue squircle)
    final boardRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.52),
      width: w * 0.78,
      height: h * 0.84,
    );
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(w * 0.20),
    );
    final boardPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF60A5FA),
          Color(0xFF3B82F6),
          Color(0xFF1D4ED8),
        ],
      ).createShader(boardRect);
    canvas.drawRRect(boardRRect, boardPaint);

    // 2. White Paper Sheet
    final paperRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.56),
      width: w * 0.62,
      height: h * 0.68,
    );
    final paperRRect = RRect.fromRectAndRadius(
      paperRect,
      Radius.circular(w * 0.12),
    );
    final paperPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF1F5F9),
        ],
      ).createShader(paperRect);
    canvas.drawRRect(paperRRect, paperPaint);

    // 3. Top Blue / Silver Clip
    final clipRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.21),
      width: w * 0.32,
      height: h * 0.11,
    );
    final clipRRect = RRect.fromRectAndRadius(
      clipRect,
      Radius.circular(w * 0.05),
    );
    final clipPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Color(0xFF64748B),
        ],
      ).createShader(clipRect);
    canvas.drawRRect(clipRRect, clipPaint);

    // 4. Checklist items on paper
    final checkColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF22C55E),
      const Color(0xFF38BDF8),
    ];
    final startY = h * 0.38;
    final rowSpacing = h * 0.14;

    for (int i = 0; i < 3; i++) {
      final y = startY + i * rowSpacing;

      // Circle checkmark badge
      final checkCenter = Offset(w * 0.30, y);
      final checkR = w * 0.052;
      canvas.drawCircle(
        checkCenter,
        checkR,
        Paint()..color = checkColors[i],
      );

      // Mini white checkmark inside
      final checkPath = Path()
        ..moveTo(checkCenter.dx - checkR * 0.45, checkCenter.dy)
        ..lineTo(checkCenter.dx - checkR * 0.10, checkCenter.dy + checkR * 0.40)
        ..lineTo(checkCenter.dx + checkR * 0.50, checkCenter.dy - checkR * 0.35);
      canvas.drawPath(
        checkPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Horizontal item text line
      final lineWidth = i == 1 ? w * 0.26 : w * 0.34;
      final lineRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, y - h * 0.015, lineWidth, h * 0.030),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        lineRRect,
        Paint()..color = const Color(0xFFCBD5E1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

