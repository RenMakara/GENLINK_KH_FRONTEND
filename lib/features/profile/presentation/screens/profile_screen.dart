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
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/full_screen_image_viewer.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_cover_preset.dart';
import '../utils/profile_navigation.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.viewingUsername});

  final String? viewingUsername;

  ProfileController get controller {
    final username = ProfileNavigation.ownerAwareUsername(
      username: viewingUsername,
    );
    return username == null
        ? Get.find<ProfileController>()
        : Get.find<ProfileController>(
            tag: ProfileController.publicTag(username),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.semanticColors.background,
      appBar: controller.isOwner
          ? _ownerAppBar(context)
          : _publicAppBar(context),
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
                    controller: controller,
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
        icon: const Icon(Icons.settings_rounded),
        onPressed: () => Get.toNamed<void>(AppRoutes.settings),
      ),
    ],
  );

  AppBar _publicAppBar(BuildContext context) => AppBar(
    titleSpacing: 0,
    leading: const Center(child: AppBackButton()),
    leadingWidth: 74,
    title: Text(
      'profile.publicProfile'.tr,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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

  void _showAvatarMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16, top: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fullscreen),
              title: Text('profile.viewAvatar'.tr),
              onTap: () {
                Navigator.pop(ctx);
                if (profile.avatarUrl != null &&
                    profile.avatarUrl!.isNotEmpty) {
                  Get.to(
                    () => FullScreenImageViewer(images: [profile.avatarUrl!]),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('profile.changeAvatar'.tr),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed<void>(AppRoutes.editProfile);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showCoverPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _CoverPickerSheet(
        selectedPreset: profile.coverPreset,
        onSelected: (preset) async {
          Navigator.of(sheetContext).pop();
          await controller.updateCoverPreset(preset);
        },
      ),
    );
  }

  Future<void> _shareProfile() async {
    await Clipboard.setData(ClipboardData(text: '@${profile.username}'));
    Get.showSnackbar(
      GetSnackBar(
        message: 'profile.shareCopied'.tr,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
        120,
      ),
      children: [
        _ProfileHero(
          coverPreset: profile.coverPreset,
          imageUrl: profile.avatarUrl,
          name: profile.fullName,
          avatarAlignment: _ProfileHeroAvatarAlignment.start,
          onAvatarEdit: () => Get.toNamed<void>(AppRoutes.editProfile),
          onAvatarTap: () => _showAvatarMenu(context),
          onChangeCover: () => _showCoverPicker(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'profile.edit'.tr,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
                  ),
                ],
              ),
              Text(
                '@${profile.username}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              if (status.isNotEmpty || (profile.location ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (status.isNotEmpty) StatusChip(label: status),
                    if ((profile.location ?? '').isNotEmpty)
                      _ProfileMeta(
                        icon: Icons.location_on_outlined,
                        label: profile.location!,
                      ),
                  ],
                ),
              ],
              if ((profile.bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(profile.bio!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => _ProfileStats(
            totalXp: profile.totalXp,
            projects: controller.portfolio.length,
            interests: controller.interests.length,
            followers: controller.followStats.value?.followers ?? 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _OwnerActionRow(onShare: _shareProfile),
        const SizedBox(height: AppSpacing.lg),
        _CompletionCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        _ProfileSectionCard(
          icon: Icons.emoji_events_outlined,
          title: 'profile.achievements'.tr,
          trailing: TextButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.profileAchievements),
            child: Text('profile.viewAll'.tr),
          ),
          child: controller.sortedBadges.isEmpty
              ? _SectionEmpty(message: 'achievements.empty'.tr)
              : SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.sortedBadges.take(5).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        BadgeTile(badge: controller.sortedBadges[index]),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ProfileSectionCard(
          icon: Icons.bar_chart_rounded,
          title: 'profile.coreExpertise'.tr,
          trailing: TextButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.profileInterests),
            child: Text('common.edit'.tr),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final interest in controller.interests)
                InterestChip(interest: interest, compact: true),
              AddChipButton(
                onPressed: () => Get.toNamed<void>(AppRoutes.profileInterests),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ProfileSectionCard(
          icon: Icons.share_outlined,
          title: 'profile.careerPath'.tr,
          trailing: TextButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
            child: Text('common.edit'.tr),
          ),
          child: _CareerCard(profile: profile),
        ),
        if (controller.portfolio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'profile.portfolio'.tr,
            trailing: TextButton(
              onPressed: () => Get.toNamed<void>(AppRoutes.profilePortfolio),
              child: Text('profile.viewAll'.tr),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.portfolio.take(4).length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, index) => SizedBox(
                width: 158,
                child: _PortfolioPreview(item: controller.portfolio[index]),
              ),
            ),
          ),
        ],
        if (controller.socialLinks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _LabelledSection(
            title: 'profile.socialLinks'.tr,
            child: _SocialLinksCard(links: controller.socialLinks),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ProfileSectionCard(
          icon: Icons.bookmark_border_rounded,
          title: 'profile.savedContent'.tr,
          trailing: TextButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.profileSaved),
            child: Text('profile.viewAll'.tr),
          ),
          child: controller.savedItems.isEmpty
              ? _SectionEmpty(message: 'profile.emptySaved'.tr)
              : SizedBox(
                  height: 145,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.savedItems.take(4).length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        SavedItemCard(item: controller.savedItems[index]),
                  ),
                ),
        ),
        Builder(
          builder: (context) {
            final commCtrl = Get.isRegistered<CommunityController>()
                ? Get.find<CommunityController>()
                : null;
            if (commCtrl == null) return const SizedBox.shrink();
            return Obx(() {
              final userPosts = commCtrl.getUserPosts(
                profile.userId,
                username: profile.fullName,
              );
              if (userPosts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: '${'community.post'.tr} & ${'community.repost'.tr}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...userPosts.map(
                    (p) => PostCardWidget(post: p, controller: commCtrl),
                  ),
                ],
              );
            });
          },
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
    final scheme = theme.colorScheme;
    return AppSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 76,
            width: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CircularProgressIndicator(
                    value: profile.completion,
                    backgroundColor: scheme.outlineVariant,
                    color: AppColors.growthAccent,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${profile.completionPercent}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.completion'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'profile.nextLevelHint'.trParams({
                    'level': '${profile.level + 1}',
                  }),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GradientProgressBar(value: profile.completion),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'profile.level'.trParams({'level': '${profile.level}'}),
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${profile.totalXp} / ${profile.xpForNextLevel} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
    final status = _enumLabel(profile.workStatus);
    final title = status.isEmpty ? 'profile.noCareerDetails'.tr : status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF17181A),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.currentTrack'.tr.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((profile.universityName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.business_center_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    profile.universityName!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF17181A),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text('profile.editCareer'.tr),
          ),
        ],
      ),
    );
  }
}

