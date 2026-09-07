import 'package:flutter/material.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/habit_detail_screen.dart';

class HabitStreakData {
  final int days;
  final int bestDays;
  final int weeklyCompletion;

  const HabitStreakData({
    required this.days,
    required this.bestDays,
    required this.weeklyCompletion,
  });
}

class HabitData {
  final String title;
  final int streak;
  final bool completed;
  final int completedDays;

  const HabitData({
    required this.title,
    required this.streak,
    required this.completed,
    required this.completedDays,
  });

  HabitData copyWith({
    String? title,
    int? streak,
    bool? completed,
    int? completedDays,
  }) {
    return HabitData(
      title: title ?? this.title,
      streak: streak ?? this.streak,
      completed: completed ?? this.completed,
      completedDays: completedDays ?? this.completedDays,
    );
  }
}

class HabitHomeWidget extends StatefulWidget {
  final String title;
  final HabitStreakData streak;
  final String todayTitle;
  final String manageText;
  final List<HabitData> habits;
  final String weeklyTitle;
  final List<List<int>> weeklyData;

  const HabitHomeWidget({
    super.key,
    required this.title,
    required this.streak,
    required this.todayTitle,
    required this.manageText,
    required this.habits,
    required this.weeklyTitle,
    required this.weeklyData,
  });

  @override
  State<HabitHomeWidget> createState() => _HabitHomeWidgetState();
}

class _HabitHomeWidgetState extends State<HabitHomeWidget> {
  late List<HabitData> _habits;

  @override
  void initState() {
    super.initState();

    _habits = List<HabitData>.from(widget.habits);
  }

  int get _completedToday {
    return _habits.where((habit) => habit.completed).length;
  }

  double get _todayProgress {
    if (_habits.isEmpty) {
      return 0;
    }

    return _completedToday / _habits.length;
  }

  // ============================================================
  // TOGGLE HABIT
  // ============================================================

