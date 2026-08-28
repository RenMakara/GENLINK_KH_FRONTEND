import 'package:flutter/material.dart';

import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled with the primary colour — one per screen.
  primary,

  /// Outlined — secondary actions.
  secondary,

  /// Text only — tertiary/inline actions.
  text,

  /// Filled with the error colour — destructive actions.
  danger,

  /// Inverse filled action for use on a primary-colour surface.
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

    // Passed through ButtonStyle rather than set on the Text: the theme's
    // labelLarge carries an explicit colour, and an explicit Text colour
    // silently beats the button's foregroundColor — which rendered the
    // label white-on-white in dark mode and black-on-black in light.
    // ButtonStyleButton overlays foregroundColor onto textStyle, so routing
    // it here also keeps the disabled and pressed states correct.
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
            // Text buttons read as links in the design: underlined, and
            // muted when they are the secondary way out of a screen.
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
          side: BorderSide(color: scheme.outline),
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
    // No colour here on purpose — the surrounding DefaultTextStyle, which
    // the button builds from its own foregroundColor, supplies it.
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
