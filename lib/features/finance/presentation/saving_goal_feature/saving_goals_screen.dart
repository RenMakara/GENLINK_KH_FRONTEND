import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_detail.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/widget/saving_goals_widget.dart';

class SavingGoalsScreen extends StatelessWidget {
  const SavingGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // COLORS
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    // ==========================================================
    // SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HEADER
              // ==================================================
              SavingGoalsHeader(
                title: 'Saving Goals',
                textPrimary: textPrimary,
                onBack: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 18),

              // ==================================================
              // TOTAL SAVED
              // ==================================================
              TotalSavedCard(
                title: 'Total Saved',
                totalSaved: '\$2,480',
                subtitle: 'Across 3 active goals',

                incomeTitle: 'Income',
                incomeValue: '+\$6,200',

                expenseTitle: 'Expenses',
                expenseValue: '-\$1,379.50',

                primary: primary,
                textInverse: textInverse,
              ),

              const SizedBox(height: 22),

              // ==================================================
              // ACTIVE GOALS TITLE
              // ==================================================
              SavingGoalsSectionTitle(
                title: 'Active Goals',
                textPrimary: textPrimary,
              ),

              const SizedBox(height: 12),

              // ==================================================
              // GOAL 1
              // ==================================================
              SavingGoalCard(
                title: 'Emergency Fund',
                progress: '\$1,240 of \$3,000',
                subtitle: 'Target: Dec 2026',
                percent: 0.41,
                color: AppColors.financeAccent,
                surface: surface,
                secondarySurface: secondarySurface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoalDetailScreen(
                        title: 'Emergency Fund',
                        savedAmount: 1240,
                        targetAmount: 3000,
                        targetDate: 'Dec 2026',
                        progress: 0.41,
                        color: AppColors.financeAccent,
                      ),
                    ),
                  );
                },
              ),

              // ==================================================
              // GOAL 2
              // ==================================================
              SavingGoalCard(
                title: 'Travel — Japan',
                progress: '\$840 of \$2,000',
                subtitle: 'Target: Mar 2027',
                percent: 0.42,
                color: AppColors.brandPrimary,
                surface: surface,
                secondarySurface: secondarySurface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoalDetailScreen(
                        title: 'Travel — Japan',
                        savedAmount: 840,
                        targetAmount: 2000,
                        targetDate: 'Mar 2027',
                        progress: 0.42,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  );
                },
              ),

              // ==================================================
              // GOAL 3
              // ==================================================
              SavingGoalCard(
                title: 'New MacBook',
                progress: '\$400 of \$1,500',
                subtitle: 'Target: Dec 2026',
                percent: 0.27,
                color: AppColors.growthAccent,
                surface: surface,
                secondarySurface: secondarySurface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoalDetailScreen(
                        title: 'New MacBook',
                        savedAmount: 400,
                        targetAmount: 1500,
                        targetDate: 'Dec 2026',
                        progress: 0.27,
                        color: AppColors.growthAccent,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              // ==================================================
              // COMPLETED GOALS TITLE
              // ==================================================
              SavingGoalsSectionTitle(
                title: 'Completed Goals',
                textPrimary: textPrimary,
              ),

              const SizedBox(height: 12),

              // ==================================================
              // COMPLETED GOAL 1
              // ==================================================
              CompletedGoalCard(
                title: 'Phone Upgrade',
                amount: '-\$800',

                textPrimary: textPrimary,
                textMuted: textMuted,

                surface: surface,
                border: border,
              ),

              // ==================================================
              // COMPLETED GOAL 2
              // ==================================================
              CompletedGoalCard(
                title: 'Rainy Day Fund',
                amount: '-\$500',

                textPrimary: textPrimary,
                textMuted: textMuted,

                surface: surface,
                border: border,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // NEW GOAL BUTTON
              // ==================================================
              NewGoalButton(
                title: 'New Goal',

                primary: primary,
                textInverse: textInverse,

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
                  );
                },
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
