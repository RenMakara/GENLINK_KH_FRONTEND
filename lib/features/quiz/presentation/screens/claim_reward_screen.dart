import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../../domain/models/quiz_models.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';

class ClaimRewardScreen extends GetView<QuizController> {
  const ClaimRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: QuizThemeColors.heading),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Obx(() {
          final result = controller.quizResult.value;
          if (result == null) return const SizedBox.shrink();

          return Column(
            children: [
              const SizedBox(height: 10),
              _buildGiftBox(),
              const SizedBox(height: 24),
              Text(
                'quiz.yourReward'.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: QuizThemeColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'quiz.rewardSubtitle'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QuizThemeColors.body,
                ),
              ),
              const SizedBox(height: 24),
              _buildRewardBreakdown(result),
              const SizedBox(height: 28),
              QuizGradientButton(
                label: 'quiz.claimReward'.tr,
                icon: Icons.card_giftcard,
                onPressed: () {
                  Get.toNamed('/quiz/reward-animation');
                },
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Get.until(
                  (route) =>
                      route.settings.name == '/quiz/dashboard' ||
                      route.settings.name == '/home',
                ),
                child: Text(
                  'quiz.maybeLater'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: QuizThemeColors.body,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGiftBox() {
    return QuizCustomCard(
      glass: true,
      padding: const EdgeInsets.all(32),
      borderRadius: AppRadius.xl,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: QuizThemeColors.primaryLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.card_giftcard,
              color: QuizThemeColors.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'quiz.rewardsUnlocked'.tr,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'quiz.performanceRewards'.tr,
            style: TextStyle(fontSize: 13, color: QuizThemeColors.body),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardBreakdown(QuizResult quizResult) {
    return Column(
      children: [
        _buildRewardRow(
          Icons.star,
          'quiz.xpValue'.trParams({'xp': '${quizResult.xpEarned}'}),
          'quiz.experiencePoints'.tr,
          QuizThemeColors.primary,
          QuizThemeColors.primarySoft,
        ),
        const SizedBox(height: 12),
        _buildRewardRow(
          Icons.monetization_on,
          'quiz.coinsValue'.trParams({'coins': '${quizResult.coinsEarned}'}),
          'quiz.quizCoins'.tr,
          QuizThemeColors.gold,
          QuizThemeColors.warningSoft,
        ),
      ],
    );
  }

  Widget _buildRewardRow(
    IconData icon,
    String value,
    String label,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: QuizThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizThemeColors.border),
        boxShadow: QuizThemeColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: QuizThemeColors.body),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: QuizThemeColors.border, size: 22),
        ],
      ),
    );
  }
}
