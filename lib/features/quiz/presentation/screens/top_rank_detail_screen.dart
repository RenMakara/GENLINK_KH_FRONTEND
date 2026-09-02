import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../../domain/models/quiz_models.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';

class TopRankDetailScreen extends GetView<QuizController> {
  const TopRankDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderSection(),
              _buildAchievementsGrid(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: QuizGradientButton(
                  label: 'quiz.challenge'.tr,
                  icon: Icons.bolt,
                  onPressed: () {
                    Get.offAndToNamed('/quiz/categories');
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Get.until(
                  (route) =>
                      route.settings.name == '/quiz/dashboard' ||
                      route.settings.name == '/home',
                ),
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

  Widget _buildHeaderSection() {
    final topEntry =
        controller.leaderboard.firstWhereOrNull((e) => e.rank == 1) ??
        const LeaderboardEntry(
          rank: 1,
          name: 'Sovannarith',
          avatarUrl: '',
          xp: 12450,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x306C5CE7), QuizColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: QuizColors.heading),
            onPressed: () => Get.back(),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 48),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: QuizColors.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
<<<<<<< Updated upstream
                        color: QuizColors.primary.withOpacity(0.3),
=======
                        color: QuizColors.primary.withValues(alpha: 0.3),
>>>>>>> Stashed changes
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
<<<<<<< Updated upstream
                  child: const Text(
                    'Global Rank #1',
                    style: TextStyle(
=======
                  child: Text(
                    'quiz.globalRank'.trParams({'rank': '1'}),
                    style: const TextStyle(
>>>>>>> Stashed changes
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            topEntry.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: QuizColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: QuizColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                '${topEntry.xp} XP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: QuizColors.body,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: QuizCustomCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
            const Text(
              'Achievements',
              style: TextStyle(
=======
            Text(
              'quiz.achievements'.tr,
              style: const TextStyle(
>>>>>>> Stashed changes
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: QuizColors.heading,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: List.generate(8, (i) {
                final colors = const [
                  Color(0xFFFFD700),
                  Color(0xFFC0C0C0),
                  Color(0xFFCD7F32),
                  Color(0xFF8B5CF6),
                  Color(0xFF10B981),
                  Color(0xFFF59E0B),
                  Color(0xFFEF4444),
                  Color(0xFF3B82F6),
                ];
                final icons = const [
                  Icons.emoji_events,
                  Icons.workspace_premium,
                  Icons.military_tech,
                  Icons.psychology,
                  Icons.rocket_launch,
                  Icons.local_fire_department,
                  Icons.favorite,
                  Icons.auto_awesome,
                ];
                return Container(
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icons[i], color: colors[i], size: 28),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('148', 'quiz.quizzes'.tr, QuizColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildStatItem('12,450', 'XP', QuizColors.gold)),
          const SizedBox(width: 10),
          Expanded(
<<<<<<< Updated upstream
            child: _buildStatItem('8', 'Badges', const Color(0xFFF59E0B)),
=======
            child: _buildStatItem(
              '8',
              'quiz.badges'.tr,
              const Color(0xFFF59E0B),
            ),
>>>>>>> Stashed changes
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return QuizCustomCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
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
    );
  }
}
