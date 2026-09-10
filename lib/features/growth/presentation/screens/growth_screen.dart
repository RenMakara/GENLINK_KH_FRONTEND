import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/shadows/app_shadows.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../leaderboard/presentation/bindings/leaderboard_binding.dart';
import '../../../leaderboard/presentation/screens/leaderboard_home_screen.dart';
import '../../../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../../../productivity/presentation/goals_plan/goal_plan.dart';
import '../../../productivity/presentation/habit_feature/habit_screen.dart';
import '../../../productivity/presentation/task_feature/task_home_screen.dart';
import '../../../home/domain/entities/home_entity.dart';
import '../../../home/presentation/controllers/home_controller.dart';

/// Level Up Screen — Personal Development & Progression
///
/// Refactored Phase 1: Visual Consistency + Information Hierarchy.
/// Aligned with GenLink's core black/white/gray design language.
/// Accent colors are used strictly for meaning (Gold=XP, Orange=Habits, Blue=Tasks, Cyan=Focus, Green=Goals, Purple=Mindset).
///
/// Section Hierarchy:
/// 1. HEADER (LEVEL UP [GROWTH] + "Your personal growth journey" + Trophy button to Leaderboard)
/// 2. YOUR PROGRESS (Clean Hero Card with level, XP progress, and Leaderboard link)
/// 3. TODAY (Main functional checklist: Habits & Tasks + Daily progress)
/// 4. IMPORTANT ALERTS (Habit Streak at Risk only; zero space when absent)
/// 5. GROW (Productivity Tools shortcuts: Habits, Tasks, Focus, Goals)
/// 6. YOUR NEXT MOVE (Recommended: Challenge / Quiz & Saving Goal)
/// 7. DAILY MINDSET (Calm inspirational quote card)
class GrowthScreen extends GetView<HomeController> {
  const GrowthScreen({super.key, this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final errorMessage = controller.errorMessage.value;
      final home = controller.home.value;

      if (isLoading && home == null) {
        return const _GrowthSkeletonView();
      }

      if (errorMessage != null && home == null) {
        return _GrowthErrorView(
          errorMessage: errorMessage,
          onRetry: controller.load,
        );
      }

      if (home == null) {
        return const _GrowthSkeletonView();
      }

      return _GrowthContentView(
        controller: controller,
        home: home,
        onNavigateTab: onNavigateTab,
      );
    });
  }
}

// ── MAIN CONTENT VIEW ────────────────────────────────────────────────────────

class _GrowthContentView extends StatelessWidget {
  const _GrowthContentView({
    required this.controller,
    required this.home,
    this.onNavigateTab,
  });

