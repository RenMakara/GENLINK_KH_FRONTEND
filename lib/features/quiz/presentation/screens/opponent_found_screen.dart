import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';

class OpponentFoundScreen extends GetView<QuizController> {
  const OpponentFoundScreen({super.key});

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
                style: const TextStyle(fontSize: 12, color: QuizColors.body),
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
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerColumn(
                  user.name,
<<<<<<< Updated upstream
                  'Lv. ${user.level}',
                  '${user.streak} Streak',
=======
                  'quiz.levelShort'.trParams({'level': '${user.level}'}),
                  'quiz.streakShort'.trParams({'count': '${user.streak}'}),
>>>>>>> Stashed changes
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: QuizColors.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                _buildPlayerColumn(
                  opp.name,
<<<<<<< Updated upstream
                  'Lv. ${opp.level}',
                  '${opp.winRate}% Win',
=======
                  'quiz.levelShort'.trParams({'level': '${opp.level}'}),
                  'quiz.winRate'.trParams({'percent': '${opp.winRate}'}),
>>>>>>> Stashed changes
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: QuizColors.border,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: QuizColors.gradient,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
<<<<<<< Updated upstream
            const Text(
              'Fair Match',
              style: TextStyle(
=======
            Text(
              'quiz.fairMatch'.tr,
              style: const TextStyle(
>>>>>>> Stashed changes
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: QuizColors.correct,
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: QuizColors.gradient,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          level,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: QuizColors.body,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: QuizColors.primary,
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
<<<<<<< Updated upstream
          const Text(
            'Game Rules',
            style: TextStyle(
=======
          Text(
            'quiz.gameRules'.tr,
            style: const TextStyle(
>>>>>>> Stashed changes
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: QuizColors.heading,
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
<<<<<<< Updated upstream
          _buildRuleRow(
            Icons.emoji_events_outlined,
            'Earn XP & Coins for correct answers',
          ),
=======
          _buildRuleRow(Icons.emoji_events_outlined, 'quiz.ruleEarnRewards'.tr),
>>>>>>> Stashed changes
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
            color: QuizColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: QuizColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: QuizColors.body),
        ),
      ],
    );
  }
}
