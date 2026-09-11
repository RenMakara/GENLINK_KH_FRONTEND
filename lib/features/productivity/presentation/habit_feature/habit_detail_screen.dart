import 'package:flutter/material.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/widget/habit_home_widget.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitData habit;
  final bool isCompletedToday;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.isCompletedToday,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late bool _isCompletedToday;

  @override
  void initState() {
    super.initState();
    _isCompletedToday = widget.isCompletedToday;
  }

  // ============================================================
  // TOGGLE TODAY
  // ============================================================

  void _toggleToday() {
    setState(() {
      _isCompletedToday = !_isCompletedToday;
    });
  }

  // ============================================================
  // CLOSE
  // ============================================================

  void _closeDetail() {
    Navigator.pop(context, _isCompletedToday);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _closeDetail();
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: RefreshIndicator(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            backgroundColor: isDark
                ? AppColors.darkSurfacePrimary
                : AppColors.lightSurfacePrimary,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));

              if (mounted) {
                setState(() {});
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final horizontalPadding = width < 360
                    ? 12.0
                    : width < 400
                    ? 14.0
                    : 16.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        36,
                      ),
                      children: [
                        // =================================================
                        // HEADER
                        // =================================================
                        _buildHeader(isDark: isDark),

                        const SizedBox(height: 18),

                        // =================================================
                        // SUMMARY
                        // =================================================
                        _buildSummaryCard(isDark: isDark),

                        const SizedBox(height: 20),

                        // =================================================
                        // THIS WEEK
                        // =================================================
                        _buildSectionHeader(title: 'This Week', isDark: isDark),

                        const SizedBox(height: 10),

                        _buildWeekCard(isDark: isDark),

                        const SizedBox(height: 20),

                        // =================================================
                        // MONTHLY HEATMAP
                        // =================================================
                        _buildSectionHeader(
                          title: 'Monthly Heatmap',
                          isDark: isDark,
                        ),

                        const SizedBox(height: 10),

                        _buildMonthlyHeatmap(isDark: isDark, width: width),

                        const SizedBox(height: 20),

                        // =================================================
                        // NOTES
                        // =================================================
                        _buildNotesCard(isDark: isDark),

                        const SizedBox(height: 20),

                        // =================================================
                        // TODAY ACTION
                        // =================================================
                        _buildTodayAction(isDark: isDark),

                        const SizedBox(height: 12),

                        // =================================================
                        // BOTTOM BUTTONS
                        // =================================================
                        _buildBottomButtons(isDark: isDark),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({required bool isDark}) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        GestureDetector(onTap: _closeDetail, child: const AppBackButton()),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            'Habit Detail',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(width: 10),

        GestureDetector(
          onTap: () {
            // TODO: Edit habit
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.lightSurfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderSubtle
                    : AppColors.lightBorderSubtle,
              ),
            ),
            child: Icon(Icons.edit_outlined, color: textSecondary, size: 20),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard({required bool isDark}) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final primarySoft = isDark
        ? AppColors.darkPrimarySoft
        : AppColors.lightPrimarySoft;

    final completion = _calculateCompletion();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productivity · Daily',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: secondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.habit.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: inverseText,
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                '$completion%',
                style: TextStyle(
                  color: inverseText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 15,
                color: AppColors.productivityAccent,
              ),

              const SizedBox(width: 5),

              Text(
                '${widget.habit.streak}-day streak',
                style: TextStyle(
                  color: inverseText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 12),

              Text(
                '$completion% completion',
                style: TextStyle(color: secondary, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 11),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 6,
              backgroundColor: primarySoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.productivityAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({required String title, required bool isDark}) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // WEEK CARD
  // ============================================================

  Widget _buildWeekCard({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final completedDays = widget.habit.completedDays.clamp(0, 7);

    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < 7; i++)
            Column(
              children: [
                Text(
                  days[i],
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < completedDays
                        ? AppColors.productivityAccent
                        : secondarySurface,
                    border: Border.all(
                      color: i < completedDays
                          ? AppColors.productivityAccent
                          : border,
                    ),
                  ),
                  child: i < completedDays
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTHLY HEATMAP
  // ============================================================

  Widget _buildMonthlyHeatmap({required bool isDark, required double width}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final columns = width < 360
        ? 12
        : width < 400
        ? 14
        : 16;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 84,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final value = _monthlyHeatValue(index);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _heatmapColor(value, isDark),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEATMAP VALUE
  // ============================================================

  int _monthlyHeatValue(int index) {
    final completedDays = widget.habit.completedDays.clamp(0, 7);

    if (completedDays == 0) {
      return 0;
    }

    final pattern = (index + completedDays) % 7;

    if (pattern < completedDays) {
      return 3;
    }

    if (pattern == completedDays) {
      return 2;
    }

    if (index % 5 == 0) {
      return 1;
    }

    return 0;
  }

  // ============================================================
  // HEATMAP COLOR
  // ============================================================

  Color _heatmapColor(int value, bool isDark) {
    switch (value.clamp(0, 3)) {
      case 1:
        return isDark ? const Color(0xFF303030) : const Color(0xFFD7D7D7);

      case 2:
        return isDark ? const Color(0xFF555555) : const Color(0xFFB9B9B9);

      case 3:
        return AppColors.productivityAccent;

      case 0:
      default:
        return isDark
            ? AppColors.darkPrimarySoft
            : AppColors.lightSurfaceSecondary;
    }
  }

  // ============================================================
  // NOTES CARD
  // ============================================================

  Widget _buildNotesCard({required bool isDark}) {
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Keep working on this habit every day.\n'
            'Consistency is more important than perfection.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textSecondary, fontSize: 11, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY ACTION
  // ============================================================

  Widget _buildTodayAction({required bool isDark}) {
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: _toggleToday,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _isCompletedToday ? primary : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _isCompletedToday ? primary : border),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCompletedToday
                    ? AppColors.productivityAccent
                    : Colors.transparent,
                border: Border.all(
                  color: _isCompletedToday
                      ? AppColors.productivityAccent
                      : textMuted,
                  width: 1.2,
                ),
              ),
              child: _isCompletedToday
                  ? Icon(Icons.check_rounded, size: 17, color: inverseText)
                  : null,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCompletedToday ? 'Completed today' : 'Complete today',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isCompletedToday ? inverseText : textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _isCompletedToday
                        ? 'Great job. Keep your streak alive.'
                        : 'Tap here when you finish this habit.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isCompletedToday
                          ? inverseText.withValues(alpha: 0.7)
                          : textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              _isCompletedToday
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 20,
              color: _isCompletedToday
                  ? AppColors.productivityAccent
                  : textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons({required bool isDark}) {
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Pause habit
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: EdgeInsets.zero,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Pause Habit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Edit habit
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: EdgeInsets.zero,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Edit Habit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPLETION
  // ============================================================

  int _calculateCompletion() {
    final completedDays = widget.habit.completedDays.clamp(0, 7);

    int value = ((completedDays / 7) * 100).round();

    if (_isCompletedToday && completedDays < 7) {
      value = (((completedDays + 1) / 7) * 100).round();
    }

    return value.clamp(0, 100);
  }
}
