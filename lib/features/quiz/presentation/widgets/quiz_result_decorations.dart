import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative confetti background for quiz celebration screens.
class CelebrationConfettiWidget extends StatelessWidget {
  const CelebrationConfettiWidget({super.key, this.height = 360});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: const CustomPaint(
          painter: _CelebrationConfettiPainter(),
        ),
      ),
    );
  }
}

class _CelebrationConfettiPainter extends CustomPainter {
  const _CelebrationConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fixed confetti items with normalized positions, sizes, angles, and colors
    const items = [
      // Top-left
      _ConfettiItem(0.08, 0.12, 10, 4, 0.35, Color(0xFF60A5FA), _ConfettiShape.rect),
      _ConfettiItem(0.18, 0.08, 7, 7, 0, Color(0xFFFBBF24), _ConfettiShape.circle),
      _ConfettiItem(0.06, 0.28, 8, 4, -0.4, Color(0xFF818CF8), _ConfettiShape.rect),
      _ConfettiItem(0.24, 0.22, 5, 5, 0, Color(0xFFF472B6), _ConfettiShape.circle),
      _ConfettiItem(0.14, 0.40, 11, 4.5, 0.5, Color(0xFF34D399), _ConfettiShape.rect),
      _ConfettiItem(0.04, 0.56, 8, 4, -0.6, Color(0xFF818CF8), _ConfettiShape.rect),
      _ConfettiItem(0.20, 0.52, 6, 6, 0, Color(0xFFFBBF24), _ConfettiShape.diamond),

      // Top-center
      _ConfettiItem(0.38, 0.10, 9, 4, -0.25, Color(0xFFF472B6), _ConfettiShape.rect),
      _ConfettiItem(0.50, 0.06, 6, 6, 0, Color(0xFF60A5FA), _ConfettiShape.circle),
      _ConfettiItem(0.62, 0.09, 8, 4, 0.45, Color(0xFF34D399), _ConfettiShape.rect),

      // Top-right
      _ConfettiItem(0.78, 0.11, 10, 4.5, 0.3, Color(0xFFF472B6), _ConfettiShape.rect),
      _ConfettiItem(0.92, 0.15, 6, 6, 0, Color(0xFFEF4444), _ConfettiShape.circle),
      _ConfettiItem(0.86, 0.25, 6, 6, 0, Color(0xFFFBBF24), _ConfettiShape.diamond),
      _ConfettiItem(0.74, 0.28, 9, 4, -0.5, Color(0xFF60A5FA), _ConfettiShape.rect),
      _ConfettiItem(0.94, 0.38, 8, 4, 0.4, Color(0xFF34D399), _ConfettiShape.rect),
      _ConfettiItem(0.84, 0.48, 10, 4, -0.3, Color(0xFFFBBF24), _ConfettiShape.rect),
      _ConfettiItem(0.96, 0.54, 7, 7, 0, Color(0xFF34D399), _ConfettiShape.circle),
    ];

    for (final item in items) {
      final cx = item.nx * w;
      final cy = item.ny * h;

      canvas.save();
      canvas.translate(cx, cy);
      if (item.angle != 0) {
        canvas.rotate(item.angle);
      }

      final paint = Paint()
        ..color = item.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      switch (item.shape) {
        case _ConfettiShape.rect:
          final rrect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: item.w, height: item.h),
            const Radius.circular(2),
          );
          canvas.drawRRect(rrect, paint);
          break;
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, item.w / 2, paint);
          break;
        case _ConfettiShape.diamond:
          final path = Path()
            ..moveTo(0, -item.h / 2)
            ..lineTo(item.w / 2, 0)
            ..lineTo(0, item.h / 2)
            ..lineTo(-item.w / 2, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _ConfettiShape { rect, circle, diamond }

class _ConfettiItem {
  const _ConfettiItem(
    this.nx,
    this.ny,
    this.w,
    this.h,
    this.angle,
    this.color,
    this.shape,
  );

  final double nx;
  final double ny;
  final double w;
  final double h;
  final double angle;
  final Color color;
  final _ConfettiShape shape;
}

/// 3D Golden Trophy with handles, center star, and pedestal base.
class GoldenTrophyWidget extends StatelessWidget {
  const GoldenTrophyWidget({
    super.key,
    this.size = 130,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _GoldenTrophyPainter(),
      ),
    );
  }
}