  final HomeController controller;
  final HomeEntity home;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.reload,
          color: isDark ? Colors.white : AppColors.lightPrimary,
          backgroundColor: isDark
              ? AppColors.darkSurfacePrimary
              : AppColors.lightSurfacePrimary,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs + 2,
                  AppSpacing.md,
                  120, // Clearance for bottom navigation bar
                ),
                children: [
                  // 1. HEADER
                  _GrowthHeader(user: home.user),
                  const SizedBox(height: 12),

                  // 2. YOUR PROGRESS (Hero Card)
                  _LevelProgressCard(user: home.user),
                  const SizedBox(height: 14),

                  // 3. TODAY (Habit & Task checklist or unified compact empty state)
                  _GrowthTodayChecklist(
                    home: home,
                    controller: controller,
                    onNavigateTab: onNavigateTab,
                  ),
                  const SizedBox(height: 12),

                  // 4. IMPORTANT ALERTS (Streak at risk only; zero space if absent)
                  _GrowthImportantAlerts(
                    home: home,
                    controller: controller,
                  ),

                  // 5. GROW (Productivity Tools shortcuts)
                  _ProductivityTools(onNavigateTab: onNavigateTab),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. YOUR NEXT MOVE (Recommended for you: Challenge / Saving Goal)
                  _GrowthYourNextStepSection(
                    home: home,
                    onNavigateTab: onNavigateTab,
                  ),

                  // 7. DAILY MINDSET (Distinctive calm inspiration card)
                  if (home.dailyMotivation != null &&
                      (home.dailyMotivation?.content?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _DailyMindsetCard(motivation: home.dailyMotivation!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 1. HEADER ────────────────────────────────────────────────────────────────

class _GrowthHeader extends StatelessWidget {
  const _GrowthHeader({required this.user});

  final HomeUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final firstName = user.fullName?.trim().split(' ').first;
    final subtitleText = (firstName != null && firstName.isNotEmpty)
        ? 'Welcome, $firstName · Your personal growth journey'
        : 'Your personal growth journey';

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LEVEL UP',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.to(
                () => const LeaderboardHomeScreen(),
                binding: LeaderboardBinding(),
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfacePrimary
                      : AppColors.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderSubtle,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 20,
                  color: textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. YOUR PROGRESS (LEVEL & XP PROGRESS HERO CARD) ─────────────────────────

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.user});

  final HomeUser user;

  static const Color growthAccent = Color(0xFFF2B84B); // Restrained Gold / Amber

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final nextLevel = user.safeLevel + 1;
    final levelLabel = 'home.levelLabel'.trParams({'level': '${user.safeLevel}'});
    final levelDisplay = (levelLabel.isNotEmpty && levelLabel != 'home.levelLabel')
        ? levelLabel
        : 'Level ${user.safeLevel}';

    // Supportive progress copy
    final xpDiff = user.xpForNextLevel - user.safeTotalXp;
    final progressCopy = xpDiff > 0
        ? 'Only $xpDiff XP to Level $nextLevel'
        : 'Progress toward Level $nextLevel';

    return Material(
      color: cardSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => Get.to(
          () => const LeaderboardHomeScreen(),
          binding: LeaderboardBinding(),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: borderSubtle,
              width: 0.8,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 28,
                        width: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: growthAccent.withValues(alpha: isDark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: growthAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        levelDisplay,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user.safeTotalXp} / ${user.xpForNextLevel} XP',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: textMuted.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: user.levelProgress,
                  minHeight: 5,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation<Color>(growthAccent),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progressCopy,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${user.percentToNext}%',
                    style: TextStyle(
                      color: growthAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
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

// ── 3. TODAY'S JOURNEY (LIGHTWEIGHT VERTICAL ACTIVITY TIMELINE) ───────────────

class _TimelineActivityItem {
  const _TimelineActivityItem({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
    this.onToggle,
    this.xpReward,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final int? xpReward;
}

class _GrowthTodayChecklist extends StatelessWidget {
  const _GrowthTodayChecklist({
    required this.home,
    required this.controller,
    this.onNavigateTab,
  });

  final HomeEntity home;
  final HomeController controller;
  final ValueChanged<int>? onNavigateTab;

  static const Color habitAccent = Color(0xFFF97316); // Semantic Orange
  static const Color taskAccent = Color(0xFF3B82F6); // Semantic Blue

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final progress = home.todayProgress;

    final todayTitle = 'home.todayJourney'.tr.isNotEmpty &&
            'home.todayJourney'.tr != 'home.todayJourney'
        ? 'home.todayJourney'.tr.toUpperCase()
        : "TODAY'S JOURNEY";

    final habitsTotal = progress.habitsTotal;
    final habitsDone = progress.habitsCompletedToday;
    final tasksTotal = progress.tasksTotal;
    final tasksDone = progress.tasksCompleted;
    final percent = progress.percent;

    // Build timeline activities from real existing data
    final habitItems = controller.habits;
    final activities = <_TimelineActivityItem>[];

    // 1. Habits (individual habits if loaded, or aggregated habit if habitsTotal > 0)
    if (habitItems.isNotEmpty) {
      for (final habit in habitItems) {
        final streakText =
            habit.streakCount > 0 ? '${habit.streakCount} day streak' : null;
        final subtitle = habit.checkedInToday
            ? 'Habit · Completed today${streakText != null ? ' · $streakText' : ''}'
            : 'Habit · ${streakText ?? (habit.category ?? 'Daily routine')}';

        activities.add(
          _TimelineActivityItem(
            title: habit.title,
            subtitle: subtitle,
            isCompleted: habit.checkedInToday,
            accentColor: habitAccent,
            onTap: () => Get.to(() => const HabitHomeScreen()),
            onToggle: () => controller.toggleHabitCheckIn(
              habitId: habit.habitId,
              targetState: !habit.checkedInToday,
            ),
          ),
        );
      }
    } else if (habitsTotal > 0) {
      final isHabitDone = habitsDone >= habitsTotal;
      final title = 'home.rowHabits'.tr.isNotEmpty &&
              'home.rowHabits'.tr != 'home.rowHabits'
          ? 'home.rowHabits'.tr
          : 'Check in your habits';
      final subtitle = 'home.rowHabitsDetail'.trParams({
        'done': '$habitsDone',
        'total': '$habitsTotal',
      });

      activities.add(
        _TimelineActivityItem(
          title: title,
          subtitle: subtitle.isNotEmpty && subtitle != 'home.rowHabitsDetail'
              ? 'Habit · $subtitle'
              : 'Habit · $habitsDone of $habitsTotal completed',
          isCompleted: isHabitDone,
          accentColor: habitAccent,
          onTap: () => Get.to(() => const HabitHomeScreen()),
          onToggle: () => controller.toggleHabitCheckIn(),
        ),
      );
    }

    // 2. Tasks
    if (tasksTotal > 0) {
      final isTaskDone = tasksDone >= tasksTotal;
      final title = isTaskDone
          ? "Today's tasks completed"
          : ('home.rowTasks'.tr.isNotEmpty &&
                  'home.rowTasks'.tr != 'home.rowTasks'
              ? 'home.rowTasks'.tr
              : "Finish today's tasks");
      final subtitle = isTaskDone
          ? 'Task · All $tasksTotal completed'
          : 'Task · $tasksDone of $tasksTotal completed';

      activities.add(
        _TimelineActivityItem(
          title: title,
          subtitle: subtitle,
          isCompleted: isTaskDone,
          accentColor: taskAccent,
          onTap: () => Get.to(() => const TasksPage()),
        ),
      );
    }

    final isAllEmpty = activities.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayTitle,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "What can I do today to Level Up?",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isAllEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),

        // Section Content: Lightweight Timeline vs All Caught Up Empty State
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: isAllEmpty
              ? _buildAllCaughtUpEmptyState(
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < activities.length; i++) ...[
                      _TimelineItemRow(
                        item: activities[i],
                        isLast: i == activities.length - 1,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                        borderSubtle: borderSubtle,
                        isDark: isDark,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Daily progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'home.dailyProgress'.tr.isNotEmpty &&
                                  'home.dailyProgress'.tr !=
                                      'home.dailyProgress'
                              ? 'home.dailyProgress'.tr
                              : 'Daily progress',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress.progress,
                        minHeight: 5,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Compact, Lightweight Empty State when no habits/tasks need attention
  Widget _buildAllCaughtUpEmptyState({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? Colors.white : AppColors.lightPrimary)
                .withValues(alpha: 0.1),
            border: Border.all(
              color: (isDark ? Colors.white : AppColors.lightPrimary)
                  .withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 18,
            color: isDark ? Colors.white : AppColors.lightPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You're all caught up",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No habits or tasks need attention right now.',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineItemRow extends StatelessWidget {
  const _TimelineItemRow({
    required this.item,
    required this.isLast,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.isDark,
  });

  final _TimelineActivityItem item;
  final bool isLast;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderSubtle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashFactory: InkRipple.splashFactory,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline status indicator & thin vertical connector
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: item.onToggle ?? item.onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 22,
                      width: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.isCompleted
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : AppColors.lightPrimary.withValues(alpha: 0.14))
                            : Colors.transparent,
                        border: Border.all(
                          color: item.isCompleted
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : AppColors.lightPrimary.withValues(alpha: 0.4))
                              : (isDark ? Colors.white38 : Colors.black38),
                          width: 1.4,
                        ),
                      ),
                      child: item.isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: isDark ? Colors.white : AppColors.lightPrimary,
                            )
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 22,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Activity details: Title, metadata, optional XP, arrow
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8, top: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: item.isCompleted
                                    ? textSecondary
                                    : textPrimary,
                                fontSize: 13.5,
                                fontWeight: item.isCompleted
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.xpReward != null && item.xpReward! > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2B84B)
                                .withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '+${item.xpReward} XP',
                            style: const TextStyle(
                              color: Color(0xFFF2B84B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: textMuted.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4. IMPORTANT ALERTS (CONDITIONAL: STREAK AT RISK ONLY) ──────────────────

class _GrowthImportantAlerts extends StatelessWidget {
  const _GrowthImportantAlerts({
    required this.home,
    required this.controller,
  });

  final HomeEntity home;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final habitsTotal = home.todayProgress.habitsTotal;
    final habitsDone = home.todayProgress.habitsCompletedToday;
    final isStreakAtRisk = habitsTotal > 0 &&
        habitsDone < habitsTotal &&
        controller.habits.any((h) => !h.checkedInToday && h.streakCount > 0);

    // If no streak at risk, take zero space on Level Up screen
    if (!isStreakAtRisk) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final alertTitle = 'home.habitStreakAlertTitle'.tr.isNotEmpty &&
            'home.habitStreakAlertTitle'.tr != 'home.habitStreakAlertTitle'
        ? 'home.habitStreakAlertTitle'.tr
        : 'Habit Streak at Risk';

    final alertMsg = 'home.habitStreakAlertMsg'.tr.isNotEmpty &&
            'home.habitStreakAlertMsg'.tr != 'home.habitStreakAlertMsg'
        ? 'home.habitStreakAlertMsg'.tr
        : "Complete today's habit check-in to protect your streak!";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GrowthAlertCard(
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFF97316),
        title: alertTitle,
        message: alertMsg,
        actionText: 'Tap → Check in habits',
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        isDark: isDark,
        onTap: () => Get.to(() => const HabitHomeScreen()),
      ),
    );
  }
}

class _GrowthAlertCard extends StatelessWidget {
  const _GrowthAlertCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionText,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionText;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Material(
      color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark
                  ? iconColor.withValues(alpha: 0.28)
                  : borderSubtle,
              width: 0.8,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      actionText,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 5. GROW (PRODUCTIVITY TOOLS SHORTCUTS) ───────────────────────────────────

class _ProductivityTools extends StatelessWidget {
  const _ProductivityTools({this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final tools = [
      (
        icon: Icons.repeat_rounded,
        label: 'Habits',
        accentColor: const Color(0xFFF97316), // Orange
        onTap: () => Get.to(() => const HabitHomeScreen()),
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        label: 'Tasks',
        accentColor: const Color(0xFF3B82F6), // Blue
        onTap: () => Get.to(() => const TasksPage()),
      ),
      (
        icon: Icons.timer_outlined,
        label: 'Focus',
        accentColor: const Color(0xFF06B6D4), // Cyan
        onTap: () => Get.to(() => const FocusPage()),
      ),
      (
        icon: Icons.flag_outlined,
        label: 'Goals',
        accentColor: const Color(0xFF10B981), // Emerald
        onTap: () => Get.to(() => const PlanGoalScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GROW',
          style: TextStyle(
            color: textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Row(
          children: [
            for (int i = 0; i < tools.length; i++) ...[
              Expanded(
                child: _ToolTile(
                  icon: tools[i].icon,
                  label: tools[i].label,
                  accentColor: tools[i].accentColor,
                  onTap: tools[i].onTap,
                ),
              ),
              if (i != tools.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashFactory: InkRipple.splashFactory,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle, width: 0.8),
                boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
              ),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── 6. YOUR NEXT MOVE (RECOMMENDED FOR YOU: CHALLENGE & SAVING GOAL) ────────

class _GrowthYourNextStepSection extends StatelessWidget {
  const _GrowthYourNextStepSection({
    required this.home,
    this.onNavigateTab,
  });

  final HomeEntity home;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    if (home.dailyChallenge == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    final challenge = home.dailyChallenge!;
    final challengeTitle = challenge.title.trim().isNotEmpty
        ? challenge.title
        : "Today's Challenge";

    final challengeDesc = challenge.description?.trim().isNotEmpty ?? false
        ? challenge.description!
        : 'Complete your daily objectives to earn XP and level up.';

    final xpReward = challenge.xpReward;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'YOUR NEXT MOVE',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RECOMMENDED FOR YOU',
              style: TextStyle(
                color: textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        _GrowthActionCard(
          icon: Icons.quiz_outlined,
          accentColor: const Color(0xFFF97316),
          title: challengeTitle,
          subtitle: challengeDesc,
          badgeText: (xpReward != null && xpReward > 0) ? '+$xpReward XP' : null,
          cardSurface: cardSurface,
          borderSubtle: borderSubtle,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onTap: () => Get.toNamed(AppRoutes.quizDashboard),
        ),
      ],
    );
  }
}

class _GrowthActionCard extends StatelessWidget {
  const _GrowthActionCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.cardSurface,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color cardSurface;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashFactory: InkRipple.splashFactory,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: borderSubtle,
              width: 0.8,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: textSecondary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 7. DAILY MINDSET (CALM & INSPIRATIONAL CARD) ──────────────────────────────

class _DailyMindsetCard extends StatelessWidget {
  const _DailyMindsetCard({required this.motivation});

  final MotivationCard motivation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    const mindsetAccent = Color(0xFF8B5CF6); // Gentle purple/indigo

    final title = motivation.title?.trim().isNotEmpty ?? false
        ? motivation.title!
        : 'Daily Mindset';

    final content = motivation.content ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderSubtle,
          width: 0.8,
        ),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mindsetAccent.withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              size: 18,
              color: mindsetAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: mindsetAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reflection for today',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SKELETON LOADING VIEW ───────────────────────────────────────────────────

class _GrowthSkeletonView extends StatelessWidget {
  const _GrowthSkeletonView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final skeletonBase =
        isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E7EB);
    final cardSurface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs + 2,
            AppSpacing.md,
            120,
          ),
          children: [
            // Header Skeleton
            Container(
              height: 44,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: skeletonBase,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 160,
                        height: 12,
                        decoration: BoxDecoration(
                          color: skeletonBase,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: skeletonBase,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Level Card Skeleton
            Container(
              height: 86,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle, width: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Today Skeleton
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle, width: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tools Skeleton
            Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 3 ? 10 : 0),
                    height: 72,
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: borderSubtle, width: 0.8),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ERROR VIEW ──────────────────────────────────────────────────────────────

class _GrowthErrorView extends StatelessWidget {
  const _GrowthErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    size: 28,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Unable to load Growth',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white : AppColors.lightPrimary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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
