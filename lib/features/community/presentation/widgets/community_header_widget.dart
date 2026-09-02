import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../screens/community_search_screen.dart';

/// GenLink KH Community Header Widget
///
/// Displays "Home" in Home mode, or "Community" in Community mode, alongside
/// standard Search, Chat, and Notification action buttons.
class CommunityHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String activeCategory;
  final bool isHomeScreen;

  const CommunityHeaderWidget({
    super.key,
    required this.activeCategory,
    this.isHomeScreen = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final titleText = isHomeScreen
        ? ('nav.home'.tr.isNotEmpty && 'nav.home'.tr != 'nav.home'
            ? 'nav.home'.tr
            : 'Home')
        : ('community.title'.tr.isNotEmpty &&
                'community.title'.tr != 'community.title'
            ? 'community.title'.tr
            : 'Community');

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;
    final isVeryNarrow = screenWidth < 335;
    final buttonSize = isVeryNarrow ? 32.0 : (isNarrow ? 36.0 : 42.0);
    final buttonGap = isVeryNarrow
        ? 2.0
        : (isNarrow ? 4.0 : AppSpacing.sm);
    final iconSize = isVeryNarrow ? 18.0 : (isNarrow ? 20.0 : 22.0);
    final titleFontSize = isVeryNarrow
        ? 18.0
        : (isNarrow ? 20.0 : 22.0);
    final horizontalPadding = isVeryNarrow ? 8.0 : (isNarrow ? 10.0 : AppSpacing.md);

    return Container(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              height: preferredSize.height,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  // 1. LEFT TITLE
                  Expanded(
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 2. RIGHT ACTION BUTTONS (Search, Chat, Notification)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Button
                      _HeaderActionButton(
                        icon: Icons.search_rounded,
                        onTap: () => Get.to(
                          () => CommunitySearchScreen(
                            activeTab: activeCategory,
                          ),
                        ),
                        iconColor: textPrimary,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                        tooltip: 'community.search'.tr,
                      ),

                      SizedBox(width: buttonGap),

                      // Chat Button - Two overlapping speech bubbles icon
                      _HeaderActionButton(
                        icon: Icons.forum_outlined,
                        onTap: () => Get.to(() => const ChatListScreen()),
                        iconColor: textPrimary,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                        tooltip: 'community.chat'.tr,
                      ),

                      SizedBox(width: buttonGap),

                      // Notification Button with reactive unread badge
                      Builder(builder: (context) {
                        if (!Get.isRegistered<NotificationController>()) {
                          return _HeaderActionButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () =>
                                Get.to(() => const NotificationScreen()),
                            iconColor: textPrimary,
                            buttonSize: buttonSize,
                            iconSize: iconSize,
                            tooltip: 'community.notifications'.tr,
                          );
                        }
                        final notifController =
                            Get.find<NotificationController>();
                        return Obx(() {
                          final unread = notifController.unreadCount;
                          return _HeaderActionButton(
                            icon: unread > 0
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_none_rounded,
                            onTap: () =>
                                Get.to(() => const NotificationScreen()),
                            iconColor: textPrimary,
                            buttonSize: buttonSize,
                            iconSize: iconSize,
                            hasBadge: unread > 0,
                            tooltip: 'community.notifications'.tr,
                          );
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable Header Action Button component with standardized touch target,
/// 24px icon size, and badge support.
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double buttonSize;
  final double iconSize;
  final String tooltip;
  final bool hasBadge;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    this.buttonSize = 44.0,
    this.iconSize = 24.0,
    required this.tooltip,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: iconSize, color: iconColor),
                  if (hasBadge)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF97316),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
