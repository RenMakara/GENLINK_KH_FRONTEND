import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../screens/community_search_screen.dart';

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

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

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

    // Matches Finance header typography (24px, w800, -0.5) with responsive scaling for compact viewports
    final titleFontSize = isVeryNarrow
        ? 21.0
        : (isNarrow ? 22.5 : 24.0);
    final titleLetterSpacing = isVeryNarrow ? -0.3 : (isNarrow ? -0.4 : -0.5);

    // Subtle tactile container styling matching Finance header action button
    final buttonSize = isVeryNarrow ? 36.0 : (isNarrow ? 38.0 : 40.0);
    final buttonGap = isVeryNarrow ? 4.0 : (isNarrow ? 6.0 : AppSpacing.xs);
    final iconSize = isVeryNarrow ? 19.0 : (isNarrow ? 20.0 : 21.0);
    const horizontalPadding = AppSpacing.md;

    return Container(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              height: preferredSize.height,
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                            color: textPrimary,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: titleLetterSpacing,
                            height: 1.2,
                          ) ??
                          TextStyle(
                            color: textPrimary,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: titleLetterSpacing,
                            height: 1.2,
                          ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeaderActionButton(
                        icon: Icons.search_rounded,
                        onTap: () => Get.to(
                          () => CommunitySearchScreen(
                            activeTab: activeCategory,
                          ),
                        ),
                        iconColor: textPrimary,
                        surfaceColor: surface,
                        borderColor: border,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                        tooltip: 'community.search'.tr,
                      ),

                      SizedBox(width: buttonGap),

                      _HeaderActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => Get.to(() => const ChatListScreen()),
                        iconColor: textPrimary,
                        surfaceColor: surface,
                        borderColor: border,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                        tooltip: 'community.chat'.tr,
                      ),

                      SizedBox(width: buttonGap),

                      Builder(builder: (context) {
                        if (!Get.isRegistered<NotificationController>()) {
                          return _HeaderActionButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () =>
                                Get.to(() => const NotificationScreen()),
                            iconColor: textPrimary,
                            surfaceColor: surface,
                            borderColor: border,
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
                            surfaceColor: surface,
                            borderColor: border,
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

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color surfaceColor;
  final Color borderColor;
  final double buttonSize;
  final double iconSize;
  final String tooltip;
  final bool hasBadge;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    required this.surfaceColor,
    required this.borderColor,
    this.buttonSize = 40.0,
    this.iconSize = 21.0,
    required this.tooltip,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(buttonSize * 0.28);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Ink(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 0.8),
            ),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF97316),
                          border: Border.all(
                            color: surfaceColor,
                            width: 1.2,
                          ),
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
