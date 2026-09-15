import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'community_creation_flow.dart';

/// "What's happening in your community?" Quick Post Card.
///
/// Used on both Home dashboard and Community feed screen to trigger
/// instant Create Post composer navigation directly with one tap.
class QuickCreatePostCard extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onTapPost;
  final VoidCallback? onTapDiscussion;
  final VoidCallback? onTapEvent;
  final String? avatarUrl;
  final String? userName;
  final EdgeInsetsGeometry padding;

  const QuickCreatePostCard({
    super.key,
    this.onTap,
    this.onTapPost,
    this.onTapDiscussion,
    this.onTapEvent,
    this.avatarUrl,
    this.userName,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    Widget buildCardContent(String? effectiveAvatar, String? effectiveName) {
      return Padding(
        padding: padding,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => CommunityCreationFlow.openCreatePost(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppAvatar(
                        imageUrl: effectiveAvatar,
                        name: effectiveName,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              effectiveName != null &&
                                      effectiveName.isNotEmpty &&
                                      effectiveName != 'Guest'
                                  ? 'community.whatsHappeningWithName'.trParams({'name': effectiveName})
                                  : 'community.whatsHappening'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ) ??
                                  TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'community.shareWithCommunity'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                  ) ??
                                  TextStyle(
                                    color: textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_note_rounded,
                        color: textMuted.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ],
                  ),
                  if (onTapPost != null || onTapDiscussion != null || onTapEvent != null) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (onTapPost != null)
                          InkWell(
                            onTap: onTapPost,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'community.post'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (onTapDiscussion != null)
                          InkWell(
                            onTap: onTapDiscussion,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'community.discussion'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (onTapEvent != null)
                          InkWell(
                            onTap: onTapEvent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                'community.event'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (authController == null) {
      return buildCardContent(avatarUrl, userName);
    }

    return Obx(() {
      final user = authController.currentUser.value;
      final effectiveAvatar = avatarUrl ?? user?.avatarUrl;
      final effectiveName = userName ?? user?.fullName;
      return buildCardContent(effectiveAvatar, effectiveName);
    });
  }
}
