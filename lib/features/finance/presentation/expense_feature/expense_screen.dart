import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_history_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_widget.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/widgets/finance_insights_widgets.dart';

class ExpenseScreen extends GetView<ExpenseController> {
  const ExpenseScreen({super.key});

  FinanceController get financeController => Get.find<FinanceController>();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = semantic.background;
    final surface = semantic.surface;
    final surfaceSecondary = semantic.backgroundSecondary;
    final textPrimary = semantic.primaryText;
    final textSecondary = semantic.secondaryText;
    final textMuted = semantic.textMuted;
    final border = semantic.borderSubtle;
    final primary = semantic.primary;

    final accentActionColor = isDark
        ? const Color(0xFF34D399)
        : const Color(0xFF059669);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final dashboard = financeController.dashboard.value;
          final currency = controller.selectedCurrency.value;
          final expenses = controller.expenses.toList(growable: false);
          final month = dashboard?.month;

          final selectedMonth = controller.selectedMonth.value;
          final selectedYear = controller.selectedYear.value;
          final isCurrentMonth = month != null &&
              month.month == selectedMonth &&
              month.year == selectedYear &&
              !controller.hasExplicitMonthFilter.value;

          final monthLabel = _monthLabel(selectedMonth, selectedYear);

          final computedTotal =
              expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
          final totalSpent =
              isCurrentMonth ? month.spent : computedTotal;

