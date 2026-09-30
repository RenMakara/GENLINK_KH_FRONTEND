import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/shadows/app_shadows.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';

// MODELS
class GrowthCategory {
  const GrowthCategory({
    required this.label,
    required this.icon,
    required this.color,
    this.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? key;
}

class TimelineActivityItem {
  const TimelineActivityItem({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
    this.onToggle,
    this.xpReward,
    this.category,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final int? xpReward;
  final String? category;
}

/// Date-specific activity item with interactive tap, toggle, and category keys.
class GrowthTimelineActivity {
  const GrowthTimelineActivity({
    required this.title,
    required this.type,
    required this.subtitle,
    required this.time,
    required this.endTime,
    required this.xp,
    required this.icon,
    required this.color,
    required this.completed,
    this.categoryKey,
    this.onTap,
    this.onToggle,
  });

  final String title;
  final String type;
  final String subtitle;
  final String time;
  final String endTime;
  final int xp;
  final IconData icon;
  final Color color;
  final bool completed;
  final String? categoryKey;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
}

// HEADER ICON BUTTON
class GrowthHeaderIconButton extends StatelessWidget {
  const GrowthHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

// DATE BUTTON
class GrowthDateButton extends StatelessWidget {
  const GrowthDateButton({
    super.key,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekdayLabel = weekdayLetters[(date.weekday - 1) % 7];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekdayLabel,
            style: TextStyle(
              color: textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: border, width: 0.8),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: (isDark ? Colors.white : const Color(0xFF0F172A))
                            .withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: selected
                    ? (isDark ? Colors.black : Colors.white)
                    : textPrimary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
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

// DATE STRIP
class GrowthDateStrip extends StatelessWidget {
  const GrowthDateStrip({
    super.key,
    required this.today,
    required this.selectedDate,
    required this.onDateSelected,
    this.startDate,
  });

  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    final base = startDate != null
        ? DateTime(startDate!.year, startDate!.month, startDate!.day)
        : DateTime(today.year, today.month, today.day);
    final dates = List.generate(7, (i) => base.add(Duration(days: i)));

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          for (final date in dates)
            Expanded(
              child: GrowthDateButton(
                date: date,
                selected: _sameDay(date, selectedDate),
                onTap: () => onDateSelected(date),
              ),
            ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// DATE CARD HEADER
class GrowthDateCardHeader extends StatelessWidget {
  const GrowthDateCardHeader({
    super.key,
    required this.selectedDate,
    required this.showDateDetail,
    required this.onToggleDetail,
    this.onTodayTap,
    this.onPreviousWeekTap,
    this.onNextWeekTap,
  });

  final DateTime selectedDate;
  final bool showDateDetail;
  final VoidCallback onToggleDetail;
  final VoidCallback? onTodayTap;
  final VoidCallback? onPreviousWeekTap;
  final VoidCallback? onNextWeekTap;

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
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleDetail,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 19,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthYear(context, selectedDate),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'levelup.trackDailyProgress'.tr.isNotEmpty &&
                              'levelup.trackDailyProgress'.tr !=
                                  'levelup.trackDailyProgress'
                          ? 'levelup.trackDailyProgress'.tr
                          : 'Track your daily progress',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Keep View/Hide day details accessible for tests
                    Text(
                      showDateDetail
                          ? 'levelup.hideDayDetails'.tr
                          : 'levelup.viewDayDetails'.tr,
                      style: TextStyle(
                        color: textMuted.withValues(alpha: 0.7),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTodayTap != null) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTodayTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'levelup.today'.tr.isNotEmpty &&
                              'levelup.today'.tr != 'levelup.today'
                          ? 'levelup.today'.tr
                          : 'Today',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (onPreviousWeekTap != null) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPreviousWeekTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 17,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              if (onNextWeekTap != null) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onNextWeekTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              AnimatedRotation(
                turns: showDateDetail ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthYear(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMonthYear(date);
  }
}

// DATE CARD
class GrowthDateCard extends StatefulWidget {
  const GrowthDateCard({
    super.key,
    required this.today,
    required this.selectedDate,
    required this.showDateDetail,
    required this.onDateSelected,
    required this.onToggleDetail,
    this.detailChild,
  });

  final DateTime today;
  final DateTime selectedDate;
  final bool showDateDetail;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onToggleDetail;
  final Widget? detailChild;

  @override
  State<GrowthDateCard> createState() => _GrowthDateCardState();
}

class _GrowthDateCardState extends State<GrowthDateCard> {
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(widget.today.year, widget.today.month, widget.today.day);
  }

  void _onPreviousWeek() {
    setState(() {
      _startDate = _startDate.subtract(const Duration(days: 7));
    });
  }

  void _onNextWeek() {
    setState(() {
      _startDate = _startDate.add(const Duration(days: 7));
    });
  }

  void _onToday() {
    setState(() {
      _startDate = DateTime(widget.today.year, widget.today.month, widget.today.day);
    });
    widget.onDateSelected(widget.today);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.8),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GrowthDateCardHeader(
            selectedDate: widget.selectedDate,
            showDateDetail: widget.showDateDetail,
            onToggleDetail: widget.onToggleDetail,
            onTodayTap: _onToday,
            onPreviousWeekTap: _onPreviousWeek,
            onNextWeekTap: _onNextWeek,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
            child: GrowthDateStrip(
              today: widget.today,
              selectedDate: widget.selectedDate,
              startDate: _startDate,
              onDateSelected: widget.onDateSelected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'levelup.selectDateHint'.tr,
              style: TextStyle(
                color: textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: widget.showDateDetail
                ? (widget.detailChild ?? const SizedBox.shrink())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// DATE DETAIL LAYOUT
class GrowthDateDetailLayout extends StatefulWidget {
  const GrowthDateDetailLayout({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.categories,
    required this.activities,
    required this.onDateSelected,
    this.onEdit,
    this.onDelete,
    this.onMarkDone,
  });

  final DateTime selectedDate;
  final DateTime today;
  final List<GrowthCategory> categories;
  final List<GrowthTimelineActivity> activities;
  final ValueChanged<DateTime> onDateSelected;
  final void Function(GrowthTimelineActivity)? onEdit;
  final void Function(GrowthTimelineActivity)? onDelete;
  final void Function(GrowthTimelineActivity)? onMarkDone;

  @override
  State<GrowthDateDetailLayout> createState() => _GrowthDateDetailLayoutState();
}

class _GrowthDateDetailLayoutState extends State<GrowthDateDetailLayout> {
  int selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final selectedCat = widget.categories[selectedCategory];
    final filtered = selectedCategory == 0
        ? widget.activities
        : widget.activities.where((e) {
            if (selectedCat.key != null && e.categoryKey != null) {
              return e.categoryKey == selectedCat.key;
            }
            return e.type.toLowerCase() == selectedCat.label.toLowerCase() ||
                e.type == selectedCat.key ||
                (e.categoryKey != null && e.categoryKey == selectedCat.label);
          }).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border, width: 0.7)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Categories
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = widget.categories[index];
                final selected = selectedCategory == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    selectedCategory = index;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: selected
                        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
                        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? cat.color.withValues(alpha: isDark ? 0.22 : 0.14)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.035)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? cat.color.withValues(alpha: 0.35)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 16,
                          color: selected ? cat.color : textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: selected ? cat.color : textSecondary,
                            fontSize: 11.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
              child: _buildEmptyState(
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _buildActivities(
                activities: filtered,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : Colors.black.withValues(alpha: 0.018),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 28, color: textSecondary),
          const SizedBox(height: 10),
          Text(
            'levelup.noActivitiesForDate'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'levelup.noHabitsOrTasks'.tr.isNotEmpty &&
                    'levelup.noHabitsOrTasks'.tr != 'levelup.noHabitsOrTasks'
                ? 'levelup.noHabitsOrTasks'.tr
                : 'levelup.activityTimelineUnavailable'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities({
    required List<GrowthTimelineActivity> activities,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.02);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      children: [
        for (final activity in activities)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: activity.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: activity.color.withValues(
                            alpha: isDark ? 0.18 : 0.12,
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: activity.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 15,
                                  color: textSecondary.withValues(alpha: 0.6),
                                ),
                                if (activity.type.trim().isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activity.color.withValues(
                                        alpha: isDark ? 0.20 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      activity.type,
                                      style: TextStyle(
                                        color: activity.color,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                if (activity.xp > 0) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    '+${activity.xp} XP',
                                    style: TextStyle(
                                      color: activity.color,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              activity.subtitle,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                            if (activity.categoryKey == 'goal') ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: Container(
                                  height: 3.5,
                                  width: double.infinity,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: activity.color,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (activity.time.trim().isNotEmpty ||
                                activity.endTime.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                [activity.time, activity.endTime]
                                    .where((value) => value.trim().isNotEmpty)
                                    .join(' - '),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (activity.categoryKey == 'goal') ...[
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/level_up/goal_summit_mountain.jpg',
                            width: 62,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ] else if (activity.onToggle != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: activity.onToggle,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activity.completed
                                  ? activity.color
                                  : Colors.transparent,
                              border: Border.all(
                                color: activity.completed
                                    ? activity.color
                                    : (isDark ? Colors.white38 : Colors.black26),
                                width: 1.5,
                              ),
                            ),
                            child: activity.completed
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ] else if (activity.completed) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: activity.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// LEVEL PROGRESS CARD
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.levelDisplay,
    required this.xpText,
    required this.progressCopy,
    required this.percentText,
    required this.progress,
    required this.onTap,
  });

  final String levelDisplay;
  final String xpText;
  final String progressCopy;
  final String percentText;
  final double progress;
  final VoidCallback onTap;

  static const Color growthAccent = Color(0xFF10B981);

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark
                    ? const Color(0xFF16202C).withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.85),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 3D Glowing Emerald Level Badge
                  Container(
                    width: 72,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            size: 15,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            levelDisplay,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Progress details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: XP Text & Chevron
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  xpText,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 13,
                                  color: textMuted,
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: textMuted.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: Smooth Progress Bar + Percent
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                child: Container(
                                  height: 8,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFE2E8F0),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: constraints.maxWidth *
                                              progress.clamp(0.0, 1.0),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF34D399),
                                                Color(0xFF10B981),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.pill),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              percentText,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 3: Only X XP to Level Y
                        Text(
                          progressCopy,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// TODAY PROGRESS CARD (Compact Growth Dashboard Summary)
class GrowthTodayProgressCard extends StatelessWidget {
  const GrowthTodayProgressCard({
    super.key,
    required this.percentText,
    required this.progress,
    required this.statusMessage,
    required this.activitiesText,
    required this.xpText,
    this.isCompleted = false,
    this.onTap,
  });

  final String percentText;
  final double progress;
  final String statusMessage;
  final String activitiesText;
  final String xpText;
  final bool isCompleted;
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
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final Color accentColor = isCompleted
        ? const Color(0xFF10B981)
        : (progress > 0
            ? const Color(0xFF3B82F6)
            : (isDark ? Colors.white60 : AppColors.lightTextSecondary));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151E2B)
                : const Color(0xFFF1F6FD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF223044)
                  : const Color(0xFFDCE8F8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0x0C2563EB),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row: Title & Percent Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'levelup.todayProgress'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      percentText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Body: Circular Ring + Stats Column
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Ring with percentText inside
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 4.5,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                        Text(
                          percentText,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Activities & XP & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                activitiesText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 8,
                              color: textMuted.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                xpText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Mini Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  height: 4,
                  width: double.infinity,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCompleted
                                  ? const [Color(0xFF34D399), Color(0xFF059669)]
                                  : const [Color(0xFF60A5FA), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      );
                    },
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

// TIMELINE ITEM ROW

class TimelineItemRow extends StatelessWidget {
  const TimelineItemRow({super.key, required this.item, required this.isLast});

  final TimelineActivityItem item;
  final bool isLast;

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

// TODAY CHECKLIST
class GrowthTodayChecklist extends StatelessWidget {
  const GrowthTodayChecklist({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percentText,
    required this.progress,
    required this.activities,
    this.emptyTitle,
    this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final String percentText;
  final double progress;
  final List<TimelineActivityItem> activities;
  final String? emptyTitle;
  final String? emptyMessage;

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
    final cardSurface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

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
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: textSecondary, fontSize: 11.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isAllEmpty)
              Text(
                percentText,
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
              ? _buildEmpty(textPrimary, textSecondary, isDark)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < activities.length; i++)
                      TimelineItemRow(
                        item: activities[i],
                        isLast: i == activities.length - 1,
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'levelup.dailyProgress'.tr,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          percentText,
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
                        value: progress,
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

  Widget _buildEmpty(Color textPrimary, Color textSecondary, bool isDark) {
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
                emptyTitle ?? 'levelup.allCaughtUp'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                emptyMessage ?? 'levelup.noHabitsOrTasks'.tr,
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

// ALERT CARD
class GrowthAlertCard extends StatelessWidget {
  const GrowthAlertCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF261914)
                : const Color(0xFFFFF6EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4A2A1E)
                  : const Color(0xFFFFDEC9),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0x0CF97316),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row: Flame Icon & Title + Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 28,
                    width: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 17, color: const Color(0xFFF97316)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              // Action pill button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B2319)
                      : const Color(0xFFFFEAD9),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText,
                      style: const TextStyle(
                        color: Color(0xFFEA580C),
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

// TOOL TILE
class GrowthToolTile extends StatelessWidget {
  const GrowthToolTile({
    super.key,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

// ACTION CARD
class GrowthActionCard extends StatelessWidget {
  const GrowthActionCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Widget? action;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C1A20)
                : const Color(0xFFFCF9F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2C2834)
                  : const Color(0xFFF1ECE4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0x08000000),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(12),
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
                                  fontSize: 11,
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
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerRight, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// DAILY MINDSET CARD
class DailyMindsetCard extends StatelessWidget {
  const DailyMindsetCard({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    const accent = Color(0xFF8B5CF6);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D172A) : const Color(0xFFF7F5FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF33254D) : const Color(0xFFE9E2FC),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0x0C8B5CF6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
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
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'levelup.reflectionForToday'.tr,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Decorative Stylized Mountain Graphic
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/level_up/motivation_growth_arrow.jpg',
                      width: 76,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
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
