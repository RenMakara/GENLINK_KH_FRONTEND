import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';
import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 60,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.lightPrimary)
                    .withValues(alpha: 0.04),
                blurRadius: AppSpacing.md,
                offset: const Offset(0, AppSpacing.xs),
              ),
            ],
          ),
          child: Material(
            color: enabled ? scheme.surface : scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide(
                color: enabled
                    ? scheme.outlineVariant
                    : scheme.outline.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? scheme.primary.withValues(alpha: 0.06)
                    : null,
              ),
              child: ExcludeSemantics(
                child: loading
                    ? Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onSurface,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: enabled
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
