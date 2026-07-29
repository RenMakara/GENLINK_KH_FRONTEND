import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/notifications/app_notification_banner.dart';
import '../screens/community_search_screen.dart';

/// Redesigned production-grade header for GenLink KH Community module.
/// Inspired by Threads, Discord, and Instagram design systems.
class CommunityHeaderWidget extends StatefulWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(62.0);

  @override
  State<CommunityHeaderWidget> createState() => _CommunityHeaderWidgetState();
}

class _CommunityHeaderWidgetState extends State<CommunityHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: widget.preferredSize.height,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Sleek, Proportionate GenLink Logo (Height: 26dp, Flexible to prevent overflow)
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/logos/genlink_logo.png',
                      height: 26,
                      fit: BoxFit.contain,
                      semanticLabel: 'GenLink KH Brand',
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Action Icons Grouped Closely Together on the Right (10px spacing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔍 Search Action (42x42dp Touch Target, 22dp Icon)
                    Hero(
                      tag: 'community_search_bar',
                      child: _HeaderActionButton(
                        tooltip: "Search",
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommunitySearchScreen(
                                activeTab: widget.activeCategory,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 6),

                    // 💬💬 Messages Action (Double Conversation Icon: Icons.forum_rounded, Blue Unread Badge)
                    _HeaderActionButton(
                      tooltip: "Messages",
                      icon: const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      badge: widget.hasUnreadMessages
                          ? Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.communityAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                            )
                          : null,
                      onTap: () {
                        AppNotificationBanner.showInfo(
                          context: context,
                          title: "Messages",
                          message: "Direct messaging features active.",
                          icon: Icons.forum_rounded,
                        );
                      },
                    ),

                    const SizedBox(width: 6),

                    // 🔔 Notifications Action (Bell Icon: Icons.notifications_none_rounded, Blue Unread Badge)
                    _HeaderActionButton(
                      tooltip: "Notifications",
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      badge: widget.hasUnreadNotifications
                          ? Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.communityAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                            )
                          : null,
                      onTap: () {
                        AppNotificationBanner.showInfo(
                          context: context,
                          title: "Notifications",
                          message: "You have 3 new campus notifications.",
                          icon: Icons.notifications_active_rounded,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable Material 3 Header Action Button with 48x48 touch target, 95% press scale & ink ripple.
class _HeaderActionButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onTap;
  final Widget? badge;
  final String tooltip;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.badge,
    required this.tooltip,
  });

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.tooltip,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: Colors.white.withValues(alpha: 0.15),
                highlightColor: Colors.white.withValues(alpha: 0.08),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    widget.icon,
                    if (widget.badge != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: widget.badge!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
