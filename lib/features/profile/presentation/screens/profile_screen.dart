import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/images/app_cached_image.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../../../design_system/widgets/surfaces/app_surface.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../chat/presentation/bindings/chat_binding.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../chat/chat_navigation.dart';

import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/widgets/community_widgets.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/full_screen_image_viewer.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import '../bindings/profile_binding.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_cover_preset.dart';
import '../utils/profile_navigation.dart';
import '../widgets/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.viewingUsername});

  final String? viewingUsername;

  String? get _resolvedDisplayName {
    final args = Get.arguments;
    if (args is Map) {
      final name = args['displayName'] ?? args['fullName'] ?? args['name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    } else if (args is String && args.trim().isNotEmpty) {
      return args.trim();
    }
    final paramName = Get.parameters['displayName'] ?? Get.parameters['name'];
    if (paramName != null && paramName.trim().isNotEmpty) {
      return paramName.trim();
    }
    return null;
  }

  String get _effectiveTargetName {
    final pub = controller.publicProfile.value;
    if (pub != null && pub.fullName.trim().isNotEmpty) {
      return pub.fullName.trim();
    }
    final fromArgs = _resolvedDisplayName;
    if (fromArgs != null && fromArgs.isNotEmpty) {
      return fromArgs;
    }
    if (pub != null && pub.username.trim().isNotEmpty) {
      return pub.username.trim().replaceAll('@', '');
    }
    final u = _resolvedUsername?.trim();
    if (u != null && u.isNotEmpty) {
      return u.replaceAll('@', '');
    }
    return 'profile.thisUser'.tr;
  }

  static bool _isPrivateError(String? msg) {
    if (msg == null) return false;
    final lower = msg.toLowerCase();
    return lower.contains('private') ||
        lower.contains('friends only') ||
        lower.contains('profile_private');
  }

  static bool _isFriendsOnlyError(String? msg) {
    if (msg == null) return false;
    final lower = msg.toLowerCase();
    return lower.contains('friends only') ||
        lower.contains('profile_friends_only');
  }

  String? get _resolvedUsername {
    if (viewingUsername != null && viewingUsername!.trim().isNotEmpty) {
      return viewingUsername!.trim();
    }
    // Only inspect route parameters when navigated directly to the standalone
    // profile route, never when embedded inside MainScreen or other tabs.
    final currentRoute = Get.currentRoute;
    if (currentRoute == AppRoutes.profile ||
        currentRoute.startsWith('${AppRoutes.profile}?') ||
        currentRoute.startsWith('${AppRoutes.profile}/')) {
      final param = Get.parameters['username'];
      if (param != null && param.trim().isNotEmpty) {
        return param.trim();
      }
    }
    return null;
  }

  ProfileController get controller {
    final username = ProfileNavigation.ownerAwareUsername(
      username: _resolvedUsername,
    );
    if (username == null) {
      if (!Get.isRegistered<ProfileController>()) {
        ProfileBinding.registerOwnerController();
      }
      return Get.find<ProfileController>();
    }
    final tag = ProfileController.publicTag(username);
    if (!Get.isRegistered<ProfileController>(tag: tag)) {
      ProfileBinding.registerPublicController(username);
    }
    return Get.find<ProfileController>(tag: tag);
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
            final isPrivate = controller.isPrivate.value ||
                _isPrivateError(controller.errorMessage.value);
            if (isPrivate && !controller.isOwner) {
              return PrivateProfileView(
                displayName: _effectiveTargetName,
                isFriendsOnly: controller.isFriendsOnly.value ||
                    _isFriendsOnlyError(controller.errorMessage.value),
              );
            }

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

  AppScreenHeader _ownerAppBar(BuildContext context) => AppScreenHeader(
    title: '',
    leading: Navigator.of(context).canPop()
        ? AppBackButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            },
          )
        : null,
    titleWidget: Obx(() {
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }),
    actions: [
      AppHeaderActionButton(
        icon: Icons.ios_share_outlined,
        tooltip: 'profile.shareProfile'.tr,
        onTap: _shareOwnerProfile,
      ),
      AppHeaderActionButton(
        icon: Icons.notifications_none_rounded,
        tooltip: 'settings.notifications'.tr,
        onTap: () => Get.toNamed<void>(AppRoutes.notifications),
      ),
      AppHeaderActionButton(
        icon: Icons.settings_rounded,
        tooltip: 'settings.title'.tr,
        onTap: () => Get.toNamed<void>(AppRoutes.settings),
      ),
    ],
  );

  AppScreenHeader _publicAppBar(BuildContext context) {
    final semantic = context.semanticColors;
    final width = MediaQuery.sizeOf(context).width;
    final isVeryNarrow = width < 335;
    final isNarrow = width < 360;
    final titleFontSize = isVeryNarrow ? 21.0 : (isNarrow ? 22.5 : 24.0);
    final titleLetterSpacing = isVeryNarrow ? -0.3 : (isNarrow ? -0.4 : -0.5);

    return AppScreenHeader(
      title: 'profile.publicProfile'.tr,
      leadingGap: AppSpacing.md,
      leading: AppBackButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Get.back();
          }
        },
      ),
      titleWidget: Obx(() {
        final profile = controller.publicProfile.value;
        final nameFromArgs = _resolvedDisplayName;
        final displayName =
            profile != null && profile.fullName.trim().isNotEmpty
            ? profile.fullName.trim()
            : (nameFromArgs != null && nameFromArgs.isNotEmpty
                  ? nameFromArgs
                  : (profile != null && profile.username.trim().isNotEmpty
                        ? '@${profile.username.trim()}'
                        : (_resolvedUsername != null && _resolvedUsername!.isNotEmpty
                              ? (_resolvedUsername!.startsWith('@')
                                    ? _resolvedUsername!
                                    : (_resolvedUsername!.contains(' ')
                                          ? _resolvedUsername!
                                          : '@$_resolvedUsername'))
                              : 'profile.publicProfile'.tr)));

        return Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: semantic.primaryText,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: titleLetterSpacing,
                height: 1.2,
              ) ??
              TextStyle(
                color: semantic.primaryText,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: titleLetterSpacing,
                height: 1.2,
              ),
        );
      }),
      actions: [
        AppHeaderActionButton(
          icon: Icons.ios_share_outlined,
          tooltip: 'profile.shareProfile'.tr,
          onTap: _sharePublicProfile,
        ),
      ],
    );
  }

  Future<void> _shareOwnerProfile() async {
    final profile = controller.profile.value;
    if (profile == null) return;
    await Clipboard.setData(ClipboardData(text: '@${profile.username}'));
    Get.showSnackbar(
      GetSnackBar(
        message: 'profile.shareCopied'.tr,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sharePublicProfile() async {
    final profile = controller.publicProfile.value;
    final username = profile?.username ?? _resolvedUsername;
    if (username == null || username.isEmpty) return;
    final handle = username.startsWith('@') ? username : '@$username';
    await Clipboard.setData(ClipboardData(text: handle));
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
        Obx(() {
          final stats = controller.followStats.value;
          return Column(
            children: [
              _ProfileStats(
                totalXp: profile.totalXp,
                projects: controller.portfolio.length,
                interests: controller.interests.length,
                followers: stats?.followers ?? 0,
                onFollowersTap: () =>
                    Get.toNamed<void>(AppRoutes.friendRequests),
              ),
              if (stats != null) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => Get.toNamed<void>(AppRoutes.friendRequests),
                  child: Text(
                    '${stats.following} ${'profile.followingCount'.tr}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        _CompletionCard(profile: profile),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => _ProfileSectionCard(
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
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => _ProfileSectionCard(
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
                  onPressed: () =>
                      Get.toNamed<void>(AppRoutes.profileInterests),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => _ProfileSectionCard(
            icon: Icons.folder_open_outlined,
            title: 'profile.portfolio'.tr,
            trailing: controller.portfolio.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        tooltip: 'profile.addPortfolio'.tr,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () =>
                            Get.toNamed<void>(AppRoutes.profilePortfolioForm),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: () =>
                            Get.toNamed<void>(AppRoutes.profilePortfolio),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: Text('profile.viewAll'.tr),
                      ),
                    ],
                  )
                : null,
            child: controller.portfolio.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_outline_rounded,
                          size: 32,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'profile.emptyPortfolio'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              Get.toNamed<void>(AppRoutes.profilePortfolioForm),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('profile.addPortfolio'.tr),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.portfolio.length < 5
                          ? controller.portfolio.length + 1
                          : 5,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, index) {
                        if (index == controller.portfolio.length) {
                          return SizedBox(
                            width: 110,
                            child: _AddPortfolioShelfCard(
                              onTap: () => Get.toNamed<void>(
                                AppRoutes.profilePortfolioForm,
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          width: 158,
                          child: _PortfolioPreview(
                            item: controller.portfolio[index],
                            onTap: () => Get.toNamed<void>(
                              AppRoutes.profilePortfolioForm,
                              arguments: controller.portfolio[index],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        Obx(() {
          if (controller.socialLinks.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _LabelledSection(
                title: 'profile.socialLinks'.tr,
                child: _SocialLinksCard(links: controller.socialLinks),
              ),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => _ProfileSectionCard(
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
        ),
        Builder(
          builder: (context) {
            final commCtrl = Get.isRegistered<CommunityController>()
                ? Get.find<CommunityController>()
                : Get.put(CommunityController());
            if (profile.userId == commCtrl.currentUserId) {
              commCtrl.fetchRepostedPosts();
            }
            commCtrl.fetchDiscussionReposts(profile.userId);
            return Obx(() {
              final userPosts = commCtrl.getUserPosts(
                profile.userId,
                username: profile.fullName,
              );
              final userDiscussionReposts = commCtrl.getUserDiscussionReposts(
                profile.userId,
              );
              if (userPosts.isEmpty && userDiscussionReposts.isEmpty) {
                return const SizedBox.shrink();
              }
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
                  ...userDiscussionReposts.map(
                    (topic) => ForumThreadCard(
                      title: topic.title,
                      author: topic.isAnonymous
                          ? 'Anonymous'
                          : topic.authorName,
                      avatarUrl: topic.isAnonymous
                          ? null
                          : (topic.authorAvatar.isNotEmpty
                                ? topic.authorAvatar
                                : null),
                      timeAgo: topic.timeAgo,
                      createdAt: topic.createdAt,
                      content: topic.content,
                      category: topic.category,
                      replies: topic.repliesCount,
                      likes: topic.upvotes,
                      isLiked: topic.isLiked,
                      isBookmarked: commCtrl.isDiscussionBookmarked(topic.id),
                      likers: topic.likers,
                      discussionId: topic.id,
                      isOwner: topic.checkIsOwner(commCtrl.currentUserId),
                      isAnonymous: topic.isAnonymous,
                      repostedBy: topic.repostedBy,
                      repostCaption: topic.repostCaption,
                      onTap: () => Get.to(
                        () => ForumDiscussionScreen(discussion: topic),
                      ),
                      onLikeTap: () => commCtrl.toggleDiscussionLike(topic.id),
                      onCommentTap: () => Get.to(
                        () => ForumDiscussionScreen(discussion: topic),
                      ),
                      onSaveTap: () =>
                          commCtrl.toggleDiscussionBookmark(topic.id),
                    ),
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
      radius: AppRadius.lg,
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
        _PublicActionRow(controller: controller, profile: profile),
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
                : Get.put(CommunityController());
            commCtrl.fetchDiscussionReposts(profile.userId);
            return Obx(() {
              final userPosts = commCtrl.getUserPosts(
                profile.userId,
                username: profile.fullName,
              );
              final userDiscussionReposts = commCtrl.getUserDiscussionReposts(
                profile.userId,
              );
              if (userPosts.isEmpty && userDiscussionReposts.isEmpty) {
                return const SizedBox.shrink();
              }
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
                  ...userDiscussionReposts.map(
                    (topic) => ForumThreadCard(
                      title: topic.title,
                      author: topic.isAnonymous
                          ? 'Anonymous'
                          : topic.authorName,
                      avatarUrl: topic.isAnonymous
                          ? null
                          : (topic.authorAvatar.isNotEmpty
                                ? topic.authorAvatar
                                : null),
                      timeAgo: topic.timeAgo,
                      createdAt: topic.createdAt,
                      content: topic.content,
                      category: topic.category,
                      replies: topic.repliesCount,
                      likes: topic.upvotes,
                      isLiked: topic.isLiked,
                      isBookmarked: commCtrl.isDiscussionBookmarked(topic.id),
                      likers: topic.likers,
                      discussionId: topic.id,
                      isOwner: topic.checkIsOwner(commCtrl.currentUserId),
                      isAnonymous: topic.isAnonymous,
                      repostedBy: topic.repostedBy,
                      repostCaption: topic.repostCaption,
                      onTap: () => Get.to(
                        () => ForumDiscussionScreen(discussion: topic),
                      ),
                      onLikeTap: () => commCtrl.toggleDiscussionLike(topic.id),
                      onCommentTap: () => Get.to(
                        () => ForumDiscussionScreen(discussion: topic),
                      ),
                      onSaveTap: () =>
                          commCtrl.toggleDiscussionBookmark(topic.id),
                    ),
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

class _PublicActionRow extends StatefulWidget {
  const _PublicActionRow({required this.controller, required this.profile});

  final ProfileController controller;
  final PublicProfileEntity profile;

  @override
  State<_PublicActionRow> createState() => _PublicActionRowState();
}

class _PublicActionRowState extends State<_PublicActionRow> {
  bool _isOpeningChat = false;

  Future<void> _handleChatTap() async {
    if (_isOpeningChat) return;
    setState(() => _isOpeningChat = true);
    try {
      if (!Get.isRegistered<ChatController>()) {
        ChatBinding().dependencies();
      }
      final chatController = Get.find<ChatController>();
      debugPrint(
        '[CHAT-NAV] source = PublicProfile, userId = ${widget.profile.userId}, currentRoute = ${Get.currentRoute}, controller = ${identityHashCode(chatController)}',
      );
      final conv = await chatController.openPrivateChat(
        widget.profile.userId,
        name: widget.profile.fullName,
        avatar: widget.profile.avatarUrl,
      );
      if (conv != null && mounted) {
        debugPrint(
          '[CHAT-NAV] PublicProfile openPrivateChat returned conv.id = ${conv.id}, calling openChatDetail',
        );
        ChatNavigation.openChatDetail(conv.id, conversation: conv);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Could not open conversation. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = widget.controller.followStats.value;
      final status = stats?.followStatus;
      final isFollowing = stats?.isFollowing ?? false;
      final followsViewer = stats?.followsViewer ?? false;
      final isFriend =
          (stats?.friend ?? false) || (isFollowing && followsViewer);

      final String label;
      final IconData icon;

      if (status == 'PENDING') {
        label = 'profile.requested'.tr;
        icon = Icons.hourglass_top_rounded;
      } else if (isFriend) {
        label =
            'friends.friend'.tr.isNotEmpty &&
                'friends.friend'.tr != 'friends.friend'
            ? 'friends.friend'.tr
            : ('profile.friend'.tr.isNotEmpty &&
                      'profile.friend'.tr != 'profile.friend'
                  ? 'profile.friend'.tr
                  : 'Friend');
        icon = Icons.people_alt_rounded;
      } else if (isFollowing) {
        label = 'profile.following'.tr;
        icon = Icons.check_rounded;
      } else if (followsViewer) {
        label =
            'friends.followBack'.tr.isNotEmpty &&
                'friends.followBack'.tr != 'friends.followBack'
            ? 'friends.followBack'.tr
            : 'Follow Back';
        icon = Icons.swap_horiz_rounded;
      } else {
        label = 'profile.follow'.tr;
        icon = Icons.person_add_alt_1_outlined;
      }

      final chatLabel =
          'profile.chat'.tr.isNotEmpty && 'profile.chat'.tr != 'profile.chat'
          ? 'profile.chat'.tr
          : 'Chat';

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: label,
                  icon: icon,
                  height: 44,
                  loading: widget.controller.isRelationshipSaving.value,
                  onPressed: () => widget.controller.toggleFollow(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: chatLabel,
                  icon: Icons.chat_bubble_outline_rounded,
                  height: 44,
                  loading: _isOpeningChat,
                  onPressed: _handleChatTap,
                ),
              ),
            ],
          ),
          if (followsViewer && !isFollowing) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'friends.followsYou'.tr.isNotEmpty &&
                          'friends.followsYou'.tr != 'friends.followsYou'
                      ? 'friends.followsYou'.tr
                      : 'Follows you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1.2,
                ),
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
              borderRadius: BorderRadius.circular(AppRadius.lg),
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
    this.onFollowersTap,
  });

  final int totalXp;
  final int projects;
  final int interests;
  final int followers;
  final VoidCallback? onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.45);
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
          child: GestureDetector(
            onTap: onFollowersTap,
            behavior: HitTestBehavior.opaque,
            child: _ProfileMetric(
              value: '$followers',
              label: 'profile.followers'.tr,
              icon: Icons.groups_2_outlined,
              color: AppColors.success,
            ),
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
      radius: AppRadius.lg,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
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
  Widget build(BuildContext context) => AppSurface(radius: 12.0, child: child);
}

class _PortfolioPreview extends StatelessWidget {
  const _PortfolioPreview({required this.item, this.onTap});
  final PortfolioItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final imageUrl = item.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                AppCachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 450,
                  errorWidget: _PortfolioPlaceholder(scheme: scheme),
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
                        alpha: theme.brightness == Brightness.dark
                            ? 0.78
                            : 0.64,
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
        ),
      ),
    );
  }
}

class _AddPortfolioShelfCard extends StatelessWidget {
  const _AddPortfolioShelfCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.8,
            ),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, size: 20, color: scheme.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'common.add'.tr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
