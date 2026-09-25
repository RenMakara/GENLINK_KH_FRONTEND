import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'splash_central_plate.dart';
import 'splash_feature_tile.dart';

/// Renders the central GL logo and the four orbiting ecosystem feature tiles
/// along a tilted 3D elliptical orbit with depth sorting, subtle decorative particles,
/// and smooth organic floating.
///
/// CRITICAL: Feature tiles NEVER rotate their content; they only translate in position.
class SplashOrbitSystem extends StatelessWidget {
  const SplashOrbitSystem({
    super.key,
    required this.orbitAnimation,
    required this.breathingAnimation,
    this.entranceScale = 1.0,
    this.entranceOpacity = 1.0,
    this.reducedMotion = false,
    this.centerPlateSize = 136,
    this.tileScale = 1.0,
  });

  final Animation<double> orbitAnimation;
  final Animation<double> breathingAnimation;
  final double entranceScale;
  final double entranceOpacity;
  final bool reducedMotion;
  final double centerPlateSize;
  final double tileScale;

  // Orbital parameters: -14 degrees tilt
  static const double _tiltAngle = -14.0 * (math.pi / 180.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 340.0;

        // Ensure the orbital system never exceeds the available viewport width.
        // Total orbit bounding box is roughly 2 * rx + tileSize + 24.
        final maxAllowedRx = ((availableWidth - 80) / 2).clamp(65.0, 140.0);
        final desiredRx = 136.0 * tileScale;
        final rx = math.min(desiredRx, maxAllowedRx);
        final ry = rx * 0.48; // proportional ellipse
        final tileSize = (rx * 0.40).clamp(40.0, 56.0);
        final effectiveCenterSize = math.min(centerPlateSize, rx * 1.0);

        final totalWidth = rx * 2 + tileSize + 16;
        final totalHeight = ry * 2 + effectiveCenterSize + 16;

        return Opacity(
          opacity: entranceOpacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: entranceScale,
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([orbitAnimation, breathingAnimation]),
                builder: (context, child) {
                  // Current base orbital angle [0..2*pi]
                  final baseTheta = reducedMotion
                      ? 0.0
                      : (orbitAnimation.value * 2 * math.pi);

                  // 4 features distributed evenly around the orbit:
                  // Community at top (-pi/2), Growth at right (0),
                  // Opportunity at bottom (pi/2), Learning at left (pi)
                  final features = [
                    _OrbitItem(
                      feature: SplashFeature.community,
                      phaseOffset: -math.pi / 2,
                    ),
                    _OrbitItem(
                      feature: SplashFeature.growth,
                      phaseOffset: 0.0,
                    ),
                    _OrbitItem(
                      feature: SplashFeature.opportunity,
                      phaseOffset: math.pi / 2,
                    ),
                    _OrbitItem(
                      feature: SplashFeature.learning,
                      phaseOffset: math.pi,
                    ),
                  ];

                  final cosTilt = math.cos(_tiltAngle);
                  final sinTilt = math.sin(_tiltAngle);

                  for (final item in features) {
                    final angle = baseTheta + item.phaseOffset;
                    final rawX = rx * math.cos(angle);
                    final rawY = ry * math.sin(angle);

                    // Rotate coordinates by tilt angle
                    final rotX = rawX * cosTilt - rawY * sinTilt;
                    final rotY = rawX * sinTilt + rawY * cosTilt;

                    // Subtle secondary vertical floating
                    final floatOffset = reducedMotion
                        ? 0.0
                        : (math.sin(angle * 2.0 + item.phaseOffset) * 3.5);

                    item.x = rotX;
                    item.y = rotY + floatOffset;

                    // Depth value for z-ordering & parallax
                    item.depth = math.sin(angle);
                  }

                  // Depth-sorted layers (back to front)
                  final behindCenter = <Widget>[];
                  final inFrontOfCenter = <Widget>[];

                  for (final item in features) {
                    final normDepth = (item.depth + 1.0) / 2.0;
                    final itemScale =
                        reducedMotion ? 1.0 : (0.95 + normDepth * 0.10);

                    final tileWidget = Transform.translate(
                      offset: Offset(item.x, item.y),
                      child: SplashFeatureTile(
                        feature: item.feature,
                        size: tileSize,
                        scale: itemScale,
                        depth: normDepth,
                      ),
                    );

                    if (item.depth < -0.15) {
                      behindCenter.add(tileWidget);
                    } else {
                      inFrontOfCenter.add(tileWidget);
                    }
                  }

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Decorative orbital ring & subtle glowing dots
                        CustomPaint(
                          size: Size(rx * 2, ry * 2),
                          painter: _OrbitRingPainter(
                            rx: rx,
                            ry: ry,
                            tiltAngle: _tiltAngle,
                            isDark: isDark,
                            rotationPhase: baseTheta,
                            reducedMotion: reducedMotion,
                          ),
                        ),

                        // Layer 1: Tiles behind center plate
                        ...behindCenter,

                        // Layer 2: Central GL Logo Plate (fixed at center, breathing only)
                        SplashCentralPlate(
                          breathingAnimation: breathingAnimation,
                          size: effectiveCenterSize,
                        ),

                        // Layer 3: Tiles in front of center plate
                        ...inFrontOfCenter,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbitItem {
  _OrbitItem({
    required this.feature,
    required this.phaseOffset,
  });

  final SplashFeature feature;
  final double phaseOffset;
  double x = 0;
  double y = 0;
  double depth = 0;
}

/// Custom painter for the minimal orbital curve and glowing planetary dots.
class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({
    required this.rx,
    required this.ry,
    required this.tiltAngle,
    required this.isDark,
    required this.rotationPhase,
    required this.reducedMotion,
  });

  final double rx;
  final double ry;
  final double tiltAngle;
  final bool isDark;
  final double rotationPhase;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    // 1. Thin orbital elliptical path curve
    final ringPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFF1F6FEB).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(rect, ringPaint);

    // 2. Tiny decorative glowing spheres on the orbital curve
    final dotColors = [
      const Color(0xFF5DADEC), // cyan/blue
      const Color(0xFF4BAE73), // emerald/mint
      const Color(0xFF8B7CF6), // purple
      const Color(0xFFF2B84B), // amber/gold
    ];

    final dotAngles = [
      0.785, // ~45 deg
      2.356, // ~135 deg
      3.927, // ~225 deg
      5.498, // ~315 deg
    ];

    for (int i = 0; i < 4; i++) {
      final angle = dotAngles[i] + (reducedMotion ? 0.0 : rotationPhase * 0.5);
      final dx = rx * math.cos(angle);
      final dy = ry * math.sin(angle);
      final color = dotColors[i];

      // Subtle glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.45 : 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(Offset(dx, dy), 4.5, glowPaint);

      // Core particle
      final corePaint = Paint()..color = color;
      canvas.drawCircle(Offset(dx, dy), 2.8, corePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.rotationPhase != rotationPhase ||
        oldDelegate.rx != rx ||
        oldDelegate.ry != ry ||
        oldDelegate.isDark != isDark;
  }
}
