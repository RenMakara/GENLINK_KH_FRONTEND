import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/notification_model.dart';
import '../bindings/notification_binding.dart';
import '../controllers/notification_controller.dart';

/// GenLink KH — Clean Mobile-First Notification Screen.
///
/// Hierarchy:
///  - Header: [Back] Notifications [Unread Count]
///  - Filter: Right-aligned compact [Filter] button (no "All notifications" text)
///  - Content: Notification list with date grouping (TODAY / EARLIER)
class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  NotificationController get _effectiveController {
    if (!Get.isRegistered<NotificationController>()) {
      NotificationBinding().dependencies();
    }
    return Get.find<NotificationController>();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context, notifController, isDark),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterRow(context, notifController, isDark),
                Expanded(child: _buildBody(context, notifController, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar (Header: Back + Title + Unread Count Badge) ─────────────────────

  AppBar _buildAppBar(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: const Center(
        child: AppBackButton(),
      ),
      titleSpacing: 4,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'notification.title'.tr,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // Unread count badge — hidden when zero
          Obx(() {
            final count = notifController.unreadCount;
            if (count == 0) return const SizedBox.shrink();
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFE8E8E4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3D3D3D)
                      : const Color(0xFFD6D6D0),
                  width: 0.8,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            );
          }),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: borderSubtle),
      ),
    );
  }

  // ── Secondary: Right-Aligned Compact Filter Button ────────────────────────

  Widget _buildFilterRow(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final filterBg =
        isDark ? const Color(0xFF1C1C1C) : AppColors.lightSurfacePrimary;
    final filterBorder =
        isDark ? const Color(0xFF2C2C2C) : AppColors.lightBorderSubtle;

    final filterLabel = 'notification.filter'.tr.isNotEmpty &&
            'notification.filter'.tr != 'notification.filter'
        ? 'notification.filter'.tr
        : ('community.filter'.tr.isNotEmpty &&
                'community.filter'.tr != 'community.filter'
            ? 'community.filter'.tr
            : 'Filter');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _PressScaleButton(
            onTap: () => _showFilterSheet(context, notifController, isDark),
            child: Obx(() {
              final selectedTab = notifController.selectedTab.value;
              final isFiltered = selectedTab != 'All';
              final activeTabLabel = _tabKeyMap[selectedTab]?.tr ?? selectedTab;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isFiltered
                      ? (isDark
                          ? const Color(0xFF282828)
                          : const Color(0xFFEAEAEA))
                      : filterBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFiltered
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : filterBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: isFiltered ? textPrimary : textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFiltered ? activeTabLabel : filterLabel,
                      style: TextStyle(
                        color: isFiltered ? textPrimary : textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isFiltered ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Filter Bottom Sheet (All / Mentions / Activity / System) ──────────────

  void _showFilterSheet(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    final sheetBg =
        isDark ? const Color(0xFF181818) : AppColors.lightSurfacePrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final itemHoverBg =
        isDark ? const Color(0xFF222222) : const Color(0xFFF2F2EF);

    final filterItems = [
      {
        'id': 'All',
        'label': 'notification.tabAll'.tr,
        'desc': 'notification.allDesc'.tr.isNotEmpty &&
                'notification.allDesc'.tr != 'notification.allDesc'
            ? 'notification.allDesc'.tr
            : 'All your notifications',
        'icon': Icons.all_inbox_rounded,
      },
      {
        'id': 'Mentions',
        'label': 'notification.tabMentions'.tr,
        'desc': 'notification.mentionsDesc'.tr.isNotEmpty &&
                'notification.mentionsDesc'.tr != 'notification.mentionsDesc'
            ? 'notification.mentionsDesc'.tr
            : 'Mentions & replies',
        'icon': Icons.alternate_email_rounded,
      },
      {
        'id': 'Activity',
        'label': 'notification.tabActivity'.tr,
        'desc': 'notification.activityDesc'.tr.isNotEmpty &&
                'notification.activityDesc'.tr != 'notification.activityDesc'
            ? 'notification.activityDesc'.tr
            : 'Likes, comments & follows',
        'icon': Icons.favorite_border_rounded,
      },
      {
        'id': 'System',
        'label': 'notification.tabSystem'.tr,
        'desc': 'notification.systemDesc'.tr.isNotEmpty &&
                'notification.systemDesc'.tr != 'notification.systemDesc'
            ? 'notification.systemDesc'.tr
            : 'System updates & events',
        'icon': Icons.info_outline_rounded,
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: borderSubtle, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3D3D3D)
                          : const Color(0xFFD0D0CA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'notification.filterTitle'.tr.isNotEmpty &&
                                'notification.filterTitle'.tr !=
                                    'notification.filterTitle'
                            ? 'notification.filterTitle'.tr
                            : 'Filter notifications',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Filter options list
                ...filterItems.map((item) {
                  final id = item['id'] as String;
                  final label = item['label'] as String;
                  final desc = item['desc'] as String;
                  final icon = item['icon'] as IconData;

                  return Obx(() {
                    final isSelected =
                        notifController.selectedTab.value == id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: isSelected ? itemHoverBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            notifController.selectTab(id);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? borderSubtle
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                            ? const Color(0xFF333333)
                                            : const Color(0xFFE4E4DE))
                                        : (isDark
                                            ? const Color(0xFF222222)
                                            : const Color(0xFFEDEDEA)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? textPrimary
                                        : textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? textPrimary
                                              : textSecondary,
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: textPrimary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Body: Loading / Empty / Grouped Notification List ─────────────────────

  Widget _buildBody(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final refreshBg =
        isDark ? const Color(0xFF1C1C1C) : AppColors.lightSurfacePrimary;

    return Obx(() {
      // Loading State
      if (notifController.isLoading.value) {
        return _LoadingSkeleton(isDark: isDark);
      }

      final list = notifController.filteredNotifications;

      // Empty State
      if (list.isEmpty) {
        return _EmptyState(
          tab: notifController.selectedTab.value,
          isDark: isDark,
        );
      }

      // Date grouping (Today vs Earlier)
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

      final hasToday = todayItems.isNotEmpty;
      final hasEarlier = earlierItems.isNotEmpty;

      return RefreshIndicator(
        onRefresh: notifController.fetchNotifications,
        color: textPrimary,
        backgroundColor: refreshBg,
        displacement: 40,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(bottom: 24, top: 4),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (hasToday && hasEarlier) ...[
              _SectionLabel(label: 'notification.today'.tr, isDark: isDark),
              ...todayItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 6),
              _SectionLabel(label: 'notification.earlier'.tr, isDark: isDark),
              ...earlierItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                  isDark: isDark,
                ),
              ),
            ] else if (hasToday) ...[
              _SectionLabel(label: 'notification.today'.tr, isDark: isDark),
              ...todayItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                  isDark: isDark,
                ),
              ),
            ] else if (hasEarlier) ...[
              _SectionLabel(label: 'notification.earlier'.tr, isDark: isDark),
              ...earlierItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                  isDark: isDark,
                ),
              ),
            ] else ...[
              ...list.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  typeKeyMap: _typeKeyMap,
                  typeIconMap: _typeIconMap,
                  isDark: isDark,
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
  final bool isDark;

  const _NotificationCard({
    required this.notif,
    required this.controller,
    required this.typeKeyMap,
    required this.typeIconMap,
    required this.isDark,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;
    final isDark = widget.isDark;

    final typeLabel =
        (widget.typeKeyMap[notif.type] ?? 'notification.typeSystem').tr;
    final typeIcon =
        widget.typeIconMap[notif.type] ?? Icons.notifications_rounded;

    return Obx(() {
      // Re-render on any notifications list reactive change
      widget.controller.notifications.length;
      final isRead = notif.isRead;

      final cardBg = isDark
          ? (isRead ? const Color(0xFF141414) : const Color(0xFF1C1C1C))
          : (isRead ? const Color(0xFFF7F7F5) : const Color(0xFFFFFFFF));

      final cardBorder = isDark
          ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF303030))
          : (isRead ? const Color(0xFFEDEDEA) : const Color(0xFFE0E0DC));

      final titleColor = isDark
          ? (isRead ? AppColors.darkTextSecondary : AppColors.darkTextPrimary)
          : (isRead ? AppColors.lightTextSecondary : AppColors.lightTextPrimary);

      final bodyColor = isDark
          ? (isRead ? AppColors.darkTextMuted : AppColors.darkTextSecondary)
          : (isRead ? AppColors.lightTextMuted : AppColors.lightTextSecondary);

      final timeColor =
          isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
      final dotColor =
          isDark ? const Color(0xFFE0E0E0) : const Color(0xFF111111);

      final dismissBg =
          isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFEE2E2);
      final dismissIconColor =
          isDark ? const Color(0xFFEF6A6A) : const Color(0xFFDC2626);

      return Dismissible(
        key: Key('notif_${notif.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: dismissBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: dismissIconColor,
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
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cardBorder,
                  width: isRead ? 0.8 : 1.0,
                ),
                boxShadow: (!isRead && !isDark)
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + Type Badge ──────────────────────────────────
                  _AvatarWithBadge(
                    avatarUrl: notif.senderAvatar,
                    icon: typeIcon,
                    isRead: isRead,
                    isDark: isDark,
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
                                  color: titleColor,
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
                              style: TextStyle(
                                color: timeColor,
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
                            color: bodyColor,
                            fontSize: 13,
                            height: 1.45,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
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
                      decoration: BoxDecoration(
                        color: dotColor,
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
// Avatar with notification type badge
// ═══════════════════════════════════════════════════════════════════════════

class _AvatarWithBadge extends StatelessWidget {
  final String? avatarUrl;
  final IconData icon;
  final bool isRead;
  final bool isDark;

  const _AvatarWithBadge({
    required this.avatarUrl,
    required this.icon,
    required this.isRead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetwork = avatarUrl != null && avatarUrl!.startsWith('http');
    final ImageProvider imgProvider = hasNetwork
        ? NetworkImage(avatarUrl!) as ImageProvider
        : (avatarUrl != null && avatarUrl!.isNotEmpty
            ? AssetImage(avatarUrl!) as ImageProvider
            : const AssetImage('assets/images/user_profile.png'));

    final avatarBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4E4DE);
    final badgeBg = isDark
        ? (isRead ? const Color(0xFF252525) : const Color(0xFF303030))
        : (isRead ? const Color(0xFFEAEAEA) : const Color(0xFFFFFFFF));
    final badgeBorder = isDark
        ? (isRead ? const Color(0xFF141414) : const Color(0xFF1C1C1C))
        : (isRead ? const Color(0xFFF7F7F5) : const Color(0xFFFFFFFF));
    final iconColor = isDark
        ? (isRead ? AppColors.darkTextMuted : AppColors.darkTextSecondary)
        : (isRead ? AppColors.lightTextMuted : AppColors.lightTextSecondary);

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: avatarBg,
            backgroundImage: imgProvider,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: badgeBorder, width: 1.5),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 10,
                  color: iconColor,
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
// Empty State
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String tab;
  final bool isDark;

  const _EmptyState({required this.tab, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary;

    String titleKey;
    String descKey;

    switch (tab) {
      case 'Mentions':
        titleKey = 'notification.emptyMentions';
        descKey = 'notification.emptyMentionsDesc';
        break;
      case 'Activity':
        titleKey = 'notification.emptyActivity';
        descKey = 'notification.emptyActivityDesc';
        break;
      case 'System':
        titleKey = 'notification.emptySystem';
        descKey = 'notification.emptySystemDesc';
        break;
      case 'All':
      default:
        titleKey = 'notification.empty';
        descKey = 'notification.emptyDesc';
        break;
    }

    final title = titleKey.tr.isNotEmpty && titleKey.tr != titleKey
        ? titleKey.tr
        : 'No notifications';
    final desc = descKey.tr.isNotEmpty && descKey.tr != descKey
        ? descKey.tr
        : 'You\'re all caught up. Reactions, comments and updates will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 52,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                color: textMuted,
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
// Loading Skeleton
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingSkeleton extends StatelessWidget {
  final bool isDark;
  const _LoadingSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF161616) : const Color(0xFFF2F2EF);
    final cardBorder =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E4);
    final placeholder1 =
        isDark ? const Color(0xFF242424) : const Color(0xFFE0E0DC);
    final placeholder2 =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E4);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: placeholder1,
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
                          color: placeholder1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 9,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: placeholder2,
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
// Section Label (TODAY / EARLIER)
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 2),
      child: Text(
        label,
        style: TextStyle(
          color: textMuted,
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
