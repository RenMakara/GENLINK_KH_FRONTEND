import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/widgets/expense_widget.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  int selectedPeriod = 2; // 0 = Today, 1 = Week, 2 = Month

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

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

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
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

                  Text(
                    'Expenses',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // PERIOD SELECTOR
              Row(
                children: [
                  Expanded(
                    child: PeriodButton(
                      title: 'Today',
                      selected: selectedPeriod == 0,
                      onTap: () {
                        setState(() {
                          selectedPeriod = 0;
                        });
                      },
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      selectedColor: primaryColor,
                      selectedTextColor: inverseText,
                      borderColor: border,
                      backgroundColor: secondarySurface,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: PeriodButton(
                      title: 'Week',
                      selected: selectedPeriod == 1,
                      onTap: () {
                        setState(() {
                          selectedPeriod = 1;
                        });
                      },
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      selectedColor: primaryColor,
                      selectedTextColor: inverseText,
                      borderColor: border,
                      backgroundColor: secondarySurface,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: PeriodButton(
                      title: 'Month',
                      selected: selectedPeriod == 2,
                      onTap: () {
                        setState(() {
                          selectedPeriod = 2;
                        });
                      },
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      selectedColor: primaryColor,
                      selectedTextColor: inverseText,
                      borderColor: border,
                      backgroundColor: secondarySurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // TOTAL SPENT CARD
              SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    ExpenseDonut(
                      size: 82,
                      strokeWidth: 9,
                      backgroundColor: secondarySurface,
                      segments: const [
                        DonutSegment(value: .40, color: AppColors.growthAccent),
                        DonutSegment(value: .25, color: AppColors.brandPrimary),
                        DonutSegment(
                          value: .20,
                          color: AppColors.financeAccent,
                        ),
                        DonutSegment(
                          value: .15,
                          color: AppColors.profileAccent,
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Spent',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '\$642',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'On track',
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

              const SizedBox(height: 14),

              // ============================================================
              // CATEGORY BREAKDOWN
              // ============================================================
              SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    CategoryRow(
                      title: 'Food & Drink',
                      amount: '\$255 / \$300',
                      percent: '85%',
                      progress: .85,
                      color: AppColors.growthAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                    ),

                    CategoryRow(
                      title: 'Transport',
                      amount: '\$138 / \$150',
                      percent: '92%',
                      progress: .92,
                      color: AppColors.brandPrimary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                    ),

                    CategoryRow(
                      title: 'Study',
                      amount: '\$51 / \$150',
                      percent: '34%',
                      progress: .34,
                      color: AppColors.productivityAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                    ),

                    CategoryRow(
                      title: 'Bills',
                      amount: '\$36 / \$300',
                      percent: '12%',
                      progress: .12,
                      color: AppColors.financeAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: secondarySurface,
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // RECENT EXPENSES
              SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Expenses',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ExpenseItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Grab Food',
                      subtitle: 'Today · 12:30 PM · Food',
                      amount: '-\$8.50',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    ExpenseItem(
                      icon: Icons.directions_bus_outlined,
                      title: 'Bus Pass',
                      subtitle: 'Today · 8:00 AM · Transport',
                      amount: '-\$1.25',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    ExpenseItem(
                      icon: Icons.menu_book_outlined,
                      title: 'Textbooks',
                      subtitle: 'Yesterday · Study',
                      amount: '-\$45.00',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    ExpenseItem(
                      icon: Icons.bolt_outlined,
                      title: 'Electricity',
                      subtitle: 'Jun 1 · Bills',
                      amount: '-\$36.00',
                      iconColor: textMuted,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      showDivider: false,
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