class _PublicProfile extends StatelessWidget {
  const _PublicProfile({
    required this.controller,
    required this.profile,
    required this.onShare,
  });

  final ProfileController controller;
  final PublicProfileEntity profile;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final subtitle = [
      _enumLabel(profile.workStatus),
      profile.location,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    final careerInterests = profile.interests.take(3).toList(growable: false);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 120),
      children: [
        _ProfileHero(
          coverPreset: profile.coverPreset,
          imageUrl: profile.avatarUrl,
          name: profile.fullName,
          avatarAlignment: _ProfileHeroAvatarAlignment.center,
          onAvatarTap: () {
            if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
              Get.to(() => FullScreenImageViewer(images: [profile.avatarUrl!]));
            }
          },
        ),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '@${profile.username}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: _ProfileMeta(
              icon: Icons.business_center_outlined,
              label: subtitle,
              color: muted,
            ),
          ),
        ],
        if ((profile.bio ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '“${profile.bio!}”',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Obx(() {
          final stats = controller.followStats.value;
          return Column(
            children: [
              _ProfileStats(
                totalXp: profile.totalXp,
                projects: profile.portfolio.length,
                interests: profile.interests.length,
                followers: stats?.followers ?? 0,
              ),
              if (stats != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${stats.following} ${'profile.followingCount'.tr}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: AppSpacing.md),
        _PublicActionRow(controller: controller, onShare: onShare),
        if ((profile.universityName ?? '').trim().isNotEmpty ||
            _formatJoinedAt(profile.joinedAt).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ProfileDetailsCard(
            universityName: profile.universityName,
            joinedAt: profile.joinedAt,
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ProfileSectionCard(
            icon: Icons.bar_chart_rounded,
            title: 'profile.coreCompetencies'.tr,
            trailing: Text(
              'profile.viewAll'.tr,
              style: theme.textTheme.labelLarge?.copyWith(color: muted),
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final interest in profile.interests)
                  InterestChip(interest: interest, compact: true),
              ],
            ),
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ProfileSectionCard(
            icon: Icons.track_changes_rounded,
            title: 'profile.careerInterests'.tr,
            trailing: Text(
              'profile.viewAll'.tr,
              style: theme.textTheme.labelLarge?.copyWith(color: muted),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < careerInterests.length;
                  index++
                ) ...[
                  _InterestCard(interest: careerInterests[index]),
                  if (index != careerInterests.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
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
        if (profile.socialLinks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _LabelledSection(
            title: 'profile.socialLinks'.tr,
            child: _SocialLinksCard(links: profile.socialLinks),
          ),
        ],
        Builder(
          builder: (context) {
            final commCtrl = Get.isRegistered<CommunityController>()
                ? Get.find<CommunityController>()
                : null;
            if (commCtrl == null) return const SizedBox.shrink();
            return Obx(() {
              final userPosts = commCtrl.getUserPosts(
                profile.userId,
                username: profile.fullName,
              );
              if (userPosts.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(
                    title: '${'community.post'.tr} & ${'community.repost'.tr}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...userPosts.map(
                    (p) => PostCardWidget(post: p, controller: commCtrl),
                  ),
                ],
              );
            });
          },
        ),
      ],
    );
  }
}

class _PublicActionRow extends StatelessWidget {
  const _PublicActionRow({required this.controller, required this.onShare});

  final ProfileController controller;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.followStats.value;
      final status = stats?.followStatus;
      final isFollowing = stats?.isFollowing ?? false;
      final label = status == 'PENDING'
          ? 'profile.requested'.tr
          : isFollowing
          ? 'profile.following'.tr
          : 'profile.follow'.tr;

      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: label,
              icon: isFollowing
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_outlined,
              loading: controller.isRelationshipSaving.value,
              onPressed: () => controller.toggleFollow(),
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
      );
    });
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({this.universityName, this.joinedAt});

  final String? universityName;
  final String? joinedAt;

  @override
  Widget build(BuildContext context) {
    final details = <_ProfileDetail>[
      if ((universityName ?? '').trim().isNotEmpty)
        _ProfileDetail(
          icon: Icons.school_outlined,
          label: 'profile.university'.tr,
          value: universityName!,
        ),
      if (_formatJoinedAt(joinedAt).isNotEmpty)
        _ProfileDetail(
          icon: Icons.calendar_month_outlined,
          label: 'profile.memberSince'.tr,
          value: _formatJoinedAt(joinedAt),
        ),
    ];

    if (details.isEmpty) return const SizedBox.shrink();

    return _SurfaceCard(
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _ProfileDetailRow(detail: details[index]),
            if (index != details.length - 1)
              Divider(
                height: AppSpacing.lg,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileDetail {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({required this.detail});

  final _ProfileDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(detail.icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              Text(
                detail.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialLinksCard extends StatelessWidget {
  const _SocialLinksCard({required this.links});

  final List<SocialLinkEntity> links;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          for (var index = 0; index < links.length; index++) ...[
            _SocialLinkRow(link: links[index]),
            if (index != links.length - 1)
              Divider(
                height: AppSpacing.lg,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _SocialLinkRow extends StatelessWidget {
  const _SocialLinkRow({required this.link});

  final SocialLinkEntity link;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _socialIcon(link.platform),
            color: scheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _socialLabel(link.platform),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                link.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'profile.copyLink'.tr,
          icon: const Icon(Icons.copy_outlined),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link.url));
            Get.showSnackbar(
              GetSnackBar(
                message: 'profile.linkCopied'.tr,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

enum _ProfileHeroAvatarAlignment { start, center }

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.coverPreset,
    required this.imageUrl,
    required this.name,
    required this.avatarAlignment,
    this.onAvatarEdit,
    this.onAvatarTap,
    this.onChangeCover,
  });

  final int coverPreset;
  final String? imageUrl;
  final String name;
  final _ProfileHeroAvatarAlignment avatarAlignment;
  final VoidCallback? onAvatarEdit;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onChangeCover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cover = ProfileCoverPresets.byId(coverPreset);
    final isEditable = onAvatarEdit != null;
    final avatarSize = isEditable ? 104.0 : 100.0;
    final avatar = isEditable
        ? RingedAvatar(
            imageUrl: imageUrl,
            name: name,
            size: avatarSize,
            onEdit: onAvatarEdit,
            onTap: onAvatarTap,
          )
        : GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
              child: AppAvatar(
                imageUrl: imageUrl,
                name: name,
                size: avatarSize - AppSpacing.sm,
              ),
            ),
          );

    return SizedBox(
      height: 218,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: AppSpacing.sm,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: SizedBox(
                height: 158,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      cover.assetPath,
                      fit: BoxFit.cover,
                      semanticLabel: cover.semanticLabel,
                      errorBuilder: (_, _, _) =>
                          ColoredBox(color: scheme.surfaceContainerHighest),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x33000000)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onChangeCover != null)
            Positioned(
              top: AppSpacing.sm + AppSpacing.sm,
              right: AppSpacing.sm,
              child: Material(
                color: Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: onChangeCover,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'profile.changeCover'.tr,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (avatarAlignment == _ProfileHeroAvatarAlignment.center)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(alignment: Alignment.center, child: avatar),
            )
          else
            Positioned(left: AppSpacing.lg, bottom: 0, child: avatar),
        ],
      ),
    );
  }
}

class _CoverPickerSheet extends StatelessWidget {
  const _CoverPickerSheet({
    required this.selectedPreset,
    required this.onSelected,
  });

  final int selectedPreset;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FractionallySizedBox(
      heightFactor: 0.72,
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Material(
          color: scheme.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 38,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'profile.chooseCover'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'common.close'.tr,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'profile.coverSelectionHint'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: ProfileCoverPresets.all.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.15,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                  ),
                  itemBuilder: (_, index) {
                    final preset = ProfileCoverPresets.all[index];
                    final selected = preset.id == selectedPreset;
                    return Semantics(
                      key: ValueKey('profile-cover-preset-${preset.id}'),
                      button: true,
                      selected: selected,
                      label: preset.semanticLabel,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onSelected(preset.id),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  preset.assetPath,
                                  fit: BoxFit.cover,
                                ),
                                if (selected)
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: scheme.primary,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.lg,
                                      ),
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                if (selected)
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Container(
                                      margin: const EdgeInsets.all(
                                        AppSpacing.sm,
                                      ),
                                      height: 28,
                                      width: 28,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: scheme.onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.totalXp,
    required this.projects,
    required this.interests,
    required this.followers,
  });

  final int totalXp;
  final int projects;
  final int interests;
  final int followers;

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      children: [
        Expanded(
          child: _ProfileMetric(
            value: '$totalXp',
            label: 'profile.xpStat'.tr,
            icon: Icons.star_border_rounded,
            color: AppColors.growthAccent,
          ),
        ),
        _ProfileStatDivider(color: divider),
        Expanded(
          child: _ProfileMetric(
            value: '$projects',
            label: 'profile.projects'.tr,
            icon: Icons.folder_open_outlined,
            color: AppColors.brandPrimary,
          ),
        ),
        _ProfileStatDivider(color: divider),
        Expanded(
          child: _ProfileMetric(
            value: '$interests',
            label: 'profile.interests'.tr,
            icon: Icons.favorite_border_rounded,
            color: AppColors.likedAccent,
          ),
        ),
        _ProfileStatDivider(color: divider),
        Expanded(
          child: _ProfileMetric(
            value: '$followers',
            label: 'profile.followers'.tr,
            icon: Icons.groups_2_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 54, width: 1, color: color);
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Icon(icon, size: 23, color: color),
      ],
    );
  }
}

class _ProfileMeta extends StatelessWidget {
  const _ProfileMeta({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: effectiveColor),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: effectiveColor),
          ),
        ),
      ],
    );
  }
}

