import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/notification_model.dart';
import '../bindings/notification_binding.dart';
import '../controllers/notification_controller.dart';

/// GenLink KH — Production-quality Notification Screen.
///
/// Design: strict monochrome (black / white / gray).
/// No blue / cyan / green / yellow / purple.
///
/// Features:
///  - Localized header, tabs, empty/error states.
///  - Context-aware "Mark all read" (hidden when count = 0).
///  - Animated unread badge on title.
///  - Scrollable filter tabs (All / Mentions / Activity / System).
///  - Date grouping: TODAY / EARLIER if timestamps are present.
///  - Monochrome type badges on avatars.
///  - Subtle read/unread visual distinction.
///  - Press-scale feedback (0.98 scale, 150ms).
///  - Animated read-state transition (200ms).
///  - Swipe-to-delete with delete background.
///  - Empty / loading / error states.
class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  NotificationController get _effectiveController {
    if (!Get.isRegistered<NotificationController>()) {
      NotificationBinding().dependencies();
    }
    return Get.find<NotificationController>();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static const _bg = Color(0xFF0F0F0F);

  static const Map<NotificationType, String> _typeKeyMap = {
    NotificationType.like: 'notification.typeLike',
    NotificationType.comment: 'notification.typeComment',
    NotificationType.mention: 'notification.typeMention',
    NotificationType.follow: 'notification.typeFollow',
    NotificationType.group: 'notification.typeGroup',
    NotificationType.event: 'notification.typeEvent',
    NotificationType.system: 'notification.typeSystem',
  };

  static const Map<NotificationType, IconData> _typeIconMap = {
    NotificationType.like: Icons.favorite_rounded,
    NotificationType.comment: Icons.chat_bubble_rounded,
    NotificationType.mention: Icons.alternate_email_rounded,
    NotificationType.follow: Icons.person_add_rounded,
    NotificationType.group: Icons.groups_rounded,
    NotificationType.event: Icons.event_rounded,
    NotificationType.system: Icons.info_outline_rounded,
  };

