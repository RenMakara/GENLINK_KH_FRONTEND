import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';
import '../../icons/app_icons.dart';
import '../../radius/app_radius.dart';
import '../../spacing/app_spacing.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.height = 60,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightPrimary.withValues(alpha: 0.04),
                blurRadius: AppSpacing.md,
                offset: const Offset(0, AppSpacing.xs),
              ),
            ],
          ),
          child: Material(
            color: enabled
                ? AppColors.lightSurfacePrimary
                : AppColors.lightSurfaceSecondary,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.lightBorderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? AppColors.lightPrimary.withValues(alpha: 0.06)
                    : null,
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppIcons.google,
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      semanticLabel ?? 'Continue with Google',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? AppColors.lightTextPrimary
                            : AppColors.lightTextMuted,
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
