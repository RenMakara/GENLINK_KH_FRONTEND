import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../colors/app_colors.dart';
import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

abstract final class AppLogoAssets {
  static const glLight = 'assets/splash/genlink_gl_light.svg';
  static const glDark = 'assets/splash/genlink_gl_dark.svg';
  static const wordmarkLight = 'assets/splash/genlink_wordmark_light.svg';
  static const wordmarkDark = 'assets/splash/genlink_wordmark_dark.svg';

  // Raster PNG companions
  static const markLight = 'assets/splash/genlink_gl_light.png';
  static const markDark = 'assets/splash/genlink_gl_dark.png';
  static const wordmark = wordmarkLight;
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark ? AppLogoAssets.glDark : AppLogoAssets.glLight;
    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(assetPath, height: size, fit: BoxFit.contain);
    }
    return Image.asset(assetPath, height: size, fit: BoxFit.contain);
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.height = 22, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark
        ? AppLogoAssets.wordmarkDark
        : AppLogoAssets.wordmarkLight;

    final image = SvgPicture.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
    );

    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }
    return image;
  }
}

class AuthBrandLockup extends StatelessWidget {
  const AuthBrandLockup({
    super.key,
    this.markSize = 52,
    this.wordmarkHeight = 26,
    this.alignment = MainAxisAlignment.start,
    this.enableHero = true,
  });

  final double markSize;
  final double wordmarkHeight;
  final MainAxisAlignment alignment;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Semantics(
      image: true,
      label: 'GenLink KH',
      child: Row(
        key: const ValueKey('auth-brand-lockup'),
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: alignment == MainAxisAlignment.center
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(markSize * 0.28),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF0EA5E9,
                  ).withValues(alpha: isDark ? 0.35 : 0.18),
                  blurRadius: markSize * 0.35,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AppLogoMark(size: markSize),
          ),
          const SizedBox(width: AppSpacing.md),
          AppWordmark(height: wordmarkHeight),
        ],
      ),
    );

    if (!enableHero) return content;

    return Hero(
      tag: 'genlink-auth-brand-lockup',
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final dip = math.sin(math.pi * curved.value);
                final opacity = (1.0 - (0.15 * dip)).clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Material(
                    type: MaterialType.transparency,
                    child: content,
                  ),
                );
              },
            );
          },
      child: Material(type: MaterialType.transparency, child: content),
    );
  }
}

class AppLogoPlate extends StatelessWidget {
  const AppLogoPlate({super.key, this.size = 240});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(size * AppRadius.plateRatio),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorderSubtle
              : AppColors.lightBorderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isDark ? 30 : 40,
            spreadRadius: isDark ? 1 : 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(child: AppLogoMark(size: size * 0.44)),
    );
  }
}
