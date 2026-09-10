import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/cash_flow_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

class CashFlowScreen extends StatelessWidget {
  const CashFlowScreen({super.key});

  CashFlowController get controller => Get.find<CashFlowController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final secondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final value = controller.cashFlow.value;
          final error = controller.errorMessage.value;
          final loading = controller.isLoading.value;
          final currency = controller.selectedCurrency.value;
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'finance.cashFlow.title'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  primary: primary,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 16),
                _PeriodBar(
                  month: controller.selectedMonth.value,
                  year: controller.selectedYear.value,
                  onPrevious: controller.selectPreviousMonth,
                  onNext: controller.selectNextMonth,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 18),
                if (loading && value == null)
                  const SizedBox(height: 300, child: AppLoader())
                else if (error != null && value == null)
                  SizedBox(
                    height: 300,
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
                    height: 300,
                    child: AppEmptyState(
                      message: 'finance.cashFlow.empty'.tr,
                      icon: Icons.compare_arrows_rounded,
                    ),
                  )
                else if (value != null) ...[
                  _MetricCard(
                    label: 'finance.cashFlow.totalIncome'.tr,
                    amount: FinanceMoneyFormatter.format(
                      value.totalIncome,
                      value.currency,
                    ),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.financeAccent,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    label: 'finance.cashFlow.totalExpense'.tr,
                    amount: FinanceMoneyFormatter.format(
                      value.totalExpense,
                      value.currency,
                    ),
                    icon: Icons.trending_down_rounded,
                    color: AppColors.brandPrimary,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _MetricCard(
                    label: 'finance.cashFlow.net'.tr,
                    amount: FinanceMoneyFormatter.format(
                      value.net,
                      value.currency,
                    ),
                    icon: value.net >= 0
                        ? Icons.account_balance_wallet_outlined
                        : Icons.warning_amber_rounded,
                    color: value.net >= 0
                        ? AppColors.success
                        : const Color(0xFFB00020),
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings_outlined, color: primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'finance.cashFlow.savingsRate'.tr,
                            style: TextStyle(
                              color: textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${value.savingsRatePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'finance.cashFlow.backendAggregateNote'.tr,
                    style: TextStyle(color: textMuted, fontSize: 12),
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
}

class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.currency,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textPrimary,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color surface;
  final Color border;
  final Color primary;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FinanceCurrency.values.map((item) {
        final selected = item == currency;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item == FinanceCurrency.usd ? 8 : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? primary : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? primary : border),
                ),
                child: Text(
                  item.apiValue,
                  style: TextStyle(
                    color: selected ? Colors.white : textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.month,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final int month;
  final int year;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final label = '${_monthName(month)} $year';
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: Icon(Icons.chevron_left_rounded, color: textMuted),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.chevron_right_rounded, color: textMuted),
          ),
        ],
      ),
    );
  }

  String _monthName(int value) {
    final names = 'date.months'.tr.split(',');
    return value >= 1 && value <= names.length ? names[value - 1] : '—';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
