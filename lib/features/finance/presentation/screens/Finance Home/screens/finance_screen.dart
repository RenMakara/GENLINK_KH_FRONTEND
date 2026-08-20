import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';

import 'package:genlink_frontend/features/finance/presentation/screens/Budget%20Feature/screens/budget_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/E%20Wallet%20Feature/screens/ewallet.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Expense%20Feature/screens/expense_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Learn%20Feature/screens/learn_finance.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Saving%20Goal%20Feature/screens/saving_goals_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/Finance%20Home/widgets/finance_widget.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

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

    final List<Widget> recentTransactions = [
      Transaction(
        title: 'Grab Food',
        subtitle: 'Today · 12:30 PM · Food',
        amount: '-\$8.50',
        icon: Icons.receipt_long_outlined,
        iconColor: AppColors.growthAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Salary Deposit',
        subtitle: 'Jun 1 · ABA Bank',
        amount: '+\$2,500',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.financeAccent,
        amountColor: AppColors.financeAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Netflix',
        subtitle: 'Yesterday · Card',
        amount: '-\$15.99',
        icon: Icons.play_circle_outline_rounded,
        iconColor: AppColors.brandPrimary,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Coffee Shop',
        subtitle: 'Yesterday · 10:20 AM · Food',
        amount: '-\$3.25',
        icon: Icons.local_cafe_outlined,
        iconColor: AppColors.growthAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Grab Ride',
        subtitle: 'May 29 · Transport',
        amount: '-\$4.50',
        icon: Icons.directions_car_outlined,
        iconColor: AppColors.brandPrimary,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Freelance Payment',
        subtitle: 'May 28 · ABA Bank',
        amount: '+\$350',
        icon: Icons.work_outline_rounded,
        iconColor: AppColors.financeAccent,
        amountColor: AppColors.financeAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Electricity Bill',
        subtitle: 'May 27 · Utilities',
        amount: '-\$32.80',
        icon: Icons.bolt_outlined,
        iconColor: AppColors.growthAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Shopping',
        subtitle: 'May 26 · Mall',
        amount: '-\$45.00',
        icon: Icons.shopping_bag_outlined,
        iconColor: AppColors.brandPrimary,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Cash Deposit',
        subtitle: 'May 25 · ABA Bank',
        amount: '+\$100',
        icon: Icons.payments_outlined,
        iconColor: AppColors.financeAccent,
        amountColor: AppColors.financeAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Internet Bill',
        subtitle: 'May 24 · Utilities',
        amount: '-\$18.00',
        icon: Icons.wifi_outlined,
        iconColor: AppColors.growthAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Lunch',
        subtitle: 'May 23 · Food',
        amount: '-\$6.50',
        icon: Icons.restaurant_outlined,
        iconColor: AppColors.growthAccent,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
      Transaction(
        title: 'Phone Bill',
        subtitle: 'May 22 · Mobile',
        amount: '-\$10.00',
        icon: Icons.phone_android_outlined,
        iconColor: AppColors.brandPrimary,
        background: surface,
        iconBackground: surfaceSecondary,
        border: border,
        textPrimary: textPrimary,
        textMuted: textMuted,
      ),
    ];

    final displayTransactions = recentTransactions.take(20).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // HEADER
              // =========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'finance.title'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'SR',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =========================================================
              // BALANCE
              // =========================================================
              BalanceCard(isDark: isDark, surfaceSecondary: surfaceSecondary),

              const SizedBox(height: 16),

              // =========================================================
              // MONTHLY SPENDING
              // =========================================================
              AppCard(
                color: surface,
                borderColor: border,
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
                                'finance.monthlySpending'.tr,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'finance.month'.tr,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        DonutChart(
                          size: 68,
                          strokeWidth: 8,
                          backgroundColor: surfaceSecondary,
                          segments: const [
                            DonutSegment(
                              value: .28,
                              color: AppColors.growthAccent,
                            ),
                            DonutSegment(
                              value: .25,
                              color: AppColors.brandPrimary,
                            ),
                            DonutSegment(
                              value: .22,
                              color: AppColors.financeAccent,
                            ),
                            DonutSegment(
                              value: .15,
                              color: AppColors.productivityAccent,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Legend(
                          color: AppColors.growthAccent,
                          title: 'finance.food'.tr,
                          textColor: textMuted,
                        ),

                        const SizedBox(width: 18),

                        Legend(
                          color: AppColors.brandPrimary,
                          title: 'finance.transport'.tr,
                          textColor: textMuted,
                        ),

                        const SizedBox(width: 18),

                        Legend(
                          color: AppColors.financeAccent,
                          title: 'finance.bills'.tr,
                          textColor: textMuted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: .72,
                        minHeight: 6,
                        backgroundColor: surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.growthAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'finance.spendingOf'.trParams({
                            'spent': '\$642',
                            'limit': '\$900',
                          }),
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),

                        Text(
                          '72%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // EMERGENCY FUND
              // =========================================================
              AppCard(
                color: surface,
                borderColor: border,
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
                                'finance.emergencyFund'.tr,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'finance.fundProgress'.trParams({
                                  'saved': '\$1,240',
                                  'target': '\$3,000',
                                }),
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        DonutChart(
                          size: 52,
                          strokeWidth: 7,
                          backgroundColor: surfaceSecondary,
                          segments: const [
                            DonutSegment(
                              value: .41,
                              color: AppColors.financeAccent,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: .41,
                        minHeight: 6,
                        backgroundColor: surfaceSecondary,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.financeAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'finance.targetDate'.trParams({'date': 'Dec 2026'}),
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // SMART INSIGHT
              // =========================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.financeAccent.withValues(alpha: .08)
                      : AppColors.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.financeAccent.withValues(alpha: .45),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.financeAccent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.financeAccent,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'finance.smartInsight'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'finance.foodSpendingInsight'.trParams({
                              'percent': '15',
                              'amount': '\$300',
                            }),
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

              const SizedBox(height: 22),

              // =========================================================
              // QUICK ACTIONS
              // =========================================================
              Text(
                'finance.quickActions'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 92,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // ADD EXPENSE
                      SizedBox(
                        width: 80,
                        child: QuickAction(
                          icon: Icons.add_rounded,
                          title: 'finance.addExpense'.tr,
                          accent: AppColors.brandPrimary,
                          background: surface,
                          border: border,
                          textColor: textPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpenseScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // BUDGET
                      SizedBox(
                        width: 80,
                        child: QuickAction(
                          icon: Icons.bar_chart_rounded,
                          title: 'finance.setBudget'.tr,
                          accent: AppColors.productivityAccent,
                          background: surface,
                          border: border,
                          textColor: textPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BudgetScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // SAVING GOAL
                      SizedBox(
                        width: 80,
                        child: QuickAction(
                          icon: Icons.savings_outlined,
                          title: 'finance.saveGoal'.tr,
                          accent: AppColors.financeAccent,
                          background: surface,
                          border: border,
                          textColor: textPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavingGoalsScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // E-WALLET
                      SizedBox(
                        width: 80,
                        child: QuickAction(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'finance.ewallet'.tr,
                          accent: const Color.fromARGB(255, 75, 148, 174),
                          background: surface,
                          border: border,
                          textColor: textPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EWalletScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // LEARN
                      SizedBox(
                        width: 80,
                        child: QuickAction(
                          icon: Icons.menu_book_rounded,
                          title: 'finance.learn'.tr,
                          accent: AppColors.growthAccent,
                          background: surface,
                          border: border,
                          textColor: textPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LearnFinanceScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // =========================================================
              // RECENT TRANSACTIONS
              // =========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'finance.recentTransactions'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpenseScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'finance.seeAll'.tr,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // TRANSACTIONS BOX
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: displayTransactions.length,
                  itemBuilder: (context, index) {
                    return displayTransactions[index];
                  },
                ),
              ),

              const SizedBox(height: 16),

              // =========================================================
              // LEARN FINANCE
              // =========================================================
              AppCard(
                color: surface,
                borderColor: border,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'finance.learnFinance'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'finance.topicsCompleted'.trParams({
                              'done': '3',
                              'total': '5',
                            }),
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'finance.keepGoing'.tr,
                            style: TextStyle(color: textMuted, fontSize: 12),
                          ),

                          const SizedBox(height: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: .6,
                              minHeight: 6,
                              backgroundColor: surfaceSecondary,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.productivityAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 22,
                        color: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}
