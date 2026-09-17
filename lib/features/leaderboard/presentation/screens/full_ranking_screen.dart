import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/leaderboard_models.dart';
import '../controllers/leaderboard_controller.dart';

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
        if (controller.entries.isEmpty) {
          return Center(
            child: Text(
              'leaderboard.noData'.tr,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          color: scheme.primary,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            itemCount: controller.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) =>
                _buildRankRow(context, scheme, controller.entries[index]),
          ),
        );
      }),
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
}
