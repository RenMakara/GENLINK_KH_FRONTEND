import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

/// The signed-in user's profile.
///
/// Every section is driven by real data: level and XP from the account,
/// achievements from the badge catalog (which carries an `earned` flag),
/// expertise from the user's interests, and saved content from
/// `/profile/saved`. Profile completion is computed on the client.
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Obx(() {
          final profile = controller.profile.value;
          return Row(
            children: [
              AppAvatar(
                imageUrl: profile?.avatarUrl,
                name: profile?.fullName,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Flexible(
                child: Text(
                  profile?.fullName ?? 'profile.title'.tr,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'settings.notifications'.tr,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'settings.title'.tr,
            onPressed: () => Get.toNamed<void>(AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        final profile = controller.profile.value;

        if (controller.isLoading.value && profile == null) {
          return const AppLoader();
        }
        if (profile == null) {
          return AppEmptyState(
            message: controller.errorMessage.value ?? 'common.error'.tr,
            icon: Icons.cloud_off_outlined,
            action: AppButton.secondary(
              label: 'common.retry'.tr,
              expanded: false,
              onPressed: controller.reload,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              _Identity(profile: profile),
              const SizedBox(height: AppSpacing.lg),
              _StatsRow(controller: controller),
              const SizedBox(height: AppSpacing.lg),
              _CompletionCard(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              _Achievements(controller: controller),
              const SizedBox(height: AppSpacing.xl),
              _CoreExpertise(controller: controller),
              const SizedBox(height: AppSpacing.xl),
              const _QuickLinks(),
            ],
          ),
        );
      }),
    );
  }
}

/// Avatar with ring + edit badge, name, handle, and the work-status chip.
class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        RingedAvatar(
          imageUrl: profile.avatarUrl,
          name: profile.fullName,
          size: 108,
          onEdit: () => Get.toNamed<void>(AppRoutes.editProfile),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(profile.fullName, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '@${profile.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        if (profile.workStatus != null) ...[
          const SizedBox(height: AppSpacing.sm + 2),
          StatusChip(label: enumToLabel(profile.workStatus!)),
        ],
      ],
    );
  }
}

/// Profile completion + level progress, the design's headline card.
class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.completion'.tr.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: muted, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'profile.percentComplete'
                          .trParams({'percent': '${profile.completionPercent}'}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'profile.level'
                        .trParams({'level': '${profile.level}'}).toUpperCase(),
                    maxLines: 1,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: muted, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${profile.totalXp} / ${profile.xpForNextLevel} XP',
                    maxLines: 1,
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GradientProgressBar(value: profile.levelProgress),
          const SizedBox(height: AppSpacing.md),
          Text(
            'profile.nextLevelHint'
                .trParams({'level': '${profile.level + 1}'}),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// Horizontal badge row. Earned badges are solid; locked ones are dimmed
/// with a padlock, exactly as the catalog's `earned` flag describes them.
class _Achievements extends StatelessWidget {
  const _Achievements({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final badges = controller.sortedBadges;
      if (badges.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'profile.achievements'.tr,
            trailing: AppButton.text(
              label: 'home.seeAll'.tr,
              muted: true,
              onPressed: () =>
                  Get.toNamed<void>(AppRoutes.profileAchievements),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) =>
                  BadgeTile(badge: badges[index]),
            ),
          ),
        ],
      );
    });
  }
}

/// The user's interests, rendered as the design's expertise chips.
class _CoreExpertise extends StatelessWidget {
  const _CoreExpertise({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final interests = controller.interests;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'profile.coreExpertise'.tr),
          const SizedBox(height: AppSpacing.md),
          if (interests.isEmpty)
            MutedText(text: 'profile.emptyInterests'.tr)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // The first chip is emphasised, matching the design.
                for (var i = 0; i < interests.length; i++)
                  ExpertiseChip(
                    label: interests[i].name,
                    emphasised: i == 0,
                  ),
                AddChipButton(
                  onPressed: () =>
                      Get.toNamed<void>(AppRoutes.profileInterests),
                ),
              ],
            ),
        ],
      );
    });
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
        );

    return Obx(() {
      final profile = controller.profile.value;
      final earned = controller.badges.where((b) => b.earned).length;
      return Row(
        children: [
          stat('${profile?.totalXp ?? 0}', 'profile.xpStat'.tr),
          stat('$earned', 'achievements.badges'.tr),
          stat('${controller.savedItems.length}', 'profile.saved'.tr),
        ],
      );
    });
  }
}

/// Navigation rows into the profile sub-screens.
class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget tile(IconData icon, String title, String route) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          onTap: () => Get.toNamed<void>(route),
        );

    // Material, not a decorated Container: ListTile paints its ink on the
    // nearest Material, so a DecoratedBox here would swallow the ripple.
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          tile(Icons.work_outline, 'profile.portfolio'.tr,
              AppRoutes.profilePortfolio),
          const Divider(height: 1),
          tile(Icons.bookmark_border, 'profile.savedContent'.tr,
              AppRoutes.profileSaved),
          const Divider(height: 1),
          tile(Icons.workspace_premium_outlined, 'profile.achievements'.tr,
              AppRoutes.profileAchievements),
        ],
      ),
    );
  }
}

/// `SNAKE_CASE` enum → "Title Case", used for the work-status chip.
String enumToLabel(String enumValue) => enumValue
    .split('_')
    .map((word) =>
        word.isEmpty ? word : word[0] + word.substring(1).toLowerCase())
    .join(' ');
