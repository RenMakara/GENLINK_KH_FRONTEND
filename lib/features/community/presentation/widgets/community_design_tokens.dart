import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/shadows/app_shadows.dart';
import '../../../../design_system/spacing/app_spacing.dart';

/// Shared visual tokens for the Community feed and forum.
abstract final class CommunityCardStyle {
  static const double cardRadius = AppRadius.lg;
  static const double borderWidth = 0.8;
  static const double cardBottomMargin = 12.0;
  static const double pageHorizontalMargin = AppSpacing.md;
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.md);

  static BoxDecoration cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: borderSubtle.withValues(alpha: isDark ? 0.45 : 0.75),
        width: borderWidth,
      ),
      boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
    );
  }

  static BoxDecoration secondarySurfaceDecoration(
    BuildContext context, {
    double radius = AppRadius.md,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return BoxDecoration(
      color: surfaceSecondary,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderSubtle.withValues(alpha: isDark ? 0.60 : 0.80),
        width: borderWidth,
      ),
    );
  }
}

class CommunityCategoryBadge extends StatelessWidget {
  const CommunityCategoryBadge({
    super.key,
    required this.label,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.0),
    this.fontSize = 11.0,
  });

  final String label;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightBgSecondary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: borderSubtle.withValues(alpha: 0.80),
          width: 0.75,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textSecondary,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.2,
        ),
      ),
    );

    if (onTap == null) return badge;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: badge,
      ),
    );
  }
}
