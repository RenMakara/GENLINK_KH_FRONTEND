import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';

class QuizGradientButton extends StatelessWidget {
  const QuizGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.height = 56,
    this.borderRadius = AppRadius.lg,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = LinearGradient(
      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.86)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final foreground = isOutlined ? scheme.primary : scheme.onPrimary;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(color: foreground);
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(label, style: labelStyle),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.primary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
