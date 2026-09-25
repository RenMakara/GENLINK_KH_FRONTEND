import 'package:flutter/material.dart';

enum SplashFeature {
  community(
    assetPath: 'assets/splash/community.png',
    glowColor: Color(0xFF5DADEC),
    label: 'Community',
  ),
  growth(
    assetPath: 'assets/splash/growth.png',
    glowColor: Color(0xFF4BAE73),
    label: 'Growth',
  ),
  opportunity(
    assetPath: 'assets/splash/opportunity.png',
    glowColor: Color(0xFFF2B84B),
    label: 'Opportunity',
  ),
  learning(
    assetPath: 'assets/splash/learning.png',
    glowColor: Color(0xFF8B7CF6),
    label: 'Learning',
  );

  const SplashFeature({
    required this.assetPath,
    required this.glowColor,
    required this.label,
  });

  final String assetPath;
  final Color glowColor;
  final String label;
}

/// Renders one of the four GenLink ecosystem feature tiles with soft glow and shadow.
///
/// NOTE: The asset itself already contains the designed glossy 3D card.
/// This widget preserves the asset exactly as designed and adds a subtle colored glow.
class SplashFeatureTile extends StatelessWidget {
  const SplashFeatureTile({
    super.key,
    required this.feature,
    this.size = 56,
    this.scale = 1.0,
    this.depth = 0.5,
  });

  final SplashFeature feature;
  final double size;
  final double scale;
  /// Depth factor from 0.0 (back of orbit) to 1.0 (front of orbit) for parallax shading.
  final double depth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Depth-based glow & shadow intensity
    final glowAlpha = (0.20 + depth * 0.18).clamp(0.0, 1.0);
    final shadowAlpha = isDark ? (0.35 + depth * 0.25) : (0.12 + depth * 0.14);

    return Semantics(
      label: feature.label,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              // Soft colored ambient glow
              BoxShadow(
                color: feature.glowColor.withValues(alpha: glowAlpha),
                blurRadius: 18 + depth * 8,
                spreadRadius: 1,
                offset: Offset(0, 3 + depth * 4),
              ),
              // Contact depth shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowAlpha),
                blurRadius: 12 + depth * 6,
                spreadRadius: -2,
                offset: Offset(0, 6 + depth * 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              feature.assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              semanticLabel: feature.label,
            ),
          ),
        ),
      ),
    );
  }
}
