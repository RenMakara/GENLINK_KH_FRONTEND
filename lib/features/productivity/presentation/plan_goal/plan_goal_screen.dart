import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

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
      dueDate: 'Due Aug 15, 2025',
    ),
    GoalModel(
      category: 'Career',
      title: 'Launch Side Project',
      progress: 0.28,
      dueDate: 'Due Sep 30, 2025',
    ),
    GoalModel(
      category: 'Personal',
      title: 'Exercise 5x/week',
      progress: 0.85,
      dueDate: 'Due Ongoing',
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

  List<GoalModel> get filteredGoals {
    if (selectedCategory == 'All') {
      return goals;
    }

    return goals.where((goal) => goal.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textPrimary),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryFilter(
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      secondarySurface: secondarySurface,
                      border: border,
                    ),

                    const SizedBox(height: 14),

                    ...filteredGoals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildGoalCard(
                          goal: goal,
                          surface: surface,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                          border: border,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    _buildMilestonesHeader(
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 8),

                    _buildMilestonesCard(
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      border: border,
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

  Widget _buildHeader(Color textPrimary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle,
          ),
        ),
      ),
      child: Text(
        'Goals',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter({
    required Color textPrimary,
    required Color textSecondary,
    required Color secondarySurface,
    required Color border,
  }) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
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
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? textPrimary : secondarySurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? textPrimary : border),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse)
                      : textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalCard({
    required GoalModel goal,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color border,
  }) {
    final percentage = (goal.progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.08
                  : 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.category,
                      style: TextStyle(
                        fontSize: 9,
                        color: textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 4,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkPrimarySoft
                  : AppColors.lightSurfaceSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentPremium,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 10, color: textMuted),
              const SizedBox(width: 4),
              Text(
                goal.dueDate,
                style: TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesHeader({
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      children: [
        Text(
          'Upcoming Milestones',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),

        const Spacer(),

        GestureDetector(
          onTap: () {
            // TODO: Navigate to all milestones
          },
          child: Text(
            'See all',
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesCard({
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(milestones.length, (index) {
          final milestone = milestones[index];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkPrimarySoft
                            : AppColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.radio_button_checked_outlined,
                        size: 14,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            milestone.subtitle,
                            style: TextStyle(fontSize: 9, color: textMuted),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      milestone.date,
                      style: TextStyle(fontSize: 9, color: textMuted),
                    ),
                  ],
                ),
              ),

              if (index < milestones.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.7,
                  indent: 10,
                  endIndent: 10,
                  color: border,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================
// MODELS
// =============================================================

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
