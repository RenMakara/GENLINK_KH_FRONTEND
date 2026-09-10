import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';

/// The shared tinted icon tile used by the Create modal and feature cards.
///
/// Keep this deliberately quiet: the semantic accent comes from the caller,
/// while the surface, border, and proportions match the main app's cards.
class QuizIconContainer extends StatelessWidget {
  const QuizIconContainer({
    super.key,
    required this.icon,
    required this.accentColor,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = AppRadius.md + 2,
  });

  final IconData icon;
  final Color accentColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final fill = accentColor.withValues(alpha: isDark ? 0.14 : 0.10);
    final border = accentColor.withValues(alpha: isDark ? 0.28 : 0.20);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: iconSize, color: accentColor),
    );
  }
}
