import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/leaderboard_controller.dart';
import '../../domain/models/leaderboard_models.dart';

class FullRankingScreen extends GetView<LeaderboardController> {
  const FullRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: Center(child: AppBackButton()),
        ),
        title: Text(
          'leaderboard.globalRanking'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ),
      body: Obx(() {
        final users = controller.globalUsers;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 1),
          itemBuilder: (_, i) => _buildRankRow(users[i], scheme),
        );
      }),
    );
  }

  Widget _buildRankRow(LeaderboardUser user, ColorScheme scheme) {
    final isMe = user.isCurrentUser;
    return GestureDetector(
      onTap: () => Get.toNamed('/leaderboard/profile', arguments: user),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isMe ? scheme.primary : scheme.outlineVariant,
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: isMe
              ? []
              : [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            _buildRankBadge(user.rank, isMe, scheme),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
                ),
              ),
              child: Icon(Icons.person, color: scheme.onPrimary, size: 22),
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
                          color: isMe ? scheme.primary : scheme.onSurface,
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
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'quiz.you'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimary,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        color: const Color(0xFFFFC107).withValues(alpha: 0.7),
                        size: 12,
                      ),
                      Text(
                        '${user.badges}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isMe, ColorScheme scheme) {
    Color bg;
    Color textColor;
    Widget child;

    if (rank == 1) {
      bg = const Color(0xFFFFC107).withValues(alpha: 0.12);
      textColor = const Color(0xFFFFA000);
      child = const Icon(
        Icons.emoji_events,
        size: 18,
        color: Color(0xFFFFA000),
      );
    } else if (rank == 2) {
      bg = scheme.surfaceContainerHighest;
      textColor = const Color(0xFF9CA3AF);
      child = const Icon(
        Icons.workspace_premium,
        size: 18,
        color: Color(0xFF9CA3AF),
      );
    } else if (rank == 3) {
      bg = const Color(0xFFD97706).withValues(alpha: 0.12);
      textColor = const Color(0xFFD97706);
      child = const Icon(
        Icons.military_tech,
        size: 18,
        color: Color(0xFFD97706),
      );
    } else {
      bg = isMe ? scheme.primary : scheme.outlineVariant;
      textColor = isMe ? scheme.onPrimary : scheme.onSurfaceVariant;
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
