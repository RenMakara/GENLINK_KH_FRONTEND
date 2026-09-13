import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../design_system/colors/app_colors.dart';
import '../../../../../design_system/shadows/app_shadows.dart';

class GrowthDateDetailScreen extends StatefulWidget {
  const GrowthDateDetailScreen({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  State<GrowthDateDetailScreen> createState() => _GrowthDateDetailScreenState();
}

class _GrowthDateDetailScreenState extends State<GrowthDateDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, textPrimary, textSecondary, isDark),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                child: Column(
                  children: [
                    _buildCalendar(context, textPrimary, textSecondary, isDark),

                    const SizedBox(height: 10),

                    _buildTimeline(context, textPrimary, textSecondary, isDark),

                    const SizedBox(height: 10),

                    _buildSelectedActivity(
                      context,
                      textPrimary,
                      textSecondary,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: textPrimary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'September 2026',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _formatDate(widget.selectedDate),
                  style: TextStyle(color: textSecondary, fontSize: 9.5),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.more_horiz_rounded,
              color: textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // CALENDAR
  Widget _buildCalendar(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final border = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    final dates = [
      ('Sun', 6),
      ('Mon', 7),
      ('Tue', 8),
      ('Wed', 9),
      ('Thu', 10),
      ('Fri', 11),
      ('Sat', 12),
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: border, width: 0.6),
          bottom: BorderSide(color: border, width: 0.6),
        ),
      ),
      child: Row(
        children: [
          for (final date in dates)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    // UI-only selected date
                  });
                },
                child: _calendarDate(
                  day: date.$1,
                  number: date.$2,
                  selected: date.$2 == widget.selectedDate.day,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _calendarDate({
    required String day,
    required int number,
    required bool selected,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          day,
          style: TextStyle(
            color: textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF111111))
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: selected
                  ? (isDark ? Colors.black : Colors.white)
                  : textPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: number == 10
                ? const Color(0xFFF97316)
                : const Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // TIMELINE
  Widget _buildTimeline(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      height: 305,
      child: Stack(
        children: [
          // TIME GRID
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

          // ACTIVITY TIMELINE
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

          // ACTIVITIES
          for (int i = 0; i < activities.length; i++)
            _timelineNode(
              index: i,
              activity: activities[i],
              textPrimary: textPrimary,
              isDark: isDark,
            ),
        ],
      ),
    );
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

  Widget _timelineNode({
    required int index,
    required _GrowthTimelineActivity activity,
    required Color textPrimary,
    required bool isDark,
  }) {
    final positions = [8.0, 62.0, 112.0, 174.0, 238.0];

    final top = positions[index.clamp(0, 4)];

    final selected = selectedActivity == index;

    return Positioned(
      left: 52,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedActivity = index;
          });
        },
        child: Row(
          children: [
            // connecting line
            Container(
              width: 13,
              height: 1,
              color: activity.color.withValues(alpha: 0.45),
            ),

            // node
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

            // selected title
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
                    color: textPrimary,
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

  // SELECTED ACTIVITY
  Widget _buildSelectedActivity(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final activity = activities[selectedActivity];

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final progress = activities.where((item) => item.completed).length;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 0.8),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      child: Column(
        children: [
          // SELECTED ACTIVITY CARD
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
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

          // CATEGORY FILTERS
          _buildCategoryFilters(textSecondary, isDark),

          // PROGRESS
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
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
                  '$progress / ${activities.length} completed',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress / activities.length,
                minHeight: 4,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(activity.color),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ACTIONS
          _buildActions(textPrimary, isDark),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // CATEGORY FILTERS
  Widget _buildCategoryFilters(Color textSecondary, bool isDark) {
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

  // ACTION BUTTONS
  Widget _buildActions(Color textPrimary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _smallActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onTap: () {},
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
              onTap: () {},
              isDark: isDark,
              filled: false,
              textPrimary: textPrimary,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            flex: 2,
            child: _smallActionButton(
              label: 'Mark as Done',
              icon: Icons.check_rounded,
              onTap: () {
                setState(() {
                  // UI only
                });
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
}

// MODELS — UI ONLY
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
