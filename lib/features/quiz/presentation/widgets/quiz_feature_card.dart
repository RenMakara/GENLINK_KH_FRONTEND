import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';

/// Reusable iOS-inspired feature card for quiz modes.
///
/// Ensures consistent geometry, typography, spacing, and interaction states
/// while allowing semantic accent differentiation derived from GenLink tokens.
class QuizFeatureCard extends StatelessWidget {
  const QuizFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.trailing,
    this.badge,
    this.margin,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? badge;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = context.isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    final card = Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                accentColor.withValues(alpha: 0.06),
                semantic.surface,
              )
            : Color.alphaBlend(
                accentColor.withValues(alpha: 0.05),
                Colors.white,
              ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
          width: 1.0,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
                width: 0.8,
              ),
            ),
            child: Icon(icon, size: 24, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge != null) ...[
                  badge!,
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.secondaryText,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? semantic.surfaceElevated
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? semantic.borderSubtle
                        : semantic.borderSubtle.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                  boxShadow: isDark
                      ? const []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: semantic.primaryText.withValues(alpha: 0.8),
                ),
              ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        splashColor: accentColor.withValues(alpha: 0.10),
        highlightColor: accentColor.withValues(alpha: 0.05),
        child: card,
      ),
    );
  }
}
