import 'package:flutter/material.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalModel goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late double progress;

  final List<String> milestones = [
    'Research and plan',
    'Complete first version',
    'Test and improve',
    'Complete final version',
  ];

  final List<bool> completed = [true, true, false, false];

  @override
  void initState() {
    super.initState();

    progress = widget.goal.progress;
  }

  void updateProgress() {
    final completedCount = completed.where((item) => item).length;

    setState(() {
      progress = completedCount / completed.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

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

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final percentage = (progress * 100).round();

    final completedCount = completed.where((item) => item).length;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            Row(
              children: [
                const AppBackButton(),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Goal Detail',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: secondarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: textPrimary,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: secondarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.goal.category,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        '$percentage%',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.goal.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: textMuted,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        widget.goal.dueDate,
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.darkPrimarySoft
                          : AppColors.lightSurfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.productivityAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  '$percentage% complete',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Current progress',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),

                      const Spacer(),

                      Text(
                        '$percentage%',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: isDark
                          ? AppColors.darkPrimarySoft
                          : AppColors.lightSurfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.productivityAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  'Milestones',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  '$completedCount/${milestones.length}',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < milestones.length; i++) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          completed[i] = !completed[i];

                          final count = completed.where((item) => item).length;

                          progress = count / completed.length;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: completed[i]
                                    ? AppColors.success
                                    : secondarySurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: completed[i]
                                      ? AppColors.success
                                      : border,
                                ),
                              ),
                              child: Icon(
                                completed[i]
                                    ? Icons.check_rounded
                                    : Icons.flag_outlined,
                                size: 15,
                                color: completed[i] ? Colors.white : textMuted,
                              ),
                            ),

                            const SizedBox(width: 11),

                            Expanded(
                              child: Text(
                                milestones[i],
                                style: TextStyle(
                                  color: completed[i] ? textMuted : textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: completed[i]
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Icon(
                              Icons.chevron_right_rounded,
                              color: textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (i < milestones.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.7,
                        indent: 14,
                        endIndent: 14,
                        color: border,
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$percentage% progress saved')),
                      );
                    },
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: textPrimary,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Update Progress',
                        style: TextStyle(
                          color: inverseText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: secondarySurface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: border),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: textPrimary,
                    size: 19,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: secondarySurface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    progress >= 1
                        ? Icons.check_circle_outline
                        : Icons.track_changes_outlined,
                    size: 18,
                    color: progress >= 1 ? AppColors.success : textSecondary,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      progress >= 1
                          ? 'Goal completed! Great work.'
                          : 'Keep going. You are making progress.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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
