import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../widgets/achievement_widgets.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedFilter = 'all';

  ProfileController get controller => Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 72,
        leading: const Center(child: AppBackButton()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'profile.achievements'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: semantic.primaryText,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'achievements.headerSubtitle'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: semantic.secondaryText,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        final profile = controller.profile.value;
        if (profile == null) {
          if (controller.isLoading.value) return const AppLoader();
          return AppEmptyState(
            message: controller.errorMessage.value ?? 'common.error'.tr,
            icon: Icons.cloud_off_outlined,
            action: FilledButton(
              onPressed: controller.reload,
              child: Text('common.retry'.tr),
            ),
          );
        }

        final allBadges = controller.sortedBadges;
        final earnedCount = allBadges.where((b) => b.earned).length;

        // Filter badges based on user selection
        final List<BadgeEntity> displayBadges;
        if (_selectedFilter == 'unlocked') {
          displayBadges = allBadges.where((b) => b.earned).toList();
        } else if (_selectedFilter == 'locked') {
          displayBadges = allBadges.where((b) => !b.earned).toList();
        } else {
          displayBadges = allBadges;
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              controller.loadBadges(),
              controller.reload(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              // 1. Achievement Progress Hero Card
              AchievementSummaryHeroCard(
                profile: profile,
                earnedBadgesCount: earnedCount,
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. My Badges Header & Filter Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'achievements.myBadges'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: semantic.primaryText,
                    ),
                  ),
                  AchievementFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Loading or Error states for badges
              if (controller.isBadgesLoading.value && allBadges.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.badgesErrorMessage.value != null &&
                  allBadges.isEmpty)
                AppEmptyState(
                  message: controller.badgesErrorMessage.value!,
                  icon: Icons.cloud_off_outlined,
                  action: FilledButton(
                    onPressed: controller.loadBadges,
                    child: Text('common.retry'.tr),
                  ),
                )
              else if (allBadges.isEmpty)
                AppEmptyState(
                  message: 'achievements.empty'.tr,
                  icon: Icons.workspace_premium_outlined,
                )
              else if (displayBadges.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedFilter == 'unlocked'
                              ? Icons.lock_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 40,
                          color: semantic.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'unlocked'
                              ? 'achievements.noUnlockedBadges'.tr
                              : 'achievements.noLockedBadges'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: semantic.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // 3. Responsive 2-column Badges Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedFilter == 'all'
                      ? displayBadges.length + 1
                      : displayBadges.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.80,
                  ),
                  itemBuilder: (context, index) {
                    if (_selectedFilter == 'all' &&
                        index == displayBadges.length) {
                      return const AchievementComingSoonCard();
                    }
                    final badge = displayBadges[index];
                    return AchievementBadgeCard(
                      badge: badge,
                      onTap: () => _showBadgeDetail(context, badge),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // 4. Motivational Card
              const AchievementMotivationalCard(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      }),
    );
  }

  void _showBadgeDetail(BuildContext context, BadgeEntity badge) {
    final semantic = context.semanticColors;
    final earned = badge.earned;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: semantic.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: earned
                        ? AppColors.growthAccent.withValues(alpha: 0.18)
                        : semantic.backgroundSecondary,
                    border: Border.all(
                      color: earned
                          ? AppColors.growthAccent.withValues(alpha: 0.45)
                          : semantic.borderSubtle,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      earned
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_outline_rounded,
                      color: earned
                          ? AppColors.growthAccent
                          : semantic.textMuted,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: earned
                        ? AppColors.growthAccent.withValues(alpha: 0.16)
                        : semantic.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    earned
                        ? 'achievements.unlocked'.tr
                        : 'achievements.locked'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: earned
                          ? AppColors.growthAccent
                          : semantic.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  badge.requirement ?? badge.description ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: semantic.secondaryText,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('common.close'.tr),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
