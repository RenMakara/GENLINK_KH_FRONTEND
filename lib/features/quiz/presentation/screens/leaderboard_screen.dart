import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../../domain/models/quiz_models.dart';
import '../widgets/quiz_gradient_button.dart';

class LeaderboardScreen extends GetView<QuizController> {
  const LeaderboardScreen({super.key});

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
        title: Text(
          'quiz.leaderboard'.tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizThemeColors.heading,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildPodium(),
            const SizedBox(height: 24),
            _buildRankedList(),
            const SizedBox(height: 20),
            QuizGradientButton(
              label: 'quiz.viewFullLeaderboard'.tr,
              onPressed: () {
                Get.toNamed('/quiz/top-rank');
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
    );
  }

  Widget _buildPodium() {
    return Obx(() {
      final entries = controller.leaderboard.take(3).toList();
      if (entries.length < 3) return const SizedBox.shrink();

      return SizedBox(
        height: 200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place
            Expanded(
              child: _buildPodiumItem(
                entries[1],
                56,
                QuizThemeColors.medalSilver,
              ),
            ),
            // 1st place
            Expanded(
              child: _buildPodiumItem(entries[0], 72, QuizThemeColors.gold),
            ),
            // 3rd place
            Expanded(
              child: _buildPodiumItem(
                entries[2],
                48,
                QuizThemeColors.medalBronze,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPodiumItem(
    LeaderboardEntry entry,
    double crownSize,
    Color crownColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [crownColor.withValues(alpha: 0.8), crownColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: crownColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: QuizThemeColors.onPrimary,
                size: 32,
              ),
            ),
            Positioned(
              top: -20,
              child: Icon(Icons.emoji_events, color: crownColor, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: QuizThemeColors.heading,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.xp} XP',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: QuizThemeColors.body,
          ),
        ),
      ],
    );
  }

  Widget _buildRankedList() {
    return Obx(() {
      final entries = controller.leaderboard.skip(3).toList();
      return Column(
        children: entries.map((entry) {
          final isMe = entry.isCurrentUser;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isMe
                  ? QuizThemeColors.primaryLight
                  : QuizThemeColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMe ? QuizThemeColors.primary : QuizThemeColors.border,
              ),
              boxShadow: isMe ? [] : QuizThemeColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isMe
                        ? QuizThemeColors.primary
                        : QuizThemeColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.rank}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isMe
                            ? QuizThemeColors.onPrimary
                            : QuizThemeColors.body,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: QuizThemeColors.gradient,
                  ),
                  child: Icon(
                    Icons.person,
                    color: QuizThemeColors.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                          color: isMe
                              ? QuizThemeColors.primary
                              : QuizThemeColors.heading,
                        ),
                      ),
                      Text(
                        '${entry.xp} XP',
                        style: TextStyle(
                          fontSize: 12,
                          color: QuizThemeColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMe)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: QuizThemeColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'quiz.you'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: QuizThemeColors.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}
