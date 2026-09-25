import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/shadows/app_shadows.dart';

/// Modern iOS-style quiz option tile supporting Default, Selected, Correct,
/// and Incorrect states with smooth visual transitions.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.index,
    required this.isSelected,
    this.isCorrect,
    this.onTap,
    this.showResult = false,
  });

  final String label;
  final int index;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback? onTap;
  final bool showResult;

  String get _optionLetter => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors and styling for the 4 distinct states
    final Color bgColor;
    final Color borderColor;
    final double borderWidth;
    final Color textColor;
    final FontWeight fontWeight;
    final Color indicatorBg;
    final Color indicatorBorder;
    final Color indicatorTextColor;
    final Widget? suffixIcon;
    final List<BoxShadow> shadows;

    if (showResult && isCorrect != null) {
      if (isCorrect!) {
        // CORRECT STATE
        bgColor = isDark
            ? AppColors.success.withValues(alpha: 0.22)
            : AppColors.success.withValues(alpha: 0.10);
        borderColor = AppColors.success;
        borderWidth = 2.0;
        textColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF14532D);
        fontWeight = FontWeight.w600;
        indicatorBg = AppColors.success;
        indicatorBorder = AppColors.success;
        indicatorTextColor = Colors.white;
        suffixIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 24,
        );
        shadows = const [];
      } else if (isSelected) {
        // INCORRECT STATE (selected by user but wrong)
        bgColor = isDark
            ? AppColors.danger.withValues(alpha: 0.22)
            : AppColors.danger.withValues(alpha: 0.08);
        borderColor = AppColors.danger;
        borderWidth = 2.0;
        textColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF7F1D1D);
        fontWeight = FontWeight.w600;
        indicatorBg = AppColors.danger;
        indicatorBorder = AppColors.danger;
        indicatorTextColor = Colors.white;
        suffixIcon = const Icon(
          Icons.cancel_rounded,
          color: AppColors.danger,
          size: 24,
        );
        shadows = const [];
      } else {
        // Unselected option during result reveal
        bgColor = isDark
            ? AppColors.darkSurfacePrimary.withValues(alpha: 0.5)
            : AppColors.lightSurfacePrimary.withValues(alpha: 0.6);
        borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
        borderWidth = 1.0;
        textColor = (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
            .withValues(alpha: 0.5);
        fontWeight = FontWeight.w400;
        indicatorBg = isDark
            ? AppColors.darkSurfaceSecondary
            : const Color(0xFFF3F4F6);
        indicatorBorder = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
        indicatorTextColor = (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        suffixIcon = null;
        shadows = const [];
      }
    } else if (isSelected) {
      // SELECTED STATE
      bgColor = isDark
          ? AppColors.success.withValues(alpha: 0.18)
          : AppColors.success.withValues(alpha: 0.08);
      borderColor = AppColors.success;
      borderWidth = 2.0;
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
      fontWeight = FontWeight.w600;
      indicatorBg = AppColors.success;
      indicatorBorder = AppColors.success;
      indicatorTextColor = Colors.white;
      suffixIcon = const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
        size: 22,
      );
      shadows = isDark
          ? const []
          : [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ];
    } else {
      // DEFAULT STATE
      bgColor = isDark
          ? AppColors.darkSurfacePrimary
          : AppColors.lightSurfacePrimary;
      borderColor = isDark
          ? AppColors.darkBorderSubtle
          : AppColors.lightBorderSubtle;
      borderWidth = 1.0;
      textColor = isDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary;
      fontWeight = FontWeight.w500;
      indicatorBg = isDark
          ? AppColors.darkSurfaceSecondary
          : const Color(0xFFF9FAFB);
      indicatorBorder = isDark
          ? AppColors.darkBorderStrong
          : AppColors.lightBorderStrong;
      indicatorTextColor = isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;
      suffixIcon = null;
      shadows = isDark ? const [] : AppShadows.cardLight;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: showResult ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashColor: AppColors.success.withValues(alpha: 0.12),
            highlightColor: AppColors.success.withValues(alpha: 0.06),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Circular A / B / C / D indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indicatorBg,
                        border: Border.all(
                          color: indicatorBorder,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _optionLetter,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: indicatorTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Option Answer Text
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: fontWeight,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                    ),

                    // Trailing icon (Check / Cancel)
                    if (suffixIcon != null) ...[
                      const SizedBox(width: 10),
                      suffixIcon,
                    ],
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
