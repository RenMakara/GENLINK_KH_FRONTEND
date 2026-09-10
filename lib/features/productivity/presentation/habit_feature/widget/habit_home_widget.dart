import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';


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
  late List<bool> completedHabits;

  @override
  void initState() {
    super.initState();

    completedHabits = widget.habits.map((habit) => habit.completed).toList();
  }

  void _toggleHabit(int index) {
    setState(() {
      completedHabits[index] = !completedHabits[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Scaffold(
      backgroundColor: colors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HabitHeader(title: widget.title),

              const SizedBox(height: 18),

              _StreakCard(data: widget.streak),

              const SizedBox(height: 18),

              _SectionHeader(
                title: widget.todayTitle,
                actionText: widget.manageText,
              ),

              const SizedBox(height: 8),

              _TodayHabitsCard(
                habits: widget.habits,
                completedHabits: completedHabits,
                onToggle: _toggleHabit,
              ),

              const SizedBox(height: 18),

              _SectionHeader(title: widget.weeklyTitle),

              const SizedBox(height: 8),

              _WeeklyOverviewCard(data: widget.weeklyData),
            ],
          ),
        ),
      ),
    );
  }
}


class _HabitColors {
  final bool isDark;

  _HabitColors(this.isDark);

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

  Color get surfaceSecondary =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}


class _HabitHeader extends StatelessWidget {
  final String title;

  const _HabitHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Text(
      title,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}


class _StreakCard extends StatelessWidget {
  final HabitStreakData data;

  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final _ = _HabitColors(Theme.of(context).brightness == Brightness.dark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFFB43B),
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.days}-day streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Keep it up! Best: ${data.bestDays} days',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .62),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: data.weeklyCompletion / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .18),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD7D0C4)),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly completion',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .55),
                  fontSize: 8,
                ),
              ),
              Text(
                '${data.weeklyCompletion}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;

  const _SectionHeader({required this.title, this.actionText});

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (actionText != null)
          Text(
            actionText!,
            style: TextStyle(color: colors.textMuted, fontSize: 8),
          ),
      ],
    );
  }
}


class _TodayHabitsCard extends StatelessWidget {
  final List<HabitData> habits;
  final List<bool> completedHabits;
  final ValueChanged<int> onToggle;

  const _TodayHabitsCard({
    required this.habits,
    required this.completedHabits,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? .10 : .04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < habits.length; index++) ...[
            _HabitTile(
              data: habits[index],
              completed: completedHabits[index],
              onToggle: () => onToggle(index),
            ),

            if (index < habits.length - 1)
              Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}


class _HabitTile extends StatelessWidget {
  final HabitData data;
  final bool completed;
  final VoidCallback onToggle;

  const _HabitTile({
    required this.data,
    required this.completed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.growthAccent
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed
                        ? AppColors.growthAccent
                        : colors.textMuted,
                  ),
                ),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 9,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  _ProgressDots(completedDays: data.completedDays),
                ],
              ),
            ),

            _StreakBadge(days: data.streak),
          ],
        ),
      ),
    );
  }
}


class _ProgressDots extends StatelessWidget {
  final int completedDays;

  const _ProgressDots({required this.completedDays});

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: List.generate(7, (index) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index < completedDays
                ? const Color(0xFFBDB5A9)
                : colors.surfaceSecondary,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}


class _StreakBadge extends StatelessWidget {
  final int days;

  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 9,
            color: Color(0xFFFFB43B),
          ),

          const SizedBox(width: 2),

          Text(
            '${days}d',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class _WeeklyOverviewCard extends StatelessWidget {
  final List<List<int>> data;

  const _WeeklyOverviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = _HabitColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? .10 : .04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final row in data)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  for (final level in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AspectRatio(
                          aspectRatio: 1.35,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _heatmapColor(colors, level),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _heatmapColor(_HabitColors colors, int level) {
    if (colors.isDark) {
      switch (level) {
        case 1:
          return const Color(0xFF4B4842);
        case 2:
          return const Color(0xFF686157);
        case 3:
          return const Color(0xFF8B8174);
        default:
          return colors.surfaceSecondary;
      }
    }

    switch (level) {
      case 1:
        return const Color(0xFFE9E6E0);
      case 2:
        return const Color(0xFFD8D3CA);
      case 3:
        return const Color(0xFFC9C2B7);
      default:
        return const Color(0xFFF6F5F2);
    }
  }
}
