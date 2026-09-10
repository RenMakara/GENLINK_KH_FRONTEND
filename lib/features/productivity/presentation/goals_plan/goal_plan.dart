import 'package:flutter/material.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_detail.dart';

class PlanGoalScreen extends StatefulWidget {
  const PlanGoalScreen({super.key});

  @override
  State<PlanGoalScreen> createState() => _PlanGoalScreenState();
}

class _PlanGoalScreenState extends State<PlanGoalScreen> {
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Personal',
    'Career',
    'Skill',
    'Finance',
  ];

  final List<GoalModel> goals = [
    GoalModel(
      category: 'Skill',
      title: 'Master TypeScript',
      progress: 0.62,
      dueDate: 'Due Aug 15, 2026',
    ),
    GoalModel(
      category: 'Career',
      title: 'Launch Side Project',
      progress: 0.28,
      dueDate: 'Due Sep 30, 2026',
    ),
    GoalModel(
      category: 'Personal',
      title: 'Exercise 5x/week',
      progress: 0.85,
      dueDate: 'Ongoing',
    ),
  ];

  final List<MilestoneModel> milestones = [
    MilestoneModel(
      title: 'Complete TypeScript generics module',
      subtitle: 'Master TypeScript',
      date: 'Jul 10',
    ),
    MilestoneModel(
      title: 'Build MVP landing page',
      subtitle: 'Launch Side Project',
      date: 'Jul 20',
    ),
  ];

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

    final filteredGoals = selectedCategory == 'All'
        ? goals
        : goals.where((goal) => goal.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: textPrimary,
          backgroundColor: surface,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              setState(() {});
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              Row(
                children: [
                  const AppBackButton(),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Goals Plan',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateGoalScreen(),
                        ),
                      );

                      if (!mounted) return;

                      if (result is GoalModel) {
                        setState(() {
                          goals.add(result);
                        });
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: textPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: inverseText,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = categories[index];

                    final selected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? textPrimary : secondarySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? textPrimary : border,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: selected ? inverseText : textSecondary,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Text(
                    'My Goals',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${filteredGoals.length} goals',
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (filteredGoals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.flag_outlined, size: 32, color: textMuted),

                      const SizedBox(height: 10),

                      Text(
                        'No goals found',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Create a goal to get started.',
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                ...filteredGoals.map((goal) {
                  final percentage = (goal.progress * 100).round();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalDetailScreen(goal: goal),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.category,
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      goal.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: goal.progress,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? AppColors.darkPrimarySoft
                                  : AppColors.lightSurfaceSecondary,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.productivityAccent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: textMuted,
                              ),

                              const SizedBox(width: 5),

                              Text(
                                goal.dueDate,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 10,
                                ),
                              ),

                              const Spacer(),

                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    'Upcoming Milestones',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

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
                      Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: secondarySurface,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.flag_outlined,
                                size: 16,
                                color: textSecondary,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    milestones[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    milestones[i].subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(
                              milestones[i].date,
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (i < milestones.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.7,
                          indent: 13,
                          endIndent: 13,
                          color: border,
                        ),
                    ],
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


class GoalModel {
  final String category;
  final String title;
  final double progress;
  final String dueDate;

  GoalModel({
    required this.category,
    required this.title,
    required this.progress,
    required this.dueDate,
  });
}


class MilestoneModel {
  final String title;
  final String subtitle;
  final String date;

  MilestoneModel({
    required this.title,
    required this.subtitle,
    required this.date,
  });
}
