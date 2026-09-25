import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Tagline section presenting "Connect Grow Thrive" and "GenLink KH".
///
/// Features:
/// - "Grow" accented with a vibrant GenLink gradient.
/// - Modern, bold typography using Sora.
/// - Secondary "GenLink KH" brand subline.
/// - Wrapped with scale-down constraints to guarantee zero overflow on any screen.
class SplashTagline extends StatelessWidget {
  const SplashTagline({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fontSize = compact ? 22.0 : 26.0;

    final baseStyle = TextStyle(
      fontFamily: AppTypography.englishFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: semantic.primaryText,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Connect Grow Thrive
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Connect ', style: baseStyle),
              // Gradient accent on "Grow"
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [
                      Color(0xFF388BFD), // GenLink blue
                      Color(0xFF22C55E), // GenLink growth green
                      Color(0xFF00D2B4), // Cyan/teal
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  'Grow',
                  style: baseStyle.copyWith(
                    color: Colors.white, // Required for ShaderMask
                  ),
                ),
              ),
              Text(' Thrive', style: baseStyle),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Subline: GenLink KH
        Text(
          'GenLink  KH',
          style: TextStyle(
            fontFamily: AppTypography.englishFontFamily,
            fontSize: compact ? 11.5 : 13.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.2,
            color: isDark ? semantic.textMuted : semantic.secondaryText,
          ),
        ),
      ],
    );
  }
}
