import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';

class FocusSessionSummaryDialog extends StatelessWidget {
  const FocusSessionSummaryDialog({
    super.key,
    required this.focusedMinutes,
    this.xpEarned = 0,
    this.isAbandoned = true,
  });

  final int focusedMinutes;
  final int xpEarned;
  final bool isAbandoned;

  static Future<void> show(
    BuildContext context, {
    required int focusedMinutes,
    int xpEarned = 0,
    bool isAbandoned = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => FocusSessionSummaryDialog(
        focusedMinutes: focusedMinutes,
        xpEarned: xpEarned,
        isAbandoned: isAbandoned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: semantic.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      elevation: 6,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Stats Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.productivityAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.productivityAccent,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'focus.sessionSummary'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: semantic.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),

            // Stat Cards Container
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightBgSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBorderSubtle,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  // Row 1: Focused Time
                  _SummaryRow(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: AppColors.productivityAccent,
                    label: 'focus.totalTime'.tr,
                    valueText: '$focusedMinutes ${'focus.minutesShort'.tr}',
                    valueColor: semantic.primaryText,
                  ),
                  Divider(
                    height: 20,
                    thickness: 1,
                    color: isDark
                        ? AppColors.darkBorderSubtle
                        : AppColors.lightBorderSubtle,
                  ),

                  // Row 2: XP Earned
                  _SummaryRow(
                    icon: Icons.stars_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'focus.xpEarned'.tr,
                    valueText: '+$xpEarned XP',
                    valueColor: semantic.primaryText,
                  ),
                  Divider(
                    height: 20,
                    thickness: 1,
                    color: isDark
                        ? AppColors.darkBorderSubtle
                        : AppColors.lightBorderSubtle,
                  ),

                  // Row 3: Status
                  _SummaryRow(
                    icon: Icons.info_rounded,
                    iconColor: isAbandoned
                        ? AppColors.danger
                        : AppColors.success,
                    label: 'focus.status'.tr,
                    valueWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isAbandoned
                                ? AppColors.danger
                                : AppColors.success)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        isAbandoned
                            ? 'focus.abandoned'.tr
                            : 'focus.complete'.tr,
                        style: TextStyle(
                          color: isAbandoned
                              ? AppColors.danger
                              : AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Primary Button "Got it"
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.productivityAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                'focus.gotIt'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.valueText,
    this.valueColor,
    this.valueWidget,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? valueText;
  final Color? valueColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: semantic.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (valueWidget != null)
          valueWidget!
        else if (valueText != null)
          Text(
            valueText!,
            style: TextStyle(
              color: valueColor ?? semantic.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
