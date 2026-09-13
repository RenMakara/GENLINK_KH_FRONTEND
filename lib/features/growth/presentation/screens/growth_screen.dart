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

// ============================================================
// MAIN CONTENT
// ============================================================

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
    setState(() {
      showDateDetail = !showDateDetail;
    });
  }

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
                  // =====================================================
                  // HEADER + MERGED DATE CARD
                  // =====================================================
                  _GrowthHeader(
                    user: widget.home.user,
                    selectedDate: selectedDate,
                    today: today,
                    showDateDetail: showDateDetail,
                    onDateSelected: _selectDate,
                    onToggleDetail: _toggleDateDetail,
                  ),

                  const SizedBox(height: 14),

                  // =====================================================
                  // LEVEL PROGRESS
                  // =====================================================
                  _LevelProgressCard(user: widget.home.user),

                  const SizedBox(height: 14),

                  // =====================================================
                  // TODAY CHECKLIST
                  // =====================================================
                  _GrowthTodayChecklist(
                    home: widget.home,
                    controller: widget.controller,
                    onNavigateTab: widget.onNavigateTab,
                  ),

                  const SizedBox(height: 12),

                  // =====================================================
                  // IMPORTANT ALERTS
                  // =====================================================
                  _GrowthImportantAlerts(
                    home: widget.home,
                    controller: widget.controller,
                  ),

                  const SizedBox(height: 2),

                  // =====================================================
                  // PRODUCTIVITY TOOLS
                  // =====================================================
                  _ProductivityTools(onNavigateTab: widget.onNavigateTab),

                  const SizedBox(height: AppSpacing.lg),

                  // =====================================================
                  // YOUR NEXT MOVE
                  // =====================================================
                  _GrowthYourNextStepSection(
                    home: widget.home,
                    onNavigateTab: widget.onNavigateTab,
                  ),

                  if (widget.home.dailyMotivation != null &&
                      (widget.home.dailyMotivation?.content
                              ?.trim()
                              .isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _DailyMindsetCard(motivation: widget.home.dailyMotivation!),
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

// ============================================================
// HEADER
// ============================================================

class _GrowthHeader extends StatelessWidget {
  const _GrowthHeader({
    required this.user,
    required this.selectedDate,
    required this.today,
    required this.showDateDetail,
    required this.onDateSelected,
    required this.onToggleDetail,
  });

  final HomeUser user;
  final DateTime selectedDate;
  final DateTime today;
  final bool showDateDetail;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onToggleDetail;

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

    final subtitle = user.fullName?.trim().isNotEmpty == true
        ? 'Welcome, ${user.fullName!.trim().split(' ').first} · Your personal growth journey'
        : 'Your personal growth journey';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // TOP HEADER
        // ==========================================================
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEVEL UP',
                    style: TextStyle(
                      color: textPrimary,
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
                      color: textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // LEADERBOARD
            _GrowthHeaderIconButton(
              icon: Icons.emoji_events_outlined,
              onTap: () {
                Get.to(
                  () => const LeaderboardHomeScreen(),
                  binding: LeaderboardBinding(),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ==========================================================
        // ONE MERGED DATE CARD
        // ==========================================================
        _GrowthDateCard(
          today: today,
          selectedDate: selectedDate,
          showDateDetail: showDateDetail,
          onDateSelected: onDateSelected,
          onToggleDetail: onToggleDetail,
        ),
      ],
    );
  }
}

// ============================================================
// HEADER ICON BUTTON
// ============================================================

class _GrowthHeaderIconButton extends StatelessWidget {
  const _GrowthHeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: border, width: 0.8),
          ),
          child: Icon(icon, size: 20, color: textPrimary),
        ),
      ),
    );
  }
}

// ============================================================
// MERGED DATE CARD
// ============================================================

class _GrowthDateCard extends StatelessWidget {
  const _GrowthDateCard({
    required this.today,
    required this.selectedDate,
    required this.showDateDetail,
    required this.onDateSelected,
    required this.onToggleDetail,
  });

