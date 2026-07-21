import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

/// Achievements: the level card (level · XP · badges earned) and the full
/// badge grid, earned first, locked greyed with their unlock requirement.
///
/// The design's "completed challenges" list has no history endpoint and is
/// not rendered.
class AchievementsScreen extends GetView<ProfileController> {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: AppBackButton(),
        ),
        leadingWidth: 58 + AppSpacing.md * 2,
        title: Text('profile.achievements'.tr),
      ),
      body: Obx(() {
        final profile = controller.profile.value;
        if (profile == null) return const AppLoader();

        final badges = controller.sortedBadges;
        final earnedCount = badges.where((b) => b.earned).length;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Level card (dark, like the design) ──────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LevelStat(
                        value: '${profile.level}',
                        label: 'achievements.level'.tr,
                      ),
                      _LevelStat(
                        value: '${profile.totalXp}',
                        label: 'achievements.totalXp'.tr,
                      ),
                      _LevelStat(
                        value: '$earnedCount',
                        label: 'achievements.badges'.tr,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: profile.levelProgress,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'achievements.toNextLevel'.trParams({
                      'xp': '${profile.xpForNextLevel - profile.totalXp}',
                      'level': '${profile.level + 1}',
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Badge grid ─────────────────────────────────────────────
            Text('achievements.myBadges'.tr,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (badges.isEmpty)
              AppEmptyState(
                message: 'achievements.empty'.tr,
                icon: Icons.workspace_premium_outlined,
              )
            else
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.72,
                children: [
                  for (final badge in badges)
                    Tooltip(
                      // The unlock requirement surfaces on long-press.
                      message: badge.earned
                          ? (badge.description ?? badge.name)
                          : (badge.requirement ?? badge.name),
                      child: BadgeTile(badge: badge),
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }
}

class _LevelStat extends StatelessWidget {
  const _LevelStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: onPrimary.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
