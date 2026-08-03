import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Budget%20Feature/screens/set_budget_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
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
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // =========================================================
                  // BACK BUTTON
                  // =========================================================
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // =========================================================
                  // TITLE
                  // =========================================================
                  Expanded(
                    child: Text(
                      'Budget',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  // =========================================================
                  // SET BUDGET BUTTON
                  // =========================================================
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SetBudgetScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        foregroundColor: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Set Budget',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================================================
              // BUDGET SUMMARY
              // =========================================================
              _BudgetSummaryCard(
                surface: surface,
                surfaceSecondary: surfaceSecondary,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                border: border,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // =========================================================
              // CATEGORY BUDGETS
              // =========================================================
              _CategoryBudgetsCard(
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
                border: border,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // =========================================================
              // WARNING
              // =========================================================
              _BudgetWarningCard(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BUDGET SUMMARY CARD
// ============================================================================

class _BudgetSummaryCard extends StatelessWidget {
  final Color surface;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final bool isDark;

  const _BudgetSummaryCard({
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const spent = 642.0;
    const total = 900.0;

    final progress = spent / total;
    final remaining = total - spent;

    return Container(
      width: double.infinity,
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          // ===========================================================
          // PROGRESS CIRCLE
          // ===========================================================
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 5,
                    color: AppColors.financeAccent.withValues(alpha: 0.10),
                  ),
                ),

                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: AppColors.financeAccent,
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'used',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ===========================================================
          // DETAILS
          // ===========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'June 2026',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$642',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' of \$900',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.financeAccent.withValues(
                      alpha: isDark ? 0.15 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'On track · \$${remaining.toStringAsFixed(0)} remaining',
                    style: TextStyle(
                      color: AppColors.financeAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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
}

// ============================================================================
// CATEGORY BUDGETS CARD
// ============================================================================

class _CategoryBudgetsCard extends StatelessWidget {
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final bool isDark;

  const _CategoryBudgetsCard({
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Budgets',
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 13),

          _CategoryBudgetRow(
            title: 'Food & Drink',
            spent: 255,
            budget: 300,
            percentage: 85,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            border: border,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          _CategoryBudgetRow(
            title: 'Transport',
            spent: 138,
            budget: 150,
            percentage: 92,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            border: border,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          _CategoryBudgetRow(
            title: 'Study',
            spent: 81,
            budget: 150,
            percentage: 54,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            border: border,
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          _CategoryBudgetRow(
            title: 'Bills',
            spent: 96,
            budget: 300,
            percentage: 32,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            border: border,
            isDark: isDark,
            last: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CATEGORY ROW
// ============================================================================

class _CategoryBudgetRow extends StatelessWidget {
  final String title;
  final double spent;
  final double budget;
  final int percentage;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  final bool isDark;
  final bool last;

  const _CategoryBudgetRow({
    required this.title,
    required this.spent,
    required this.budget,
    required this.percentage,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.isDark,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (spent / budget).clamp(0.0, 1.0);

    final Color progressColor = percentage >= 90
        ? AppColors.warning
        : AppColors.financeAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===============================================================
        // TOP ROW
        // ===============================================================
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: progressColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              '\$${spent.toStringAsFixed(0)} / \$${budget.toStringAsFixed(0)}',
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 34,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: percentage >= 90 ? AppColors.warning : textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        // ===============================================================
        // PROGRESS BAR
        // ===============================================================
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.lightSurfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),

        if (!last) const SizedBox(height: 1),
      ],
    );
  }
}

// ============================================================================
// WARNING CARD
// ============================================================================

class _BudgetWarningCard extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _BudgetWarningCard({
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 17,
              color: AppColors.warning,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Near limit on 2 categories',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Food & Transport budgets are nearly exhausted.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Consider adjusting spending for the rest of the month.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
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
