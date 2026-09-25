import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders the GenLink wordmark asset with seamless light and dark variants.
class SplashWordmark extends StatelessWidget {
  const SplashWordmark({
    super.key,
    this.height = 24,
  });

  final double height;

  static const String lightAssetPath = 'assets/splash/genlink_wordmark_light.svg';
  static const String darkAssetPath = 'assets/splash/genlink_wordmark_dark.svg';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark ? darkAssetPath : lightAssetPath;

    return SvgPicture.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

