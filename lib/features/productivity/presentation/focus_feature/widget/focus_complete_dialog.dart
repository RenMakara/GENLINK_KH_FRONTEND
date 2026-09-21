import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';

class FocusCompleteDialog extends StatelessWidget {
  const FocusCompleteDialog({
    super.key,
    required this.focusedMinutes,
    required this.xpEarned,
  });

  final int focusedMinutes;
  final int xpEarned;

  static Future<void> show(
    BuildContext context, {
    required int focusedMinutes,
    required int xpEarned,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => FocusCompleteDialog(
        focusedMinutes: focusedMinutes,
        xpEarned: xpEarned,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Illustration / Hero Graphic
            _CelebrationHeroGraphic(isDark: isDark),
            const SizedBox(height: 16),

            // Great Job Title
            Text(
              'focus.greatJob'.tr,
              style: TextStyle(
                color: semantic.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),

            // "You stayed focused"
            Text(
              'focus.youStayedFocused'.tr,
              style: TextStyle(
                color: semantic.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Large Duration text
            Text(
              '$focusedMinutes ${'focus.minutesStat'.tr}',
              style: TextStyle(
                color: semantic.primaryText,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // XP Earned Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Subtle Quote Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    size: 24,
                    color: AppColors.productivityAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'focus.completedQuote'.tr,
                      style: TextStyle(
                        color: semantic.secondaryText,
                        fontSize: 11.5,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Primary Done Button
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
                'focus.done'.tr,
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

class _CelebrationHeroGraphic extends StatelessWidget {
  const _CelebrationHeroGraphic({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft circular glow background
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: isDark ? 0.18 : 0.12),
            ),
          ),

          // Confetti decorative dots
          const Positioned(
            top: 10,
            left: 20,
            child: _ParticleDot(color: Color(0xFF8B7CF6), size: 9),
          ),
          const Positioned(
            top: 24,
            right: 22,
            child: _ParticleDot(color: Color(0xFFF59E0B), size: 7),
          ),
          const Positioned(
            bottom: 18,
            left: 18,
            child: _ParticleDot(color: Color(0xFF388BFD), size: 8),
          ),
          const Positioned(
            bottom: 22,
            right: 18,
            child: _ParticleDot(color: Color(0xFF22C55E), size: 7),
          ),
          const Positioned(
            top: 4,
            child: _ParticleDot(color: Color(0xFFFF1640), size: 6),
          ),

          // Success circle badge
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticleDot extends StatelessWidget {
  const _ParticleDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
