import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';

/// Ambient animated background for the splash screen with subtle organic gradient glows.
class SplashBackground extends StatelessWidget {
  const SplashBackground({
    super.key,
    required this.animation,
    this.reducedMotion = false,
  });

  final Animation<double> animation;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    if (reducedMotion) {
      return Container(
        color: baseBg,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -80,
              child: _StaticGlow(
                size: 320,
                color: isDark
                    ? const Color(0xFF1F6FEB).withValues(alpha: 0.14)
                    : const Color(0xFF5DADEC).withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: _StaticGlow(
                size: 340,
                color: isDark
                    ? const Color(0xFF8B7CF6).withValues(alpha: 0.10)
                    : const Color(0xFF4BAE73).withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value * 2 * math.pi;
        final dx1 = math.sin(t) * 18.0;
        final dy1 = math.cos(t) * 14.0;
        final dx2 = math.cos(t * 0.8) * 20.0;
        final dy2 = math.sin(t * 0.8) * 16.0;

        return Container(
          color: baseBg,
          child: Stack(
            children: [
              // Top-left ambient blue glow
              Positioned(
                top: -90 + dy1,
                left: -90 + dx1,
                child: _StaticGlow(
                  size: 340,
                  color: isDark
                      ? const Color(0xFF1F6FEB).withValues(alpha: 0.15)
                      : const Color(0xFF5DADEC).withValues(alpha: 0.18),
                ),
              ),
              // Center-right subtle purple glow
              Positioned(
                top: 200 + dy2 * 0.6,
                right: -100 + dx2 * 0.5,
                child: _StaticGlow(
                  size: 280,
                  color: isDark
                      ? const Color(0xFF8B7CF6).withValues(alpha: 0.08)
                      : const Color(0xFF8B7CF6).withValues(alpha: 0.10),
                ),
              ),
              // Bottom-right ambient green/teal glow
              Positioned(
                bottom: -80 + dy2,
                right: -70 + dx2,
                child: _StaticGlow(
                  size: 360,
                  color: isDark
                      ? const Color(0xFF4BAE73).withValues(alpha: 0.10)
                      : const Color(0xFF4BAE73).withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaticGlow extends StatelessWidget {
  const _StaticGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.72],
          ),
        ),
      ),
    );
  }
}
