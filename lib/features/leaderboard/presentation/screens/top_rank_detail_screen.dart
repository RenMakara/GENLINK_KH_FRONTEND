import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../domain/models/leaderboard_models.dart';

class TopRankDetailScreen extends StatelessWidget {
  const TopRankDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = Get.arguments is LeaderboardEntry
        ? Get.arguments as LeaderboardEntry
        : null;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'leaderboard.profile'.tr,
          style: TextStyle(color: scheme.onSurface),
        ),
      ),
      body: entry == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'leaderboard.profileUnavailable'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  elevation: 0,
                  color: scheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        AppAvatar(
                          imageUrl: entry.avatarUrl,
                          name: entry.name,
                          size: 88,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          entry.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'leaderboard.rankValue'.trParams({
                            'rank': '${entry.rank}',
                          }),
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        context,
                        scheme,
                        '${entry.points}',
                        'leaderboard.points'.tr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metric(
                        context,
                        scheme,
                        '${entry.level}',
                        'leaderboard.level'.tr,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _metric(
    BuildContext context,
    ColorScheme scheme,
    String value,
    String label,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
