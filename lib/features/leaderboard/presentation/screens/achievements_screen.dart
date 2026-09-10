import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/surfaces/app_surface.dart';
import '../../../../features/quiz/presentation/widgets/quiz_icon_container.dart';
import '../controllers/leaderboard_controller.dart';
import '../../domain/models/leaderboard_models.dart';

class AchievementsScreen extends GetView<LeaderboardController> {
  const AchievementsScreen({super.key});

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
          'leaderboard.allAchievements'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        ),
      ),
      body: Obx(() {
        final achievements = controller.allAchievements;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: achievements
                    .map((a) => _buildAchievementCard(a, scheme))
                    .toList(),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'leaderboard.backToLeaderboard'.tr,
                height: 54,
                radius: AppRadius.pill,
                onPressed: () => Get.back(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAchievementCard(Achievement a, ColorScheme scheme) {
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      radius: AppRadius.lg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QuizIconContainer(
            icon: a.icon,
            accentColor: a.isUnlocked ? a.color : scheme.outline,
            size: 52,
            iconSize: 26,
            borderRadius: AppRadius.lg,
          ),
          const SizedBox(height: 12),
          Text(
            a.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: a.isUnlocked ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: a.isUnlocked ? scheme.onSurfaceVariant : scheme.outline,
            ),
          ),
          if (!a.isUnlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'leaderboard.locked'.tr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: scheme.outline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