  final DateTime today;
  final DateTime selectedDate;
  final bool showDateDetail;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onToggleDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 0.8),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ======================================================
          // DATE HEADER
          // ======================================================
          _GrowthDateCardHeader(
            selectedDate: selectedDate,
            showDateDetail: showDateDetail,
            onToggleDetail: onToggleDetail,
          ),

          // ======================================================
          // FIXED 7-DAY STRIP
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
            child: _GrowthDateStrip(
              today: today,
              selectedDate: selectedDate,
              onDateSelected: onDateSelected,
            ),
          ),

          // ======================================================
          // SLIDE DOWN DETAIL
          // ======================================================
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showDateDetail
                ? _GrowthDateDetailInsideCard(
                    selectedDate: selectedDate,
                    today: today,
                    onDateSelected: onDateSelected,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATE CARD HEADER
// ============================================================

class _GrowthDateCardHeader extends StatelessWidget {
  const _GrowthDateCardHeader({
    required this.selectedDate,
    required this.showDateDetail,
    required this.onToggleDetail,
  });

  final DateTime selectedDate;
  final bool showDateDetail;
  final VoidCallback onToggleDetail;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleDetail,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 7),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 17,
                  color: textPrimary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthYear(selectedDate),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      showDateDetail ? 'Hide day details' : 'View day details',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedRotation(
                turns: showDateDetail ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

// ============================================================
// DATE STRIP
// ============================================================

class _GrowthDateStrip extends StatelessWidget {
  const _GrowthDateStrip({
    required this.today,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    //
    // The strip ALWAYS starts from TODAY.
    //
    // selectedDate is ONLY used to determine which date
    // is highlighted.
    //
    // Therefore selecting another date will NOT move
    // the seven dates.

    final base = DateTime(today.year, today.month, today.day);

    final dates = List.generate(7, (index) => base.add(Duration(days: index)));

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          for (final date in dates)
            Expanded(
              child: _GrowthDateButton(
                date: date,
                selected: _sameDay(date, selectedDate),
                onTap: () {
                  onDateSelected(date);
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ============================================================
// DATE BUTTON
// ============================================================

class _GrowthDateButton extends StatelessWidget {
  const _GrowthDateButton({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekdays[date.weekday % 7],
            style: TextStyle(
              color: textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF111111))
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: border, width: 0.7),
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: selected
                    ? (isDark ? Colors.black : Colors.white)
                    : textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 3),

          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF97316)
                  : const Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATE DETAIL INSIDE SAME CARD
// ============================================================

class _GrowthDateDetailInsideCard extends StatefulWidget {
  const _GrowthDateDetailInsideCard({
    required this.selectedDate,
    required this.today,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_GrowthDateDetailInsideCard> createState() =>
      _GrowthDateDetailInsideCardState();
}

class _GrowthDateDetailInsideCardState
    extends State<_GrowthDateDetailInsideCard> {
  int selectedCategory = 0;
  int selectedActivity = 0;

  final List<_GrowthCategory> categories = const [
    _GrowthCategory(
      label: 'All',
      icon: Icons.apps_rounded,
      color: Color(0xFF777777),
    ),
    _GrowthCategory(
      label: 'Task',
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF3B82F6),
    ),
    _GrowthCategory(
      label: 'Habit',
      icon: Icons.repeat_rounded,
      color: Color(0xFFF97316),
    ),
    _GrowthCategory(
      label: 'Focus',
      icon: Icons.timer_outlined,
      color: Color(0xFF8B5CF6),
    ),
    _GrowthCategory(
      label: 'Goal',
      icon: Icons.flag_outlined,
      color: Color(0xFF10B981),
    ),
    _GrowthCategory(
      label: 'Quiz',
      icon: Icons.quiz_outlined,
      color: Color(0xFFF2B84B),
    ),
  ];

  final List<_GrowthTimelineActivity> activities = const [
    _GrowthTimelineActivity(
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
    _GrowthTimelineActivity(
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
    _GrowthTimelineActivity(
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
    _GrowthTimelineActivity(
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
    _GrowthTimelineActivity(
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final filteredActivities = selectedCategory == 0
        ? activities
        : activities
              .where((item) => item.type == categories[selectedCategory].label)
              .toList();

    final safeSelectedActivity = filteredActivities.isEmpty
        ? 0
        : selectedActivity.clamp(0, filteredActivities.length - 1);

    final activity = filteredActivities.isEmpty
        ? null
        : filteredActivities[safeSelectedActivity];

    final completedCount = filteredActivities
        .where((item) => item.completed)
        .length;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.7)),
      ),
      child: Column(
        children: [
          // ======================================================
          // DETAIL HEADER
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 9),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.045),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.today_rounded,
                          size: 16,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(widget.selectedDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your activity for this day',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // DONE COUNT
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.035),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${completedCount}/${filteredActivities.length} Done',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // NEXT DATE
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onDateSelected(
                        widget.selectedDate.add(const Duration(days: 1)),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // CATEGORY FILTERS
          // ======================================================
          _buildCategoryFilters(textSecondary: textSecondary, isDark: isDark),

          // ======================================================
          // TIMELINE
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
            child: _buildTimeline(isDark: isDark, textSecondary: textSecondary),
          ),

          // ======================================================
          // SELECTED ACTIVITY
          // ======================================================
          if (activity != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: _buildActivityCard(
                activity: activity,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // CATEGORY FILTERS
  // ==========================================================

  Widget _buildCategoryFilters({
    required Color textSecondary,
    required bool isDark,
  }) {
    return SizedBox(
      height: 55,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = index;
                selectedActivity = 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 45,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? category.color.withValues(alpha: 0.16)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      size: 15,
                      color: selected ? category.color : textSecondary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    category.label,
                    style: TextStyle(
                      color: selected ? category.color : textSecondary,
                      fontSize: 7.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // TIMELINE
  // ==========================================================

  Widget _buildTimeline({required bool isDark, required Color textSecondary}) {
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final positions = [8.0, 62.0, 112.0, 174.0, 238.0];

    return SizedBox(
      height: 305,
      child: Stack(
        children: [
          Column(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          _timelineTime(i),
                          style: TextStyle(
                            color: textSecondary.withValues(alpha: 0.65),
                            fontSize: 7.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: lineColor, width: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // VERTICAL TIMELINE
          Positioned(
            left: 65,
            top: 5,
            bottom: 5,
            child: Container(
              width: 1.2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.10),
            ),
          ),

          // NODES
          for (int i = 0; i < activities.length; i++)
            _timelineNode(
              index: i,
              activity: activities[i],
              position: positions[i],
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // TIMELINE NODE
  // ==========================================================

  Widget _timelineNode({
    required int index,
    required _GrowthTimelineActivity activity,
    required double position,
    required bool isDark,
  }) {
    final selected = selectedActivity == index;

    return Positioned(
      left: 52,
      top: position,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedActivity = index;
          });
        },
        child: Row(
          children: [
            Container(
              width: 13,
              height: 1,
              color: activity.color.withValues(alpha: 0.45),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 30 : 24,
              height: selected ? 30 : 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activity.color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color: isDark ? Colors.white : Colors.black,
                        width: 2,
                      )
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: activity.color.withValues(alpha: 0.28),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                activity.icon,
                size: selected ? 14 : 12,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 8),

            if (selected)
              Container(
                constraints: const BoxConstraints(maxWidth: 145),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.65)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isDark ? null : AppShadows.cardLight,
                ),
                child: Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIVITY CARD
  // ==========================================================

  Widget _buildActivityCard({
    required _GrowthTimelineActivity activity,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.025)
        : Colors.black.withValues(alpha: 0.018);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: activity.color.withValues(
                      alpha: isDark ? 0.17 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(activity.icon, color: activity.color, size: 20),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(width: 7),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: activity.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              activity.type,
                              style: TextStyle(
                                color: activity.color,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      Text(
                        activity.subtitle,
                        style: TextStyle(color: textSecondary, fontSize: 10.5),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.time} - ${activity.endTime}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 9.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '+${activity.xp} XP',
                            style: TextStyle(
                              color: activity.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildProgress(
            isDark: isDark,
            textSecondary: textSecondary,
            activity: activity,
          ),

          const SizedBox(height: 10),

          _buildActions(
            textPrimary: textPrimary,
            isDark: isDark,
            activity: activity,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==========================================================
  // PROGRESS
  // ==========================================================

  Widget _buildProgress({
    required bool isDark,
    required Color textSecondary,
    required _GrowthTimelineActivity activity,
  }) {
    final filtered = selectedCategory == 0
        ? activities
        : activities
              .where((item) => item.type == categories[selectedCategory].label)
              .toList();

    final completed = filtered.where((item) => item.completed).length;

    final total = filtered.length;

    final progress = total == 0 ? 0.0 : completed / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progress',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$completed / $total completed',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(activity.color),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Widget _buildActions({
    required Color textPrimary,
    required bool isDark,
    required _GrowthTimelineActivity activity,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _smallActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onTap: () {
                _showMessage('Edit ${activity.title}');
              },
              isDark: isDark,
              filled: false,
              textPrimary: textPrimary,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: _smallActionButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              onTap: () {
                _showMessage('Delete ${activity.title}');
              },
              isDark: isDark,
              filled: false,
              textPrimary: textPrimary,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            flex: 2,
            child: _smallActionButton(
              label: activity.completed ? 'Completed' : 'Mark as Done',
              icon: activity.completed
                  ? Icons.check_circle_rounded
                  : Icons.check_rounded,
              onTap: () {
                _showMessage(
                  activity.completed ? 'Already completed' : 'Marked as done',
                );
              },
              isDark: isDark,
              filled: true,
              textPrimary: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required bool filled,
    required Color textPrimary,
  }) {
    final background = filled
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.035));

    final foreground = filled
        ? (isDark ? Colors.black : Colors.white)
        : textPrimary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 1),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _timelineTime(int index) {
    switch (index) {
      case 0:
        return '8 AM';
      case 1:
        return '10 AM';
      case 2:
        return '12 PM';
      case 3:
        return '2 PM';
      case 4:
        return '4 PM';
      case 5:
        return '6 PM';
      case 6:
        return '8 PM';
      default:
        return '';
    }
  }
}

// ============================================================
// LEVEL PROGRESS
// ============================================================

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.user});

  final HomeUser user;

  static const Color growthAccent = Color(0xFFF2B84B);

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

    final xpDiff = user.xpForNextLevel - user.safeTotalXp;

    final progressCopy = xpDiff > 0
        ? 'Only $xpDiff XP to Level $nextLevel'
        : 'Progress toward Level $nextLevel';

    return Material(
      color: cardSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () {
          Get.to(
            () => const LeaderboardHomeScreen(),
            binding: LeaderboardBinding(),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
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
                          color: growthAccent.withValues(
                            alpha: isDark ? 0.16 : 0.12,
                          ),
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
                    style: const TextStyle(
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

// ============================================================
// TODAY CHECKLIST
// ============================================================

class _TimelineActivityItem {
  const _TimelineActivityItem({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
    this.onToggle,
  }) : xpReward = null;

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

  static const Color habitAccent = Color(0xFFF97316);

  static const Color taskAccent = Color(0xFF3B82F6);

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
        'home.todayJourney'.tr.isNotEmpty &&
            'home.todayJourney'.tr != 'home.todayJourney'
        ? 'home.todayJourney'.tr.toUpperCase()
        : "TODAY'S JOURNEY";

    final habitsTotal = progress.habitsTotal;

    final habitsDone = progress.habitsCompletedToday;

    final tasksTotal = progress.tasksTotal;

    final tasksDone = progress.tasksCompleted;

    final percent = progress.percent;

    final habitItems = controller.habits;

    final activities = <_TimelineActivityItem>[];

    // ==========================================================
    // HABITS
    // ==========================================================

    if (habitItems.isNotEmpty) {
      for (final habit in habitItems) {
        final streakText = habit.streakCount > 0
            ? '${habit.streakCount} day streak'
            : null;

        final subtitle = habit.checkedInToday
            ? 'Habit · Completed today'
                  '${streakText != null ? ' · $streakText' : ''}'
            : 'Habit · '
                  '${streakText ?? (habit.category ?? 'Daily routine')}';

        activities.add(
          _TimelineActivityItem(
            title: habit.title,
            subtitle: subtitle,
            isCompleted: habit.checkedInToday,
            accentColor: habitAccent,
            onTap: () {
              Get.to(() => const HabitHomeScreen());
            },
            onToggle: () {
              controller.toggleHabitCheckIn(
                habitId: habit.habitId,
                targetState: !habit.checkedInToday,
              );
            },
          ),
        );
      }
    } else if (habitsTotal > 0) {
      final isHabitDone = habitsDone >= habitsTotal;

      final title =
          'home.rowHabits'.tr.isNotEmpty &&
              'home.rowHabits'.tr != 'home.rowHabits'
          ? 'home.rowHabits'.tr
          : 'Check in your habits';

      activities.add(
        _TimelineActivityItem(
          title: title,
          subtitle: 'Habit · $habitsDone of $habitsTotal completed',
          isCompleted: isHabitDone,
          accentColor: habitAccent,
          onTap: () {
            Get.to(() => const HabitHomeScreen());
          },
          onToggle: () {
            controller.toggleHabitCheckIn();
          },
        ),
      );
    }

    // ==========================================================
    // TASKS
    // ==========================================================

    if (tasksTotal > 0) {
      final isTaskDone = tasksDone >= tasksTotal;

      final title = isTaskDone
          ? "Today's tasks completed"
          : 'Finish today\'s tasks';

      final subtitle = isTaskDone
          ? 'Task · All $tasksTotal completed'
          : 'Task · $tasksDone of $tasksTotal completed';

      activities.add(
        _TimelineActivityItem(
          title: title,
          subtitle: subtitle,
          isCompleted: isTaskDone,
          accentColor: taskAccent,
          onTap: () {
            Get.to(() => const TasksPage());
          },
        ),
      );
    }

    final isAllEmpty = activities.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    style: TextStyle(color: textSecondary, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isAllEmpty)
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

        const SizedBox(height: 10),

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
                  children: [
                    for (int i = 0; i < activities.length; i++)
                      _TimelineItemRow(
                        item: activities[i],
                        isLast: i == activities.length - 1,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                        borderSubtle: borderSubtle,
                        isDark: isDark,
                      ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily progress',
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

  Widget _buildAllCaughtUpEmptyState({
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final primary = isDark ? Colors.white : AppColors.lightPrimary;

    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.check_rounded, size: 18, color: primary),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

// ============================================================
// TIMELINE ITEM ROW
// ============================================================

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
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
                                  : AppColors.lightPrimary.withValues(
                                      alpha: 0.14,
                                    ))
                            : Colors.transparent,
                        border: Border.all(
                          color: item.isCompleted
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : AppColors.lightPrimary.withValues(
                                        alpha: 0.4,
                                      ))
                              : (isDark ? Colors.white38 : Colors.black38),
                          width: 1.4,
                        ),
                      ),
                      child: item.isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightPrimary,
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

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8, top: 1),
                  child: Row(
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
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (item.xpReward != null && item.xpReward! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '+${item.xpReward} XP',
                          style: const TextStyle(
                            color: Color(0xFFF2B84B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],

                      const SizedBox(width: 7),

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

// ============================================================
// IMPORTANT ALERTS
// ============================================================

class _GrowthImportantAlerts extends StatelessWidget {
  const _GrowthImportantAlerts({required this.home, required this.controller});

  final HomeEntity home;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final habitsTotal = home.todayProgress.habitsTotal;

    final habitsDone = home.todayProgress.habitsCompletedToday;

    final isStreakAtRisk =
        habitsTotal > 0 &&
        habitsDone < habitsTotal &&
        controller.habits.any((h) => !h.checkedInToday && h.streakCount > 0);

    if (!isStreakAtRisk) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GrowthAlertCard(
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFF97316),
        title: 'Habit Streak at Risk',
        message: "Complete today's habit check-in to protect your streak!",
        actionText: 'Tap → Check in habits',
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        isDark: isDark,
        onTap: () {
          Get.to(() => const HabitHomeScreen());
        },
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
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? iconColor.withValues(alpha: 0.28) : borderSubtle,
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

// ============================================================
// GROW TOOLS
// ============================================================

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
        color: const Color(0xFFF97316),
        onTap: () {
          Get.to(() => const HabitHomeScreen());
        },
      ),
      (
        icon: Icons.check_circle_outline_rounded,
        label: 'Tasks',
        color: const Color(0xFF3B82F6),
        onTap: () {
          Get.to(() => const TasksPage());
        },
      ),
      (
        icon: Icons.timer_outlined,
        label: 'Focus',
        color: const Color(0xFF06B6D4),
        onTap: () {
          Get.to(() => const FocusPage());
        },
      ),
      (
        icon: Icons.flag_outlined,
        label: 'Goals',
        color: const Color(0xFF10B981),
        onTap: () {
          Get.to(() => const PlanGoalScreen());
        },
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
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            for (int i = 0; i < tools.length; i++) ...[
              Expanded(
                child: _ToolTile(
                  icon: tools[i].icon,
                  label: tools[i].label,
                  accentColor: tools[i].color,
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

// ============================================================
// YOUR NEXT MOVE
// ============================================================

class _GrowthYourNextStepSection extends StatelessWidget {
  const _GrowthYourNextStepSection({required this.home, this.onNavigateTab});

  final HomeEntity home;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    if (home.dailyChallenge == null) {
      return const SizedBox.shrink();
    }

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
              ),
            ),
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

        const SizedBox(height: 10),

        _GrowthActionCard(
          icon: Icons.quiz_outlined,
          accentColor: const Color(0xFFF97316),
          title: challengeTitle,
          subtitle: challengeDesc,
          badgeText: xpReward != null && xpReward > 0 ? '+$xpReward XP' : null,
          cardSurface: cardSurface,
          borderSubtle: borderSubtle,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
          onTap: () {
            Get.toNamed(AppRoutes.quizDashboard);
          },
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderSubtle, width: 0.8),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: Row(
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

              const SizedBox(width: 12),

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
                          Text(
                            badgeText!,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
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

              const SizedBox(width: 7),

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

// ============================================================
// DAILY MINDSET
// ============================================================

class _DailyMindsetCard extends StatelessWidget {
  const _DailyMindsetCard({required this.motivation});

  final MotivationCard motivation;

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

    const accent = Color(0xFF8B5CF6);

    final title = motivation.title?.trim().isNotEmpty ?? false
        ? motivation.title!
        : 'Daily Mindset';

    final content = motivation.content ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderSubtle, width: 0.8),
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
              color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              size: 18,
              color: accent,
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
                    color: accent,
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

// ============================================================
// MODELS
// ============================================================

class _GrowthCategory {
  const _GrowthCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _GrowthTimelineActivity {
  const _GrowthTimelineActivity({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.endTime,
    required this.type,
    required this.icon,
    required this.color,
    required this.completed,
    required this.xp,
  });

  final String title;
  final String subtitle;
  final String time;
  final String endTime;
  final String type;
  final IconData icon;
  final Color color;
  final bool completed;
  final int xp;
}

// ============================================================
// SKELETON
// ============================================================

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
            AppSpacing.xs + 2,
            AppSpacing.md,
            120,
          ),
          children: [
            SizedBox(
              height: 44,
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

            const SizedBox(height: 12),

            Container(
              height: 130,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle, width: 0.8),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              height: 150,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderSubtle, width: 0.8),
              ),
            ),

            const SizedBox(height: 14),

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

// ============================================================
// ERROR
// ============================================================

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
