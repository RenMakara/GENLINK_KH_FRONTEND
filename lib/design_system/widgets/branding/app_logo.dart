import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

abstract final class AppLogoAssets {
  static const markLight = 'assets/logos/gl_mark_light.png';

  static const markDark = 'assets/logos/gl_mark_dark.png';

  static const wordmark = 'assets/logos/genlink_wordmark.png';
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? AppLogoAssets.markDark : AppLogoAssets.markLight,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.height = 22, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: Image.asset(
        AppLogoAssets.wordmark,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

class AuthBrandLockup extends StatelessWidget {
  const AuthBrandLockup({
    super.key,
    this.markSize = 44,
    this.wordmarkHeight = 18,
    this.alignment = MainAxisAlignment.start,
  });

  final double markSize;
  final double wordmarkHeight;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'GenLink KH',
      child: Row(
        key: const ValueKey('auth-brand-lockup'),
        mainAxisAlignment: alignment,
        mainAxisSize: alignment == MainAxisAlignment.center
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          AppLogoMark(size: markSize),
          const SizedBox(width: AppSpacing.md),
          AppWordmark(height: wordmarkHeight),
        ],
      ),
    );
  }
}

class AppLogoPlate extends StatelessWidget {
  const AppLogoPlate({super.key, this.size = 240});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(size * AppRadius.plateRatio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.06),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(child: AppLogoMark(size: size * 0.34)),
    );
  }
}
