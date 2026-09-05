import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.heading),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: QuizColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'quiz.rewardSubtitle'.tr,
                style: const TextStyle(fontSize: 14, color: QuizColors.body),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: QuizColors.body,
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
      padding: const EdgeInsets.all(32),
      borderRadius: 24,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: QuizColors.primaryLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: QuizColors.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'quiz.rewardsUnlocked'.tr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: QuizColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'quiz.performanceRewards'.tr,
            style: const TextStyle(fontSize: 13, color: QuizColors.body),
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
          QuizColors.primary,
          const Color(0x206C5CE7),
        ),
        const SizedBox(height: 12),
        _buildRewardRow(
          Icons.monetization_on,
          'quiz.coinsValue'.trParams({'coins': '${quizResult.coinsEarned}'}),
          'quiz.quizCoins'.tr,
          QuizColors.gold,
          const Color(0x20FFC107),
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
        color: QuizColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizColors.border),
        boxShadow: QuizColors.cardShadow,
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
                  style: const TextStyle(fontSize: 12, color: QuizColors.body),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: QuizColors.border, size: 22),
        ],
      ),
    );
  }
}
