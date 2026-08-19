import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/leaderboard_controller.dart';
import '../../domain/models/leaderboard_models.dart';
import '../../../quiz/presentation/quiz_colors.dart';

class AchievementsScreen extends GetView<LeaderboardController> {
  const AchievementsScreen({super.key});

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
        title: const Text(
          'All Achievements',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: QuizColors.heading),
        ),
      ),
      body: Obx(() {
        final achievements = controller.allAchievements;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: achievements.map((a) => _buildAchievementCard(a)).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: QuizColors.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Text(
                          'Back to Leaderboard',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAchievementCard(Achievement a) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QuizColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizColors.border),
        boxShadow: QuizColors.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: a.isUnlocked
                  ? a.color.withOpacity(0.12)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              a.icon,
              color: a.isUnlocked ? a.color : const Color(0xFFD1D5DB),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            a.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: a.isUnlocked ? QuizColors.heading : QuizColors.body,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: a.isUnlocked ? QuizColors.body : const Color(0xFFD1D5DB),
            ),
          ),
          if (!a.isUnlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Locked',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DB)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
