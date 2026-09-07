import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import '../../../leaderboard/presentation/screens/leaderboard_home_screen.dart';
import '../../../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../../../productivity/presentation/habit_feature/habit_screen.dart';
import '../../../productivity/presentation/task_feature/task_home_screen.dart';
import '../../../home/domain/entities/home_entity.dart';
import '../../../home/presentation/controllers/home_controller.dart';

/// Growth Screen — Personal Development & Productivity
///
/// Role: "Personal Development & Productivity"
/// Answers: "How am I improving? What do I need to do today?"
///
/// Contains:
/// - Personal Greeting & Growth level/XP badge
/// - Level progress & XP overview
/// - Important Alerts (Budget alert, Streak at risk)
/// - Today's unified Habits & Tasks checklist with progress
/// - Productivity Tools shortcuts (Habits, Tasks, Focus, Goals, Leaderboard)
/// - For You personalized recommendations (Challenges, Goal updates, Mindset)
///
/// Strictly NO community feed content in Growth.
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  AppSpacing.xs,
                  AppSpacing.md,
                  120, // Clearance for bottom navigation bar
                ),
                children: [
                  // 1. GROWTH HEADER
                  const _GrowthHeader(),
                  const SizedBox(height: AppSpacing.md),

                  // 2. PERSONAL GREETING ("Good morning, Enat 👋")
                  _GrowthGreeting(user: home.user),
                  const SizedBox(height: AppSpacing.md),

                  // 3. LEVEL & XP PROGRESS CARD
                  _LevelProgressCard(user: home.user),
                  const SizedBox(height: AppSpacing.md + 2),

                  // 4. IMPORTANT ALERTS (Conditional)
                  _GrowthImportantAlerts(
                    home: home,
                    controller: controller,
                    onNavigateTab: onNavigateTab,
                  ),

                  // 5. TODAY (Unified Habits & Tasks Checklist)
                  _GrowthTodayChecklist(
                    home: home,
                    controller: controller,
                    onNavigateTab: onNavigateTab,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. PRODUCTIVITY TOOLS (Quick access to Habits, Tasks, Focus, Goals, Leaderboard)
                  _ProductivityTools(onNavigateTab: onNavigateTab),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. FOR YOU (Personalized development cards: max 2-3 items)
                  _GrowthForYouSection(
                    home: home,
                    onNavigateTab: onNavigateTab,
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

// ── 1. GROWTH HEADER ─────────────────────────────────────────────────────────

class _GrowthHeader extends StatelessWidget {
  const _GrowthHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final growthTitle =
        'nav.growth'.tr.isNotEmpty && 'nav.growth'.tr != 'nav.growth'
        ? 'nav.growth'.tr.toUpperCase()
        : 'GROWTH';

    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.track_changes_rounded,
                size: 24,
                color: Color(0xFFF2B84B),
              ),
              const SizedBox(width: 8),
              Text(
                growthTitle,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.emoji_events_outlined,
              size: 22,
              color: textPrimary,
            ),
            tooltip: 'Leaderboard',
            onPressed: () => Get.to(() => const LeaderboardHomeScreen()),
          ),
        ],
      ),
    );
  }
}

// ── 2. PERSONAL GREETING ────────────────────────────────────────────────────

class _GrowthGreeting extends StatelessWidget {
  const _GrowthGreeting({required this.user});

