import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.radius = AppRadius.xl,
    this.showBorder = true,
    this.borderSide,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool showBorder;
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderSide = borderSide ??
        (showBorder
            ? BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.8,
              )
            : BorderSide.none);

    return SizedBox(
      width: double.infinity,
      child: Card(
        color: color ?? theme.cardTheme.color ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: effectiveBorderSide,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
