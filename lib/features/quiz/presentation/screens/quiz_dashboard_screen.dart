import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';
import '../../../../app/routes/app_routes.dart';

class QuizDashboardScreen extends GetView<QuizController> {
  const QuizDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.heading),
          onPressed: () {
            if (Get.previousRoute.isNotEmpty) {
              Get.back();
            } else {
              Get.offAllNamed(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: QuizColors.heading),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildQuickPlayCards(),
            const SizedBox(height: 24),
            _buildLearningProgress(),
            const SizedBox(height: 24),
            _buildCategoriesPreview(),
            const SizedBox(height: 24),
            _buildLeaderboardCard(),
            const SizedBox(height: 24),
            _buildBottomAction(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final stats = controller.userStats.value;
      return QuizCustomCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: QuizColors.gradient,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${stats.name} 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: QuizColors.heading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: QuizColors.gradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Level ${stats.level}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.xp / stats.xpToNextLevel,
                backgroundColor: QuizColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(QuizColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${stats.xp} / ${stats.xpToNextLevel} XP',
              style: const TextStyle(fontSize: 12, color: QuizColors.body),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsRow() {
    return Obx(() {
      final stats = controller.userStats.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: QuizColors.statGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: QuizColors.gold, size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${stats.streak} Days',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const Text('Active Streak',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 36, color: const Color(0xFF4B5563)),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: QuizColors.gold, size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${stats.coins}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const Text('Coins',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickPlayCards() {
    return Row(
      children: [
        Expanded(
          child: _buildQuizTypeCard(
            Icons.person_outline,
            'Single Quiz',
            'Play alone',
            QuizColors.correct,
            QuizType.single,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuizTypeCard(
            Icons.group_outlined,
            'Random Quiz',
            'Find opponent',
            QuizColors.primary,
            QuizType.random,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizTypeCard(IconData icon, String title, String subtitle, Color color, QuizType type) {
    return GestureDetector(
      onTap: () {
        controller.setQuizType(type);
        Get.toNamed('/quiz/categories');
      },
      child: QuizCustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: QuizColors.heading)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: QuizColors.body)),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningProgress() {
    return QuizCustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.trending_up, color: QuizColors.correct, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Learning Progress',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: QuizColors.heading)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    backgroundColor: QuizColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(QuizColors.correct),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('72% Complete', style: TextStyle(fontSize: 12, color: QuizColors.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: QuizColors.heading)),
            GestureDetector(
              onTap: () => Get.toNamed('/quiz/categories'),
              child: const Text('See All',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: QuizColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = controller.categories[index];
              final bgColor = QuizColors.categoryColors[cat.colorIndex];
              final iconColor = QuizColors.categoryIconColors[cat.colorIndex];
              return GestureDetector(
                onTap: () {
                  controller.selectCategory(cat);
                  if (controller.quizType.value == QuizType.single) {
                    controller.startQuiz();
                    Get.toNamed('/quiz/in-progress');
                  } else {
                    controller.startMatchmaking();
                    Get.toNamed('/quiz/matchmaking');
                  }
                },
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: QuizColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: QuizColors.border),
                    boxShadow: QuizColors.cardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.star, color: iconColor, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(cat.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: QuizColors.heading),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.leaderboard),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: QuizColors.statGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x301E1B4B),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: QuizColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.emoji_events, color: QuizColors.gold, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Leaderboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'See how you rank globally',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return QuizGradientButton(
      label: 'Start New Quiz',
      icon: Icons.play_arrow_rounded,
      onPressed: () => Get.toNamed('/quiz/categories'),
    );
  }
}
