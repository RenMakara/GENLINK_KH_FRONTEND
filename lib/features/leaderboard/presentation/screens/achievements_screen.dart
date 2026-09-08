import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
          ),
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
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Text(
                          'leaderboard.backToLeaderboard'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAchievementCard(Achievement a, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: a.isUnlocked
                  ? a.color.withValues(alpha: 0.12)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              a.icon,
              color: a.isUnlocked ? a.color : scheme.outline,
              size: 26,
            ),
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
              color: a.isUnlocked
                  ? scheme.onSurfaceVariant
                  : scheme.outline,
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
