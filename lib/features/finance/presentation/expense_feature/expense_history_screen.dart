import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_history_widget.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  int selectedFilter = 0;

  final List<String> filters = [
    'finance.expense.all',
    'finance.expense.food',
    'finance.expense.transport',
    'finance.expense.study',
    'finance.expense.bills',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // COLORS

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

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
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  ExpenseHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    background: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'finance.expense.history'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExpenseSearchField(
                hintText: 'finance.expense.searchHint'.tr,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
                primary: primary,
              ),
            ),

            const SizedBox(height: 14),

            // FILTER
            ExpenseFilterBar(
              filters: filters.map((item) => item.tr).toList(),
              selectedIndex: selectedFilter,
              primary: primary,
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              inverseText: inverseText,
              onChanged: (index) {
                setState(() {
                  selectedFilter = index;
                });
              },
            ),

            const SizedBox(height: 16),

            // HISTORY
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                children: [
                  // TODAY
                  ExpenseDateHeader(
                    text: 'finance.expense.todayDate'.tr,
                    color: textMuted,
                  ),

                  ExpenseHistoryCard(
                    icon: Icons.restaurant_outlined,
                    iconColor: AppColors.growthAccent,
                    iconBackground: AppColors.growthAccent.withValues(
                      alpha: .12,
                    ),
                    title: 'Grab Food',
                    subtitle: '12:30 PM · Food & Drink',
                    amount: '-\$8.50',
                    isPositive: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      _openDetail(
                        context,
                        icon: Icons.restaurant_outlined,
                        iconColor: AppColors.growthAccent,
                        iconBackground: AppColors.growthAccent.withValues(
                          alpha: .12,
                        ),
                        title: 'Grab Food',
                        subtitle: '12:30 PM · Food & Drink',
                        amount: '-\$8.50',
                        date: 'Jun 28, 2026',
                        time: '12:30 PM',
                        category: 'Food & Drink',
                        payment: 'Cash',
                        note: 'Dinner from Grab Food',
                      );
                    },
                  ),

                  // BUS PASS
                  ExpenseHistoryCard(
                    icon: Icons.directions_bus_outlined,
                    iconColor: AppColors.brandPrimary,
                    iconBackground: AppColors.brandPrimary.withValues(
                      alpha: .10,
                    ),
                    title: 'Bus Pass',
                    subtitle: '8:00 AM · Transport',
                    amount: '-\$1.25',
                    isPositive: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      _openDetail(
                        context,
                        icon: Icons.directions_bus_outlined,
                        iconColor: AppColors.brandPrimary,
                        iconBackground: AppColors.brandPrimary.withValues(
                          alpha: .10,
                        ),
                        title: 'Bus Pass',
                        subtitle: '8:00 AM · Transport',
                        amount: '-\$1.25',
                        date: 'Jun 28, 2026',
                        time: '8:00 AM',
                        category: 'Transport',
                        payment: 'Cash',
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // YESTERDAY
                  ExpenseDateHeader(
                    text: 'finance.expense.yesterdayDate'.tr,
                    color: textMuted,
                  ),

                  ExpenseHistoryCard(
                    icon: Icons.menu_book_outlined,
                    iconColor: AppColors.productivityAccent,
                    iconBackground: AppColors.productivityAccent.withValues(
                      alpha: .12,
                    ),
                    title: 'Textbooks',
                    subtitle: 'Study',
                    amount: '-\$45.00',
                    isPositive: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      _openDetail(
                        context,
                        icon: Icons.menu_book_outlined,
                        iconColor: AppColors.productivityAccent,
                        iconBackground: AppColors.productivityAccent.withValues(
                          alpha: .12,
                        ),
                        title: 'Textbooks',
                        subtitle: 'Study',
                        amount: '-\$45.00',
                        date: 'Jun 27, 2026',
                        time: '2:15 PM',
                        category: 'Study',
                        payment: 'Cash',
                        note: 'University textbooks',
                      );
                    },
                  ),

                  ExpenseHistoryCard(
                    icon: Icons.lunch_dining_outlined,
                    iconColor: AppColors.growthAccent,
                    iconBackground: AppColors.growthAccent.withValues(
                      alpha: .12,
                    ),
                    title: 'Lunch Box',
                    subtitle: 'Food & Drink',
                    amount: '-\$4.20',
                    isPositive: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      _openDetail(
                        context,
                        icon: Icons.lunch_dining_outlined,
                        iconColor: AppColors.growthAccent,
                        iconBackground: AppColors.growthAccent.withValues(
                          alpha: .12,
                        ),
                        title: 'Lunch Box',
                        subtitle: 'Food & Drink',
                        amount: '-\$4.20',
                        date: 'Jun 27, 2026',
                        time: '12:00 PM',
                        category: 'Food & Drink',
                        payment: 'Cash',
                        note: 'Lunch',
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // JUN 26
                  ExpenseDateHeader(
                    text: 'finance.expense.jun26'.tr,
                    color: textMuted,
                  ),

                  ExpenseHistoryCard(
                    icon: Icons.account_balance_outlined,
                    iconColor: AppColors.financeAccent,
                    iconBackground: AppColors.financeAccent.withValues(
                      alpha: .12,
                    ),
                    title: 'ABA Transfer',
                    subtitle: 'Deposit',
                    amount: '+\$200.00',
                    isPositive: true,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      _openDetail(
                        context,
                        icon: Icons.account_balance_outlined,
                        iconColor: AppColors.financeAccent,
                        iconBackground: AppColors.financeAccent.withValues(
                          alpha: .12,
                        ),
                        title: 'ABA Transfer',
                        subtitle: 'Deposit',
                        amount: '+\$200.00',
                        date: 'Jun 26, 2026',
                        time: '10:30 AM',
                        category: 'Deposit',
                        payment: 'ABA',
                        note: 'Money received',
                      );
                    },
                  ),

                  ExpenseHistoryCard(
                    icon: Icons.play_circle_outline_rounded,
                    iconColor: AppColors.financeAccent,
                    iconBackground: AppColors.financeAccent.withValues(
                      alpha: .12,
                    ),
                    title: 'Netflix',
                    subtitle: 'Bills',
                    amount: '-\$15.99',
                    isPositive: false,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    onTap: () {
                      _openDetail(
                        context,
                        icon: Icons.play_circle_outline_rounded,
                        iconColor: AppColors.financeAccent,
                        iconBackground: AppColors.financeAccent.withValues(
                          alpha: .12,
                        ),
                        title: 'Netflix',
                        subtitle: 'Bills',
                        amount: '-\$15.99',
                        date: 'Jun 26, 2026',
                        time: '9:00 AM',
                        category: 'Bills',
                        payment: 'Card',
                        note: 'Monthly Netflix subscription',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OPEN EXPENSE DETAIL
  void _openDetail(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required String time,
    required String category,
    required String payment,
    String? note,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          icon: icon,
          iconColor: iconColor,
          iconBackground: iconBackground,
          title: title,
          subtitle: subtitle,
          amount: amount,
          date: date,
          time: time,
          category: category,
          payment: payment,
          note: note,
        ),
      ),
    );
  }
}