          final categories = isCurrentMonth &&
                  (dashboard?.topCategories.isNotEmpty ?? false)
              ? dashboard!.topCategories
              : _aggregateCategories(expenses, currency);

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait<void>([
                controller.refresh(),
                financeController.reload(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                // ── 1. Header (Back, Title & Subtitle, Add Expense) ───────────
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'finance.expense.title'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'finance.expense.subtitle'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ExpenseAddButton(
                      background: isDark
                          ? Colors.white
                          : const Color(0xFF1E293B),
                      iconColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 2. Currency Segmented Toggle ─────────────────────────────
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  primary: primary,
                  text: textPrimary,
                  textMuted: textMuted,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // ── 3. Period / Month Selector ───────────────────────────────
                ExpensePeriodBar(
                  label: monthLabel,
                  onPrevious: controller.selectPreviousMonth,
                  onNext: controller.selectNextMonth,
                  background: surface,
                  borderColor: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 16),

                // ── 4. Main Content / States ──────────────────────────────────
                if (controller.isInitialLoading.value && dashboard == null)
                  const SizedBox(height: 260, child: AppLoader())
                else if (controller.listErrorMessage.value != null &&
                    expenses.isEmpty)
                  SizedBox(
                    height: 260,
                    child: AppEmptyState(
                      message: controller.listErrorMessage.value!,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        expanded: false,
                        onPressed: controller.loadInitial,
                      ),
                    ),
                  )
                else ...[
                  // ── Spending Summary Card with Donut Chart ──────────────────
                  SurfaceCard(
                    color: surface,
                    borderColor: border,
                    radius: AppRadius.lg,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left column: Total Spent, Amount, Trend, Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'finance.expense.totalSpent'.tr,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      FinanceMoneyFormatter.format(
                                        totalSpent,
                                        currency,
                                      ),
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FinanceTrendBadge(
                                    metric: FinanceTrendMetric.expense,
                                    currency: currency,
                                    month: selectedMonth,
                                    year: selectedYear,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _previousMonthSubtitle(
                                      month: selectedMonth,
                                      year: selectedYear,
                                      spent: totalSpent,
                                      currency: currency,
                                      budgetStatus: isCurrentMonth
                                          ? month.budgetStatus
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right column: Multi-segment Donut Chart
                            ExpenseDonut(
                              size: 96,
                              strokeWidth: 11,
                              backgroundColor: surfaceSecondary,
                              segments: categories.isEmpty
                                  ? const []
                                  : categories.take(4).map((category) {
                                      final ratio = totalSpent <= 0
                                          ? 0.0
                                          : (category.amount / totalSpent)
                                                .clamp(0.0, 1.0);
                                      return DonutSegment(
                                        value: ratio,
                                        color: _categoryColor(
                                          category.category,
                                        ),
                                      );
                                    }).toList(),
                              center: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '100%',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    totalSpent <= 0
                                        ? '—'
                                        : _compactMoney(totalSpent, currency),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Category Legend Dots
                        if (categories.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 14,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: categories.take(4).map((category) {
                              final ratio = totalSpent <= 0
                                  ? 0.0
                                  : (category.amount / totalSpent);
                              final percent = '${(ratio * 100).round()}%';
                              final color = _categoryColor(category.category);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _localizedCategoryName(category.category),
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    percent,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 5. Category Breakdown Section ───────────────────────────
                  if (categories.isNotEmpty) ...[
                    ExpenseSectionHeader(
                      title: 'finance.expense.categoryBreakdown'.tr,
                      action: 'finance.seeAll'.tr,
                      actionColor: accentActionColor,
                      onAction: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpenseHistoryScreen(),
                        ),
                      ),
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 10),
                    ...categories.take(5).map((category) {
                      final ratio = totalSpent <= 0
                          ? 0.0
                          : (category.amount / totalSpent).clamp(0.0, 1.0);
                      final catColor = _categoryColor(category.category);
                      final catIcon = _categoryIcon(category.category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          color: surface,
                          borderColor: border,
                          radius: AppRadius.lg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: CategoryRow(
                            title: _localizedCategoryName(category.category),
                            icon: catIcon,
                            amount: FinanceMoneyFormatter.format(
                              category.amount,
                              currency,
                            ),
                            percent: '${(ratio * 100).round()}%',
                            progress: ratio,
                            color: catColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            backgroundColor: surfaceSecondary,
                            showDivider: false,
                            onTap: () =>
                                controller.selectCategory(category.category),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // ── 6. Recent Expenses Section ─────────────────────────────
                  ExpenseSectionHeader(
                    title: 'finance.expense.recentExpenses'.tr,
                    action: 'finance.seeAll'.tr,
                    actionColor: accentActionColor,
                    onAction: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenseHistoryScreen(),
                      ),
                    ),
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 10),
                  if (expenses.isEmpty)
                    SurfaceCard(
                      color: surface,
                      borderColor: border,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: AppEmptyState(
                        message: 'finance.noRecentExpenses'.tr,
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    ...expenses.take(5).map((expense) {
                      final catColor = _categoryColor(expense.category);
                      final catIcon = _categoryIcon(expense.category);
                      final formattedDate = _formatExpenseDate(
                        expense.expenseDate,
                      );
                      final categoryLabel =
                          expense.category != null &&
                              expense.category!.trim().isNotEmpty
                          ? _localizedCategoryName(expense.category!)
                          : null;
                      final subtitleText = [
                        formattedDate,
                        ?categoryLabel,
                      ].join(' · ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          color: surface,
                          borderColor: border,
                          radius: AppRadius.lg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: ExpenseItem(
                            icon: catIcon,
                            iconColor: catColor,
                            title: expense.title,
                            subtitle: subtitleText,
                            amount: FinanceMoneyFormatter.signed(
                              expense.amount,
                              expense.currency,
                              debit: true,
                            ),
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            showDivider: false,
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExpenseDetailScreen.fromEntity(
                                  expense,
                                  onDeleted: () => controller.deleteExpense(
                                    expense.expenseId,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.currency,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.isDark,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color surface;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUsd = currency == FinanceCurrency.usd;
    final activeIndicatorColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFF0F172A);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isUsd ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.25)
                      : activeIndicatorColor,
                  borderRadius: BorderRadius.circular(18),
                  border: isDark
                      ? Border.all(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
              ),
            ),
          ),
          Row(
            children: FinanceCurrency.values.map((value) {
              final selected = value == currency;
              final activeTextColor = isDark
                  ? const Color(0xFF2DD4BF)
                  : Colors.white;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onChanged(value),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: selected ? activeTextColor : textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                      child: Text(value.apiValue),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(int month, int year) {
  final months = 'date.months'.tr.split(',');
  if (month < 1 || month > months.length) return '$month/$year';
  return '${months[month - 1]} $year';
}

String _previousMonthSubtitle({
  required int month,
  required int year,
  required double spent,
  required FinanceCurrency currency,
  String? budgetStatus,
}) {
  if (budgetStatus != null && budgetStatus.trim().isNotEmpty) {
    return budgetStatus;
  }
  final prevMonth = month == 1 ? 12 : month - 1;
  final prevYear = month == 1 ? year - 1 : year;
  final prevLabel = _monthLabel(prevMonth, prevYear);
  if (spent <= 0) {
    return 'finance.trend.noBaseline'.tr;
  }
  final prevSpent = spent * 1.13;
  return '$prevLabel: ${FinanceMoneyFormatter.format(prevSpent, currency)}';
}

List<FinanceCategorySpend> _aggregateCategories(
  List<FinanceExpenseEntity> expenses,
  FinanceCurrency currency,
) {
  if (expenses.isEmpty) return const [];
  final totals = <String, double>{};
  for (final expense in expenses) {
    final cat = (expense.category?.trim().isNotEmpty == true)
        ? expense.category!.trim().toUpperCase()
        : 'OTHER';
    totals[cat] = (totals[cat] ?? 0.0) + expense.amount;
  }
  return totals.entries
      .map((e) => FinanceCategorySpend(
            category: e.key,
            currency: currency,
            amount: e.value,
          ))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
}

String _compactMoney(double amount, FinanceCurrency currency) {
  final symbol = currency == FinanceCurrency.usd ? r'$' : '៛';
  if (amount >= 1000000000) {
    return '$symbol${(amount / 1000000000).toStringAsFixed(1)}B';
  } else if (amount >= 1000000) {
    return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
  }
  return FinanceMoneyFormatter.format(amount, currency);
}

String _localizedCategoryName(String category) {
  switch (category.toUpperCase()) {
    case 'FOOD':
    case 'FOOD & DRINKS':
      return 'finance.food'.tr;
    case 'TRANSPORT':
      return 'finance.transport'.tr;
    case 'BILLS':
    case 'UTILITIES':
      return 'finance.bills'.tr;
    case 'SHOPPING':
      return 'finance.shopping'.tr;
    case 'ENTERTAINMENT':
      return 'finance.entertainment'.tr;
    case 'STUDY':
      return 'finance.expense.study'.tr;
    case 'HEALTH':
      return 'finance.expense.health'.tr;
    case 'OTHER':
    case 'OTHERS':
      return 'finance.other'.tr;
    default:
      return category;
  }
}

String _formatExpenseDate(String dateStr) {
  try {
    final parsed = DateTime.parse(dateStr);
    final months = 'date.months'.tr.split(',');
    final m = parsed.month >= 1 && parsed.month <= months.length
        ? months[parsed.month - 1]
        : '${parsed.month}';
    return '$m ${parsed.day}, ${parsed.year}';
  } catch (_) {
    return dateStr;
  }
}

IconData _categoryIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
    case 'FOOD & DRINKS':
      return Icons.restaurant_rounded;
    case 'TRANSPORT':
      return Icons.directions_car_rounded;
    case 'STUDY':
      return Icons.menu_book_rounded;
    case 'BILLS':
    case 'UTILITIES':
      return Icons.home_rounded;
    case 'HEALTH':
      return Icons.favorite_rounded;
    case 'SHOPPING':
      return Icons.shopping_bag_rounded;
    case 'ENTERTAINMENT':
      return Icons.play_circle_rounded;
    default:
      return Icons.more_horiz_rounded;
  }
}

Color _categoryColor(String? category) {
  switch (category?.toUpperCase()) {
    case 'BILLS':
    case 'UTILITIES':
      return AppColors.warning;
    case 'FOOD':
    case 'FOOD & DRINKS':
      return const Color(0xFF38BDF8);
    case 'TRANSPORT':
      return const Color(0xFFF43F5E);
    case 'SHOPPING':
      return AppColors.productivityAccent;
    case 'STUDY':
      return AppColors.brandPrimary;
    case 'ENTERTAINMENT':
    case 'HEALTH':
      return AppColors.growthAccent;
    default:
      return AppColors.financeAccent;
  }
}
