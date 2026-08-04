import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/avatar/app_avatar.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:genlink_frontend/features/notification/presentation/screens/notification_screen.dart';

/// Community Header implementation identical in style and design tokens
/// to the Finance Header in [FinanceScreen].
class CommunityHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String activeCategory;
  final bool hasUnreadMessages;
  final bool hasUnreadNotifications;
  final String? userAvatarUrl;
  final String userName;

  const CommunityHeaderWidget({
    super.key,
    required this.activeCategory,
    this.hasUnreadMessages = true,
    this.hasUnreadNotifications = true,
    this.userAvatarUrl = 'assets/images/user_profile.png',
    this.userName = 'Sokny Enat',
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. TITLE - Identical to Finance Header Title TextStyle
              Text(
                titleText,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),

              // 2. ACTION BUTTONS - Identical to Finance Action Button Containers
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chat Button (Identical style to Finance Notification button)
                  GestureDetector(
                    onTap: () => Get.to(() => const ChatListScreen()),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 22,
                            color: textPrimary,
                          ),
                          if (hasUnreadMessages)
                            Positioned(
                              top: 9,
                              right: 9,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.communityAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Notification Button (Exact Finance Notification button)
                  GestureDetector(
                    onTap: () => Get.to(() => const NotificationScreen()),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: textPrimary,
                          ),
                          if (hasUnreadNotifications)
                            Positioned(
                              top: 9,
                              right: 9,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.communityAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Profile Avatar Button (Exact 42x42 size target)
                  AppAvatar(
                    imageUrl: userAvatarUrl,
                    name: userName,
                    size: 42,
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
