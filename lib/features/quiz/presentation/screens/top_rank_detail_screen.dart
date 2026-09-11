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
      backgroundColor: QuizThemeColors.background,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [QuizThemeColors.primarySoft, QuizThemeColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: QuizThemeColors.heading),
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
                  gradient: LinearGradient(
                    colors: [
                      QuizThemeColors.gold,
                      QuizThemeColors.gold.withValues(alpha: 0.78),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: QuizThemeColors.gold.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: QuizThemeColors.onPrimary,
                  size: 48,
                ),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: QuizThemeColors.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: QuizThemeColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'quiz.globalRank'.trParams({'rank': '1'}),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: QuizThemeColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            topEntry.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: QuizThemeColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                '${topEntry.xp} XP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: QuizThemeColors.body,
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
            Text(
              'quiz.achievements'.tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: QuizThemeColors.heading,
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
                final colors = [
                  QuizThemeColors.gold,
                  QuizThemeColors.medalSilver,
                  QuizThemeColors.medalBronze,
                  QuizThemeColors.primary,
                  QuizThemeColors.correct,
                  QuizThemeColors.gold,
                  QuizThemeColors.incorrect,
                  QuizThemeColors.primary,
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
            child: _buildStatItem(
              '148',
              'quiz.quizzes'.tr,
              QuizThemeColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildStatItem('12,450', 'XP', QuizThemeColors.gold)),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatItem('8', 'quiz.badges'.tr, QuizThemeColors.gold),
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
            style: TextStyle(fontSize: 12, color: QuizThemeColors.body),
          ),
        ],
      ),
    );
  }
}
