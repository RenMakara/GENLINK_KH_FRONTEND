import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';

class RewardClaimedScreen extends GetView<QuizController> {
  const RewardClaimedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSuccessBadge(),
              const SizedBox(height: 20),
<<<<<<< Updated upstream
              const Text(
                'Reward Claimed!',
                style: TextStyle(
=======
              Text(
                'quiz.rewardClaimed'.tr,
                style: const TextStyle(
>>>>>>> Stashed changes
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: QuizColors.heading,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'quiz.rewardsAdded'.tr,
                style: const TextStyle(fontSize: 14, color: QuizColors.body),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _buildBalanceDisplay(),
              const SizedBox(height: 32),
              Obx(
                () => QuizGradientButton(
<<<<<<< Updated upstream
                  label: 'Continue',
=======
                  label: 'common.continue'.tr,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(
=======
                child: Text(
                  'quiz.backToDashboard'.tr,
                  style: const TextStyle(
>>>>>>> Stashed changes
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: QuizColors.body,
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x2010B981),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle,
                color: QuizColors.correct,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 14),
<<<<<<< Updated upstream
          const Text(
            'Congratulations!',
            style: TextStyle(
=======
          Text(
            'quiz.congratulations'.tr,
            style: const TextStyle(
>>>>>>> Stashed changes
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: QuizColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'quiz.rewardsCredited'.tr,
            style: const TextStyle(fontSize: 13, color: QuizColors.body),
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
              QuizColors.primary,
<<<<<<< Updated upstream
              '+${controller.quizResult.value?.xpEarned ?? 0}',
=======
              'quiz.xpValue'.trParams({
                'xp': '${controller.quizResult.value?.xpEarned ?? 0}',
              }),
>>>>>>> Stashed changes
            ),
            const SizedBox(width: 10),
            _buildBalancePill(
              Icons.monetization_on,
<<<<<<< Updated upstream
              'Coins',
              '${stats.coins}',
              QuizColors.gold,
              '+${controller.quizResult.value?.coinsEarned ?? 0}',
=======
              'quiz.coins'.tr,
              '${stats.coins}',
              QuizColors.gold,
              'quiz.coinsValue'.trParams({
                'coins': '${controller.quizResult.value?.coinsEarned ?? 0}',
              }),
>>>>>>> Stashed changes
            ),
            const SizedBox(width: 10),
            _buildBalancePill(
              Icons.military_tech,
<<<<<<< Updated upstream
              'Badges',
              '${stats.badges}',
              const Color(0xFFF59E0B),
              '+1',
=======
              'quiz.badges'.tr,
              '${stats.badges}',
              const Color(0xFFF59E0B),
              '+0',
>>>>>>> Stashed changes
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
            Icon(icon, color: color, size: 24),
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: QuizColors.body,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x2010B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                increment,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: QuizColors.correct,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
