import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

/// Backend-backed monthly budget view.
///
/// The API exposes the current budget as a currency/month/year-scoped
/// resource. This screen intentionally does not use the unfiltered historical
/// list endpoint, so USD and KHR can never appear together.
class BudgetScreen extends GetView<BudgetController> {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final secondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Obx(() {
      final value = controller.budget.value;
      final loading = controller.isLoading.value;
      final error = controller.listErrorMessage.value;
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                Row(
                  children: [
                    AppBackButton(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'finance.budget.title'.tr,
                        style: TextStyle(
                          color: text,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SetBudgetScreen(),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: inverse,
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
                const SizedBox(height: 14),
                _CurrencyBar(
                  value: controller.selectedCurrency.value,
                  onChanged: controller.selectCurrency,
                  text: text,
                  muted: muted,
                  secondary: secondary,
                  border: border,
                  primary: primary,
                ),
                const SizedBox(height: 10),
                _PeriodBar(
                  month: controller.selectedMonth.value,
                  year: controller.selectedYear.value,
                  onPrevious: controller.selectPreviousMonth,
                  onNext: controller.selectNextMonth,
                  text: text,
                  muted: muted,
                  secondary: secondary,
                  border: border,
                ),
                const SizedBox(height: 18),
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
                        onPressed: controller.load,
                        height: 46,
                      ),
                    ),
                  )
                else if (value == null)
                  SizedBox(
                    height: 360,
                    child: AppEmptyState(
                      message: 'finance.budget.noBudget'.tr,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  )
                else
                  _BudgetContent(
                    budget: value,
                    surface: surface,
                    secondary: secondary,
                    text: text,
                    muted: muted,
                    border: border,
                    primary: primary,
                    onOpenDetail: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BudgetDetailScreen(budget: value),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.value,
    required this.onChanged,
    required this.text,
    required this.muted,
    required this.secondary,
    required this.border,
    required this.primary,
  });

  final FinanceCurrency value;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color text;
  final Color muted;
  final Color secondary;
  final Color border;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final currencies = FinanceCurrency.values;
    final selectedIndex = currencies.indexOf(value);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / currencies.length;

          return SizedBox(
            height: 40,
            child: Stack(
              children: [
                // Sliding selected background
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),

                // Currency buttons
                Row(
                  children: currencies.map((currency) {
                    final selected = currency == value;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(currency),
                        child: Center(
                          child: Text(
                            currency.apiValue,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.month,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.text,
    required this.muted,
    required this.secondary,
    required this.border,
  });

  final int month;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Color text;
  final Color muted;
  final Color secondary;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final names = 'date.months'.tr.split(',');
    final label = month >= 1 && month <= names.length
        ? '${names[month - 1]} $year'
        : '$month/$year';
    return Container(
      decoration: BoxDecoration(
        color: secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: Icon(Icons.chevron_left, color: muted),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.chevron_right, color: muted),
          ),
        ],
      ),
    );
  }
}

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.budget,
    required this.surface,
    required this.secondary,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.onOpenDetail,
  });

  final FinanceBudgetEntity budget;
  final Color surface;
  final Color secondary;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final progress = budget.totalBudget <= 0
        ? 0.0
        : (budget.spentAmount / budget.totalBudget).clamp(0.0, 1.0);
    final percent = budget.totalBudget <= 0
        ? 0
        : ((budget.spentAmount / budget.totalBudget) * 100).round();
    final statusColor = _statusColor(budget.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onOpenDetail,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${budget.month}/${budget.year}',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _StatusChip(status: budget.status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${FinanceMoneyFormatter.format(budget.spentAmount, budget.currency)} / ${FinanceMoneyFormatter.format(budget.totalBudget, budget.currency)}',
                  style: TextStyle(
                    color: text,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: secondary,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$percent% ${'finance.budget.used'.tr.toLowerCase()}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${FinanceMoneyFormatter.format(budget.remainingAmount, budget.currency)} ${'finance.budget.remaining'.tr.toLowerCase()}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'finance.budget.categoryBudgets'.tr,
          style: TextStyle(
            color: text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: budget.categories.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'finance.budget.noCategories'.tr,
                    style: TextStyle(color: muted),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < budget.categories.length; i++) ...[
                      _CategoryRow(
                        category: budget.categories[i],
                        currency: budget.currency,
                        text: text,
                        muted: muted,
                        secondary: secondary,
                        color: _categoryColor(i),
                        onTap: onOpenDetail,
                      ),
                      if (i != budget.categories.length - 1)
                        Divider(height: 1, color: border),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.currency,
    required this.text,
    required this.muted,
    required this.secondary,
    required this.color,
    required this.onTap,
  });

  final FinanceCategoryBudget category;
  final FinanceCurrency currency;
  final Color text;
  final Color muted;
  final Color secondary;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = category.allocatedAmount <= 0
        ? 0.0
        : (category.spentAmount / category.allocatedAmount).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.category,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: text, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${FinanceMoneyFormatter.format(category.spentAmount, currency)} / ${FinanceMoneyFormatter.format(category.allocatedAmount, currency)}',
                  style: TextStyle(
                    color: text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$percent%', style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: secondary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'LIMIT_REACHED':
      return AppColors.danger;
    case 'WARNING':
      return const Color(0xFFC58A00);
    case 'SAFE':
      return AppColors.success;
    default:
      return AppColors.brandPrimary;
  }
}

Color _categoryColor(int index) => <Color>[
  AppColors.growthAccent,
  AppColors.brandPrimary,
  AppColors.productivityAccent,
  AppColors.financeAccent,
][index % 4];
