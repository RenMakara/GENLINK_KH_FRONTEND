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
    this.exitAnimation,
    this.entranceScale = 1.0,
    this.entranceOpacity = 1.0,
    this.reducedMotion = false,
    this.centerPlateSize = 136,
    this.tileScale = 1.0,
  });

  final Animation<double> orbitAnimation;
  final Animation<double> breathingAnimation;
  final Animation<double>? exitAnimation;
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
                animation: Listenable.merge([
                  orbitAnimation,
                  breathingAnimation,
                  ?exitAnimation,
                ]),
                builder: (context, child) {
                  final exitVal = (exitAnimation != null && !reducedMotion)
                      ? exitAnimation!.value
                      : 0.0;

                  // Phase 2: Orbit Acceleration (exitVal: 0.00 -> 0.18)
                  // Smooth ease-in curve so acceleration is physical and seamless.
                  double addedTheta = 0.0;
                  if (exitVal > 0.0) {
                    final accelT = (exitVal / 0.18).clamp(0.0, 1.0);
                    final accelCurve = Curves.easeIn.transform(accelT);
                    addedTheta = accelCurve * (0.35 * math.pi);
                  }

                  // Current base orbital angle [0..2*pi] + acceleration delta
                  final baseTheta = reducedMotion
                      ? 0.0
                      : (orbitAnimation.value * 2 * math.pi + addedTheta);

                  // Phase 3: Fly-out progress (exitVal: 0.18 -> 0.52)
                  final flyProgress = exitVal <= 0.18
                      ? 0.0
                      : ((exitVal - 0.18) / 0.34).clamp(0.0, 1.0);

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

                  // Unique path distance variations to ensure individual trajectories
                  const distVariations = [780.0, 860.0, 820.0, 890.0];

                  for (int i = 0; i < features.length; i++) {
                    final item = features[i];
                    final angle = baseTheta + item.phaseOffset;
                    final rawX = rx * math.cos(angle);
                    final rawY = ry * math.sin(angle);

                    // Rotate coordinates by tilt angle
                    final rotX = rawX * cosTilt - rawY * sinTilt;
                    final rotY = rawX * sinTilt + rawY * cosTilt;

                    // Subtle secondary vertical floating (damped out during fly-out)
                    final floatWeight = (1.0 - flyProgress).clamp(0.0, 1.0);
                    final floatOffset = reducedMotion
                        ? 0.0
                        : (math.sin(angle * 2.0 + item.phaseOffset) * 3.5 * floatWeight);

                    if (flyProgress > 0.0) {
                      // Physical trajectory computation:
                      // 1. Radial unit vector pointing outward from center
                      final rLen = math.sqrt(rotX * rotX + rotY * rotY);
                      final rX = rLen > 0.001 ? (rotX / rLen) : 0.0;
                      final rY = rLen > 0.001 ? (rotY / rLen) : 1.0;

                      // 2. Tangential orbital velocity vector in the direction of motion
                      final rawVx = -rx * math.sin(angle);
                      final rawVy = ry * math.cos(angle);
                      final rotVx = rawVx * cosTilt - rawVy * sinTilt;
                      final rotVy = rawVx * sinTilt + rawVy * cosTilt;
                      final vLen = math.sqrt(rotVx * rotVx + rotVy * rotVy);
                      final vX = vLen > 0.001 ? (rotVx / vLen) : 0.0;
                      final vY = vLen > 0.001 ? (rotVy / vLen) : 0.0;

                      // 3. Blend centrifugal push with tangential momentum
                      final launchX = rX * 0.72 + vX * 0.52;
                      final launchY = rY * 0.72 + vY * 0.52;
                      final lLen = math.sqrt(launchX * launchX + launchY * launchY);
                      final dirX = lLen > 0.001 ? (launchX / lLen) : rX;
                      final dirY = lLen > 0.001 ? (launchY / lLen) : rY;

                      // 4. Physical fly-out curve (smooth ease-in / fast-out)
                      final flyCurve = Curves.easeInCubic.transform(flyProgress);
                      final flyDistance = distVariations[i] * flyCurve;

                      item.x = rotX + (dirX * flyDistance);
                      item.y = rotY + floatOffset + (dirY * flyDistance);

                      // Swell during flight (+12% scale mid-flight)
                      final swell = 0.12 * math.sin(flyProgress * math.pi);
                      item.scaleMultiplier = 1.0 + swell;

                      // Gradually reduce opacity only near the end (> 60% fly-out)
                      if (flyProgress > 0.60) {
                        final fadeT = ((flyProgress - 0.60) / 0.40).clamp(0.0, 1.0);
                        item.opacity = (1.0 - Curves.easeOut.transform(fadeT)).clamp(0.0, 1.0);
                      } else {
                        item.opacity = 1.0;
                      }
                    } else {
                      item.x = rotX;
                      item.y = rotY + floatOffset;
                      item.scaleMultiplier = 1.0;
                      item.opacity = 1.0;
                    }

                    // Depth value for z-ordering & parallax
                    item.depth = math.sin(angle);
                  }

                  // Phase 4: Center Logo Scale Reaction (Compress 1.0 -> 0.96 -> Pulse 1.04)
                  double logoScaleMultiplier = 1.0;
                  if (exitVal >= 0.38 && exitVal < 0.45) {
                    final t = (exitVal - 0.38) / 0.07;
                    logoScaleMultiplier = 1.0 - (0.04 * Curves.easeInOutSine.transform(t));
                  } else if (exitVal >= 0.45 && exitVal <= 0.56) {
                    final t = ((exitVal - 0.45) / 0.11).clamp(0.0, 1.0);
                    logoScaleMultiplier = 0.96 + (0.08 * Curves.easeOutBack.transform(t));
                  } else if (exitVal > 0.56) {
                    logoScaleMultiplier = 1.04;
                  }

                  // Depth-sorted layers (back to front)
                  final behindCenter = <Widget>[];
                  final inFrontOfCenter = <Widget>[];

                  for (final item in features) {
                    final normDepth = (item.depth + 1.0) / 2.0;
                    final itemScale =
                        reducedMotion ? 1.0 : ((0.95 + normDepth * 0.10) * item.scaleMultiplier);

                    if (item.opacity <= 0.0) continue;

                    final tileWidget = Opacity(
                      opacity: item.opacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(item.x, item.y),
                        child: RepaintBoundary(
                          child: SplashFeatureTile(
                            feature: item.feature,
                            size: tileSize,
                            scale: itemScale,
                            depth: normDepth,
                          ),
                        ),
                      ),
                    );

                    if (item.depth < -0.15) {
                      behindCenter.add(tileWidget);
                    } else {
                      inFrontOfCenter.add(tileWidget);
                    }
                  }

                  // Orbital ring fade-out during fly-out
                  final ringOpacity = flyProgress > 0.0
                      ? (1.0 - (flyProgress / 0.50)).clamp(0.0, 1.0)
                      : 1.0;

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Decorative orbital ring & subtle glowing dots
                        if (ringOpacity > 0.0)
                          CustomPaint(
                            size: Size(rx * 2, ry * 2),
                            painter: _OrbitRingPainter(
                              rx: rx,
                              ry: ry,
                              tiltAngle: _tiltAngle,
                              isDark: isDark,
                              rotationPhase: baseTheta,
                              reducedMotion: reducedMotion,
                              ringOpacity: ringOpacity,
                            ),
                          ),

                        // Layer 1: Tiles behind center plate
                        ...behindCenter,

                        // Layer 2: Central GL Logo Plate (with Phase 4 tactile pulse)
                        Transform.scale(
                          scale: logoScaleMultiplier,
                          child: SplashCentralPlate(
                            breathingAnimation: breathingAnimation,
                            size: effectiveCenterSize,
                          ),
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
  double scaleMultiplier = 1.0;
  double opacity = 1.0;
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
    this.ringOpacity = 1.0,
  });

  final double rx;
  final double ry;
  final double tiltAngle;
  final bool isDark;
  final double rotationPhase;
  final bool reducedMotion;
  final double ringOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (ringOpacity <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    // 1. Thin orbital elliptical path curve
    final ringPaint = Paint()
      ..color = (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFF1F6FEB).withValues(alpha: 0.16))
          .withValues(alpha: (isDark ? 0.12 : 0.16) * ringOpacity)
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
        ..color = color.withValues(
          alpha: (isDark ? 0.45 : 0.35) * ringOpacity,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(Offset(dx, dy), 4.5, glowPaint);

      // Core particle
      final corePaint = Paint()
        ..color = color.withValues(alpha: ringOpacity);
      canvas.drawCircle(Offset(dx, dy), 2.8, corePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.rotationPhase != rotationPhase ||
        oldDelegate.rx != rx ||
        oldDelegate.ry != ry ||
        oldDelegate.isDark != isDark ||
        oldDelegate.ringOpacity != ringOpacity;
  }
}
