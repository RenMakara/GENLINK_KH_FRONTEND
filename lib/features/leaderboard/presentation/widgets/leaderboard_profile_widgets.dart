import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../domain/models/leaderboard_models.dart';

/// Hero card displaying user avatar, crown badge, name, rank pill, and subtle emblem.
class LeaderboardProfileHero extends StatelessWidget {
  const LeaderboardProfileHero({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF222631),
            Color(0xFF14161E),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle background decorative crown emblem
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'leaderboard.smallStepsBigKnowledge'.tr,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Profile Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Crown Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 2.0,
                      ),
                    ),
                    child: AppAvatar(
                      imageUrl: entry.avatarUrl,
                      name: entry.name,
                      size: 76,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.growthAccent,
                        border: Border.all(
                          color: const Color(0xFF1B1E26),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 15,
                          color: Color(0xFF2C1F03),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Name, Rank Pill, Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'leaderboard.rankValue'.trParams({
                          'rank': '${entry.rank}',
                        }),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'leaderboard.keepLearning'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3-column statistics card displaying Points, Global Rank, and Level.
class LeaderboardProfileStatsRow extends StatelessWidget {
  const LeaderboardProfileStatsRow({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: semantic.borderSubtle,
        ),
        boxShadow: semantic.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatColumn(
                icon: Icons.star_rounded,
                iconColor: AppColors.growthAccent,
                iconBgColor: AppColors.growthAccent.withValues(alpha: 0.14),
                value: '${entry.points}',
                title: 'leaderboard.points'.tr.capitalizeFirst ?? 'Points',
                subtitle: 'leaderboard.totalPointsEarned'.tr,
              ),
            ),
            VerticalDivider(
              color: semantic.borderSubtle,
              thickness: 1,
              width: 1,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: _StatColumn(
                icon: Icons.bar_chart_rounded,
                iconColor: AppColors.financeAccent,
                iconBgColor: AppColors.financeAccent.withValues(alpha: 0.14),
                value: '#${entry.rank}',
                title: 'leaderboard.globalRank'.tr,
                subtitle: 'leaderboard.outOfAllLearners'.tr,
              ),
            ),
            VerticalDivider(
              color: semantic.borderSubtle,
              thickness: 1,
              width: 1,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: _StatColumn(
                icon: Icons.layers_rounded,
                iconColor: AppColors.productivityAccent,
                iconBgColor:
                    AppColors.productivityAccent.withValues(alpha: 0.14),
                value: '${entry.level}',
                title: 'leaderboard.level'.tr,
                subtitle: 'leaderboard.currentLevel'.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String value;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: semantic.primaryText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: semantic.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: semantic.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP and Level progress card calculated dynamically from real points and level.
class LeaderboardXpProgressCard extends StatelessWidget {
  const LeaderboardXpProgressCard({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    // Standard 100 XP per level calculation
    final currentXpInLevel = entry.points % 100;
    final xpToNext = 100 - currentXpInLevel;
    final progress = (currentXpInLevel / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'leaderboard.level'.tr} ${entry.level}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: semantic.primaryText,
                      ),
                    ),
                    Text(
                      'leaderboard.xpToNextLevel'.trParams({
                        'xp': '$xpToNext',
                      }),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: semantic.backgroundSecondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.financeAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'leaderboard.xpProgress'.trParams({
                    'current': '$currentXpInLevel',
                    'max': '100',
                  }),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.financeAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.financeAccent.withValues(alpha: 0.25),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.spa_rounded,
                color: AppColors.financeAccent,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievements section showing real badges from GenLink's backend with a "See All" link.
class LeaderboardAchievementsSection extends StatelessWidget {
  const LeaderboardAchievementsSection({
    super.key,
    required this.badges,
    this.isLoading = false,
  });

  final List<BadgeEntity> badges;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'leaderboard.achievements'.tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: semantic.primaryText,
              ),
            ),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.leaderboardAchievements),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'leaderboard.seeAll'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: semantic.primaryText,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: semantic.primaryText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Badges container
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: semantic.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: semantic.borderSubtle),
            boxShadow: semantic.cardShadow,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 90,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : badges.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'leaderboard.achievementsUnavailable'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: semantic.secondaryText,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < badges.take(4).length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: _BadgeItem(badge: badges[i]),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({required this.badge});

  final BadgeEntity badge;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final earned = badge.earned;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: earned
                ? AppColors.growthAccent.withValues(alpha: 0.16)
                : semantic.backgroundSecondary,
            border: Border.all(
              color: earned
                  ? AppColors.growthAccent.withValues(alpha: 0.4)
                  : semantic.borderSubtle,
              width: 1.2,
            ),
          ),
          child: Center(
            child: earned
                ? const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.growthAccent,
                    size: 26,
                  )
                : Icon(
                    Icons.lock_outline_rounded,
                    color: semantic.textMuted,
                    size: 22,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: earned ? semantic.primaryText : semantic.secondaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          badge.requirement ?? badge.description ?? '',
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            height: 1.2,
            color: earned ? semantic.secondaryText : semantic.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Navigation action card for "View Ranking".
class LeaderboardActionCard extends StatelessWidget {
  const LeaderboardActionCard({
    super.key,
    required this.entry,
  });

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (Get.previousRoute == AppRoutes.leaderboardRanking) {
            Get.back();
          } else {
            Get.toNamed(AppRoutes.leaderboardRanking);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: semantic.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: semantic.borderSubtle),
            boxShadow: semantic.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.brandPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'leaderboard.viewRanking'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: semantic.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'leaderboard.viewRankingSubtitle'.trParams({
                        'name': entry.name,
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: semantic.secondaryText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Motivational quote card at the bottom of the profile.
class LeaderboardMotivationalCard extends StatelessWidget {
  const LeaderboardMotivationalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? semantic.surface
            : const Color(0xFFFFFBEB).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? semantic.borderSubtle
              : const Color(0xFFFDE68A).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.growthAccent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppColors.growthAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'leaderboard.profileMotivationQuote'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'leaderboard.profileMotivationSub'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: semantic.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
