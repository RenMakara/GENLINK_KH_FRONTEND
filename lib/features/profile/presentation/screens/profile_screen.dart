import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_widgets.dart';

import '../../../community/presentation/controllers/community_controller.dart';
import '../../../community/presentation/widgets/post_card_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.viewingUsername});

  final String? viewingUsername;

  ProfileController get controller {
    final username = viewingUsername?.trim();
    if (username == null || username.isEmpty) {
      return Get.find<ProfileController>();
    }
    return Get.find<ProfileController>(
      tag: ProfileController.publicTag(username),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        titleSpacing: AppSpacing.md,
        title: Obx(() {
          final profile = !controller.isOwner
              ? controller.publicProfile.value
              : controller.profile.value;

          if (profile == null) return const SizedBox.shrink();

          return Row(
            children: [
              AppAvatar(
                imageUrl: _getAvatar(profile),
                name: _getFullName(profile),
                size: 32,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Flexible(
                child: Text(
                  _getFullName(profile),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }),
        actions: [
          if (controller.isOwner) ...[
            IconButton(
              icon: Icon(Icons.notifications_none, color: textPrimary),
              tooltip: 'settings.notifications'.tr,
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textPrimary),
              tooltip: 'settings.title'.tr,
              onPressed: () => Get.toNamed<void>(AppRoutes.settings),
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.more_horiz, color: textPrimary),
              onPressed: () {},
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        final profile = !controller.isOwner
            ? controller.publicProfile.value
            : controller.profile.value;

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

        final isOwner = controller.isOwner;

        return RefreshIndicator(
          onRefresh: controller.reload,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: _Identity(profile: profile, isOwner: isOwner),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (controller.interests.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _Skills(interests: controller.interests),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    const Divider(height: 1),
                  ]),
                ),
              ),
              _ProfilePosts(userId: _getUserId(profile)),
            ],
          ),
        );
      }),
    );
  }

  String? _getAvatar(dynamic p) =>
      (p is ProfileEntity) ? p.avatarUrl : (p as PublicProfileEntity).avatarUrl;
  String _getFullName(dynamic p) =>
      (p is ProfileEntity) ? p.fullName : (p as PublicProfileEntity).fullName;
  String _getUserId(dynamic p) =>
      (p is ProfileEntity) ? p.userId : (p as PublicProfileEntity).userId;
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile, required this.isOwner});

  final dynamic profile;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final String fullName = profile is ProfileEntity
        ? profile.fullName
        : (profile as PublicProfileEntity).fullName;
    final String username = profile is ProfileEntity
        ? profile.username
        : (profile as PublicProfileEntity).username;
    final String? bio = profile is ProfileEntity
        ? profile.bio
        : (profile as PublicProfileEntity).bio;
    final String? universityName = profile is ProfileEntity
        ? profile.universityName
        : (profile as PublicProfileEntity).universityName;
    final String? avatarUrl = profile is ProfileEntity
        ? profile.avatarUrl
        : (profile as PublicProfileEntity).avatarUrl;

    return Column(
      children: [
        if (isOwner)
          RingedAvatar(
            imageUrl: avatarUrl,
            name: fullName,
            size: 108,
            onEdit: () => Get.toNamed<void>(AppRoutes.editProfile),
          )
        else
          AppAvatar(imageUrl: avatarUrl, name: fullName, size: 108),
        const SizedBox(height: AppSpacing.md),
        Text(
          fullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '@$username',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        if (universityName != null && universityName.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 15, color: muted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  universityName,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (bio != null && bio.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (isOwner)
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              label: 'profile.edit'.tr,
              icon: Icons.edit_outlined,
              onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: textInverse,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Follow',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorderStrong
                          : AppColors.lightBorderStrong,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Skills extends StatelessWidget {
  const _Skills({required this.interests});
  final List<InterestEntity> interests;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: interests
          .map(
            (interest) =>
                ExpertiseChip(label: interest.name, emphasised: false),
          )
          .toList(),
    );
  }
}

class _ProfilePosts extends StatelessWidget {
  const _ProfilePosts({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CommunityController>()) {
      return _emptyState(context);
    }
    final communityController = Get.find<CommunityController>();

    return Obx(() {
      final userPosts = communityController.posts
          .where((p) => p.userId == userId)
          .toList();

      if (userPosts.isEmpty) {
        return _emptyState(context);
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => PostCardWidget(
            post: userPosts[index],
            controller: communityController,
          ),
          childCount: userPosts.length,
        ),
      );
    });
  }

  Widget _emptyState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            'No posts yet.',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
