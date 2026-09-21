import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/entities/profile_entity.dart';

/// Elevated hero card showing Level, Total XP, Badges, and dynamic XP progress.
class AchievementSummaryHeroCard extends StatelessWidget {
  const AchievementSummaryHeroCard({
    super.key,
    required this.profile,
    required this.earnedBadgesCount,
  });

  final ProfileEntity profile;
  final int earnedBadgesCount;

  @override
  Widget build(BuildContext context) {
    final toNext = profile.xpForNextLevel - profile.totalXp;
    final nextLevel = profile.level + 1;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Level Emblem + 3 Stats
          Row(
            children: [
              // Level Emblem
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.growthAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.growthAccent.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.growthAccent.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.growthAccent,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'achievements.level'.tr} ${profile.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),

              // 3 Stats Columns
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HeroStatItem(
                      value: '${profile.level}',
                      label: 'achievements.level'.tr,
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    _HeroStatItem(
                      value: '${profile.totalXp}',
                      label: 'achievements.totalXp'.tr,
                    ),
                    Container(
                      height: 32,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    _HeroStatItem(
                      value: '$earnedBadgesCount',
                      label: 'achievements.badges'.tr,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // XP Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: profile.levelProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.financeAccent,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Row: 212 / 300 XP and 88 XP to Level 4
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'achievements.xpProgress'.trParams({
                  'current': '${profile.totalXp}',
                  'max': '${profile.xpForNextLevel}',
                }),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'achievements.toNextLevel'.trParams({
                  'xp': '$toNext',
                  'level': '$nextLevel',
                }),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// Filter pill bar: [ All ] [ Unlocked ] [ Locked ]
class AchievementFilterBar extends StatelessWidget {
  const AchievementFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterPill(
          label: 'achievements.filterAll'.tr,
          filterKey: 'all',
          isSelected: selectedFilter == 'all',
          onTap: () => onFilterChanged('all'),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: 'achievements.filterUnlocked'.tr,
          filterKey: 'unlocked',
          isSelected: selectedFilter == 'unlocked',
          onTap: () => onFilterChanged('unlocked'),
        ),
        const SizedBox(width: 8),
        _FilterPill(
          label: 'achievements.filterLocked'.tr,
          filterKey: 'locked',
          isSelected: selectedFilter == 'locked',
          onTap: () => onFilterChanged('locked'),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.filterKey,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String filterKey;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: isSelected ? semantic.primary : semantic.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? semantic.primary : semantic.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? semantic.textInverse : semantic.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean responsive badge card communicating earned vs locked states with clear hierarchy.
class AchievementBadgeCard extends StatelessWidget {
  const AchievementBadgeCard({
    super.key,
    required this.badge,
    this.onTap,
  });

  final BadgeEntity badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semantic = context.semanticColors;
    final earned = badge.earned;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: earned
                ? (isDark ? const Color(0xFF28251E) : const Color(0xFFFFFDF5))
                : semantic.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: earned
                  ? AppColors.growthAccent.withValues(alpha: isDark ? 0.45 : 0.4)
                  : semantic.borderSubtle,
              width: earned ? 1.2 : 1.0,
            ),
            boxShadow: earned
                ? [
                    BoxShadow(
                      color: AppColors.growthAccent.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : semantic.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon Squircle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: earned
                      ? AppColors.growthAccent.withValues(alpha: 0.18)
                      : semantic.backgroundSecondary,
                  border: Border.all(
                    color: earned
                        ? AppColors.growthAccent.withValues(alpha: 0.45)
                        : semantic.borderSubtle,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: _badgeIcon(earned, semantic),
                ),
              ),
              const SizedBox(height: 10),

              // Badge Name
              Text(
                badge.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: semantic.primaryText,
                ),
              ),
              const SizedBox(height: 4),

              // Requirement / Description
              Expanded(
                child: Text(
                  badge.requirement ?? badge.description ?? '',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: earned ? semantic.secondaryText : semantic.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Status Pill (Unlocked vs Locked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: earned
                      ? AppColors.growthAccent.withValues(alpha: 0.16)
                      : semantic.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: earned
                        ? AppColors.growthAccent.withValues(alpha: 0.3)
                        : semantic.borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      earned
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      size: 13,
                      color: earned
                          ? AppColors.growthAccent
                          : semantic.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      earned
                          ? 'achievements.unlocked'.tr
                          : 'achievements.locked'.tr,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: earned
                            ? AppColors.growthAccent
                            : semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeIcon(bool earned, AppSemanticColors semantic) {
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Image.network(
          badge.iconUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _fallbackIcon(earned, semantic),
        ),
      );
    }
    return _fallbackIcon(earned, semantic);
  }

  Widget _fallbackIcon(bool earned, AppSemanticColors semantic) {
    final name = badge.name.toUpperCase();
    IconData icon = Icons.workspace_premium_rounded;

    if (name.contains('FINANCE') || name.contains('FINANCIAL')) {
      icon = Icons.menu_book_rounded;
    } else if (name.contains('PRODUCTIV')) {
      icon = Icons.trending_up_rounded;
    } else if (name.contains('COMMUNIC')) {
      icon = Icons.chat_bubble_outline_rounded;
    } else if (name.contains('CONSISTEN')) {
      icon = Icons.calendar_month_rounded;
    } else if (name.contains('QUIZ')) {
      icon = Icons.emoji_events_rounded;
    } else if (name.contains('EVENT')) {
      icon = Icons.explore_rounded;
    }

    if (earned) {
      return Icon(icon, color: AppColors.growthAccent, size: 26);
    }
    return Icon(icon, color: semantic.textMuted, size: 24);
  }
}

/// Subtle placeholder card indicating future achievements.
class AchievementComingSoonCard extends StatelessWidget {
  const AchievementComingSoonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: semantic.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: semantic.borderSubtle,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.backgroundSecondary,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: semantic.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'achievements.moreComingSoon'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: semantic.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'achievements.moreComingSoonSub'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: semantic.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Motivational section near the bottom of the achievements screen.
class AchievementMotivationalCard extends StatelessWidget {
  const AchievementMotivationalCard({super.key});

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
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? semantic.borderSubtle
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.financeAccent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColors.financeAccent,
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
                  'achievements.motivationTitle'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'achievements.motivationSubtitle'.tr,
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