class _OwnerActionRow extends StatelessWidget {
  const _OwnerActionRow({required this.onShare});

  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            label: 'profile.edit'.tr,
            icon: Icons.edit_outlined,
            height: 54,
            onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            label: 'profile.shareProfile'.tr,
            icon: Icons.share_outlined,
            height: 54,
            onPressed: () {
              onShare();
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppSurface(
      radius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 19, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58),
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
    final scheme = theme.colorScheme;
    final imageUrl = item.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PortfolioPlaceholder(scheme: scheme),
            )
          else
            _PortfolioPlaceholder(scheme: scheme),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.78 : 0.64,
                  ),
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.work_outline,
          size: 32,
          color: scheme.onSurface.withValues(alpha: 0.35),
        ),
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
        InterestIconTile(interest: interest),
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

String _enumLabel(String? value) => (value ?? '')
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0]}${word.substring(1).toLowerCase()}')
    .join(' ');

String _formatJoinedAt(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return '';
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _socialLabel(String platform) => switch (platform.toUpperCase()) {
  'LINKEDIN' => 'profile.linkedIn'.tr,
  'WEBSITE' => 'profile.website'.tr,
  'GITHUB' => 'GitHub',
  'TELEGRAM' => 'Telegram',
  _ => _enumLabel(platform),
};

IconData _socialIcon(String platform) => switch (platform.toUpperCase()) {
  'LINKEDIN' => Icons.business_center_outlined,
  'WEBSITE' => Icons.language_outlined,
  'GITHUB' => Icons.code_outlined,
  'TELEGRAM' => Icons.send_outlined,
  _ => Icons.link_outlined,
};
