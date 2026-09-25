import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/notification_model.dart';
import '../bindings/notification_binding.dart';
import '../controllers/notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Timer? _relativeTimeTimer;

  NotificationController get _effectiveController {
    if (!Get.isRegistered<NotificationController>()) {
      NotificationBinding().dependencies();
    }
    return Get.find<NotificationController>();
  }

  @override
  void initState() {
    super.initState();
    // Periodically refresh relative timestamps (e.g. 1m -> 2m) every 30s
    // without triggering network re-fetches or full state resets.
    _relativeTimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _relativeTimeTimer?.cancel();
    super.dispose();
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
      appBar: _buildHeader(context, notifController, isDark),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCategoryNav(context, notifController, isDark),
                Expanded(child: _buildBody(context, notifController, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildHeader(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final titleText =
        'notification.title'.tr.isNotEmpty &&
            'notification.title'.tr != 'notification.title'
        ? 'notification.title'.tr
        : 'Notifications';

    final markAllText =
        'notification.markAllRead'.tr.isNotEmpty &&
            'notification.markAllRead'.tr != 'notification.markAllRead'
        ? 'notification.markAllRead'.tr
        : 'Mark all read';

    return AppBar(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: Center(
        child: AppBackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Get.offAllNamed(AppRoutes.home);
            }
          },
        ),
      ),
      leadingWidth: 72,
      titleSpacing: 0,
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
      actions: [
        Obx(() {
          if (notifController.unreadCount == 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: notifController.markAllAsRead,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.done_all_rounded, size: 16, color: textMuted),
              label: Text(
                markAllText,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryNav(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 4, top: 2),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
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

  Widget _buildBody(
    BuildContext context,
    NotificationController notifController,
    bool isDark,
  ) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final refreshBg = isDark
        ? const Color(0xFF1C1C1C)
        : AppColors.lightSurfacePrimary;

    return Obx(() {
      if (notifController.isLoading.value &&
          notifController.notifications.isEmpty) {
        return _LoadingSkeleton(isDark: isDark);
      }

      if (notifController.isError.value &&
          notifController.notifications.isEmpty) {
        return _ErrorState(
          onRetry: notifController.fetchNotifications,
          isDark: isDark,
        );
      }

      final list = notifController.filteredNotifications;

      if (list.isEmpty) {
        return _EmptyState(
          category: notifController.selectedCategory.value,
          isDark: isDark,
        );
      }

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

      final todayLabel =
          'notification.today'.tr.isNotEmpty &&
              'notification.today'.tr != 'notification.today'
          ? 'notification.today'.tr
          : 'TODAY';
      final yesterdayLabel =
          'notification.yesterday'.tr.isNotEmpty &&
              'notification.yesterday'.tr != 'notification.yesterday'
          ? 'notification.yesterday'.tr
          : 'YESTERDAY';
      final earlierLabel =
          'notification.earlier'.tr.isNotEmpty &&
              'notification.earlier'.tr != 'notification.earlier'
          ? 'notification.earlier'.tr
          : 'Earlier';

      return RefreshIndicator(
        onRefresh: notifController.refreshNotifications,
        color: textPrimary,
        backgroundColor: refreshBg,
        displacement: 32,
        child: ListView(
          controller: notifController.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
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
            if (notifController.isLoadingMore.value) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    });
  }
}

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
          : (isRead
                ? AppColors.lightTextSecondary
                : AppColors.lightTextPrimary);

      final contextColor = isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;

      final timeColor = isDark
          ? AppColors.darkTextMuted
          : AppColors.lightTextMuted;

      final dotColor = isDark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF111111);

      final dismissBg = isDark
          ? const Color(0xFF351616)
          : const Color(0xFFFEE2E2);
      final dismissIconColor = isDark
          ? const Color(0xFFEF6A6A)
          : const Color(0xFFDC2626);

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
          margin: const EdgeInsets.only(bottom: 6),
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
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  _LeadingVisual(
                    notif: notif,
                    isRead: isRead,
                    isDark: isDark,
                    cardBg: cardBg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              formatCommunityTimestamp(notif.timestamp),
                              style: TextStyle(
                                color: timeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
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

class _LeadingVisual extends StatelessWidget {
  final NotificationModel notif;
  final bool isRead;
  final bool isDark;
  final Color cardBg;

  const _LeadingVisual({
    required this.notif,
    required this.isRead,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final isSocial =
        notif.category == NotificationCategory.social ||
        notif.type == NotificationType.like ||
        notif.type == NotificationType.comment ||
        notif.type == NotificationType.reply ||
        notif.type == NotificationType.follow ||
        notif.type == NotificationType.friendRequest ||
        notif.type == NotificationType.mention ||
        notif.type == NotificationType.chat ||
        notif.type == NotificationType.group;

    final hasActorInfo =
        (notif.senderAvatar != null && notif.senderAvatar!.isNotEmpty) ||
        (notif.senderName.isNotEmpty &&
            notif.senderName != 'GenLink KH' &&
            notif.senderName != 'Community Member');

    if (isSocial && hasActorInfo) {
      final badgeIcon = _resolveSocialBadgeIcon(notif.type);
      final badgeColor = _resolveSocialBadgeColor(notif.type, isDark);

      return SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppAvatar(
              imageUrl: notif.senderAvatar,
              name: notif.senderName,
              size: 42,
            ),
            if (badgeIcon != null)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF222222) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(badgeIcon, size: 9.5, color: badgeColor),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // SYSTEM / FEATURE CATEGORIES -> Beautiful Category Icon
    final iconData = _resolveCategoryIcon(notif.type, notif.category);
    final iconColor = _resolveCategoryColor(notif.type, notif.category, isDark);
    final iconBg = _resolveCategoryBackground(
      notif.type,
      notif.category,
      isDark,
      isRead,
    );
    final iconBorder = isDark
        ? (isRead ? const Color(0xFF262626) : const Color(0xFF333333))
        : (isRead ? const Color(0xFFE5E5DF) : const Color(0xFFDDDDDA));

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconBg,
        shape: BoxShape.circle,
        border: Border.all(color: iconBorder, width: 0.8),
      ),
      child: Center(child: Icon(iconData, size: 20, color: iconColor)),
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
      case NotificationType.chat:
        return Icons.chat_bubble_rounded;
      default:
        return null;
    }
  }

  static Color _resolveSocialBadgeColor(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.like:
        return const Color(0xFFEF4444); // Red
      case NotificationType.comment:
      case NotificationType.reply:
      case NotificationType.chat:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.friendRequest:
      case NotificationType.follow:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.mention:
        return const Color(0xFF8B5CF6); // Purple
      default:
        return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }
  }

  static IconData _resolveCategoryIcon(
    NotificationType type,
    NotificationCategory category,
  ) {
    switch (type) {
      // Finance
      case NotificationType.savingGoal:
        return Icons.savings_rounded;
      case NotificationType.budgetWarning:
      case NotificationType.budgetExceeded:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.financeUpdate:
        return Icons.receipt_long_rounded;

      // Security
      case NotificationType.security:
        return Icons.shield_rounded;

      // Events
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventRsvp:
      case NotificationType.event:
        return Icons.calendar_month_rounded;

      // Habits & Tasks
      case NotificationType.habitReminder:
      case NotificationType.streakMilestone:
        return Icons.local_fire_department_rounded;
      case NotificationType.taskReminder:
        return Icons.check_circle_rounded;
      case NotificationType.goalReminder:
      case NotificationType.goalMilestone:
        return Icons.flag_rounded;

      // Quiz & Achievement
      case NotificationType.quizResult:
        return Icons.quiz_rounded;
      case NotificationType.challengeReward:
        return Icons.emoji_events_rounded;
      case NotificationType.badgeAwarded:
        return Icons.workspace_premium_rounded;
      case NotificationType.levelUp:
        return Icons.stars_rounded;
      case NotificationType.achievement:
        return Icons.emoji_events_rounded;

      // System / Updates
      case NotificationType.system:
        return Icons.system_update_rounded;

      default:
        break;
    }

    switch (category) {
      case NotificationCategory.finance:
        return Icons.account_balance_wallet_rounded;
      case NotificationCategory.events:
        return Icons.calendar_month_rounded;
      case NotificationCategory.reminders:
        return Icons.notifications_active_rounded;
      case NotificationCategory.updates:
        return Icons.info_outline_rounded;
      case NotificationCategory.social:
        return Icons.people_outline_rounded;
      case NotificationCategory.all:
        return Icons.notifications_none_rounded;
    }
  }

  static Color _resolveCategoryColor(
    NotificationType type,
    NotificationCategory category,
    bool isDark,
  ) {
    if (category == NotificationCategory.finance ||
        type == NotificationType.savingGoal ||
        type == NotificationType.budgetWarning ||
        type == NotificationType.budgetExceeded ||
        type == NotificationType.financeUpdate) {
      return const Color(0xFF10B981); // Emerald
    }
    if (type == NotificationType.security) {
      return const Color(0xFF6366F1); // Indigo
    }
    if (category == NotificationCategory.events ||
        type == NotificationType.eventReminder ||
        type == NotificationType.eventUpdate ||
        type == NotificationType.eventRsvp ||
        type == NotificationType.event) {
      return const Color(0xFFF97316); // Orange
    }
    if (type == NotificationType.habitReminder ||
        type == NotificationType.streakMilestone) {
      return const Color(0xFFEC4899); // Rose/Pink
    }
    if (type == NotificationType.quizResult ||
        type == NotificationType.challengeReward ||
        type == NotificationType.badgeAwarded ||
        type == NotificationType.levelUp ||
        type == NotificationType.achievement) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (category == NotificationCategory.reminders ||
        type == NotificationType.taskReminder ||
        type == NotificationType.goalReminder) {
      return const Color(0xFF0EA5E9); // Sky Blue
    }
    return isDark ? const Color(0xFFA0A0A0) : const Color(0xFF64748B);
  }

  static Color _resolveCategoryBackground(
    NotificationType type,
    NotificationCategory category,
    bool isDark,
    bool isRead,
  ) {
    if (isRead) {
      return isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF2F2EE);
    }
    final color = _resolveCategoryColor(type, category, isDark);
    return color.withValues(alpha: isDark ? 0.16 : 0.10);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4, left: 4),
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

class _EmptyState extends StatelessWidget {
  final String category;
  final bool isDark;

  const _EmptyState({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextSecondary;

    String title;
    String desc;

    if (category == 'All') {
      title =
          'notification.emptyAllTitle'.tr.isNotEmpty &&
              'notification.emptyAllTitle'.tr != 'notification.emptyAllTitle'
          ? 'notification.emptyAllTitle'.tr
          : 'No notifications yet';

      desc =
          'notification.emptyAllDesc'.tr.isNotEmpty &&
              'notification.emptyAllDesc'.tr != 'notification.emptyAllDesc'
          ? 'notification.emptyAllDesc'.tr
          : "You're all caught up!";
    } else {
      final categoryKey = 'notification.category$category';
      final localizedCategory =
          categoryKey.tr.isNotEmpty && categoryKey.tr != categoryKey
          ? categoryKey.tr
          : category;

      title =
          'notification.emptyCategoryTitle'.tr.isNotEmpty &&
              'notification.emptyCategoryTitle'.tr !=
                  'notification.emptyCategoryTitle'
          ? 'notification.emptyCategoryTitle'.trParams({
              'category': localizedCategory,
            })
          : 'No $category notifications';

      desc =
          'notification.emptyCategoryDesc'.tr.isNotEmpty &&
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
              style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final errorTitle =
        'notification.errorTitle'.tr.isNotEmpty &&
            'notification.errorTitle'.tr != 'notification.errorTitle'
        ? 'notification.errorTitle'.tr
        : 'Something went wrong';

    final errorDesc =
        'notification.errorDesc'.tr.isNotEmpty &&
            'notification.errorDesc'.tr != 'notification.errorDesc'
        ? 'notification.errorDesc'.tr
        : 'Unable to load notifications. Please check your connection and try again.';

    final retryText =
        'notification.retry'.tr.isNotEmpty &&
            'notification.retry'.tr != 'notification.retry'
        ? 'notification.retry'.tr
        : 'Retry';

    final btnBg = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111111);
    final btnText = isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              errorTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              errorDesc,
              style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnBg,
                foregroundColor: btnText,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                retryText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final bool isDark;
  const _LoadingSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF161616) : const Color(0xFFF2F2EF);
    final cardBorder = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE8E8E4);
    final placeholder1 = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFE0E0DC);
    final placeholder2 = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFE8E8E4);

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
