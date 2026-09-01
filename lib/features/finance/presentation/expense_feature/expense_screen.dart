import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_widget.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_history_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  int selectedPeriod = 2;

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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  ExpenseBackButton(
                    background: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'finance.expense.title'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),

                  ExpenseAddButton(
                    background: primaryColor,
                    iconColor: inverseText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // PERIOD SELECTOR
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: border, width: 1),
                ),
                child: Stack(
                  children: [
                    // SLIDING SELECTED BACKGROUND
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: selectedPeriod == 0
                          ? Alignment.centerLeft
                          : selectedPeriod == 1
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 1 / 3,
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),

                    // BUTTONS
                    Row(
                      children: [
                        PeriodButton(
                          title: 'finance.expense.today'.tr,
                          selected: selectedPeriod == 0,
                          onTap: () {
                            setState(() {
                              selectedPeriod = 0;
                            });
                          },
                          textMuted: textMuted,
                          selectedColor: primaryColor,
                          selectedTextColor: inverseText,
                        ),

                        PeriodButton(
                          title: 'finance.expense.week'.tr,
                          selected: selectedPeriod == 1,
                          onTap: () {
                            setState(() {
                              selectedPeriod = 1;
                            });
                          },
                          textMuted: textMuted,
                          selectedColor: primaryColor,
                          selectedTextColor: inverseText,
                        ),

                        PeriodButton(
                          title: 'finance.expense.month'.tr,
                          selected: selectedPeriod == 2,
                          onTap: () {
                            setState(() {
                              selectedPeriod = 2;
                            });
                          },
                          textMuted: textMuted,
                          selectedColor: primaryColor,
                          selectedTextColor: inverseText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SPENDING OVERVIEW
              SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ExpenseDonut(
                          size: 92,
                          strokeWidth: 10,
                          backgroundColor: surfaceSecondary,
                          segments: const [
                            DonutSegment(
                              value: .40,
                              color: AppColors.growthAccent,
                            ),
                            DonutSegment(
                              value: .25,
                              color: AppColors.brandPrimary,
                            ),
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
                                'finance.expense.totalSpent'.tr,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                '\$642',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_down_rounded,
                                    color: AppColors.success,
                                    size: 15,
                                  ),

                                  const SizedBox(width: 4),

                                  const Text(
                                    '8.4% from last month',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SpendingStatus(
                      title: 'finance.expense.onTrack'.tr,
                      remaining: '\$158 left',
                      color: AppColors.success,
                      background: AppColors.success.withValues(alpha: .08),
                      textMuted: textMuted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // CATEGORY BREAKDOWN
              ExpenseSectionHeader(
                title: 'finance.expense.categoryBreakdown'.tr,
                subtitle: 'finance.expense.thismonth'.tr,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),

              const SizedBox(height: 10),

              SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  children: [
                    CategoryRow(
                      title: 'finance.expense.food'.tr,
                      amount: '\$255 / \$300',
                      percent: '85%',
                      progress: .85,
                      color: AppColors.growthAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: surfaceSecondary,
                    ),

                    CategoryRow(
                      title: 'finance.expense.transport'.tr,
                      amount: '\$138 / \$150',
                      percent: '92%',
                      progress: .92,
                      color: AppColors.brandPrimary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: surfaceSecondary,
                    ),

                    CategoryRow(
                      title: 'finance.expense.study'.tr,
                      amount: '\$51 / \$150',
                      percent: '34%',
                      progress: .34,
                      color: AppColors.productivityAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: surfaceSecondary,
                    ),

                    CategoryRow(
                      title: 'finance.expense.bills'.tr,
                      amount: '\$36 / \$300',
                      percent: '12%',
                      progress: .12,
                      color: AppColors.financeAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                      backgroundColor: surfaceSecondary,
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // RECENT EXPENSES
              ExpenseSectionHeader(
                title: 'finance.expense.recentExpenses'.tr,
                textPrimary: textPrimary,
                textMuted: textMuted,
                action: 'finance.expense.seeAll'.tr,
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpenseHistoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // EXPENSE LIST
              SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    ExpenseItem(
                      icon: Icons.restaurant_outlined,
                      iconColor: AppColors.growthAccent,
                      title: 'Grab Food',
                      subtitle: 'Today · 12:30 PM · Food & Drink',
                      amount: '-\$8.50',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _openDetail(
                          context,
                          title: 'Grab Food',
                          subtitle: 'Today · 12:30 PM · Food & Drink',
                          amount: '-\$8.50',
                          category: 'Food & Drink',
                          date: 'Jun 28, 2026',
                          time: '12:30 PM',
                          payment: 'Cash',
                          note: 'Dinner from Grab Food.',
                          icon: Icons.restaurant_outlined,
                          iconColor: AppColors.growthAccent,
                        );
                      },
                    ),

                    ExpenseItem(
                      icon: Icons.directions_bus_outlined,
                      iconColor: AppColors.brandPrimary,
                      title: 'Bus Pass',
                      subtitle: 'Today · 8:00 AM · Transport',
                      amount: '-\$1.25',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _openDetail(
                          context,
                          title: 'Bus Pass',
                          subtitle: 'Today · 8:00 AM · Transport',
                          amount: '-\$1.25',
                          category: 'Transport',
                          date: 'Jun 28, 2026',
                          time: '8:00 AM',
                          payment: 'Cash',
                          note: 'Morning bus pass.',
                          icon: Icons.directions_bus_outlined,
                          iconColor: AppColors.brandPrimary,
                        );
                      },
                    ),

                    ExpenseItem(
                      icon: Icons.menu_book_outlined,
                      iconColor: AppColors.productivityAccent,
                      title: 'Textbooks',
                      subtitle: 'Yesterday · Study',
                      amount: '-\$45.00',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _openDetail(
                          context,
                          title: 'Textbooks',
                          subtitle: 'Yesterday · Study',
                          amount: '-\$45.00',
                          category: 'Study',
                          date: 'Jun 27, 2026',
                          time: '3:20 PM',
                          payment: 'Cash',
                          note: 'University textbooks.',
                          icon: Icons.menu_book_outlined,
                          iconColor: AppColors.productivityAccent,
                        );
                      },
                    ),

                    ExpenseItem(
                      icon: Icons.bolt_outlined,
                      iconColor: AppColors.financeAccent,
                      title: 'Electricity',
                      subtitle: 'Jun 1 · Bills',
                      amount: '-\$36.00',
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      showDivider: false,
                      onTap: () {
                        _openDetail(
                          context,
                          title: 'Electricity',
                          subtitle: 'Jun 1 · Bills',
                          amount: '-\$36.00',
                          category: 'Bills',
                          date: 'Jun 1, 2026',
                          time: '9:00 AM',
                          payment: 'Bank',
                          note: 'Monthly electricity bill.',
                          icon: Icons.bolt_outlined,
                          iconColor: AppColors.financeAccent,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // OPEN EXPENSE DETAIL
  void _openDetail(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String amount,
    required String category,
    required String date,
    required String time,
    required String payment,
    required String note,
    required IconData icon,
    required Color iconColor,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          title: title,
          subtitle: subtitle,
          amount: amount,
          category: category,
          date: date,
          time: time,
          payment: payment,
          note: note,
          icon: icon,
          iconColor: iconColor,
          iconBackground: iconColor.withValues(alpha: .12),
        ),
      ),
    );
  }
}
