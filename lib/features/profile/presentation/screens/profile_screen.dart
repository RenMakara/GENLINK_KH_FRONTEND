import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../../../design_system/widgets/surfaces/app_surface.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

/// Owner and public profile shell. Public profiles use a route-tagged
/// controller and never read or mutate the signed-in owner's identity.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.viewingUsername});

  final String? viewingUsername;

  ProfileController get controller {
    final username = viewingUsername?.trim();
    return username == null || username.isEmpty
        ? Get.find<ProfileController>()
        : Get.find<ProfileController>(
            tag: ProfileController.publicTag(username),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: controller.isOwner ? _ownerAppBar(context) : _publicAppBar(context),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final data = controller.isOwner
              ? controller.profile.value
              : controller.publicProfile.value;
          if (controller.isLoading.value && data == null) {
            return const AppLoader();
          }
          if (data == null) {
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
            child: controller.isOwner
                ? _OwnerProfile(
                    controller: controller,
                    profile: data as ProfileEntity,
                  )
                : _PublicProfile(
                    profile: data as PublicProfileEntity,
                    onShare: _sharePublicProfile,
                  ),
          );
        }),
      ),
    );
  }

  AppBar _ownerAppBar(BuildContext context) => AppBar(
    titleSpacing: AppSpacing.md,
    title: Obx(() {
      final profile = controller.profile.value;
      if (profile == null) return const SizedBox.shrink();
      return Row(
        children: [
          AppAvatar(
            imageUrl: profile.avatarUrl,
            name: profile.fullName,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              profile.fullName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
    }),
    actions: [
      IconButton(
        tooltip: 'settings.notifications'.tr,
        icon: const Icon(Icons.notifications_none),
        onPressed: () => Get.toNamed<void>(AppRoutes.notifications),
      ),
      IconButton(
        tooltip: 'settings.title'.tr,
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => Get.toNamed<void>(AppRoutes.settings),
      ),
    ],
  );

  AppBar _publicAppBar(BuildContext context) => AppBar(
        titleSpacing: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        leadingWidth: 74,
        title: Text(
          'profile.publicProfile'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
      IconButton(
        tooltip: 'profile.shareProfile'.tr,
        icon: const Icon(Icons.ios_share_outlined),
        onPressed: _sharePublicProfile,
      ),
    ],
  );

  Future<void> _sharePublicProfile() async {
    final profile = controller.publicProfile.value;
    if (profile == null) return;
    await Clipboard.setData(ClipboardData(text: '@${profile.username}'));
    Get.showSnackbar(
      GetSnackBar(
        message: 'profile.shareCopied'.tr,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _OwnerProfile extends StatelessWidget {
  const _OwnerProfile({required this.controller, required this.profile});

  final ProfileController controller;
  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.58);
    final status = _enumLabel(profile.workStatus);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        120, // Bottom padding for floating navbar
      ),
      children: [
        Center(
          child: RingedAvatar(
            imageUrl: profile.avatarUrl,
            name: profile.fullName,
            size: 98,
            onEdit: () => Get.toNamed<void>(AppRoutes.editProfile),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '@${profile.username}${status.isEmpty ? '' : ' · $status'}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(child: StatusChip(label: status)),
        ],
        const SizedBox(height: AppSpacing.lg),
        _CompletionCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'profile.achievements'.tr,
          trailing: TextButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.profileAchievements),
            child: Text('profile.viewAll'.tr),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (controller.sortedBadges.isEmpty)
          _EmptySection(message: 'achievements.empty'.tr)
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.sortedBadges.take(5).length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, index) =>
                  BadgeTile(badge: controller.sortedBadges[index]),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: 'profile.coreExpertise'.tr),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < controller.interests.length; i++)
              ExpertiseChip(
                label: controller.interests[i].name,
                emphasised: i == 0,
              ),
            AddChipButton(
              onPressed: () => Get.toNamed<void>(AppRoutes.profileInterests),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: 'profile.careerPath'.tr),
        const SizedBox(height: AppSpacing.sm),
        _CareerCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: 'profile.savedContent'.tr,
          trailing: IconButton(
            tooltip: 'profile.saved'.tr,
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => Get.toNamed<void>(AppRoutes.profileSaved),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (controller.savedItems.isEmpty)
          _EmptySection(message: 'profile.emptySaved'.tr)
        else
          SizedBox(
            height: 145,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.savedItems.take(4).length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, index) =>
                  SavedItemCard(item: controller.savedItems[index]),
            ),
          ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.profile});
  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.completion'.tr.toUpperCase(),
                      style: theme.textTheme.labelSmall,
                    ),
                    Text(
                      'profile.percentComplete'.trParams({
                        'percent': '${profile.completionPercent}',
                      }),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'profile.level'.trParams({'level': '${profile.level}'}),
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    '${profile.totalXp} / ${profile.xpForNextLevel} XP',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientProgressBar(value: profile.levelProgress),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'profile.nextLevelHint'.trParams({
                'level': '${profile.level + 1}',
              }),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  const _CareerCard({required this.profile});
  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = _enumLabel(profile.workStatus);
    final title = status.isEmpty ? 'profile.noCareerDetails'.tr : status;
    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: scheme.primary,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.currentTrack'.tr.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
          if ((profile.universityName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.business_center_outlined,
                  size: 18,
                  color: AppColors.growthAccent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    profile.universityName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton.inverse(
            expanded: false,
            height: 44,
            label: 'profile.editCareer'.tr,
            onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
          ),
        ],
      ),
    );
  }
}

