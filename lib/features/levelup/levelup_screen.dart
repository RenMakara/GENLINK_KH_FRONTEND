import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/levelup/widget/levelup_widget.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../design_system/colors/app_colors.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../leaderboard/presentation/bindings/leaderboard_binding.dart';
import '../leaderboard/presentation/screens/leaderboard_home_screen.dart';
import '../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../productivity/presentation/goals_plan/goal_plan.dart';
import '../productivity/presentation/habit_feature/habit_screen.dart';
import '../productivity/presentation/task_feature/task_home_screen.dart';
import '../home/domain/entities/home_entity.dart';
import '../home/presentation/controllers/home_controller.dart';

class LevelUpScreen extends GetView<HomeController> {
  const LevelUpScreen({super.key, this.onNavigateTab});

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

// MAIN CONTENT
class _GrowthContentView extends StatefulWidget {
  const _GrowthContentView({
    required this.controller,
    required this.home,
    this.onNavigateTab,
  });

  final HomeController controller;
  final HomeEntity home;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<_GrowthContentView> createState() => _GrowthContentViewState();
}

class _GrowthContentViewState extends State<_GrowthContentView> {
  late DateTime selectedDate;
  late DateTime today;
  bool showDateDetail = false;
  static final List<GrowthCategory> categories = [
    GrowthCategory(
      label: 'levelup.categoryAll'.tr,
      icon: Icons.apps_rounded,
      color: const Color(0xFF777777),
    ),
    GrowthCategory(
      label: 'levelup.categoryTask'.tr,
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF3B82F6),
    ),
    GrowthCategory(
      label: 'levelup.categoryHabit'.tr,
      icon: Icons.repeat_rounded,
      color: const Color(0xFFF97316),
    ),
    GrowthCategory(
      label: 'levelup.categoryFocus'.tr,
      icon: Icons.timer_outlined,
      color: const Color(0xFF8B5CF6),
    ),
    GrowthCategory(
      label: 'levelup.categoryGoal'.tr,
      icon: Icons.flag_outlined,
      color: const Color(0xFF10B981),
    ),
    GrowthCategory(
      label: 'levelup.categoryQuiz'.tr,
      icon: Icons.quiz_outlined,
      color: const Color(0xFFF2B84B),
    ),
  ];

