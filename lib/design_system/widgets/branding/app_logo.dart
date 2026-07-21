import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';

/// Brand asset paths.
///
/// The source files are `.svg`, but each is only a wrapper around an
/// embedded PNG, so the raster was extracted and is used directly —
/// no `flutter_svg` dependency needed.
abstract final class AppLogoAssets {
  /// GL mark for light backgrounds (black G, gradient L).
  static const markLight = 'assets/logos/gl_mark_light.png';

  /// GL mark for dark backgrounds (outlined G, gradient L).
  static const markDark = 'assets/logos/gl_mark_dark.png';

  /// "GENLINK KH" wordmark. Monochrome, so it is recoloured at paint time
  /// rather than shipping a second file.
  static const wordmark = 'assets/logos/genlink_wordmark.png';
}

/// The GL mark, picking the light or dark artwork from the active theme.
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

/// The "GENLINK KH" wordmark, tinted to [color] (defaults to the theme's
/// primary text colour) so it reads on both light and dark backgrounds.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.height = 22, this.color});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    return ColorFiltered(
      // srcIn keeps the glyph alpha and replaces every opaque pixel, which
      // is exactly what a flat monochrome wordmark needs.
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: Image.asset(
        AppLogoAssets.wordmark,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// The mark inside the soft squircle plate used on the splash screen.
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