  final HomeUser user;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'home.goodMorning'.tr.isNotEmpty &&
              'home.goodMorning'.tr != 'home.goodMorning'
          ? 'home.goodMorning'.tr
          : 'Good morning';
    } else if (hour < 17) {
      return 'home.goodAfternoon'.tr.isNotEmpty &&
              'home.goodAfternoon'.tr != 'home.goodAfternoon'
          ? 'home.goodAfternoon'.tr
          : 'Good afternoon';
    } else {
      return 'home.goodEvening'.tr.isNotEmpty &&
              'home.goodEvening'.tr != 'home.goodEvening'
          ? 'home.goodEvening'.tr
          : 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final greetingBase = _getGreeting();
    final name = user.firstName.isNotEmpty ? user.firstName : '';
    final greetingDisplay = name.isNotEmpty
        ? '$greetingBase, $name 👋'
        : '$greetingBase 👋';

    final subtitle =
        'home.greetingSubtitle'.tr.isNotEmpty &&
            'home.greetingSubtitle'.tr != 'home.greetingSubtitle'
        ? 'home.greetingSubtitle'.tr
        : "Here's what's important today.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingDisplay,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── 3. LEVEL & XP PROGRESS CARD ─────────────────────────────────────────────

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.user});

  final HomeUser user;

  static const Color growthAccent = Color(0xFFF2B84B); // Gold / Amber

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final nextLevel = user.safeLevel + 1;
    final levelLabel = 'home.levelLabel'.trParams({
      'level': '${user.safeLevel}',
    });
    final levelDisplay =
        (levelLabel.isNotEmpty && levelLabel != 'home.levelLabel')
        ? levelLabel
        : 'Level ${user.safeLevel}';

    final progressToward = 'home.progressTowardLevel'.trParams({
      'level': '$nextLevel',
    });
    final progressLabel =
        (progressToward.isNotEmpty &&
            progressToward != 'home.progressTowardLevel')
        ? progressToward
        : 'Progress toward Level $nextLevel';

    return Material(
      color: cardSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => Get.to(() => const LeaderboardHomeScreen()),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
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
                        height: 26,
                        width: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: growthAccent.withValues(
                            alpha: isDark ? 0.16 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: growthAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        levelDisplay,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${user.safeTotalXp} / ${user.xpForNextLevel} XP',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: user.levelProgress,
                  minHeight: 5,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(growthAccent),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progressLabel,
                    style: TextStyle(color: textSecondary, fontSize: 11.5),
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

// ── 4. IMPORTANT ALERTS ─────────────────────────────────────────────────────

class _GrowthImportantAlerts extends StatelessWidget {
  const _GrowthImportantAlerts({
    required this.home,
    required this.controller,
    this.onNavigateTab,
  });

  final HomeEntity home;
  final HomeController controller;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final finance = home.financeSnapshot;
    final isFinanceAlert =
        finance != null &&
        ((finance.budgetStatus == 'WARNING' ||
                finance.budgetStatus == 'LIMIT_REACHED') ||
            (finance.totalBudget != null &&
                finance.totalBudget! > 0 &&
                finance.spentAmount != null &&
                (finance.spentAmount! / finance.totalBudget!) >= 0.8));

    final habitsTotal = home.todayProgress.habitsTotal;
    final habitsDone = home.todayProgress.habitsCompletedToday;
    final isStreakAtRisk =
        habitsTotal > 0 &&
        habitsDone < habitsTotal &&
        controller.habits.any((h) => !h.checkedInToday && h.streakCount > 0);

    if (!isFinanceAlert && !isStreakAtRisk) {
      return const SizedBox.shrink();
    }

    final alerts = <Widget>[];

    if (isFinanceAlert) {
      final total = finance.totalBudget ?? 1.0;
      final spent = finance.spentAmount ?? 0.0;
      final percent = total > 0 ? ((spent / total) * 100).round() : 80;
      final isLimit = percent >= 100 || finance.budgetStatus == 'LIMIT_REACHED';

      final alertTitle =
          'home.budgetAlertTitle'.tr.isNotEmpty &&
              'home.budgetAlertTitle'.tr != 'home.budgetAlertTitle'
          ? 'home.budgetAlertTitle'.tr
          : 'Budget Alert';

      final alertMsg = isLimit
          ? ('home.budgetAlertLimit'.tr.isNotEmpty &&
                    'home.budgetAlertLimit'.tr != 'home.budgetAlertLimit'
                ? 'home.budgetAlertLimit'.tr
                : "You've reached your monthly budget limit.")
          : ('home.budgetAlertWarning'.trParams({
                      'percent': '$percent',
                    }).isNotEmpty &&
                    'home.budgetAlertWarning'.trParams({
                          'percent': '$percent',
                        }) !=
                        'home.budgetAlertWarning'
                ? 'home.budgetAlertWarning'.trParams({'percent': '$percent'})
                : "You've used $percent% of your monthly budget.");

      alerts.add(
        _GrowthAlertCard(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: alertTitle,
          message: alertMsg,
          actionText: 'Tap → Open Finance',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onTap: () => onNavigateTab?.call(2), // Navigate to Finance tab
        ),
      );
    }

    if (isStreakAtRisk) {
      final alertTitle =
          'home.habitStreakAlertTitle'.tr.isNotEmpty &&
              'home.habitStreakAlertTitle'.tr != 'home.habitStreakAlertTitle'
          ? 'home.habitStreakAlertTitle'.tr
          : 'Habit Streak at Risk';

      final alertMsg =
          'home.habitStreakAlertMsg'.tr.isNotEmpty &&
              'home.habitStreakAlertMsg'.tr != 'home.habitStreakAlertMsg'
          ? 'home.habitStreakAlertMsg'.tr
          : "Complete today's habit check-in to protect your streak!";

      alerts.add(
        _GrowthAlertCard(
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      child: Column(
        children: [
          for (int i = 0; i < alerts.length; i++) ...[
            alerts[i],
            if (i != alerts.length - 1) const SizedBox(height: 8),
          ],
        ],
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
    return Material(
      color: isDark
          ? AppColors.darkSurfacePrimary
          : AppColors.lightSurfacePrimary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.35 : 0.40),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 32,
                width: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.16 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
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

// ── 5. TODAY (UNIFIED HABITS & TASKS CHECKLIST) ─────────────────────────────

class _GrowthTodayChecklist extends StatelessWidget {
  const _GrowthTodayChecklist({
    required this.home,
    required this.controller,
    this.onNavigateTab,
  });

  final HomeEntity home;
  final HomeController controller;
  final ValueChanged<int>? onNavigateTab;

  static const Color habitAccent = Color(0xFFF97316); // Orange
  static const Color taskAccent = Color(0xFF3B82F6); // Blue

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final progress = home.todayProgress;

    final todayTitle =
        'home.today'.tr.isNotEmpty && 'home.today'.tr != 'home.today'
        ? 'home.today'.tr.toUpperCase()
        : 'TODAY';

    final habitsTotal = progress.habitsTotal;
    final habitsDone = progress.habitsCompletedToday;
    final isHabitDone = habitsTotal > 0 && habitsDone >= habitsTotal;

    final tasksTotal = progress.tasksTotal;
    final tasksDone = progress.tasksCompleted;
    final isTaskDone = tasksTotal > 0 && tasksDone >= tasksTotal;

    final percent = progress.percent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              todayTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Habits Checklist Item
              if (habitsTotal == 0)
                _buildEmptyRow(
                  title:
                      'home.noHabitsTitle'.tr.isNotEmpty &&
                          'home.noHabitsTitle'.tr != 'home.noHabitsTitle'
                      ? 'home.noHabitsTitle'.tr
                      : 'No habits for today',
                  subtitle:
                      'home.noHabitsSubtitle'.tr.isNotEmpty &&
                          'home.noHabitsSubtitle'.tr != 'home.noHabitsSubtitle'
                      ? 'home.noHabitsSubtitle'.tr
                      : 'Start building a routine.',
                  accentColor: habitAccent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderSubtle: borderSubtle,
                )
              else
                _GrowthTodayChecklistRow(
                  isDone: isHabitDone,
                  title:
                      'home.rowHabits'.tr.isNotEmpty &&
                          'home.rowHabits'.tr != 'home.rowHabits'
                      ? 'home.rowHabits'.tr
                      : 'Check in your habits',
                  subtitle: 'home.rowHabitsDetail'.trParams({
                    'done': '$habitsDone',
                    'total': '$habitsTotal',
                  }),
                  accentColor: habitAccent,
                  onTap: () => Get.to(() => const HabitHomeScreen()),
                  onToggle: () => controller.toggleHabitCheckIn(),
                ),

              const SizedBox(height: 10),

              // 2. Tasks Checklist Item
              if (tasksTotal == 0)
                _buildEmptyRow(
                  title:
                      'home.noTasksTitle'.tr.isNotEmpty &&
                          'home.noTasksTitle'.tr != 'home.noTasksTitle'
                      ? 'home.noTasksTitle'.tr
                      : 'No tasks for today',
                  subtitle:
                      'home.noTasksSubtitle'.tr.isNotEmpty &&
                          'home.noTasksSubtitle'.tr != 'home.noTasksSubtitle'
                      ? 'home.noTasksSubtitle'.tr
                      : "You're all caught up.",
                  accentColor: taskAccent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderSubtle: borderSubtle,
                )
              else
                _GrowthTodayChecklistRow(
                  isDone: isTaskDone,
                  title:
                      'home.rowTasks'.tr.isNotEmpty &&
                          'home.rowTasks'.tr != 'home.rowTasks'
                      ? 'home.rowTasks'.tr
                      : "Finish today's tasks",
                  subtitle: 'home.rowTasksDetail'.trParams({
                    'done': '$tasksDone',
                    'total': '$tasksTotal',
                  }),
                  accentColor: taskAccent,
                  onTap: () => Get.to(() => const TasksPage()),
                ),

              const SizedBox(height: AppSpacing.md),

              // 3. Daily progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home.dailyProgress'.tr.isNotEmpty &&
                            'home.dailyProgress'.tr != 'home.dailyProgress'
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
                  minHeight: 4,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08),
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

  Widget _buildEmptyRow({
    required String title,
    required String subtitle,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderSubtle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderSubtle, width: 1.2),
            ),
            child: Container(
              height: 5,
              width: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
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

class _GrowthTodayChecklistRow extends StatelessWidget {
  const _GrowthTodayChecklistRow({
    required this.isDone,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.onToggle,
  });

  final bool isDone;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle ?? onTap,
                child: Container(
                  height: 24,
                  width: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? (isDark ? Colors.white : AppColors.lightPrimary)
                        : Colors.transparent,
                    border: Border.all(
                      color: isDone ? Colors.transparent : borderSubtle,
                      width: 1.4,
                    ),
                  ),
                  child: isDone
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: isDark ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDone ? textSecondary : textPrimary,
                        fontSize: 13.5,
                        fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 6,
                width: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 6. PRODUCTIVITY TOOLS (HABITS, TASKS, FOCUS, GOALS, LEADERBOARD) ────────

class _ProductivityTools extends StatelessWidget {
  const _ProductivityTools({this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

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
        icon: Icons.savings_outlined,
        label: 'Goals',
        accentColor: const Color(0xFF10B981), // Emerald
        onTap: () => Get.to(() => const SavingGoalsScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUCTIVITY TOOLS',
          style: TextStyle(
            color: textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
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
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle, width: 0.8),
              ),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── 7. FOR YOU (PERSONALIZED CARDS) ─────────────────────────────────────────

class _GrowthForYouSection extends StatelessWidget {
  const _GrowthForYouSection({required this.home, this.onNavigateTab});

  final HomeEntity home;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final cards = <Widget>[];

    // Card 1: Daily Challenge / Quiz Recommendation
    if (home.dailyChallenge != null) {
      final challenge = home.dailyChallenge!;
      final challengeTitle = challenge.title.trim().isNotEmpty
          ? challenge.title
          : "Today's Challenge";

      final challengeDesc = challenge.description?.trim().isNotEmpty ?? false
          ? challenge.description!
          : 'Complete your daily objectives to earn XP and level up.';

      final xpReward = challenge.xpReward;

      cards.add(
        _GrowthForYouCard(
          icon: Icons.emoji_events_outlined,
          accentColor: const Color(0xFFF97316),
          title: challengeTitle,
          subtitle: challengeDesc,
          badgeText: (xpReward != null && xpReward > 0)
              ? '+$xpReward XP'
              : null,
          cardSurface: cardSurface,
          borderSubtle: borderSubtle,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onTap: () => Get.toNamed(AppRoutes.quizDashboard),
        ),
      );
    }

    // Card 2: Savings Goal Progress Update
    final finance = home.financeSnapshot;
    if (cards.length < 3 &&
        finance != null &&
        finance.savingTarget != null &&
        finance.savingTarget! > 0) {
      final target = finance.savingTarget!;
      final current = finance.savingCurrent ?? 0.0;
      final percent = ((current / target) * 100).round().clamp(0, 100);

      cards.add(
        _GrowthForYouCard(
          icon: Icons.savings_outlined,
          accentColor: const Color(0xFF10B981),
          title: 'Saving Goal Update',
          subtitle:
              '$percent% saved (${current.toStringAsFixed(0)} of ${target.toStringAsFixed(0)})',
          badgeText: '$percent%',
          cardSurface: cardSurface,
          borderSubtle: borderSubtle,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onTap: () => Get.to(() => const SavingGoalsScreen()),
        ),
      );
    }

    // Card 3: Daily Mindset / Motivation
    if (cards.length < 3 &&
        home.dailyMotivation != null &&
        (home.dailyMotivation?.content?.trim().isNotEmpty ?? false)) {
      final motivation = home.dailyMotivation!;
      final title = motivation.title?.trim().isNotEmpty ?? false
          ? motivation.title!
          : 'Daily Mindset';

      cards.add(
        _GrowthForYouCard(
          icon: Icons.lightbulb_outline_rounded,
          accentColor: const Color(0xFF8B5CF6),
          title: title,
          subtitle: motivation.content!,
          cardSurface: cardSurface,
          borderSubtle: borderSubtle,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onTap: () {},
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDED FOR YOU',
          style: TextStyle(
            color: textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GrowthForYouCard extends StatelessWidget {
  const _GrowthForYouCard({
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
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
                              color: accentColor.withValues(
                                alpha: isDark ? 0.20 : 0.12,
                              ),
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
            ],
          ),
        ),
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
    final skeletonBase = isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFE5E7EB);
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            120,
          ),
          children: [
            // Header Skeleton
            Container(
              height: 48,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 100,
                    height: 22,
                    decoration: BoxDecoration(
                      color: skeletonBase,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: skeletonBase,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Greeting Skeleton
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: 20,
                  decoration: BoxDecoration(
                    color: skeletonBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Level Card Skeleton
            Container(
              height: 80,
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
                borderRadius: BorderRadius.circular(AppRadius.xl),
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
  const _GrowthErrorView({required this.errorMessage, required this.onRetry});

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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
                    backgroundColor: isDark
                        ? Colors.white
                        : AppColors.lightPrimary,
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
