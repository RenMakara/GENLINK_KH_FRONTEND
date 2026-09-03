import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';

/// Reusable Creation Menu Bottom Sheet for GenLink KH.
///
/// Features 3 distinct creation options:
/// 1. Create Post -> Opens Create Post composer
/// 2. Create Story -> Opens Story Creator hub
/// 3. Create Event -> Opens Create Event screen
///
/// Styled following GenLink KH design system tokens and dark mode standards.
class CommunityCreationBottomSheet extends StatelessWidget {
  final VoidCallback onSelectCreatePost;
  final VoidCallback onSelectCreateStory;
  final VoidCallback onSelectCreateEvent;

  const CommunityCreationBottomSheet({
    super.key,
    required this.onSelectCreatePost,
    required this.onSelectCreateStory,
    required this.onSelectCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: borderSubtle, width: 1),
          left: BorderSide(color: borderSubtle, width: 1),
          right: BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.lightBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Sheet Title Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'home.actionCreate'.tr.isNotEmpty && 'home.actionCreate'.tr != 'home.actionCreate'
                    ? 'home.actionCreate'.tr
                    : 'Create',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 1. Create Post Option
            _CreationOptionTile(
              icon: Icons.post_add_rounded,
              iconColor: AppColors.communityAccent,
              title: 'community.createPost'.tr,
              subtitle: 'community.shareWithCommunity'.tr,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: onSelectCreatePost,
            ),

            const SizedBox(height: 8),

            // 2. Create Story Option
            _CreationOptionTile(
              icon: Icons.amp_stories_rounded,
              iconColor: AppColors.growthAccent,
              title: 'community.createStory'.tr,
              subtitle: 'Create a photo, video, or text story',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: onSelectCreateStory,
            ),

            const SizedBox(height: 8),

            // 3. Create Event Option
            _CreationOptionTile(
              icon: Icons.event_available_rounded,
              iconColor: AppColors.brandPrimary,
              title: 'community.createEvent'.tr,
              subtitle: 'Host an event or community meetup',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
              onTap: onSelectCreateEvent,
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _CreationOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _CreationOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.14 : 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.squircle),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
