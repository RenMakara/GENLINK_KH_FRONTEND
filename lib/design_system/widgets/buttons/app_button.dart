import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

enum AppButtonVariant {
  primary,

  secondary,

  text,

  danger,

  inverse,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
    this.icon,
    this.muted = false,
    this.height = 60,
    this.radius,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
    this.height = 60,
    this.radius,
  }) : variant = AppButtonVariant.secondary,
       muted = false;

  const AppButton.inverse({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
    this.height = 60,
    this.radius,
  }) : variant = AppButtonVariant.inverse,
       muted = false;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = false,
    this.icon,
    this.muted = false,
    this.height = 44,
    this.radius,
  }) : variant = AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;
  final IconData? icon;
  final double height;
  final double? radius;

  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveOnPressed = loading ? null : onPressed;

    final textStyle = theme.textTheme.labelLarge;

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundOf(scheme),
            ),
          )
        : _Label(
            label: label,
            icon: icon,
            underline: variant == AppButtonVariant.text,
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? AppRadius.pill),
    );
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textStyle,
          minimumSize: Size(0, height),
          padding: padding,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          textStyle: textStyle,
          minimumSize: Size(0, height),
          padding: padding,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: textStyle,
          side: BorderSide(color: scheme.outline, width: 1.2),
          minimumSize: Size(0, height),
          padding: padding,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          foregroundColor: muted
              ? scheme.onSurface.withValues(alpha: 0.55)
              : scheme.onSurface,
          textStyle: textStyle,
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.inverse => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.onPrimary,
          foregroundColor: scheme.primary,
          textStyle: textStyle,
          minimumSize: Size(0, height),
          padding: padding,
          shape: shape,
        ),
        child: child,
      ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color _foregroundOf(ColorScheme scheme) => switch (variant) {
    AppButtonVariant.primary => scheme.onPrimary,
    AppButtonVariant.danger => scheme.onError,
    AppButtonVariant.inverse => scheme.primary,
    _ => scheme.onSurface,
  };
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon, this.underline = false});

  final String label;
  final IconData? icon;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: underline
          ? const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 1.2,
            )
          : null,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}