  static const Map<String, String> _tabKeyMap = {
    'All': 'notification.tabAll',
    'Mentions': 'notification.tabMentions',
    'Activity': 'notification.tabActivity',
    'System': 'notification.tabSystem',
  };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final notifController = _effectiveController;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(notifController),
      body: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTabBar(notifController),
              const SizedBox(height: 2),
              Expanded(child: _buildBody(notifController)),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(NotificationController notifController) {
    return AppBar(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 74,
      leading: const Center(
        child: AppBackButton(),
      ),
      titleSpacing: 8,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'notification.title'.tr,
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          // Unread count badge — hidden when zero
          Obx(() {
            final count = notifController.unreadCount;
            if (count == 0) return const SizedBox.shrink();
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3D3D3D), width: 0.8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        // "Mark all read" — only shown when there are unread notifications
        Obx(() {
          final count = notifController.unreadCount;
          if (count == 0) return const SizedBox.shrink();
          return Semantics(
            label: 'notification.markAllRead'.tr,
            button: true,
            child: _PressScaleButton(
              onTap: notifController.markAllAsRead,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  'notification.markAllRead'.tr,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: AppColors.darkBorderSubtle),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar(NotificationController notifController) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: notifController.tabs.map((tab) {
            final isSelected = notifController.selectedTab.value == tab;
            final label = _tabKeyMap[tab]?.tr ?? tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PressScaleButton(
                onTap: () => notifController.selectTab(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.darkTextPrimary
                        : const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF2E2E2E),
                      width: 1,
                    ),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF111111)
                          : AppColors.darkTextSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    child: Text(label),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Body: Loading / Empty / Error / List ──────────────────────────────────

  Widget _buildBody(NotificationController notifController) {
    return Obx(() {
      // Loading
      if (notifController.isLoading.value) {
        return const _LoadingSkeleton();
      }

      final list = notifController.filteredNotifications;

      // Empty
      if (list.isEmpty) {
        return _EmptyState(tab: notifController.selectedTab.value);
      }

      // Notification list with optional date grouping
      final todayItems = <NotificationModel>[];
      final earlierItems = <NotificationModel>[];

      final now = DateTime.now();
      for (final n in list) {
        final diff = now.difference(n.timestamp);
        if (diff.inHours < 24) {
          todayItems.add(n);
        } else {
          earlierItems.add(n);
        }
      }

      final showGroups = todayItems.isNotEmpty && earlierItems.isNotEmpty;

      return RefreshIndicator(
        onRefresh: notifController.fetchNotifications,
        color: AppColors.darkTextPrimary,
        backgroundColor: const Color(0xFF1C1C1C),
        displacement: 40,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(bottom: 24, top: 4),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (showGroups) ...[
              _SectionLabel(label: 'notification.today'.tr),
              ...todayItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                ),
              ),
              const SizedBox(height: 4),
              _SectionLabel(label: 'notification.earlier'.tr),
              ...earlierItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                ),
              ),
            ] else ...[
              ...list.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Notification Card
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationCard extends StatefulWidget {
  final NotificationModel notif;
  final NotificationController controller;
  final Map<NotificationType, String> typeKeyMap;
  final Map<NotificationType, IconData> typeIconMap;

  const _NotificationCard({
    required this.notif,
    required this.controller,
    required this.typeKeyMap,
    required this.typeIconMap,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;
    final typeLabel =
        (widget.typeKeyMap[notif.type] ?? 'notification.typeSystem').tr;
    final typeIcon =
        widget.typeIconMap[notif.type] ?? Icons.notifications_rounded;

    return Obx(() {
      // Re-render on any notifications list change
      widget
          .controller
          .notifications
          .length; // reactive dependency (length is public)
      final isRead = notif.isRead;

      return Dismissible(
        key: Key('notif_${notif.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3A1A1A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFEF6A6A),
            size: 22,
          ),
        ),
        onDismissed: (_) => widget.controller.deleteNotification(notif.id),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.controller.handleNotificationTap(notif, context);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: isRead
                    ? const Color(0xFF141414)
                    : const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isRead
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFF363636),
                  width: isRead ? 0.8 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + Type Badge ──────────────────────────────────
                  _AvatarWithBadge(
                    avatarUrl: notif.senderAvatar,
                    icon: typeIcon,
                    isRead: isRead,
                  ),
                  const SizedBox(width: 12),

                  // ── Text Content ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Type label + Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  color: isRead
                                      ? AppColors.darkTextSecondary
                                      : AppColors.darkTextPrimary,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notif.timeAgo,
                              style: const TextStyle(
                                color: AppColors.darkTextMuted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Row 2: Notification body (2-3 lines max)
                        Text(
                          notif.body,
                          style: TextStyle(
                            color: isRead
                                ? AppColors.darkTextMuted
                                : AppColors.darkTextSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ── Unread dot ───────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: isRead ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(left: 8, top: 5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD0D0D0),
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
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Avatar with monochrome type badge
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarWithBadge extends StatelessWidget {
  final String? avatarUrl;
  final IconData icon;
  final bool isRead;

  const _AvatarWithBadge({
    required this.avatarUrl,
    required this.icon,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetwork = avatarUrl != null && avatarUrl!.startsWith('http');
    final ImageProvider imgProvider = hasNetwork
        ? NetworkImage(avatarUrl!) as ImageProvider
        : (avatarUrl != null
              ? AssetImage(avatarUrl!) as ImageProvider
              : const AssetImage('assets/images/user_profile.png'));

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage: imgProvider,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isRead
                    ? const Color(0xFF252525)
                    : const Color(0xFF303030),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F0F0F), width: 1.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 10,
                  color: isRead
                      ? AppColors.darkTextMuted
                      : AppColors.darkTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 52,
              color: AppColors.darkTextMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'notification.empty'.tr,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'notification.emptyDesc'.tr,
              style: const TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Loading skeleton
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E1E1E)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFF242424),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 10,
                        width: 100 + (i % 3) * 30.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 9,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════
// Section label (TODAY / EARLIER)
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Press-scale button wrapper
// ═══════════════════════════════════════════════════════════════════════════

class _PressScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressScaleButton({required this.onTap, required this.child});

  @override
  State<_PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<_PressScaleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: widget.child,
      ),
    );
  }
}
