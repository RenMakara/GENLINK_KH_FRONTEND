import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../quiz_colors.dart';

class QuizStatBadge extends StatelessWidget {
  const QuizStatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: QuizThemeColors.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor ?? scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? scheme.onSurface,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
