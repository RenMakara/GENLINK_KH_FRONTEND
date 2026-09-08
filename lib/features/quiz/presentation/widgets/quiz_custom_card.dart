import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/surfaces/app_glass_surface.dart';
import '../quiz_colors.dart';

class QuizCustomCard extends StatelessWidget {
  const QuizCustomCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.margin,
    this.onTap,
    this.border,
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? AppRadius.squircle;
    final card = glass
        ? AppGlassSurface(
            margin: margin,
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            radius: radius,
            border: border,
            child: child,
          )
        : Container(
            margin: margin,
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(radius),
              border: border ?? Border.all(color: scheme.outlineVariant),
              boxShadow: QuizThemeColors.cardShadow,
            ),
            child: child,
          );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        hoverColor: scheme.primary.withValues(alpha: 0.04),
        splashColor: scheme.primary.withValues(alpha: 0.08),
        child: card,
      ),
    );
  }
}