class _PublicProfile extends StatelessWidget {
  const _PublicProfile({required this.profile, required this.onShare});
  final PublicProfileEntity profile;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final cover = profile.portfolio
        .firstWhereOrNull((item) => (item.imageUrl ?? '').isNotEmpty)
        ?.imageUrl;
    final subtitle = [
      _enumLabel(profile.workStatus),
      profile.location,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        120, // Bottom padding for floating navbar
      ),
      children: [
        _PublicHeader(profile: profile, cover: cover),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PublicStat(
              value: '${profile.totalXp}',
              label: 'profile.xpStat'.tr,
            ),
            _PublicStat(
              value: '${profile.portfolio.length}',
              label: 'profile.projects'.tr,
            ),
            _PublicStat(
              value: '${profile.interests.length}',
              label: 'profile.interests'.tr,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'profile.connect'.tr,
                onPressed: () => Get.showSnackbar(
                  GetSnackBar(
                    message: 'profile.connectUnavailable'.tr,
                    duration: const Duration(seconds: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton.secondary(
                label: 'profile.shareProfile'.tr,
                icon: Icons.share_outlined,
                onPressed: onShare,
              ),
            ),
          ],
        ),
        if ((profile.bio ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _LabelledSection(
            title: 'profile.professionalBio'.tr,
            child: _SurfaceCard(child: Text(profile.bio!)),
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _LabelledSection(
            title: 'profile.coreCompetencies'.tr,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final interest in profile.interests)
                  ExpertiseChip(label: interest.name),
              ],
            ),
          ),
        ],
        if (profile.portfolio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'profile.portfolioPreview'.tr),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: profile.portfolio.take(4).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (_, index) =>
                _PortfolioPreview(item: profile.portfolio[index]),
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _LabelledSection(
            title: 'profile.careerInterests'.tr,
            child: Column(
              children: [
                for (final interest in profile.interests.take(3)) ...[
                  _InterestCard(interest: interest),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PublicHeader extends StatelessWidget {
  const _PublicHeader({required this.profile, required this.cover});
  final PublicProfileEntity profile;
  final String? cover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 145,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: SizedBox(
                width: double.infinity,
                height: 100,
                child: cover == null
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [scheme.primary, scheme.secondary],
                          ),
                        ),
                      )
                    : Image.network(
                        cover!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            ColoredBox(color: scheme.primary),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: AppAvatar(
              imageUrl: profile.avatarUrl,
              name: profile.fullName,
              size: 72,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicStat extends StatelessWidget {
  const _PublicStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 94,
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );
}

class _LabelledSection extends StatelessWidget {
  const _LabelledSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: AppSpacing.sm),
      child,
    ],
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppSurface(radius: AppRadius.lg, child: child);
}

class _PortfolioPreview extends StatelessWidget {
  const _PortfolioPreview({required this.item});
  final PortfolioItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((item.imageUrl ?? '').isNotEmpty)
            Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.darkSurfacePrimary),
            )
          else
            const ColoredBox(color: AppColors.darkSurfacePrimary),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.darkBgPrimary.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({required this.interest});
  final InterestEntity interest;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _categoryIcon(interest.category),
            color: Theme.of(context).colorScheme.onPrimary,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                interest.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if ((interest.category ?? '').isNotEmpty)
                Text(
                  _enumLabel(interest.category),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    ),
  );
}

String _enumLabel(String? value) => (value ?? '')
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0]}${word.substring(1).toLowerCase()}')
    .join(' ');

IconData _categoryIcon(String? category) => switch (category) {
  'CAREER' => Icons.rocket_launch_outlined,
  'FINANCE' => Icons.payments_outlined,
  'EDUCATION' => Icons.school_outlined,
  'LIFESTYLE' => Icons.eco_outlined,
  'ENTERTAINMENT' => Icons.auto_awesome_outlined,
  'COMMUNITY' => Icons.groups_outlined,
  _ => Icons.interests_outlined,
};
