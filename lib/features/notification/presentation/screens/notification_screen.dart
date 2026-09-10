import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/models/notification_model.dart';
import '../bindings/notification_binding.dart';
import '../controllers/notification_controller.dart';

/// GenLink KH — Unified Mobile-First Notification Center.
///
/// Principles:
///  - One unified activity stream for the entire application.
///  - Simple clean header: "Notifications" (NO back button, NO settings button, NO all/unread tabs).
///  - Telegram-inspired compact horizontal category navigation (All, Social, Finance, Events, Reminders, Updates).
///  - Grouped by time: TODAY, YESTERDAY, Earlier.
///  - Unified visual system: avatar or context icon, natural language title, short context, time, subtle unread indicator.
///  - Tapping navigates to the relevant feature (posts, friend requests, budget, events, habits, tasks, quiz).
///  - Light Mode & Dark Mode, English & Khmer support without text overflow.
class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  NotificationController get _effectiveController {
    if (!Get.isRegistered<NotificationController>()) {
      NotificationBinding().dependencies();
    }
    return Get.find<NotificationController>();
  }

  static const List<Map<String, String>> _categories = [
    {'name': 'All', 'key': 'notification.categoryAll'},
    {'name': 'Social', 'key': 'notification.categorySocial'},
    {'name': 'Finance', 'key': 'notification.categoryFinance'},
    {'name': 'Events', 'key': 'notification.categoryEvents'},
    {'name': 'Reminders', 'key': 'notification.categoryReminders'},
    {'name': 'Updates', 'key': 'notification.categoryUpdates'},
  ];

  @override
  Widget build(BuildContext context) {
    final notifController = _effectiveController;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildHeader(context, isDark),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact Telegram-style category navigation bar
                _buildCategoryNav(context, notifController, isDark),
                // Grouped vertical notification activity feed
                Expanded(child: _buildBody(context, notifController, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. HEADER (Simple Title: Notifications — NO back button, NO settings, NO unread tabs) ──

  AppBar _buildHeader(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final titleText = 'notification.title'.tr.isNotEmpty &&
            'notification.title'.tr != 'notification.title'
        ? 'notification.title'.tr
        : 'Notifications';

    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      centerTitle: false,
      title: Text(
        titleText,
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // ── 2. COMPACT TELEGRAM-STYLE CATEGORY NAVIGATION ────────────────────────

  Widget _buildCategoryNav(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8, top: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final name = item['name']!;
          final key = item['key']!;
          final label = key.tr.isNotEmpty && key.tr != key ? key.tr : name;

          return Obx(() {
            final isSelected = notifController.selectedCategory.value == name;

            // Telegram-style compact pills
            final activeBg = isDark
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF111111);
            final activeText = isDark
                ? const Color(0xFF111111)
                : const Color(0xFFFFFFFF);

            final inactiveBg = isDark
                ? const Color(0xFF1C1C1C)
                : const Color(0xFFF0F0ED);
            final inactiveText = isDark
                ? const Color(0xFFA0A0A0)
                : const Color(0xFF666666);
            final inactiveBorder = isDark
                ? const Color(0xFF2B2B2B)
                : const Color(0xFFE2E2DE);

            return GestureDetector(
              onTap: () => notifController.selectCategory(name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : inactiveBorder,
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeText : inactiveText,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // ── 3. BODY (Grouped by TODAY, YESTERDAY, Earlier) ───────────────────────

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
      if (notifController.isLoading.value) {
        return _LoadingSkeleton(isDark: isDark);
      }

      final list = notifController.filteredNotifications;

      if (list.isEmpty) {
        return _EmptyState(
          category: notifController.selectedCategory.value,
          isDark: isDark,
        );
      }

      // Grouping: TODAY, YESTERDAY, Earlier
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

      final todayItems = <NotificationModel>[];
      final yesterdayItems = <NotificationModel>[];
      final earlierItems = <NotificationModel>[];

      for (final item in list) {
        final itemDate = DateTime(
          item.timestamp.year,
          item.timestamp.month,
          item.timestamp.day,
        );
        if (itemDate.isAtSameMomentAs(todayStart) ||
            itemDate.isAfter(todayStart)) {
          todayItems.add(item);
        } else if (itemDate.isAtSameMomentAs(yesterdayStart)) {
          yesterdayItems.add(item);
        } else {
          earlierItems.add(item);
        }
      }

      final todayLabel = 'notification.today'.tr.isNotEmpty &&
              'notification.today'.tr != 'notification.today'
          ? 'notification.today'.tr
          : 'TODAY';
      final yesterdayLabel = 'notification.yesterday'.tr.isNotEmpty &&
              'notification.yesterday'.tr != 'notification.yesterday'
          ? 'notification.yesterday'.tr
          : 'YESTERDAY';
      final earlierLabel = 'notification.earlier'.tr.isNotEmpty &&
              'notification.earlier'.tr != 'notification.earlier'
          ? 'notification.earlier'.tr
          : 'Earlier';

      return RefreshIndicator(
        onRefresh: notifController.fetchNotifications,
        color: textPrimary,
        backgroundColor: refreshBg,
        displacement: 32,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            if (todayItems.isNotEmpty) ...[
              _SectionLabel(label: todayLabel, isDark: isDark),
              ...todayItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  isDark: isDark,
                ),
              ),
            ],
            if (yesterdayItems.isNotEmpty) ...[
              const SizedBox(height: 6),
              _SectionLabel(label: yesterdayLabel, isDark: isDark),
              ...yesterdayItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
                  isDark: isDark,
                ),
              ),
            ],
            if (earlierItems.isNotEmpty) ...[
              const SizedBox(height: 6),
              _SectionLabel(label: earlierLabel, isDark: isDark),
              ...earlierItems.map(
                (n) => _NotificationCard(
                  notif: n,
                  controller: notifController,
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
// Unified Notification Card (Consistent across all features)
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationCard extends StatefulWidget {
  final NotificationModel notif;
  final NotificationController controller;
  final bool isDark;

  const _NotificationCard({
    required this.notif,
    required this.controller,
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

    return Obx(() {
      // Observe reactive collection changes
      widget.controller.notifications.length;
      final isRead = notif.isRead;

      final cardBg = isDark
          ? (isRead ? const Color(0xFF141414) : const Color(0xFF1B1B1B))
          : (isRead ? const Color(0xFFF7F7F5) : const Color(0xFFFFFFFF));

      final cardBorder = isDark
          ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF2C2C2C))
          : (isRead ? const Color(0xFFEDEDEA) : const Color(0xFFE2E2DE));

      final titleColor = isDark
          ? (isRead ? AppColors.darkTextSecondary : AppColors.darkTextPrimary)
          : (isRead ? AppColors.lightTextSecondary : AppColors.lightTextPrimary);

      final contextColor =
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

      final timeColor =
          isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

      final dotColor =
          isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111111);

      final dismissBg =
          isDark ? const Color(0xFF351616) : const Color(0xFFFEE2E2);
      final dismissIconColor =
          isDark ? const Color(0xFFEF6A6A) : const Color(0xFFDC2626);

      // Context text: either explicit contextText, or body if different from title
      final shortContext = notif.contextText?.isNotEmpty == true
          ? notif.contextText!
          : (notif.body.isNotEmpty && notif.body != notif.title
              ? notif.body
              : null);

      return Dismissible(
        key: Key('notif_${notif.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: dismissBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: dismissIconColor,
            size: 20,
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
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cardBorder,
                  width: isRead ? 0.7 : 0.9,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Leading Avatar or Semantic Icon ─────────────────────
                  _LeadingVisual(
                    notif: notif,
                    isRead: isRead,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),

                  // ── Title + Short Context + Time ─────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Title and Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  fontSize: 13.5,
                                  letterSpacing: -0.2,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notif.timeAgo,
                              style: TextStyle(
                                color: timeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),

                        // Short context line (if present)
                        if (shortContext != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            shortContext,
                            style: TextStyle(
                              color: contextColor,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Subtle Unread Dot Indicator ──────────────────────────
                  if (!isRead)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 8, top: 5),
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
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
// Leading Visual: Avatar or Clean Semantic Context Icon
// ═══════════════════════════════════════════════════════════════════════════

class _LeadingVisual extends StatelessWidget {
  final NotificationModel notif;
  final bool isRead;
  final bool isDark;

  const _LeadingVisual({
    required this.notif,
    required this.isRead,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = notif.senderAvatar != null &&
        notif.senderAvatar!.isNotEmpty &&
        (notif.category == NotificationCategory.social ||
            notif.type == NotificationType.friendRequest ||
            notif.type == NotificationType.reply ||
            notif.type == NotificationType.comment ||
            notif.type == NotificationType.like);

    if (hasAvatar) {
      final avatarUrl = notif.senderAvatar!;
      final hasNetwork = avatarUrl.startsWith('http');
      final ImageProvider imgProvider = hasNetwork
          ? NetworkImage(avatarUrl) as ImageProvider
          : AssetImage(avatarUrl) as ImageProvider;

      final badgeIcon = _resolveSocialBadgeIcon(notif.type);
      final badgeBg = isDark
          ? (isRead ? const Color(0xFF222222) : const Color(0xFF2D2D2D))
          : (isRead ? const Color(0xFFE8E8E4) : const Color(0xFFFFFFFF));
      final badgeBorder = isDark
          ? const Color(0xFF141414)
          : const Color(0xFFFFFFFF);

      return SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: isDark
                  ? const Color(0xFF282828)
                  : const Color(0xFFE5E5DF),
              backgroundImage: imgProvider,
            ),
            if (badgeIcon != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeBorder, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      badgeIcon,
                      size: 9.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Feature Icon with subtle, premium container
    final iconData = _resolveCategoryIcon(notif.type, notif.category);
    final iconBg = isDark
        ? (isRead ? const Color(0xFF1E1E1E) : const Color(0xFF262626))
        : (isRead ? const Color(0xFFF2F2EE) : const Color(0xFFFFFFFF));
    final iconBorder = isDark
        ? (isRead ? const Color(0xFF262626) : const Color(0xFF333333))
        : (isRead ? const Color(0xFFE5E5DF) : const Color(0xFFDDDDDA));
    final iconColor = isDark
        ? (isRead ? AppColors.darkTextSecondary : AppColors.darkTextPrimary)
        : (isRead ? AppColors.lightTextSecondary : AppColors.lightTextPrimary);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconBg,
        shape: BoxShape.circle,
        border: Border.all(color: iconBorder, width: 0.9),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 19,
          color: iconColor,
        ),
      ),
    );
  }

  static IconData? _resolveSocialBadgeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.chat_bubble_rounded;
      case NotificationType.reply:
        return Icons.reply_rounded;
      case NotificationType.friendRequest:
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.mention:
        return Icons.alternate_email_rounded;
      default:
        return null;
    }
  }

  static IconData _resolveCategoryIcon(
    NotificationType type,
    NotificationCategory category,
  ) {
    switch (category) {
      case NotificationCategory.finance:
        if (type == NotificationType.savingGoal) {
          return Icons.savings_outlined;
        }
        return Icons.account_balance_wallet_outlined;

      case NotificationCategory.events:
        return Icons.calendar_today_rounded;

      case NotificationCategory.reminders:
        if (type == NotificationType.habitReminder ||
            type == NotificationType.streakMilestone) {
          return Icons.local_fire_department_rounded;
        }
        if (type == NotificationType.taskReminder) {
          return Icons.check_circle_outline_rounded;
        }
        return Icons.flag_outlined;

      case NotificationCategory.updates:
        if (type == NotificationType.quizResult ||
            type == NotificationType.achievement) {
          return Icons.emoji_events_outlined;
        }
        return Icons.notifications_none_rounded;

      case NotificationCategory.social:
        return Icons.people_outline_rounded;

      case NotificationCategory.all:
        return Icons.notifications_none_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section Label (TODAY / YESTERDAY / Earlier)
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
      padding: const EdgeInsets.only(bottom: 8, top: 6, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty State (Contextual for All & specific categories)
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String category;
  final bool isDark;

  const _EmptyState({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary;

    String title;
    String desc;

    if (category == 'All') {
      title = 'notification.emptyAllTitle'.tr.isNotEmpty &&
              'notification.emptyAllTitle'.tr != 'notification.emptyAllTitle'
          ? 'notification.emptyAllTitle'.tr
          : 'No notifications yet';

      desc = 'notification.emptyAllDesc'.tr.isNotEmpty &&
              'notification.emptyAllDesc'.tr != 'notification.emptyAllDesc'
          ? 'notification.emptyAllDesc'.tr
          : "You're all caught up!";
    } else {
      final categoryKey = 'notification.category$category';
      final localizedCategory =
          categoryKey.tr.isNotEmpty && categoryKey.tr != categoryKey
              ? categoryKey.tr
              : category;

      title = 'notification.emptyCategoryTitle'.tr.isNotEmpty &&
              'notification.emptyCategoryTitle'.tr !=
                  'notification.emptyCategoryTitle'
          ? 'notification.emptyCategoryTitle'
              .trParams({'category': localizedCategory})
          : 'No $category notifications';

      desc = 'notification.emptyCategoryDesc'.tr.isNotEmpty &&
              'notification.emptyCategoryDesc'.tr !=
                  'notification.emptyCategoryDesc'
          ? 'notification.emptyCategoryDesc'.tr
          : "You're all caught up.";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: textMuted.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 5),
            Text(
              desc,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
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
                        width: 120 + (i % 3) * 25.0,
                        decoration: BoxDecoration(
                          color: placeholder1,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        height: 9,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: placeholder2,
                          borderRadius: BorderRadius.circular(5),
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

