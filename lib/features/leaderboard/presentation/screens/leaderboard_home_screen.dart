import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../domain/models/leaderboard_models.dart';
import '../controllers/leaderboard_controller.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_user_tile.dart';

class LeaderboardHomeScreen extends GetView<LeaderboardController> {
  const LeaderboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              children: [
                AppBackButton(
                  onPressed: () {
                    if (Get.previousRoute.isNotEmpty) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quiz.leaderboard'.tr,
                        style: textTheme.headlineSmall?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'leaderboard.headerSubtitle'.tr,
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppHeaderActionButton(
                  icon: Icons.notifications_outlined,
                  tooltip: 'notification.title'.tr,
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.entries.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: semantic.primary),
          );
        }

        if (controller.errorMessage.value != null && controller.entries.isEmpty) {
          return _buildErrorState(context);
        }

        final top3 = controller.entries.take(3).toList();
        final restEntries = controller.entries.length > 3
            ? controller.entries.skip(3).take(7).toList()
            : <LeaderboardEntry>[];

        return RefreshIndicator(
          onRefresh: controller.load,
          color: semantic.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            children: [
              _buildCategoryFilter(context),
              const SizedBox(height: AppSpacing.sm),
              _buildPeriodFilter(context),
              const SizedBox(height: AppSpacing.md),
              if (controller.me != null) ...[
                _buildCurrentStandingCard(context),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (controller.entries.isEmpty)
                _buildEmptyState(context)
              else ...[
                // Top Learners Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'leaderboard.topLearners'.tr,
                      style: textTheme.titleMedium?.copyWith(
                        color: semantic.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      controller.periodLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Top 3 Podium
                LeaderboardPodium(
                  entries: top3,
                  onTapUser: (entry) => Get.toNamed(
                    AppRoutes.leaderboardProfile,
                    arguments: entry,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Ranking List #4+
                if (restEntries.isNotEmpty) ...[
                  _buildTableHeader(context),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: restEntries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = restEntries[index];
                      return LeaderboardUserTile(
                        entry: entry,
                        isCard: true,
                        showPointsLabel: false,
                        onTap: () => Get.toNamed(
                          AppRoutes.leaderboardProfile,
                          arguments: entry,
                        ),
                      );
                    },
                  ),
                ],
                if (controller.entries.length > 10) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: semantic.primaryText,
                        side: BorderSide(
                          color: semantic.borderSubtle,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () =>
                          Get.toNamed(AppRoutes.leaderboardRanking),
                      child: Text(
                        'leaderboard.viewFull'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              _buildMotivationalFooter(context),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      }),
    );
  }

  /// Category filter pills
  Widget _buildCategoryFilter(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'leaderboard.category'.tr,
          style: textTheme.labelLarge?.copyWith(
            color: semantic.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: LeaderboardCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = LeaderboardCategory.values[index];
              return Obx(() {
                final isSelected = controller.selectedCategory.value == cat;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.selectCategory(cat),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? semantic.primaryText : const Color(0xFF18191B))
                            : (isDark ? semantic.surface : Colors.white),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? semantic.primaryText : const Color(0xFF18191B))
                              : (isDark ? semantic.borderSubtle : semantic.borderSubtle.withValues(alpha: 0.8)),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        cat.translationKey.tr,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? semantic.background : Colors.white)
                              : semantic.primaryText,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  /// Period filter dropdown pill
  Widget _buildPeriodFilter(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          'leaderboard.period'.tr,
          style: textTheme.labelLarge?.copyWith(
            color: semantic.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Obx(() {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? semantic.surface : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isDark ? semantic.borderSubtle : semantic.borderSubtle.withValues(alpha: 0.8),
                width: 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LeaderboardPeriod>(
                value: controller.selectedPeriod.value,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                isDense: true,
                dropdownColor: isDark ? semantic.surfaceElevated : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                items: LeaderboardPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(
                      period.translationKey.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: semantic.primaryText,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (period) {
                  if (period != null) controller.selectPeriod(period);
                },
              ),
            ),
          );
        }),
        const Spacer(),
        Obx(() {
          if (!controller.isLoading.value) return const SizedBox.shrink();
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }),
      ],
    );
  }

  /// Current Standing Card
  Widget _buildCurrentStandingCard(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final me = controller.me!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Color.alphaBlend(
                    AppColors.productivityAccent.withValues(alpha: 0.20),
                    semantic.surface,
                  ),
                  Color.alphaBlend(
                    AppColors.brandPrimary.withValues(alpha: 0.12),
                    semantic.surface,
                  ),
                ]
              : const [
                  Color(0xFFEDE9FE),
                  Color(0xFFF5F3FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.productivityAccent.withValues(
            alpha: isDark ? 0.35 : 0.22,
          ),
          width: 1.0,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: AppColors.productivityAccent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          // Current User Avatar
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.productivityAccent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: AppAvatar(
                imageUrl: controller.topUser?.isCurrentUser == true
                    ? controller.topUser?.avatarUrl
                    : null,
                name: 'quiz.you'.tr,
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Standing Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leaderboard.currentStanding'.tr,
                  style: textTheme.labelSmall?.copyWith(
                    color: semantic.secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  me.rank == null
                      ? 'leaderboard.rankUnavailable'.tr
                      : 'leaderboard.rankValue'.trParams({'rank': '${me.rank}'}),
                  style: textTheme.titleMedium?.copyWith(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'leaderboard.standingKeepGoing'.tr,
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Crown Emblem
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: isDark ? 0.20 : 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Column headers (# User Level Points)
  Widget _buildTableHeader(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: semantic.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'leaderboard.profile'.tr,
              style: textTheme.labelSmall?.copyWith(
                color: semantic.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
          Text(
            'leaderboard.points'.tr,
            style: textTheme.labelSmall?.copyWith(
              color: semantic.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Motivational banner at the bottom
  Widget _buildMotivationalFooter(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.leaderboardRanking),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Color.alphaBlend(
                    AppColors.productivityAccent.withValues(alpha: 0.10),
                    semantic.surface,
                  )
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark
                  ? semantic.borderSubtle
                  : semantic.borderSubtle.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'quiz.footerQuote'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: semantic.primaryText,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? semantic.surfaceElevated : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? semantic.borderSubtle
                        : semantic.borderSubtle.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: semantic.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final semantic = context.semanticColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value!,
              textAlign: TextAlign.center,
              style: TextStyle(color: semantic.primaryText, fontSize: 14),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: semantic.primary,
                foregroundColor: semantic.textInverse,
              ),
              onPressed: controller.load,
              child: Text('common.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final semantic = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 48,
            color: semantic.borderStrong,
          ),
          const SizedBox(height: 12),
          Text(
            'leaderboard.noData'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: semantic.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