class _GoldenTrophyPainter extends CustomPainter {
  const _GoldenTrophyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Contact shadow beneath pedestal base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.94),
        width: w * 0.52,
        height: h * 0.12,
      ),
      Paint()
        ..color = const Color(0x28000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 1. Pedestal Bottom Base (dark amber/brown wood pedestal)
    final baseRect1 = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.88),
      width: w * 0.44,
      height: h * 0.10,
    );
    final baseRRect1 = RRect.fromRectAndRadius(baseRect1, Radius.circular(h * 0.03));
    final basePaint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB45309), Color(0xFF78350F)],
      ).createShader(baseRect1);
    canvas.drawRRect(baseRRect1, basePaint1);

    // 2. Pedestal Top Tier
    final baseRect2 = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.82),
      width: w * 0.32,
      height: h * 0.07,
    );
    final baseRRect2 = RRect.fromRectAndRadius(baseRect2, Radius.circular(h * 0.02));
    final basePaint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD97706), Color(0xFF92400E)],
      ).createShader(baseRect2);
    canvas.drawRRect(baseRRect2, basePaint2);

    // 3. Stem / Neck
    final stemPath = Path()
      ..moveTo(w * 0.42, h * 0.79)
      ..lineTo(w * 0.58, h * 0.79)
      ..lineTo(w * 0.54, h * 0.65)
      ..lineTo(w * 0.46, h * 0.65)
      ..close();
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
      ).createShader(Rect.fromLTWH(w * 0.42, h * 0.65, w * 0.16, h * 0.14));
    canvas.drawPath(stemPath, stemPaint);

    // Stem ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.72), width: w * 0.18, height: h * 0.04),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = const Color(0xFFF59E0B),
    );

    // 4. Handles (Left and Right)
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B), Color(0xFFB45309)],
      ).createShader(Rect.fromLTWH(w * 0.10, h * 0.20, w * 0.80, h * 0.40))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round;

    // Left handle
    final leftHandlePath = Path()
      ..moveTo(w * 0.32, h * 0.25)
      ..cubicTo(w * 0.08, h * 0.22, w * 0.08, h * 0.52, w * 0.34, h * 0.48);
    canvas.drawPath(leftHandlePath, handlePaint);

    // Right handle
    final rightHandlePath = Path()
      ..moveTo(w * 0.68, h * 0.25)
      ..cubicTo(w * 0.92, h * 0.22, w * 0.92, h * 0.52, w * 0.66, h * 0.48);
    canvas.drawPath(rightHandlePath, handlePaint);

    // 5. Trophy Cup Body
    final cupPath = Path()
      ..moveTo(w * 0.25, h * 0.21)
      ..cubicTo(w * 0.26, h * 0.52, w * 0.38, h * 0.67, w * 0.50, h * 0.67)
      ..cubicTo(w * 0.62, h * 0.67, w * 0.74, h * 0.52, w * 0.75, h * 0.21)
      ..close();

    final cupRect = Rect.fromLTWH(w * 0.25, h * 0.21, w * 0.50, h * 0.46);
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
      ).createShader(cupRect);
    canvas.drawPath(cupPath, cupPaint);

    // 6. Trophy Rim (Oval Lip)
    final rimRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.21),
      width: w * 0.50,
      height: h * 0.10,
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
        center: Offset(w * 0.50, h * 0.21),
        width: w * 0.42,
        height: h * 0.06,
      ),
      Paint()..color = const Color(0xFFD97706),
    );

    // 7. Center White Star on Cup
    _drawStar(
      canvas,
      Offset(w * 0.50, h * 0.40),
      radius: w * 0.085,
      innerRadius: w * 0.040,
      color: Colors.white,
    );

    // 8. Sparkles (top-right and top-left)
    _drawSparkle(canvas, Offset(w * 0.68, h * 0.12), w * 0.04, const Color(0xFFF59E0B));
    _drawSparkle(canvas, Offset(w * 0.32, h * 0.12), w * 0.035, const Color(0xFFFDE047));
  }

  void _drawStar(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double innerRadius,
    required Color color,
  }) {
    final path = Path();
    const points = 5;
    const double step = math.pi / points;
    double angle = -math.pi / 2;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();

    // Subtle star shadow
    canvas.drawPath(
      path.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0x30B45309)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Friendly Robot Mascot matching the reference image.
class RobotMascotWidget extends StatelessWidget {
  const RobotMascotWidget({
    super.key,
    this.width = 54,
    this.height = 62,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(
        painter: _RobotMascotPainter(),
      ),
    );
  }
}

class _RobotMascotPainter extends CustomPainter {
  const _RobotMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Contact shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.96), width: w * 0.55, height: h * 0.08),
      Paint()
        ..color = const Color(0x18000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 1. Cute Stubby Legs
    final legPaint = Paint()..color = const Color(0xFFCBD5E1);
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.34, h * 0.82, w * 0.12, h * 0.14),
        Radius.circular(w * 0.06),
      ),
      legPaint,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.54, h * 0.82, w * 0.12, h * 0.14),
        Radius.circular(w * 0.06),
      ),
      legPaint,
    );

    // 2. Cute Little Arms
    final armPaint = Paint()..color = const Color(0xFFCBD5E1);
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.14, h * 0.65), width: w * 0.12, height: h * 0.14),
        Radius.circular(w * 0.06),
      ),
      armPaint,
    );
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.86, h * 0.65), width: w * 0.12, height: h * 0.14),
        Radius.circular(w * 0.06),
      ),
      armPaint,
    );

    // 3. Body
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.67),
      width: w * 0.54,
      height: h * 0.32,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.20));
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
      ).createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Chest indicator / button
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.67),
      w * 0.065,
      Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.67),
      w * 0.03,
      Paint()..color = Colors.white,
    );

    // 4. Neck connector
    canvas.drawRect(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.51), width: w * 0.16, height: h * 0.05),
      Paint()..color = const Color(0xFF94A3B8),
    );

    // 5. Antenna
    // Antenna rod
    canvas.drawLine(
      Offset(w * 0.50, h * 0.20),
      Offset(w * 0.50, h * 0.11),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // Antenna tip bead
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.10),
      w * 0.045,
      Paint()..color = const Color(0xFF38BDF8),
    );

    // 6. Head
    // Ears
    canvas.drawCircle(Offset(w * 0.19, h * 0.36), w * 0.05, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(Offset(w * 0.81, h * 0.36), w * 0.05, Paint()..color = const Color(0xFF94A3B8));

    // Head casing
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.36),
      width: w * 0.60,
      height: h * 0.32,
    );
    final headRRect = RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.16));
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
      ).createShader(headRect);
    canvas.drawRRect(headRRect, headPaint);
    canvas.drawRRect(
      headRRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 7. Visor / Face Screen
    final visorRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.36),
      width: w * 0.44,
      height: h * 0.18,
    );
    final visorRRect = RRect.fromRectAndRadius(visorRect, Radius.circular(w * 0.08));
    canvas.drawRRect(visorRRect, Paint()..color = const Color(0xFF0F172A));

    // Glowing cyan eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Left eye slit/curve
    canvas.drawLine(
      Offset(w * 0.38, h * 0.36),
      Offset(w * 0.44, h * 0.36),
      eyePaint,
    );
    // Right eye slit/curve
    canvas.drawLine(
      Offset(w * 0.56, h * 0.36),
      Offset(w * 0.62, h * 0.36),
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stack of 3 books with graduation cap on top (bottom-left illustration).
class BookStackGradCapWidget extends StatelessWidget {
  const BookStackGradCapWidget({super.key, this.width = 64, this.height = 54});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(
        painter: _BookStackPainter(),
      ),
    );
  }
}

