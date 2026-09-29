import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../notification/domain/models/notification_model.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../../levelup/widget/grow_section_widget.dart';
import '../../domain/entities/productivity_entities.dart' hide ProductivityPage;
import '../controllers/productivity_controller.dart';
import '../focus_feature/focus_home_screen.dart';
import '../goals_plan/goal_plan_create.dart';
import '../screens/create_habit_screen.dart';
import '../screens/create_task_screen.dart';
import 'productivity_illustrations.dart';

/// 1. Modern iOS-Style Productivity Header with Title, Subtitle, Streak Pill & Notification Badge
class ProductivityHeader extends StatelessWidget {
  const ProductivityHeader({
    super.key,
    required this.streakCount,
    required this.onNotifications,
    this.onBack,
    this.showBackButton = true,
  });

  final int? streakCount;
  final VoidCallback onNotifications;
  final VoidCallback? onBack;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final streak = streakCount ?? 0;
    final streakText = streak == 1
        ? 'productivity.dayCount'.trParams({'count': '$streak'})
        : 'productivity.daysCount'.trParams({'count': '$streak'});

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBackButton) ...[
          AppBackButton(
            onPressed:
                onBack ??
                () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.back();
                  }
                },
          ),
          const SizedBox(width: 14),
        ],

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'productivity.title'.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'productivity.subtitle'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Streak Pill Badge
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C1A0F) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF9A3412).withValues(alpha: 0.45)
                  : const Color(0xFFFFEDD5),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFF97316,
                ).withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: Color(0xFFF97316),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    streakText,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFDBA74)
                          : const Color(0xFFC2410C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'productivity.streakStat'.tr,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFED7AA)
                          : const Color(0xFFEA580C),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Notification Bell with Unread Indicator
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotifications,
              splashRadius: 22,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: textPrimary,
                size: 24,
              ),
            ),
            _buildNotificationBadge(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationBadge(bool isDark) {
    if (!Get.isRegistered<NotificationController>()) {
      return const SizedBox.shrink();
    }

    final notifController = Get.find<NotificationController>();
    return Obx(() {
      final serverUnread = notifController.totalUnreadCount.value;
      final localUnread = notifController.notifications
          .where((n) => !n.isRead && n.type != NotificationType.chat)
          .length;
      final unreadChatCount = notifController.notifications
          .where((n) => !n.isRead && n.type == NotificationType.chat)
          .length;
      final adjustedServerUnread = serverUnread > unreadChatCount
          ? serverUnread - unreadChatCount
          : localUnread;
      final unread = adjustedServerUnread > localUnread
          ? adjustedServerUnread
          : localUnread;

      if (unread <= 0) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 10,
        right: 10,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEF4444),
            border: Border.all(
              color: isDark ? AppColors.darkBgPrimary : Colors.white,
              width: 1.5,
            ),
          ),
        ),
      );
    });
  }
}

/// 2. Gamified Today Summary Card with Blue → Indigo → Purple gradient,
/// soft 3D Target Dartboard, 3 circular stat badges, and daily progress bar.
class ProductivitySummaryCard extends StatelessWidget {
  const ProductivitySummaryCard({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.focusMinutes,
    required this.habitStreak,
  });

  final int completedTasks;
  final int totalTasks;
  final int focusMinutes;
  final int? habitStreak;