  static const List<GrowthTimelineActivity> activities = [
    GrowthTimelineActivity(
      title: 'Rise and Shine',
      subtitle: 'Morning meditation',
      time: '8:00 AM',
      endTime: '8:30 AM',
      type: 'Habit',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFF97316),
      completed: true,
      xp: 15,
    ),
    GrowthTimelineActivity(
      title: 'Go for a walk',
      subtitle: 'Clear your mind',
      time: '11:00 AM',
      endTime: '11:15 AM',
      type: 'Task',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF3B82F6),
      completed: false,
      xp: 10,
    ),
    GrowthTimelineActivity(
      title: 'Study session',
      subtitle: 'Focus for 25 minutes',
      time: '2:00 PM',
      endTime: '2:25 PM',
      type: 'Focus',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF8B5CF6),
      completed: false,
      xp: 20,
    ),
    GrowthTimelineActivity(
      title: 'Update portfolio',
      subtitle: 'Work on your goal',
      time: '6:00 PM',
      endTime: '6:30 PM',
      type: 'Goal',
      icon: Icons.track_changes_rounded,
      color: Color(0xFF10B981),
      completed: false,
      xp: 15,
    ),
    GrowthTimelineActivity(
      title: "Today's Challenge",
      subtitle: 'Test your knowledge',
      time: '8:00 PM',
      endTime: '8:20 PM',
      type: 'Quiz',
      icon: Icons.extension_rounded,
      color: Color(0xFFF2B84B),
      completed: false,
      xp: 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    selectedDate = today;
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _toggleDateDetail() {
    setState(() => showDateDetail = !showDateDetail);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final user = widget.home.user;

    final subtitle = user.fullName?.trim().isNotEmpty == true
        ? 'levelup.subtitleWelcome'.trParams({
            'name': user.fullName!.trim().split(' ').first,
          })
        : 'levelup.subtitleDefault'.tr;

    // Level progress data
    final nextLevel = user.safeLevel + 1;
    final levelDisplay = 'levelup.levelLabel'.trParams({
      'level': '${user.safeLevel}',
    });
    final xpDiff = user.xpForNextLevel - user.safeTotalXp;
    final progressCopy = xpDiff > 0
        ? 'levelup.onlyXpToLevel'.trParams({
            'xp': '$xpDiff',
            'level': '$nextLevel',
          })
        : 'levelup.progressTowardLevel'.trParams({'level': '$nextLevel'});

    // Today checklist data
    final progress = widget.home.todayProgress;
    final habitsTotal = progress.habitsTotal;
    final habitsDone = progress.habitsCompletedToday;
    final tasksTotal = progress.tasksTotal;
    final tasksDone = progress.tasksCompleted;
    final percent = progress.percent;

    final todayTitle = 'levelup.todayJourney'.tr;

    final habitItems = widget.controller.habits;
    final activitiesList = <TimelineActivityItem>[];

    // Habits
    if (habitItems.isNotEmpty) {
      for (final habit in habitItems) {
        final streakText = habit.streakCount > 0
            ? 'levelup.habitStreak'.trParams({'streak': '${habit.streakCount}'})
            : null;

        final sub = habit.checkedInToday
            ? 'levelup.habitCompletedToday'.tr +
                  (streakText != null ? ' · $streakText' : '')
            : 'levelup.habitPrefix'.tr +
                  (streakText ??
                      (habit.category ?? 'levelup.habitDailyRoutine'.tr));

        activitiesList.add(
          TimelineActivityItem(
            title: habit.title,
            subtitle: sub,
            isCompleted: habit.checkedInToday,
            accentColor: const Color(0xFFF97316),
            onTap: () => Get.to(() => const HabitHomeScreen()),
            onToggle: () => widget.controller.toggleHabitCheckIn(
              habitId: habit.habitId,
              targetState: !habit.checkedInToday,
            ),
          ),
        );
      }
    } else if (habitsTotal > 0) {
      final isHabitDone = habitsDone >= habitsTotal;

      activitiesList.add(
        TimelineActivityItem(
          title: 'levelup.checkInHabits'.tr,
          subtitle: 'levelup.habitProgress'.trParams({
            'done': '$habitsDone',
            'total': '$habitsTotal',
          }),
          isCompleted: isHabitDone,
          accentColor: const Color(0xFFF97316),
          onTap: () => Get.to(() => const HabitHomeScreen()),
          onToggle: () => widget.controller.toggleHabitCheckIn(),
        ),
      );
    }

    // Tasks
    if (tasksTotal > 0) {
      final isTaskDone = tasksDone >= tasksTotal;
      activitiesList.add(
        TimelineActivityItem(
          title: isTaskDone
              ? 'levelup.tasksCompleted'.tr
              : 'levelup.finishTasks'.tr,
          subtitle: isTaskDone
              ? 'levelup.taskAllCompleted'.trParams({'total': '$tasksTotal'})
              : 'levelup.taskProgress'.trParams({
                  'done': '$tasksDone',
                  'total': '$tasksTotal',
                }),
          isCompleted: isTaskDone,
          accentColor: const Color(0xFF3B82F6),
          onTap: () => Get.to(() => const TasksPage()),
        ),
      );
    }

    // Alert
    final isStreakAtRisk =
        habitsTotal > 0 &&
        habitsDone < habitsTotal &&
        widget.controller.habits.any(
          (h) => !h.checkedInToday && h.streakCount > 0,
        );

    // Challenge
    final challenge = widget.home.dailyChallenge;
    final challengeTitle = challenge?.title.trim().isNotEmpty == true
        ? challenge!.title
        : 'levelup.todaysChallenge'.tr;
    final challengeDesc = challenge?.description?.trim().isNotEmpty == true
        ? challenge!.description!
        : 'levelup.challengeDefaultDesc'.tr;
    final xpReward = challenge?.xpReward;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: widget.controller.reload,
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
                  120,
                ),
                children: [
                  // HEADER
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'levelup.title'.tr,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GrowthHeaderIconButton(
                        icon: Icons.emoji_events_outlined,
                        onTap: () => Get.to(
                          () => const LeaderboardHomeScreen(),
                          binding: LeaderboardBinding(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // DATE CARD
                  GrowthDateCard(
                    today: today,
                    selectedDate: selectedDate,
                    showDateDetail: showDateDetail,
                    onDateSelected: _selectDate,
                    onToggleDetail: _toggleDateDetail,
                    detailChild: GrowthDateDetailLayout(
                      selectedDate: selectedDate,
                      today: today,
                      categories: categories,
                      activities: activities,
                      onDateSelected: _selectDate,
                      onEdit: (a) => Get.snackbar(
                        '',
                        'levelup.editActivity'.trParams({'title': a.title}),
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(12),
                        duration: const Duration(seconds: 1),
                      ),
                      onDelete: (a) => Get.snackbar(
                        '',
                        'levelup.deleteActivity'.trParams({'title': a.title}),
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(12),
                        duration: const Duration(seconds: 1),
                      ),
                      onMarkDone: (a) => Get.snackbar(
                        '',
                        a.completed
                            ? 'levelup.alreadyCompleted'.tr
                            : 'levelup.markedAsDone'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(12),
                        duration: const Duration(seconds: 1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // LEVEL PROGRESS
                  LevelProgressCard(
                    levelDisplay: levelDisplay,
                    xpText: '${user.safeTotalXp} / ${user.xpForNextLevel} XP',
                    progressCopy: progressCopy,
                    percentText: '${user.percentToNext}%',
                    progress: user.levelProgress,
                    onTap: () => Get.to(
                      () => const LeaderboardHomeScreen(),
                      binding: LeaderboardBinding(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TODAY CHECKLIST
                  GrowthTodayChecklist(
                    title: todayTitle,
                    subtitle: 'levelup.whatCanIDoToday'.tr,
                    percentText: '$percent%',
                    progress: progress.progress,
                    activities: activitiesList,
                    emptyTitle: 'levelup.allCaughtUp'.tr,
                    emptyMessage: 'levelup.noHabitsOrTasks'.tr,
                  ),

                  const SizedBox(height: 12),

                  // ALERT
                  if (isStreakAtRisk)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GrowthAlertCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFF97316),
                        title: 'levelup.streakAtRiskTitle'.tr,
                        message: 'levelup.streakAtRiskMessage'.tr,
                        actionText: 'levelup.streakAtRiskAction'.tr,
                        onTap: () => Get.to(() => const HabitHomeScreen()),
                      ),
                    ),

                  // PRODUCTIVITY TOOLS
                  Text(
                    'levelup.grow'.tr,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 4),
                      children: [
                        _buildToolItem(
                          context: context,
                          icon: Icons.check_circle_outline_rounded,
                          label: 'levelup.tasks'.tr,
                          color: const Color(0xFF3B82F6),
                          onTap: () => Get.to(() => const TasksPage()),
                        ),
                        const SizedBox(width: 5),

                        _buildToolItem(
                          context: context,
                          icon: Icons.repeat_rounded,
                          label: 'levelup.habits'.tr,
                          color: const Color(0xFFF97316),
                          onTap: () => Get.to(() => const HabitHomeScreen()),
                        ),
                        const SizedBox(width: 5),

                        _buildToolItem(
                          context: context,
                          icon: Icons.flag_outlined,
                          label: 'levelup.goals'.tr,
                          color: const Color(0xFF10B981),
                          onTap: () => Get.to(() => const PlanGoalScreen()),
                        ),
                        const SizedBox(width: 5),

                        _buildToolItem(
                          context: context,
                          icon: Icons.timer_outlined,
                          label: 'levelup.focus'.tr,
                          color: const Color(0xFF06B6D4),
                          onTap: () => Get.to(() => const FocusPage()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // YOUR NEXT MOVE
                  if (challenge != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'levelup.yourNextMove'.tr,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Text(
                          'levelup.recommendedForYou'.tr,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GrowthActionCard(
                      icon: Icons.quiz_outlined,
                      accentColor: const Color(0xFFF97316),
                      title: challengeTitle,
                      subtitle: challengeDesc,
                      badgeText: xpReward != null && xpReward > 0
                          ? '+$xpReward XP'
                          : null,
                      onTap: () => Get.toNamed(AppRoutes.quizDashboard),
                    ),
                  ],

                  // DAILY MINDSET
                  if (widget.home.dailyMotivation != null &&
                      (widget.home.dailyMotivation?.content
                              ?.trim()
                              .isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    DailyMindsetCard(
                      title:
                          widget.home.dailyMotivation!.title
                                  ?.trim()
                                  .isNotEmpty ==
                              true
                          ? widget.home.dailyMotivation!.title!
                          : 'levelup.dailyMindset'.tr,
                      content: widget.home.dailyMotivation!.content ?? '',
                    ),
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

// SKELETON
class _GrowthSkeletonView extends StatelessWidget {
  const _GrowthSkeletonView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            Container(height: 44, color: skeletonBase),
            const SizedBox(height: 12),
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderSubtle),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderSubtle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ERROR
class _GrowthErrorView extends StatelessWidget {
  const _GrowthErrorView({required this.errorMessage, required this.onRetry});

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(height: 18),
                Text(
                  'levelup.unableToLoad'.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'levelup.checkConnection'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text('levelup.retry'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildToolItem({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final cardSurface = isDark
      ? AppColors.darkSurfacePrimary
      : AppColors.lightSurfacePrimary;
  final border = isDark
      ? AppColors.darkBorderSubtle
      : AppColors.lightBorderSubtle;
  final textSecondary = isDark
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 78,
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 0.8),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
