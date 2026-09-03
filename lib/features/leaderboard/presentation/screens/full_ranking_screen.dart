import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/leaderboard_controller.dart';
import '../../domain/models/leaderboard_models.dart';
import '../../../quiz/presentation/quiz_colors.dart';

class FullRankingScreen extends GetView<LeaderboardController> {
  const FullRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'leaderboard.globalRanking'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
          ),
        ),
      ),
      body: Obx(() {
        final users = controller.globalUsers;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 1),
          itemBuilder: (_, i) => _buildRankRow(users[i]),
        );
      }),
    );
  }

  Widget _buildRankRow(LeaderboardUser user) {
    final isMe = user.isCurrentUser;
    return GestureDetector(
      onTap: () => Get.toNamed('/leaderboard/profile', arguments: user),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? QuizColors.primaryLight : QuizColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? QuizColors.primary : QuizColors.border,
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: isMe ? [] : QuizColors.cardShadow,
        ),
        child: Row(
          children: [
            _buildRankBadge(user.rank, isMe),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: QuizColors.gradient,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                          color: isMe ? QuizColors.primary : QuizColors.heading,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: QuizColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'quiz.you'.tr,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${user.xp} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: QuizColors.body,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        color: QuizColors.gold.withValues(alpha: 0.7),
                        size: 12,
                      ),
                      Text(
                        '${user.badges}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: QuizColors.body,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: QuizColors.border, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isMe) {
    Color bg;
    Color textColor;
    Widget child;

    if (rank == 1) {
      bg = const Color(0xFFFFF7E0);
      textColor = const Color(0xFFFFA000);
      child = const Icon(
        Icons.emoji_events,
        size: 18,
        color: Color(0xFFFFA000),
      );
    } else if (rank == 2) {
      bg = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF9CA3AF);
      child = const Icon(
        Icons.workspace_premium,
        size: 18,
        color: Color(0xFF9CA3AF),
      );
    } else if (rank == 3) {
      bg = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFD97706);
      child = const Icon(
        Icons.military_tech,
        size: 18,
        color: Color(0xFFD97706),
      );
    } else {
      bg = isMe ? QuizColors.primary : QuizColors.border;
      textColor = isMe ? Colors.white : QuizColors.body;
      child = Text(
        '$rank',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: child),
    );
  }
}
