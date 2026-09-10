import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/surfaces/app_surface.dart';

class QuizCustomCard extends StatelessWidget {
  const QuizCustomCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.margin,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? AppRadius.xl;
    final card = border == null
        ? Container(
            margin: margin,
            child: AppSurface(
              padding: padding ?? const EdgeInsets.all(AppSpacing.md),
              radius: radius,
              child: child,
            ),
          )
        : Container(
            margin: margin,
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(radius),
              border: border,
            ),
            child: child,
          );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.04),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: card,
      ),
    );
  }
}
