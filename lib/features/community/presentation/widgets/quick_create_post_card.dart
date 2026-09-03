import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import 'community_creation_flow.dart';

/// "What's happening in your community?" Quick Post Card.
///
/// Used on both Home dashboard and Community feed screen to trigger
/// instant Create Post composer navigation directly with one tap.
class QuickCreatePostCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String? avatarUrl;
  final String? userName;
  final EdgeInsetsGeometry padding;

  const QuickCreatePostCard({
    super.key,
    this.onTap,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? (avatarUrl!.startsWith('assets/')
                          ? AssetImage(avatarUrl!) as ImageProvider
                          : NetworkImage(avatarUrl!))
                      : const AssetImage('assets/images/user_profile.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName != null && userName!.isNotEmpty
                            ? 'community.whatsHappeningSokny'.tr
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
          ),
        ),
      ),
    );
  }
}
