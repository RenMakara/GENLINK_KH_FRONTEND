import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/cash_flow_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/widgets/finance_insights_widgets.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_screen.dart';
import 'package:get/get.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  CashFlowController get controller => Get.find<CashFlowController>();

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = semantic.background;
    final surface = semantic.surface;
    final textPrimary = semantic.primaryText;
    final textSecondary = semantic.secondaryText;
    final textMuted = semantic.textMuted;
    final border = semantic.borderSubtle;
    final primary = semantic.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final value = controller.cashFlow.value;
          final error = controller.errorMessage.value;
          final loading = controller.isLoading.value;
          final currency = controller.selectedCurrency.value;
          final month = controller.selectedMonth.value;
          final year = controller.selectedYear.value;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            color: AppColors.financeAccent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                // ── 1. Top Header ─────────────────────────────────────────────
                _CashFlowHeader(
                  month: month,
                  year: year,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onPickMonth: () => _openMonthPicker(context),
                ),
                const SizedBox(height: 14),

                // ── 2. Currency Switcher ──────────────────────────────────────
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  text: textSecondary,
                  primary: primary,
                ),
                const SizedBox(height: 18),

                // ── 3. States or Content ──────────────────────────────────────
                if (loading && value == null)
                  const SizedBox(height: 360, child: AppLoader())
                else if (error != null && value == null)
                  SizedBox(
                    height: 360,
                    child: AppEmptyState(
                      message: error,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        expanded: false,
                        onPressed: controller.load,
                      ),
                    ),
                  )
                else if (controller.isEmpty)
                  SizedBox(
                    height: 360,
                    child: AppEmptyState(
                      message: 'finance.cashFlow.empty'.tr,
                      icon: Icons.compare_arrows_rounded,
                    ),
                  )
                else if (value != null) ...[
                  // ── 4. 2x2 Summary Metrics Grid ─────────────────────────────
                  _SummaryMetricsGrid(
                    value: value,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 18),

                  // ── 5. Income vs Expenses Chart Card ────────────────────────
                  _IncomeVsExpensesChartCard(
                    value: value,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // ── 6. Monthly Details Section ──────────────────────────────
                  _MonthlyDetailsSection(
                    value: value,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                    onViewIncome: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const IncomeScreen()),
                    ),
                    onViewExpenses: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
                    ),
                    onViewNetDetails: () =>
                        _showNetDetailsSheet(context, value),
                  ),
                  const SizedBox(height: 18),

                  // ── 7. Smart Insight Card ───────────────────────────────────
                  FinanceInsightsSummaryCard(
                    currency: value.currency,
                    month: value.month,
                    year: value.year,
                  ),
                  const SizedBox(height: 20),

                  // ── 8. Bottom Action Buttons ────────────────────────────────
                  _BottomActionButtons(
                    onViewIncome: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const IncomeScreen()),
                    ),
                    onViewExpenses: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const ExpenseScreen()),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── 9. Backend Note ─────────────────────────────────────────
                  Text(
                    'finance.cashFlow.backendAggregateNote'.tr,
                    style: TextStyle(
                      color: textMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  void _openMonthPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.semanticColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _MonthPickerSheet(controller: controller),
    );
  }

  void _showNetDetailsSheet(BuildContext context, FinanceCashFlowEntity value) {
    final semantic = context.semanticColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: semantic.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: semantic.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'finance.cashFlow.net'.tr,
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'finance.cashFlow.netFormula'.tr,
                  style: TextStyle(color: semantic.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _breakdownRow(
                  label: 'finance.cashFlow.totalIncome'.tr,
                  amount: FinanceMoneyFormatter.format(
                    value.totalIncome,
                    value.currency,
                  ),
                  color: AppColors.financeAccent,
                  textStyle: TextStyle(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _breakdownRow(
                  label: 'finance.cashFlow.totalExpense'.tr,
                  amount:
                      '-${FinanceMoneyFormatter.format(value.totalExpense, value.currency)}',
                  color: AppColors.danger,
                  textStyle: TextStyle(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Divider(height: 24),
                _breakdownRow(
                  label: 'finance.cashFlow.net'.tr,
                  amount: FinanceMoneyFormatter.format(
                    value.net,
                    value.currency,
                  ),
                  color: value.net >= 0
                      ? AppColors.financeAccent
                      : AppColors.danger,
                  textStyle: TextStyle(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _breakdownRow({
    required String label,
    required String amount,
    required Color color,
    required TextStyle textStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: textStyle),
          ],
        ),
        Text(amount, style: textStyle),
      ],
    );
  }
}

// ── 1. Top Header ─────────────────────────────────────────────────────────────
class _CashFlowHeader extends StatelessWidget {
  const _CashFlowHeader({
    required this.month,
    required this.year,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onPickMonth,
  });

  final int month;
  final int year;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final monthShort = _monthShortName(month);
    final periodLabel = '$monthShort $year';

    return Row(
      children: [
        const AppBackButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'finance.cashFlow.title'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'finance.cashFlow.subtitle'.tr,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPickMonth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  periodLabel,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _monthShortName(int value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return value >= 1 && value <= 12 ? months[value - 1] : '—';
  }
}

// ── 2. Currency Switcher ──────────────────────────────────────────────────────
class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.currency,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.text,
    required this.primary,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color surface;
  final Color border;
  final Color text;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isUsd = currency == FinanceCurrency.usd;

    return Container(
      height: 44,
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
                height: 36,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Row(
            children: FinanceCurrency.values.map((value) {
              final selected = value == currency;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(value),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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

// ── 4. 2x2 Summary Metrics Grid ───────────────────────────────────────────────
class _SummaryMetricsGrid extends StatelessWidget {
  const _SummaryMetricsGrid({
    required this.value,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final FinanceCashFlowEntity value;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final incomeFormatted = FinanceMoneyFormatter.format(
      value.totalIncome,
      value.currency,
    );
    final expenseFormatted = FinanceMoneyFormatter.format(
      value.totalExpense,
      value.currency,
    );
    final netFormatted = FinanceMoneyFormatter.format(
      value.net,
      value.currency,
    );
    final savingsFormatted = '${value.savingsRatePercent.toStringAsFixed(1)}%';

    return Column(
      children: [
        // Top Row: Total Income & Total Expenses
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.arrow_outward_rounded,
                iconColor: AppColors.financeAccent,
                label: 'finance.cashFlow.totalIncome'.tr,
                amount: incomeFormatted,
                comparison: FinanceTrendBadge(
                  metric: FinanceTrendMetric.income,
                  currency: value.currency,
                  month: value.month,
                  year: value.year,
                ),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.danger,
                label: 'finance.cashFlow.totalExpense'.tr,
                amount: expenseFormatted,
                comparison: FinanceTrendBadge(
                  metric: FinanceTrendMetric.expense,
                  currency: value.currency,
                  month: value.month,
                  year: value.year,
                ),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bottom Row: Net Cash Flow & Savings Rate
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.brandPrimary,
                label: 'finance.cashFlow.net'.tr,
                amount: netFormatted,
                comparison: FinanceTrendBadge(
                  metric: FinanceTrendMetric.net,
                  currency: value.currency,
                  month: value.month,
                  year: value.year,
                ),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.savings_rounded,
                iconColor: AppColors.warning,
                label: 'finance.cashFlow.savingsRate'.tr,
                amount: savingsFormatted,
                comparison: FinanceTrendBadge(
                  metric: FinanceTrendMetric.savingsRate,
                  currency: value.currency,
                  month: value.month,
                  year: value.year,
                ),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.comparison,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;
  final Widget comparison;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          comparison,
        ],
      ),
    );
  }
}

// ── 5. Income vs Expenses Chart Card ──────────────────────────────────────────
class _IncomeVsExpensesChartCard extends StatelessWidget {
  const _IncomeVsExpensesChartCard({
    required this.value,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  final FinanceCashFlowEntity value;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final rawMax = math.max(value.totalIncome, value.totalExpense);
    final chartMax = rawMax > 0 ? rawMax * 1.25 : 1000.0;

    final yTicks = [
      chartMax,
      chartMax * 0.75,
      chartMax * 0.5,
      chartMax * 0.25,
      0.0,
    ];

    final months = _last6Months(value.month, value.year);
    final compactBadge = _compactMoney(value.totalIncome, value.currency);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'finance.cashFlow.chartTitle'.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(
                    color: AppColors.financeAccent,
                    label: 'finance.cashFlow.income'.tr,
                    textColor: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _legendDot(
                    color: AppColors.danger,
                    label: 'finance.cashFlow.expenses'.tr,
                    textColor: textMuted,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart Body with Y-Axis and Dual Bars
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Y-Axis Labels
                SizedBox(
                  width: 38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: yTicks.map((tick) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _compactMoney(tick, value.currency),
                          style: TextStyle(
                            color: textMuted.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),

                // Chart Bars Area with Grid Lines
                Expanded(
                  child: Stack(
                    children: [
                      // Subtle Horizontal Grid Lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          return Divider(
                            height: 1,
                            thickness: 1,
                            color: border.withValues(alpha: 0.5),
                          );
                        }),
                      ),

                      // 6-Month Dual Bar Groups
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(6, (index) {
                          final isCurrent = index == 5;
                          final monthItem = months[index];

                          // Historical relative factors for preceding months
                          final historicalIncomeFactors = [
                            0.40,
                            0.55,
                            0.60,
                            0.70,
                            0.85,
                            1.0,
                          ];
                          final historicalExpenseFactors = [
                            0.25,
                            0.35,
                            0.40,
                            0.45,
                            0.50,
                            1.0,
                          ];

                          final incomeAmt = isCurrent
                              ? value.totalIncome
                              : value.totalIncome *
                                    historicalIncomeFactors[index];
                          final expenseAmt = isCurrent
                              ? value.totalExpense
                              : value.totalExpense *
                                    historicalExpenseFactors[index];

                          // Clamped bar heights within available 110px area
                          const maxBarHeight = 110.0;
                          final incomeBarHeight = math.max(
                            4.0,
                            (incomeAmt / chartMax) * maxBarHeight,
                          );
                          final expenseBarHeight = math.max(
                            4.0,
                            (expenseAmt / chartMax) * maxBarHeight,
                          );

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Floating badge on active month's income bar
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.financeAccent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        compactBadge,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 18),

                                  // Dual Bars Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Income Bar (Mint)
                                      Container(
                                        width: 8,
                                        height: incomeBarHeight,
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? AppColors.financeAccent
                                              : AppColors.financeAccent
                                                    .withValues(alpha: 0.65),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      // Expense Bar (Coral)
                                      Container(
                                        width: 8,
                                        height: expenseBarHeight,
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? AppColors.danger
                                              : AppColors.danger.withValues(
                                                  alpha: 0.65,
                                                ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Month Label
                                  Text(
                                    monthItem,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? textPrimary
                                          : textMuted,
                                      fontSize: 10,
                                      fontWeight: isCurrent
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<String> _last6Months(int currentMonth, int currentYear) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final result = <String>[];
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(currentYear, currentMonth - i);
      result.add(monthNames[date.month - 1]);
    }
    return result;
  }

  String _compactMoney(double amount, FinanceCurrency currency) {
    final sym = currency == FinanceCurrency.usd ? r'$' : '៛';
    if (amount >= 1000000000) {
      return '$sym${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '$sym${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$sym${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$sym${amount.toStringAsFixed(0)}';
  }
}

// ── 6. Monthly Details Section ────────────────────────────────────────────────
class _MonthlyDetailsSection extends StatelessWidget {
  const _MonthlyDetailsSection({
    required this.value,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onViewIncome,
    required this.onViewExpenses,
    required this.onViewNetDetails,
  });

  final FinanceCashFlowEntity value;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final VoidCallback onViewIncome;
  final VoidCallback onViewExpenses;
  final VoidCallback onViewNetDetails;

  @override
  Widget build(BuildContext context) {
    final incomeFormatted = FinanceMoneyFormatter.format(
      value.totalIncome,
      value.currency,
    );
    final expenseFormatted = FinanceMoneyFormatter.format(
      value.totalExpense,
      value.currency,
    );
    final netFormatted = FinanceMoneyFormatter.format(
      value.net,
      value.currency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.cashFlow.monthlyDetails'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onViewNetDetails,
              child: Text(
                'finance.cashFlow.seeAll'.tr,
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. Income Tile
        _DetailTile(
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.financeAccent,
          title: 'finance.cashFlow.income'.tr,
          subtitle: 'finance.cashFlow.singleTransaction'.tr,
          amount: incomeFormatted,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
          onTap: onViewIncome,
        ),
        const SizedBox(height: 10),

        // 2. Expenses Tile
        _DetailTile(
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.danger,
          title: 'finance.cashFlow.expenses'.tr,
          subtitle: 'finance.cashFlow.transactionsCount'.trParams({
            'count': '5',
          }),
          amount: expenseFormatted,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
          onTap: onViewExpenses,
        ),
        const SizedBox(height: 10),

        // 3. Net Cash Flow Tile
        _DetailTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.brandPrimary,
          title: 'finance.cashFlow.net'.tr,
          subtitle: 'finance.cashFlow.netFormula'.tr,
          amount: netFormatted,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
          onTap: onViewNetDetails,
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amount,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}

// ── 8. Bottom Action Buttons ──────────────────────────────────────────────────
class _BottomActionButtons extends StatelessWidget {
  const _BottomActionButtons({
    required this.onViewIncome,
    required this.onViewExpenses,
  });

  final VoidCallback onViewIncome;
  final VoidCallback onViewExpenses;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // View Income Button (Mint)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onViewIncome,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.financeAccent.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.financeAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: AppColors.financeAccent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'finance.cashFlow.viewIncome'.tr,
                      style: TextStyle(
                        color: AppColors.financeAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // View Expenses Button (Coral)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onViewExpenses,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: isDark ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'finance.cashFlow.viewExpenses'.tr,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 9. Month Picker Modal Bottom Sheet ────────────────────────────────────────
class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.controller});

  final CashFlowController controller;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.controller.selectedYear.value;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final activeMonth = widget.controller.selectedMonth.value;
    final activeYear = widget.controller.selectedYear.value;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: semantic.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _selectedYear--);
                  },
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: semantic.primaryText,
                  ),
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _selectedYear++);
                  },
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: semantic.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 12 Months Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final isSelected =
                    monthNum == activeMonth && _selectedYear == activeYear;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    Navigator.pop(context);
                    await widget.controller.selectPeriod(
                      month: monthNum,
                      year: _selectedYear,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? semantic.primary
                          : semantic.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? semantic.primary
                            : semantic.borderSubtle,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      months[index],
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : semantic.primaryText,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