class _BookStackPainter extends CustomPainter {
  const _BookStackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Bottom Book (Soft Blue)
    final b1Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.88), width: w * 0.82, height: h * 0.18),
      const Radius.circular(3),
    );
    canvas.drawRRect(b1Rect, Paint()..color = const Color(0xFF60A5FA));
    // Book pages edge
    canvas.drawRect(
      Rect.fromLTWH(w * 0.76, h * 0.81, w * 0.10, h * 0.14),
      Paint()..color = const Color(0xFFF1F5F9),
    );

    // 2. Middle Book (Purple)
    final b2Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.70), width: w * 0.72, height: h * 0.18),
      const Radius.circular(3),
    );
    canvas.drawRRect(b2Rect, Paint()..color = const Color(0xFF7C3AED));
    // Book pages edge
    canvas.drawRect(
      Rect.fromLTWH(w * 0.72, h * 0.63, w * 0.08, h * 0.14),
      Paint()..color = const Color(0xFFF1F5F9),
    );

    // 3. Top Book (Dark Slate)
    final b3Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.52), width: w * 0.64, height: h * 0.17),
      const Radius.circular(3),
    );
    canvas.drawRRect(b3Rect, Paint()..color = const Color(0xFF334155));

    // 4. Graduation Cap (Mortarboard)
    // Skull cap base
    final capBaseRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.38),
      width: w * 0.32,
      height: h * 0.14,
    );
    canvas.drawOval(capBaseRect, Paint()..color = const Color(0xFF0F172A));

    // Diamond board
    final capPath = Path()
      ..moveTo(w * 0.50, h * 0.16) // top
      ..lineTo(w * 0.78, h * 0.28) // right
      ..lineTo(w * 0.50, h * 0.38) // bottom
      ..lineTo(w * 0.22, h * 0.28) // left
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFF1E293B));

    // Gold button on cap
    canvas.drawCircle(Offset(w * 0.50, h * 0.27), 2.5, Paint()..color = const Color(0xFFF59E0B));

    // Gold tassel hanging
    final tasselPath = Path()
      ..moveTo(w * 0.50, h * 0.27)
      ..quadraticBezierTo(w * 0.56, h * 0.30, w * 0.60, h * 0.42);
    canvas.drawPath(
      tasselPath,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(Offset(w * 0.60, h * 0.44), 2, Paint()..color = const Color(0xFFF59E0B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sprout/plant illustration (bottom-right illustration).
class SproutPlantWidget extends StatelessWidget {
  const SproutPlantWidget({super.key, this.width = 64, this.height = 54});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(
        painter: _SproutPainter(),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  const _SproutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground shadow oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.90), width: w * 0.60, height: h * 0.14),
      Paint()..color = const Color(0xFFE2E8F0).withValues(alpha: 0.6),
    );

    // Stem
    final stemPath = Path()
      ..moveTo(w * 0.50, h * 0.88)
      ..quadraticBezierTo(w * 0.50, h * 0.55, w * 0.48, h * 0.28);
    canvas.drawPath(
      stemPath,
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Right large leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.48, h * 0.45)
      ..cubicTo(w * 0.68, h * 0.32, w * 0.88, h * 0.45, w * 0.78, h * 0.60)
      ..cubicTo(w * 0.68, h * 0.68, w * 0.52, h * 0.55, w * 0.48, h * 0.45)
      ..close();
    canvas.drawPath(rightLeaf, Paint()..color = const Color(0xFF86EFAC).withValues(alpha: 0.85));

    // Left leaf
    final leftLeaf = Path()
      ..moveTo(w * 0.48, h * 0.36)
      ..cubicTo(w * 0.30, h * 0.25, w * 0.16, h * 0.38, w * 0.24, h * 0.50)
      ..cubicTo(w * 0.34, h * 0.58, w * 0.44, h * 0.45, w * 0.48, h * 0.36)
      ..close();
    canvas.drawPath(leftLeaf, Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.75));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
