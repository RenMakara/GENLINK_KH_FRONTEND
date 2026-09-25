import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../design_system/colors/app_colors.dart';

/// The central visual focal point of the GenLink splash screen.
///
/// Features:
/// - Glossy rounded squircle container inspired by iOS glassmorphism.
/// - Illuminated surface with subtle specular border and soft layered drop shadows.
/// - Houses the dedicated GenLink GL logo SVG assets ('assets/splash/genlink_gl_dark.svg'
///   and 'assets/splash/genlink_gl_light.svg') with strictly preserved aspect ratio.
/// - Smooth dark elevated glass surface seamlessly integrated into the dark background,
///   with no white background artifact.
/// - Driven by a gentle breathing animation (0.98 <-> 1.02) without rotation or bouncing.
class SplashCentralPlate extends StatelessWidget {
  const SplashCentralPlate({
    super.key,
    required this.breathingAnimation,
    this.size = 140,
  });

  final Animation<double> breathingAnimation;
  final double size;

  static const String lightAssetPath = 'assets/splash/genlink_gl_light.svg';
  static const String darkAssetPath = 'assets/splash/genlink_gl_dark.svg';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark ? darkAssetPath : lightAssetPath;

    return AnimatedBuilder(
      animation: breathingAnimation,
      builder: (context, child) {
        // Breathing scale between 0.98 and 1.02
        final scale = 0.98 + (breathingAnimation.value * 0.04);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.30),
              // Multi-layer premium shadow + ambient cyan/blue glow
              boxShadow: [
                // Subtle blue/teal brand glow (not overdone)
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(
                    alpha: isDark ? 0.20 : 0.14,
                  ),
                  blurRadius: 32,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                // Soft depth drop shadow
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.38 : 0.06,
                  ),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.30),
                // Frosted glossy gradient surface matching GenLink design system
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.darkSurfaceSecondary,
                          AppColors.darkSurfacePrimary,
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF4F6F9),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.lightBorderSubtle,
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.28),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: size * 0.58,
                    height: size * 0.58,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

