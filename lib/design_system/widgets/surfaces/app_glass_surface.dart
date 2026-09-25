import 'dart:ui';

import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

/// A restrained, theme-aware translucent surface for large, stable surfaces.
///
/// Keep this for hero and summary content. Repeated list rows should use
/// opaque surfaces so text stays crisp and scrolling remains inexpensive.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.radius = AppRadius.squircle,
    this.blurSigma = 12,
    this.backgroundOpacity,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blurSigma;
  final double? backgroundOpacity;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = scheme.surface.withValues(
      alpha: backgroundOpacity ?? (isDark ? 0.74 : 0.84),
    );
    final outline = border ??
        Border.all(
          color: scheme.outlineVariant.withValues(
            alpha: isDark ? 0.92 : 0.78,
          ),
        );
    final shadows = boxShadow ??
        (isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: outline,
        boxShadow: shadows,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (blurSigma > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
      child: surface,
    );
  }
}