  void _toggleHabit(int index) {
    setState(() {
      final habit = _habits[index];

      _habits[index] = habit.copyWith(completed: !habit.completed);
    });
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  Future<void> _openHabitDetail(int index) async {
    final habit = _habits[index];

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HabitDetailScreen(habit: habit, isCompletedToday: habit.completed),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null) {
      setState(() {
        _habits[index] = habit.copyWith(completed: result);
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshHabits() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding = width < 360
                ? 12.0
                : width < 400
                ? 14.0
                : 16.0;

            final titleSize = width < 360 ? 19.0 : 21.0;

            return RefreshIndicator(
              onRefresh: _refreshHabits,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              backgroundColor: isDark
                  ? AppColors.darkSurfacePrimary
                  : AppColors.lightSurfacePrimary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  10,
                  horizontalPadding,
                  28,
                ),
                children: [
                  _buildHeader(
                    titleSize: titleSize,
                    textPrimary: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    inverseText: isDark
                        ? AppColors.darkTextInverse
                        : AppColors.lightTextInverse,
                    width: width,
                  ),

                  const SizedBox(height: 16),

                  _buildStreakCard(isDark: isDark),

                  const SizedBox(height: 18),

                  _buildTodayHeader(isDark: isDark),

                  const SizedBox(height: 9),

                  if (_habits.isEmpty)
                    _buildEmptyState(isDark: isDark)
                  else
                    ...List.generate(_habits.length, (index) {
                      return _buildHabitCard(
                        habit: _habits[index],
                        index: index,
                        isDark: isDark,
                      );
                    }),

                  const SizedBox(height: 7),

                  _buildWeeklyHeader(isDark: isDark),

                  const SizedBox(height: 9),

                  _buildWeeklyCard(isDark: isDark),

                  const SizedBox(height: 18),

                  _buildMotivationCard(isDark: isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required double titleSize,
    required Color textPrimary,
    required Color inverseText,
    required double width,
  }) {
    final buttonSize = width < 360 ? 38.0 : 40.0;

    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const AppBackButton(),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateHabitScreen()),
                );

                if (!mounted) return;

                if (result is HabitData) {
                  setState(() {
                    // habits.add(result);
                    // completed.add(false);
                  });
                }
              },
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: inverseText,
                  size: width < 360 ? 20 : 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STREAK CARD
  // ============================================================

  Widget _buildStreakCard({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final primarySoft = isDark
        ? AppColors.darkPrimarySoft
        : AppColors.lightPrimarySoft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  color: textPrimary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: TextStyle(color: textMuted, fontSize: 9),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${widget.streak.days} days',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Best', style: TextStyle(color: textMuted, fontSize: 9)),

                  const SizedBox(height: 2),

                  Text(
                    '${widget.streak.bestDays} days',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _todayProgress,
                    minHeight: 5,
                    backgroundColor: primarySoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.productivityAccent,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Text(
                '${widget.streak.weeklyCompletion}%',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY HEADER
  // ============================================================

  Widget _buildTodayHeader({required bool isDark}) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.todayTitle,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Text(
          '$_completedToday/${_habits.length}',
          style: TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HABIT CARD
  // ============================================================

  Widget _buildHabitCard({
    required HabitData habit,
    required int index,
    required bool isDark,
  }) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openHabitDetail(index),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Row(
              children: [
                // CHECK
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _toggleHabit(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.completed ? textPrimary : secondarySurface,
                      border: Border.all(
                        color: habit.completed ? textPrimary : border,
                      ),
                    ),
                    child: habit.completed
                        ? Icon(
                            Icons.check_rounded,
                            size: 17,
                            color: inverseText,
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 11),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: habit.completed ? textMuted : textPrimary,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          decoration: habit.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: textMuted,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_outlined,
                            size: 11,
                            color: textMuted,
                          ),

                          const SizedBox(width: 3),

                          Text(
                            '${habit.streak} day streak',
                            style: TextStyle(color: textMuted, fontSize: 9),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '${habit.completedDays}/7',
                            style: TextStyle(color: textMuted, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 7),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(Icons.repeat_rounded, size: 30, color: textMuted),

          const SizedBox(height: 9),

          Text(
            'No habits yet',
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Create your first habit to start your routine.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEEKLY HEADER
  // ============================================================

  Widget _buildWeeklyHeader({required bool isDark}) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Text(
      widget.weeklyTitle,
      style: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // WEEKLY CARD
  // ============================================================

  Widget _buildWeeklyCard({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 7),

          if (widget.weeklyData.isEmpty)
            const SizedBox(height: 30)
          else
            Column(
              children: [
                for (int row = 0; row < widget.weeklyData.length; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        for (int column = 0; column < 7; column++)
                          Expanded(
                            child: Center(
                              child: _buildHeatCell(
                                value: widget.weeklyData[row][column],
                                isDark: isDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HEAT CELL
  // ============================================================

  Widget _buildHeatCell({required int value, required bool isDark}) {
    return Container(
      width: 24,
      height: 20,
      decoration: BoxDecoration(
        color: _heatColor(value, isDark),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Color _heatColor(int value, bool isDark) {
    switch (value.clamp(0, 3)) {
      case 1:
        return isDark ? const Color(0xFF303030) : const Color(0xFFD9D9D9);

      case 2:
        return isDark ? const Color(0xFF555555) : const Color(0xFFBDBDBD);

      case 3:
        return isDark ? const Color(0xFF888888) : const Color(0xFF8D8D8D);

      case 0:
      default:
        return isDark
            ? AppColors.darkPrimarySoft
            : AppColors.lightSurfaceSecondary;
    }
  }

  // ============================================================
  // MOTIVATION
  // ============================================================

  Widget _buildMotivationCard({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 19, color: textPrimary),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Small habits become big results. '
                  'Stay consistent every day.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    height: 1.35,
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
