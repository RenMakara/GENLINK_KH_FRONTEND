import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/leaderboard_models.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardHomeScreen extends GetView<LeaderboardController> {
  const LeaderboardHomeScreen({super.key});

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
          'quiz.leaderboard'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.entries.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );
        }

        if (controller.errorMessage.value != null &&
            controller.entries.isEmpty) {
          return _buildErrorState(context, scheme);
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          color: scheme.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              _buildFilters(context, scheme),
              const SizedBox(height: AppSpacing.md),
              if (controller.me != null) _buildMyStanding(context, scheme),
              if (controller.me != null) const SizedBox(height: AppSpacing.md),
              if (controller.entries.isEmpty)
                _buildEmptyState(context, scheme)
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.categoryLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      controller.periodLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...controller.entries
                    .take(10)
                    .map((entry) => _buildRankRow(context, scheme, entry)),
                if (controller.entries.length > 10) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => Get.toNamed(AppRoutes.leaderboardRanking),
                    child: Text('leaderboard.viewFull'.tr),
                  ),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilters(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'leaderboard.category'.tr,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LeaderboardCategory.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final category = LeaderboardCategory.values[index];
              return Obx(
                () => ChoiceChip(
                  label: Text(category.translationKey.tr),
                  selected: controller.selectedCategory.value == category,
                  onSelected: (_) => controller.selectCategory(category),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'leaderboard.period'.tr,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Obx(
              () => DropdownButton<LeaderboardPeriod>(
                value: controller.selectedPeriod.value,
                underline: const SizedBox.shrink(),
                items: LeaderboardPeriod.values
                    .map(
                      (period) => DropdownMenuItem(
                        value: period,
                        child: Text(period.translationKey.tr),
                      ),
                    )
                    .toList(),
                onChanged: (period) {
                  if (period != null) controller.selectPeriod(period);
                },
              ),
            ),
            const Spacer(),
            if (controller.isLoading.value)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyStanding(BuildContext context, ColorScheme scheme) {
    final me = controller.me!;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.person_pin_circle_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'leaderboard.currentStanding'.tr,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    me.rank == null
                        ? 'leaderboard.rankUnavailable'.tr
                        : 'leaderboard.rankValue'.trParams({
                            'rank': '${me.rank}',
                          }),
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            Text(
              '${me.points} ${'leaderboard.points'.tr}',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankRow(
    BuildContext context,
    ColorScheme scheme,
    LeaderboardEntry entry,
  ) {
    final highlighted = entry.isCurrentUser;
    return Card(
      elevation: 0,
      color: highlighted ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlighted ? scheme.primary : scheme.outlineVariant,
          width: highlighted ? 1.4 : 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Get.toNamed(AppRoutes.leaderboardProfile, arguments: entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${entry.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: highlighted
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppAvatar(imageUrl: entry.avatarUrl, name: entry.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: highlighted ? scheme.primary : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${'leaderboard.level'.tr} ${entry.level}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.points} ${'leaderboard.points'.tr}',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.load,
              child: Text('common.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.leaderboard_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'leaderboard.noData'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