  @override
  Widget build(BuildContext context) {
    final double percent = totalTasks == 0
        ? 0.0
        : (completedTasks / totalTasks).clamp(0.0, 1.0);
    final streak = habitStreak ?? 0;
    final streakFormatted = streak == 1
        ? 'productivity.dayCount'.trParams({'count': '$streak'})
        : 'productivity.daysCount'.trParams({'count': '$streak'});

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Top-left ambient radial highlight
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -0.8),
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Background sparkle 1
            const Positioned(
              top: 18,
              right: 88,
              child: Opacity(
                opacity: 0.35,
                child: Text(
                  '✦',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            // Background sparkle 2
            const Positioned(
              top: 48,
              right: 120,
              child: Opacity(
                opacity: 0.20,
                child: Text(
                  '✦',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title + Dartboard Illustration
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'productivity.today'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'productivity.keepBuildingMomentum'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Soft3DTargetDartboardWidget(size: 74),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Middle Row: 3 Circular Stat Badges
                  Row(
                    children: [
                      // Tasks Stat
                      Expanded(
                        child: _StatBadge(
                          iconBgColor: const Color(0xFF22C55E),
                          icon: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          value: '$completedTasks/$totalTasks',
                          label: 'productivity.tasksStat'.tr,
                        ),
                      ),

                      // Focus Stat
                      Expanded(
                        child: _StatBadge(
                          iconBgColor: const Color(0xFFA855F7),
                          icon: const Icon(
                            Icons.timer_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          value: _formatMinutes(focusMinutes),
                          label: 'productivity.focus'.tr,
                        ),
                      ),

                      // Streak Stat
                      Expanded(
                        child: _StatBadge(
                          iconBgColor: const Color(0xFFF97316),
                          icon: const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          value: streakFormatted,
                          label: 'productivity.streakStat'.tr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'productivity.dailyProgress'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(percent * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.iconBgColor,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Color iconBgColor;
  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBgColor,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 3. Modern Activity Card for Today's Plan with interactive task checkmarks
class ProductivityTodayPlan extends StatelessWidget {
  const ProductivityTodayPlan({
    super.key,
    required this.controller,
    required this.onSeeAll,
  });

  final ProductivityController controller;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final visibleTasks = controller.tasks.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'productivity.todayplan'.tr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'productivity.seeall'.tr,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tasks Container
        if (visibleTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Icon(Icons.checklist_rounded, color: textMuted, size: 28),
                const SizedBox(height: 8),
                Text(
                  'productivity.noTasksYet'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < visibleTasks.length; i++) ...[
                  InkWell(
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(18) : Radius.zero,
                      bottom: i == visibleTasks.length - 1
                          ? const Radius.circular(18)
                          : Radius.zero,
                    ),
                    onTap: () => controller.toggleTask(
                      visibleTasks[i].taskId,
                      completed: !visibleTasks[i].completed,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Status check icon
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: visibleTasks[i].completed
                                  ? const Color(0xFF22C55E)
                                  : Colors.transparent,
                              border: Border.all(
                                color: visibleTasks[i].completed
                                    ? const Color(0xFF22C55E)
                                    : (isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFFCBD5E1)),
                                width: 1.8,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: visibleTasks[i].completed
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Task Title & Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visibleTasks[i].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: visibleTasks[i].completed
                                        ? textMuted
                                        : textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: visibleTasks[i].completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _taskSubtitle(visibleTasks[i]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trailing chevron
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < visibleTasks.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: border,
                      indent: 50,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// 4. Quick Actions (2x2 Grid) with soft 3D icons, soft tinted cards, subtitles,
/// and small circular arrow buttons matching the Grow visual language.
class ProductivityQuickActions extends StatelessWidget {
  const ProductivityQuickActions({super.key, required this.controller});

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'productivity.quickActions'.tr,
          style: TextStyle(
            color: textPrimary,
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        // 2x2 Grid
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'productivity.addTask'.tr,
                subtitle: 'productivity.addTaskSubtitle'.tr,
                icon: const Soft3DTasksIcon(size: 38),
                bgColor: isDark
                    ? const Color(0xFF132338)
                    : const Color(0xFFEFF6FF),
                borderColor: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.45)
                    : const Color(0xFFDBEAFE),
                titleColor: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E3A8A),
                onTap: () async {
                  await Get.to(() => const CreateTaskScreen());
                  await controller.reload();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                title: 'productivity.addHabit'.tr,
                subtitle: 'productivity.addHabitSubtitle'.tr,
                icon: const Soft3DHabitsIcon(size: 38),
                bgColor: isDark
                    ? const Color(0xFF2C1E14)
                    : const Color(0xFFFFF7ED),
                borderColor: isDark
                    ? const Color(0xFF9A3412).withValues(alpha: 0.45)
                    : const Color(0xFFFFEDD5),
                titleColor: isDark
                    ? const Color(0xFFFDBA74)
                    : const Color(0xFF9A3412),
                onTap: () async {
                  await Get.to(() => const CreateHabitScreen());
                  await controller.reload();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'productivity.focus'.tr,
                subtitle: 'productivity.focusSubtitle'.tr,
                icon: const Soft3DFocusIcon(size: 38),
                bgColor: isDark
                    ? const Color(0xFF241535)
                    : const Color(0xFFFAF5FF),
                borderColor: isDark
                    ? const Color(0xFF7E22CE).withValues(alpha: 0.45)
                    : const Color(0xFFF3E8FF),
                titleColor: isDark
                    ? const Color(0xFFD8B4FE)
                    : const Color(0xFF581C87),
                onTap: () async {
                  await Get.to(() => const FocusPage());
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionCard(
                title: 'productivity.newGoal'.tr,
                subtitle: 'productivity.newGoalSubtitle'.tr,
                icon: const Soft3DGoalsIcon(size: 38),
                bgColor: isDark
                    ? const Color(0xFF12281D)
                    : const Color(0xFFF0FDF4),
                borderColor: isDark
                    ? const Color(0xFF16A34A).withValues(alpha: 0.45)
                    : const Color(0xFFDCFCE7),
                titleColor: isDark
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFF065F46),
                onTap: () async {
                  await Get.to(() => const CreateGoalScreen());
                  await controller.reload();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.titleColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final Color bgColor;
  final Color borderColor;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              widget.icon,
              const SizedBox(width: 8),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.titleColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Circular arrow button
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.85),
                  border: Border.all(color: widget.borderColor, width: 0.8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: widget.titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Goal Progress Section: Displays polished empty state with Soft3D mound & Create Goal pill,
/// or progress cards when goals exist.
class ProductivityGoalProgressSection extends StatelessWidget {
  const ProductivityGoalProgressSection({
    super.key,
    required this.goals,
    required this.onSeeAll,
  });

  final List<ProductivityGoalProgress> goals;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'productivity.goalProgress'.tr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'productivity.seeall'.tr,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (goals.isEmpty)
          // Polished Empty State Card with Soft 3D Mound & "Create Goal" Action Pill
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Soft 3D Mound Illustration
                const Soft3DGoalMoundWidget(width: 66, height: 50),
                const SizedBox(width: 12),

                // Text Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'productivity.noGoalsTitle'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'productivity.noGoalsDesc'.tr,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // "Create Goal" Action Pill Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.to(() => const CreateGoalScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'productivity.createGoal'.tr,
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Active Goal Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < goals.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goals[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${goals[i].progressPercentage.round()}%',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (goals[i].progressPercentage / 100).clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 6,
                      color: const Color(0xFF10B981),
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  if (i < goals.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// 6. Premium Motivation / Daily Tip Card with Sparkle, inspirational copy, and Mountain Peak
class ProductivityMotivationSection extends StatelessWidget {
  const ProductivityMotivationSection({
    super.key,
    required this.motivation,
    this.onTap,
  });

  final ProductivityMotivationCard motivation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E162B) : const Color(0xFFF7F5FE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xFF6B21A8).withValues(alpha: 0.45)
                : const Color(0xFFEDE9FE),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF7C3AED,
              ).withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Soft 3D Sparkle
            const Soft3DSparkleWidget(size: 22),
            const SizedBox(width: 10),

            // Title & Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    motivation.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    motivation.content,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Soft 3D Mountain Peak
            const Soft3DMountainPeakWidget(width: 68, height: 48),
          ],
        ),
      ),
    );
  }
}

// Helpers
String _formatMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

String _taskSubtitle(ProductivityTask task) {
  if (task.overdue) return 'tasks.overdue'.tr;
  if (task.dueDate == null) return task.category ?? 'tasks.noDueDate'.tr;
  return '${'tasks.due'.tr} ${_formatDateTime(task.dueDate!)}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.month}/${local.day} $hour:$minute $period';
}
