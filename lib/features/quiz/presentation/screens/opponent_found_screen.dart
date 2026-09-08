import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';

class OpponentFoundScreen extends GetView<QuizController> {
  const OpponentFoundScreen({super.key});

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
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildVsCard(),
            const SizedBox(height: 20),
            _buildGameInfoCard(),
            const SizedBox(height: 28),
            QuizGradientButton(
              label: 'quiz.startQuiz'.tr,
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                controller.startQuiz();
                Get.toNamed('/quiz/in-progress');
              },
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'quiz.quitAnytime'.tr,
                style: TextStyle(fontSize: 12, color: QuizThemeColors.body),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVsCard() {
    return Obx(() {
      final opp = controller.opponent.value;
      final user = controller.userStats.value;

      return QuizCustomCard(
        glass: true,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerColumn(
                  user.name,
                  'quiz.levelShort'.trParams({'level': '${user.level}'}),
                  user.streak == null
                      ? '-'
                      : 'quiz.streakShort'.trParams({
                          'count': '${user.streak}',
                        }),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: QuizThemeColors.gradient,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: QuizThemeColors.onPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                _buildPlayerColumn(
                  opp.name,
                  'quiz.levelShort'.trParams({'level': '${opp.level}'}),
                  'quiz.winRate'.trParams({'percent': '${opp.winRate}'}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                color: QuizThemeColors.border,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                    gradient: QuizThemeColors.gradient,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'quiz.fairMatch'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: QuizThemeColors.correct,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlayerColumn(String name, String level, String stat) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: QuizThemeColors.gradient,
          ),
          child: Icon(Icons.person, color: QuizThemeColors.onPrimary, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
            color: QuizThemeColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          level,
          style: Theme.of(Get.context!).textTheme.labelMedium?.copyWith(
            color: QuizThemeColors.body,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat,
          style: Theme.of(Get.context!).textTheme.labelSmall?.copyWith(
            color: QuizThemeColors.body,
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfoCard() {
    return QuizCustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quiz.gameRules'.tr,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 14),
          _buildRuleRow(
            Icons.quiz_outlined,
            'quiz.ruleQuestions'.trParams({'count': '10'}),
          ),
          const SizedBox(height: 10),
          _buildRuleRow(
            Icons.timer_outlined,
            'quiz.ruleSecondsPerQuestion'.trParams({'seconds': '30'}),
          ),
          const SizedBox(height: 10),
          _buildRuleRow(Icons.emoji_events_outlined, 'quiz.ruleEarnRewards'.tr),
          const SizedBox(height: 10),
          _buildRuleRow(Icons.skip_next_outlined, 'quiz.ruleSkipAnytime'.tr),
        ],
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: QuizThemeColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: QuizThemeColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 14, color: QuizThemeColors.body)),
      ],
    );
  }
}
