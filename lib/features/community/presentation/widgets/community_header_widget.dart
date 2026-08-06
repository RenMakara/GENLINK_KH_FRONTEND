import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../screens/community_search_screen.dart';

/// GenLink KH Community Header Widget
///
/// Refactored to strictly match the design system tokens, layout, typography,
/// and component architecture of the Finance header.
class CommunityHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String activeCategory;
  final bool hasUnreadMessages;
  final bool hasUnreadNotifications;

  const CommunityHeaderWidget({
    super.key,
    required this.activeCategory,
    this.hasUnreadMessages = true,
    this.hasUnreadNotifications = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final titleText = 'community.title'.tr.isNotEmpty && 'community.title'.tr != 'community.title'
        ? 'community.title'.tr
        : 'Community';

    return Container(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. LEFT TITLE - Identical to Finance Header Title TextStyle
              Text(
                titleText,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),

              // 2. RIGHT ACTION BUTTONS (Search, Chat, Notification)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Button
                  _HeaderActionButton(
                    icon: Icons.search_rounded,
                    onTap: () => Get.to(() => CommunitySearchScreen(activeTab: activeCategory)),
                    backgroundColor: surface,
                    borderColor: border,
                    iconColor: textPrimary,
                    tooltip: 'community.search'.tr,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Chat Button
                  _HeaderActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => Get.to(() => const ChatListScreen()),
                    showBadge: hasUnreadMessages,
                    badgeColor: AppColors.communityAccent,
                    backgroundColor: surface,
                    borderColor: border,
                    iconColor: textPrimary,
                    tooltip: 'community.chat'.tr,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Notification Button
                  _HeaderActionButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => Get.to(() => const NotificationScreen()),
                    showBadge: hasUnreadNotifications,
                    badgeColor: AppColors.communityAccent,
                    backgroundColor: surface,
                    borderColor: border,
                    iconColor: textPrimary,
                    tooltip: 'community.notifications'.tr,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Header Action Button component with standardized 44x44 touch target,
/// 24px icon size, border radius, and optional badge indicator.
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;
  final Color badgeColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final String tooltip;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
    this.badgeColor = AppColors.communityAccent,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 24.0,
                  color: iconColor,
                ),
                if (showBadge)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
