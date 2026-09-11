import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';
import '../widgets/quiz_icon_container.dart';

class RewardClaimedScreen extends GetView<QuizController> {
  const RewardClaimedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSuccessBadge(),
              const SizedBox(height: 20),
              Text(
                'quiz.rewardClaimed'.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: QuizThemeColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'quiz.rewardsAdded'.tr,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: QuizThemeColors.body),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _buildBalanceDisplay(),
              const SizedBox(height: 32),
              Obx(
                () => QuizGradientButton(
                  label: 'common.continue'.tr,
                  icon: Icons.arrow_forward,
                  isLoading: controller.isRewardClaimed.value,
                  onPressed: controller.isRewardClaimed.value
                      ? null
                      : () {
                          controller.claimReward();
                          Get.until(
                            (route) =>
                                route.settings.name == '/quiz/dashboard' ||
                                route.settings.name == '/home',
                          );
                        },
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  if (!controller.isRewardClaimed.value) {
                    controller.claimReward();
                  }
                  Get.until(
                    (route) =>
                        route.settings.name == '/quiz/dashboard' ||
                        route.settings.name == '/home',
                  );
                },
                child: Text(
                  'quiz.backToDashboard'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: QuizThemeColors.body,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return QuizCustomCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QuizThemeColors.correctSoft,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle,
                color: QuizThemeColors.correct,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'quiz.congratulations'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'quiz.rewardsCredited'.tr,
            style: TextStyle(fontSize: 13, color: QuizThemeColors.body),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return Obx(() {
      final stats = controller.userStats.value;
      return QuizCustomCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildBalancePill(
              Icons.star,
              'XP',
              '${stats.xp}',
              QuizThemeColors.primary,
              'quiz.xpValue'.trParams({
                'xp': '${controller.quizResult.value?.xpEarned ?? 0}',
              }),
            ),
            const SizedBox(width: 10),
            _buildBalancePill(
              Icons.monetization_on,
              'quiz.coins'.tr,
              '${stats.coins ?? '-'}',
              QuizThemeColors.gold,
              'quiz.coinsValue'.trParams({
                'coins': '${controller.quizResult.value?.coinsEarned ?? 0}',
              }),
            ),
            const SizedBox(width: 10),
            _buildBalancePill(
              Icons.military_tech,
              'quiz.badges'.tr,
              '${stats.badges ?? '-'}',
              QuizThemeColors.gold,
              '-',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBalancePill(
    IconData icon,
    String label,
    String value,
    Color color,
    String increment,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            QuizIconContainer(
              icon: icon,
              accentColor: color,
              size: 36,
              iconSize: 20,
              borderRadius: AppRadius.md,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: QuizThemeColors.body,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: QuizThemeColors.correctSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                increment,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: QuizThemeColors.correct,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
