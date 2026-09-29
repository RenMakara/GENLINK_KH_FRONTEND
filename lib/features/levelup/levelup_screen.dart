import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/levelup/widget/levelup_widget.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../design_system/colors/app_colors.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/widgets/headers/app_screen_header.dart';
import '../leaderboard/presentation/bindings/leaderboard_binding.dart';
import '../leaderboard/presentation/screens/leaderboard_home_screen.dart';
import '../productivity/presentation/focus_feature/focus_home_screen.dart';
import '../productivity/presentation/goals_plan/goal_plan.dart';
import '../productivity/presentation/habit_feature/habit_screen.dart';
import '../productivity/presentation/task_feature/task_home_screen.dart';
import '../productivity/productivity_screen.dart';
import 'widget/grow_section_widget.dart';
import '../productivity/domain/entities/productivity_entities.dart'
    hide ProductivityPage;
import '../productivity/presentation/controllers/productivity_controller.dart';
import '../productivity/presentation/productivity_scope.dart';
import '../home/domain/entities/home_entity.dart';
import '../home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/challenge/domain/models/challenge_models.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';

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
  late final ProductivityController? _productivityController;

  List<GrowthCategory> get categories => [
    GrowthCategory(
      label: 'levelup.categoryAll'.tr,
      icon: Icons.apps_rounded,
      color: const Color(0xFF777777),
      key: 'all',
    ),
    GrowthCategory(
      label: 'levelup.categoryTask'.tr,
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF3B82F6),
      key: 'task',
    ),
    GrowthCategory(
      label: 'levelup.categoryHabit'.tr,
      icon: Icons.repeat_rounded,
      color: const Color(0xFFF97316),
      key: 'habit',
    ),
    GrowthCategory(
      label: 'levelup.categoryFocus'.tr,
      icon: Icons.timer_outlined,
      color: const Color(0xFF8B5CF6),
      key: 'focus',
    ),
    GrowthCategory(
      label: 'levelup.categoryGoal'.tr,
      icon: Icons.flag_outlined,
      color: const Color(0xFF10B981),
      key: 'goal',
    ),
    GrowthCategory(
      label: 'levelup.categoryQuiz'.tr,
      icon: Icons.quiz_outlined,
      color: const Color(0xFFF2B84B),
      key: 'quiz',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    selectedDate = today;
    _productivityController = ensureProductivityController();
    _productivityController?.loadFocusHistory();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      widget.controller.reload(),
      if (_productivityController != null) _productivityController.reload(),
    ]);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<GrowthTimelineActivity> _buildDateActivities(DateTime date) {
    final activities = <GrowthTimelineActivity>[];
    final isToday = _isSameDay(date, today);

    // 1. Tasks
    final prodTasks =
        _productivityController?.tasks ?? const <ProductivityTask>[];
    if (prodTasks.isNotEmpty) {
      for (final task in prodTasks) {
        final matchesDate = task.dueDate != null
            ? _isSameDay(task.dueDate!, date)
            : isToday;
        final isOverdueToday =
            isToday &&
            !task.completed &&
            task.dueDate != null &&
            task.dueDate!.isBefore(today);

        if (matchesDate || isOverdueToday) {
          final timeStr = task.reminderTime != null
              ? '${task.reminderTime!.hour.toString().padLeft(2, '0')}:${task.reminderTime!.minute.toString().padLeft(2, '0')}'
              : (task.dueDate != null
                    ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
                    : '');

          final subtitle = task.completed
              ? ('levelup.taskCompleted'.tr.isNotEmpty &&
                        'levelup.taskCompleted'.tr != 'levelup.taskCompleted'
                    ? 'levelup.taskCompleted'.tr
                    : 'common.done'.tr)
              : isOverdueToday
              ? ('productivity.overdue'.tr.isNotEmpty &&
                        'productivity.overdue'.tr != 'productivity.overdue'
                    ? 'productivity.overdue'.tr
                    : 'Overdue')
              : (task.priority ?? task.category ?? 'levelup.categoryTask'.tr);

          activities.add(
            GrowthTimelineActivity(
              title: task.title,
              type: 'levelup.categoryTask'.tr,
              categoryKey: 'task',
              subtitle: subtitle,
              time: timeStr == '00:00' ? '' : timeStr,
              endTime: '',
              xp: task.xpEarned,
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF3B82F6),
              completed: task.completed,
              onTap: () => Get.to(() => const TasksPage()),
              onToggle: () {
                _productivityController?.toggleTask(
                  task.taskId,
                  completed: !task.completed,
                );
              },
            ),
          );
        }
      }
    } else if (isToday && widget.home.todayProgress.tasksTotal > 0) {
      final tasksDone = widget.home.todayProgress.tasksCompleted;
      final tasksTotal = widget.home.todayProgress.tasksTotal;
      final isTaskDone = tasksDone >= tasksTotal;
      activities.add(
        GrowthTimelineActivity(
          title: isTaskDone
              ? 'levelup.tasksCompleted'.tr
              : 'levelup.finishTasks'.tr,
          type: 'levelup.categoryTask'.tr,
          categoryKey: 'task',
          subtitle: isTaskDone
              ? 'levelup.taskAllCompleted'.trParams({'total': '$tasksTotal'})
              : 'levelup.taskProgress'.trParams({
                  'done': '$tasksDone',
                  'total': '$tasksTotal',
                }),
          time: '',
          endTime: '',
          xp: 0,
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF3B82F6),
          completed: isTaskDone,
          onTap: () => Get.to(() => const TasksPage()),
        ),
      );
    }

    // 2. Habits
    final habitItems =
        _productivityController?.habits ?? const <ProductivityHabit>[];
    if (habitItems.isNotEmpty) {
      for (final habit in habitItems) {
        final isWeekly = habit.frequency?.toUpperCase() == 'WEEKLY';
        final habitDone = isWeekly
            ? habit.checkedInThisWeek
            : habit.checkedInToday;
        final streakText = habit.streakCount > 0
            ? 'levelup.habitStreak'.trParams({'streak': '${habit.streakCount}'})
            : null;
        final sub = isToday
            ? (habitDone
                  ? (isWeekly
                            ? 'habits.completedThisWeek'.tr
                            : 'levelup.habitCompletedToday'.tr) +
                        (streakText != null ? ' · $streakText' : '')
                  : 'levelup.habitPrefix'.tr +
                        (streakText ??
                            (habit.category ?? 'levelup.habitDailyRoutine'.tr)))
            : (date.isAfter(today)
                  ? (habit.frequency ?? 'levelup.habitDailyRoutine'.tr)
                  : (habitDone
                        ? (isWeekly
                              ? 'habits.completedThisWeek'.tr
                              : 'levelup.habitCompletedToday'.tr)
                        : (habit.category ?? 'levelup.habitDailyRoutine'.tr)));

        final isDone = isToday ? habitDone : false;

        activities.add(
          GrowthTimelineActivity(
            title: habit.title,
            type: 'levelup.categoryHabit'.tr,
            categoryKey: 'habit',
            subtitle: sub,
            time: habit.reminderTime ?? '',
            endTime: '',
            xp: habit.xpEarned,
            icon: Icons.repeat_rounded,
            color: const Color(0xFFF97316),
            completed: isDone,
            onTap: () => Get.to(() => const HabitHomeScreen()),
            onToggle: isToday && !isDone
                ? () async {
                    await widget.controller.toggleHabitCheckIn(
                      habitId: habit.habitId,
                      targetState: true,
                    );
                    await _productivityController?.reload();
                  }
                : null,
          ),
        );
      }
    } else if (widget.controller.habits.isNotEmpty) {
      for (final habit in widget.controller.habits) {
        final streakText = habit.streakCount > 0
            ? 'levelup.habitStreak'.trParams({'streak': '${habit.streakCount}'})
            : null;
        final sub = habit.checkedInToday
            ? 'levelup.habitCompletedToday'.tr +
                  (streakText != null ? ' · $streakText' : '')
            : 'levelup.habitPrefix'.tr +
                  (streakText ??
                      (habit.category ?? 'levelup.habitDailyRoutine'.tr));
        activities.add(
          GrowthTimelineActivity(
            title: habit.title,
            type: 'levelup.categoryHabit'.tr,
            categoryKey: 'habit',
            subtitle: sub,
            time: '',
            endTime: '',
            xp: 0,
            icon: Icons.repeat_rounded,
            color: const Color(0xFFF97316),
            completed: habit.checkedInToday,
            onTap: () => Get.to(() => const HabitHomeScreen()),
            onToggle: isToday
                ? () => widget.controller.toggleHabitCheckIn(
                    habitId: habit.habitId,
                    targetState: !habit.checkedInToday,
                  )
                : null,
          ),
        );
      }
    }

    // 3. Focus Sessions
    final focusSessions =
        _productivityController?.focusHistory ??
        const <ProductivityFocusSession>[];
    for (final session in focusSessions) {
      if (session.startedAt != null && _isSameDay(session.startedAt!, date)) {
        final startTimeStr =
            '${session.startedAt!.hour.toString().padLeft(2, '0')}:${session.startedAt!.minute.toString().padLeft(2, '0')}';
        final endTimeStr = session.endedAt != null
            ? '${session.endedAt!.hour.toString().padLeft(2, '0')}:${session.endedAt!.minute.toString().padLeft(2, '0')}'
            : '';
        activities.add(
          GrowthTimelineActivity(
            title: session.mode?.trim().isNotEmpty == true
                ? '${session.mode} Focus'
                : 'levelup.focus'.tr,
            type: 'levelup.categoryFocus'.tr,
            categoryKey: 'focus',
            subtitle: '${session.focusedSeconds}s · ${session.xpEarned} XP',
            time: startTimeStr,
            endTime: endTimeStr,
            xp: session.xpEarned,
            icon: Icons.timer_outlined,
            color: const Color(0xFF8B5CF6),
            completed: session.isCompleted,
            onTap: () => Get.to(() => const FocusPage()),
          ),
        );
      }
    }

    // 4. Goals
    final goals = _productivityController?.goals ?? const <ProductivityGoal>[];
    for (final goal in goals) {
      final matchesDeadline =
          goal.deadline != null && _isSameDay(goal.deadline!, date);
      final isActiveToday =
          isToday &&
          goal.progressPercentage < 100 &&
          goal.status != 'COMPLETED';

      if (matchesDeadline || isActiveToday) {
        final isGoalDone =
            goal.progressPercentage >= 100 || goal.status == 'COMPLETED';
        activities.add(
          GrowthTimelineActivity(
            title: goal.title,
            type: 'levelup.categoryGoal'.tr,
            categoryKey: 'goal',
            subtitle:
                '${goal.progressPercentage.toInt()}% · ${goal.completedMilestones}/${goal.totalMilestones} milestones',
            time: '',
            endTime: '',
            xp: 0,
            icon: Icons.flag_outlined,
            color: const Color(0xFF10B981),
            completed: isGoalDone,
            onTap: () => Get.to(() => const PlanGoalScreen()),
          ),
        );
      }
    }

    // 5. Quiz / Daily Challenge
    if (isToday) {
      final challenge = widget.home.dailyChallenge;
      if (challenge != null) {
        final challengeTitle = challenge.title.trim().isNotEmpty == true
            ? challenge.title
            : 'levelup.todaysChallenge'.tr;
        final challengeDesc = challenge.description?.trim().isNotEmpty == true
            ? challenge.description!
            : 'levelup.challengeDefaultDesc'.tr;
        activities.add(
          GrowthTimelineActivity(
            title: challengeTitle,
            type: 'levelup.categoryQuiz'.tr,
            categoryKey: 'quiz',
            subtitle: challengeDesc,
            time: '',
            endTime: '',
            xp: challenge.xpReward ?? 0,
            icon: Icons.quiz_outlined,
            color: const Color(0xFFF2B84B),
            completed: false,
            onTap: () => _handleNextMove(challenge),
          ),
        );
      }
    }

    return activities;
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _toggleDateDetail() {
    setState(() => showDateDetail = !showDateDetail);
  }

  void _handleNextMove(ChallengePreview challenge) {
    switch (challenge.resolvedType) {
      case ChallengeType.habit:
        Get.to(() => const HabitHomeScreen());
        break;

      case ChallengeType.task:
        Get.to(() => const TasksPage());
        break;

      case ChallengeType.quiz:
        Get.toNamed(AppRoutes.quizDashboard);
        break;

      case ChallengeType.finance:
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(2);
        } else {
          Get.to(() => const FinanceScreen());
        }
        break;

      case ChallengeType.focus:
        Get.to(() => const FocusPage());
        break;

      case ChallengeType.event:
      case ChallengeType.community:
      case ChallengeType.unknown:
        final id = challenge.challengeId.trim();
        if (id.isNotEmpty) {
          Get.toNamed(AppRoutes.challengeDetail, arguments: id);
        } else {
          Get.toNamed(AppRoutes.challengeList);
        }
        break;
    }
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

    // Today progress summary data
    final progress = widget.home.todayProgress;
    final habitsTotal = progress.habitsTotal;
    final habitsDone = progress.habitsCompletedToday;
    final doneCount = progress.doneCount;
    final totalCount = progress.totalCount;
    final percent = progress.percent;
    final isGoalCompleted = totalCount > 0 && doneCount >= totalCount;

    final earnedXp = progress.xpEarnedToday;

    final String statusMessage;
    final String activitiesSummary;

    if (totalCount == 0) {
      statusMessage = 'levelup.startYourDay'.tr;
      activitiesSummary = 'levelup.activitiesCount'.trParams({
        'done': '0',
        'total': '0',
      });
    } else if (isGoalCompleted) {
      statusMessage = 'levelup.dailyGoalCompleted'.tr;
      activitiesSummary = 'levelup.activitiesCompleted'.trParams({
        'done': '$doneCount',
        'total': '$totalCount',
      });
    } else if (doneCount > 0) {
      statusMessage = 'levelup.inProgress'.tr;
      activitiesSummary = 'levelup.activitiesCount'.trParams({
        'done': '$doneCount',
        'total': '$totalCount',
      });
    } else {
      statusMessage = 'levelup.startYourDay'.tr;
      activitiesSummary = 'levelup.activitiesCount'.trParams({
        'done': '0',
        'total': '$totalCount',
      });
    }

    final xpEarnedText = 'levelup.xpEarnedCount'.trParams({'xp': '$earnedXp'});

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
          onRefresh: _handleRefresh,
          color: isDark ? Colors.white : AppColors.lightPrimary,
          backgroundColor: isDark
              ? AppColors.darkSurfacePrimary
              : AppColors.lightSurfacePrimary,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs + 2,
                  AppSpacing.md,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    AppScreenHeader(
                      title: 'levelup.title'.tr,
                      subtitle: subtitle,
                      includeSafeArea: false,
                      horizontalPadding: EdgeInsets.zero,
                      actions: [
                        AppHeaderActionButton(
                          icon: Icons.emoji_events_outlined,
                          onTap: () => Get.to(
                            () => const LeaderboardHomeScreen(),
                            binding: LeaderboardBinding(),
                          ),
                          tooltip: 'quiz.leaderboard'.tr,
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
                      detailChild: Obx(() {
                        // Observe changes from controllers
                        _productivityController?.tasks.length;
                        _productivityController?.habits.length;
                        _productivityController?.goals.length;
                        _productivityController?.focusHistory.length;
                        widget.controller.habits.length;

                        final dateActivities = _buildDateActivities(
                          selectedDate,
                        );
                        return GrowthDateDetailLayout(
                          selectedDate: selectedDate,
                          today: today,
                          categories: categories,
                          activities: dateActivities,
                          onDateSelected: _selectDate,
                        );
                      }),
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

                    // TODAY'S PROGRESS (Compact Summary)
                    GrowthTodayProgressCard(
                      percentText: '$percent%',
                      progress: progress.progress,
                      statusMessage: statusMessage,
                      activitiesText: activitiesSummary,
                      xpText: xpEarnedText,
                      isCompleted: isGoalCompleted,
                      onTap: () {
                        if (!showDateDetail) {
                          _toggleDateDetail();
                        }
                      },
                    ),

                    const SizedBox(height: 14),

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

                    // PRODUCTIVITY TOOLS (GROW)
                    GrowSectionWidget(
                      onTasksTap: () => Get.to(() => const TasksPage()),
                      onHabitsTap: () => Get.to(() => const HabitHomeScreen()),
                      onGoalsTap: () => Get.to(() => const PlanGoalScreen()),
                      onFocusTap: () => Get.to(() => const FocusPage()),
                      onQuizTap: () => Get.toNamed(AppRoutes.quizDashboard),
                      onLeaderboardTap: () => Get.to(
                        () => const LeaderboardHomeScreen(),
                        binding: LeaderboardBinding(),
                      ),
                      onExploreAllTap: () =>
                          Get.to(() => const ProductivityPage()),
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
                        icon: Icons.flag_outlined,
                        accentColor: const Color(0xFFF97316),
                        title: challengeTitle,
                        subtitle: challengeDesc,
                        badgeText: xpReward != null && xpReward > 0
                            ? '+$xpReward XP'
                            : null,
                        onTap: () => _handleNextMove(challenge),
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
