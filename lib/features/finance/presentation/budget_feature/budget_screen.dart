import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/widget/budget_widget.dart';

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
              // ===========================================================
              // HEADER
              // ===========================================================
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 4),

                  Expanded(
                    child: Text(
                      'finance.budget.title'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  // ADD BUDGET
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SetBudgetScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: inverseText,
                      minimumSize: const Size(42, 42),
                      maximumSize: const Size(42, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===========================================================
              // TOTAL OVERVIEW
              // ===========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    BudgetProgressRing(
                      progress: 0.71,
                      percentage: 71,
                      color: AppColors.growthAccent,
                      backgroundColor: secondarySurface,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
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

                          const SizedBox(height: 5),

                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '\$642',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                TextSpan(
                                  text: ' of \$900',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 9),

                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),

                              const SizedBox(width: 7),

                              Flexible(
                                child: Text(
                                  '${'finance.budget.onTrack'.tr} · \$258 ${'finance.budget.remaining'.tr.toLowerCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
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

              const SizedBox(height: 20),

              // ===========================================================
              // CATEGORY TITLE
              // ===========================================================
              Text(
                'finance.budget.categoryBudgets'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              // ===========================================================
              // CATEGORY LIST
              // ===========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    // FOOD
                    CategoryBudgetRow(
                      title: 'Food & Drink',
                      amount: '\$255 / \$300',
                      percent: '85%',
                      progress: 0.85,
                      color: AppColors.growthAccent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {
                        _openDetail(
                          context,
                          category: 'Food & Drink',
                          spent: 255,
                          budget: 300,
                          color: AppColors.growthAccent,
                        );
                      },
                    ),

                    Divider(height: 1, color: border),

                    // TRANSPORT
                    CategoryBudgetRow(
                      title: 'Transport',
                      amount: '\$138 / \$150',
                      percent: '92%',
                      progress: 0.92,
                      color: AppColors.brandPrimary,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {
                        _openDetail(
                          context,
                          category: 'Transport',
                          spent: 138,
                          budget: 150,
                          color: AppColors.brandPrimary,
                        );
                      },
                    ),

                    Divider(height: 1, color: border),

                    // STUDY
                    CategoryBudgetRow(
                      title: 'Study',
                      amount: '\$51 / \$150',
                      percent: '34%',
                      progress: 0.34,
                      color: AppColors.productivityAccent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {
                        _openDetail(
                          context,
                          category: 'Study',
                          spent: 51,
                          budget: 150,
                          color: AppColors.productivityAccent,
                        );
                      },
                    ),

                    Divider(height: 1, color: border),

                    // BILLS
                    CategoryBudgetRow(
                      title: 'Bills',
                      amount: '\$36 / \$300',
                      percent: '12%',
                      progress: 0.12,
                      color: AppColors.financeAccent,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      secondarySurface: secondarySurface,
                      onTap: () {
                        _openDetail(
                          context,
                          category: 'Bills',
                          spent: 36,
                          budget: 300,
                          color: AppColors.financeAccent,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===========================================================
              // NEAR LIMIT NOTICE
              // ===========================================================
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
                            '${'finance.budget.nearLimit'.tr} on 2 categories',
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

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // OPEN DETAIL
  // =========================================================================

  void _openDetail(
    BuildContext context, {
    required String category,
    required double spent,
    required double budget,
    required Color color,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetDetailScreen(
          category: category,
          spent: spent,
          budget: budget,
          categoryColor: color,
        ),
      ),
    );
  }
}
