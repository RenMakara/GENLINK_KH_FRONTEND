import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/set_budget_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_detail_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
                  const SizedBox(width: 4),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SetBudgetScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Set Budget',
                        style: TextStyle(
                          color: inverseText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Total Overview Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: 0.71,
                              strokeWidth: 7,
                              backgroundColor: secondarySurface,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.growthAccent,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'June 2026',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '\$642',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: ' of \$900',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'On track · \$258 remaining',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Category Budgets ──
              Text(
                'Category Budgets',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    _CategoryBudgetRow(
                      title: 'Food & Drink',
                      amount: '\$255 / \$300',
                      percent: '85%',
                      progress: 0.85,
                      color: AppColors.growthAccent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetDetailScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: border),
                    _CategoryBudgetRow(
                      title: 'Transport',
                      amount: '\$138 / \$150',
                      percent: '92%',
                      progress: 0.92,
                      color: AppColors.brandPrimary,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: border),
                    _CategoryBudgetRow(
                      title: 'Study',
                      amount: '\$51 / \$150',
                      percent: '34%',
                      progress: 0.34,
                      color: AppColors.productivityAccent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {},
                    ),
                    Divider(height: 1, color: border),
                    _CategoryBudgetRow(
                      title: 'Bills',
                      amount: '\$36 / \$300',
                      percent: '12%',
                      progress: 0.12,
                      color: AppColors.financeAccent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {},
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Near Limit Notice ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE8D5A3).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Color(0xFFC9A227),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Near limit on 2 categories',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Food & Transport budgets are nearly exhausted. Consider adjusting spending for the rest of the month.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBudgetRow extends StatelessWidget {
  final String title;
  final String amount;
  final String percent;
  final double progress;
  final Color color;
  final Color textPrimary;
  final Color textMuted;
  final Color secondarySurface;
  final VoidCallback onTap;
  final bool showDivider;

  const _CategoryBudgetRow({
    required this.title,
    required this.amount,
    required this.percent,
    required this.progress,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
    required this.secondarySurface,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  percent,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: secondarySurface,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
