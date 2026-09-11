import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
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

class ExpenseScreen extends GetView<ExpenseController> {
  const ExpenseScreen({super.key});

  FinanceController get financeController => Get.find<FinanceController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final dashboard = financeController.dashboard.value;
          final currency = controller.selectedCurrency.value;
          final expenses = controller.expenses.toList(growable: false);
          final month = dashboard?.month;
          final categories = dashboard?.topCategories ?? const [];
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
                Row(
                  children: [
                    AppBackButton(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'finance.expense.title'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    ExpenseAddButton(
                      background: primary,
                      iconColor: inverseText,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  primary: primary,
                  text: textPrimary,
                ),
                const SizedBox(height: 16),
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
                  SurfaceCard(
                    color: surface,
                    borderColor: border,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        ExpenseDonut(
                          size: 92,
                          strokeWidth: 10,
                          backgroundColor: surfaceSecondary,
                          segments: categories.isEmpty
                              ? const []
                              : categories.take(4).map((category) {
                                  final total = month?.spent ?? 0;
                                  final ratio = total <= 0
                                      ? 0.0
                                      : (category.amount / total).clamp(
                                          0.0,
                                          1.0,
                                        );
                                  return DonutSegment(
                                    value: ratio,
                                    color: _categoryColor(category.category),
                                  );
                                }).toList(),
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
                              const SizedBox(height: 4),
                              Text(
                                month == null
                                    ? '—'
                                    : FinanceMoneyFormatter.format(
                                        month.spent,
                                        currency,
                                      ),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                month == null
                                    ? 'Loading dashboard…'
                                    : '${month.month}/${month.year} · ${currency.apiValue}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (categories.isNotEmpty) ...[
                    Text(
                      'finance.expense.categoryBreakdown'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      color: surface,
                      borderColor: border,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: categories.take(5).map((category) {
                          final total = month?.spent ?? 0;
                          final ratio = total <= 0
                              ? 0.0
                              : (category.amount / total).clamp(0.0, 1.0);
                          return CategoryRow(
                            title: category.category,
                            amount: FinanceMoneyFormatter.format(
                              category.amount,
                              currency,
                            ),
                            percent: '${(ratio * 100).round()}%',
                            progress: ratio,
                            color: _categoryColor(category.category),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            backgroundColor: surfaceSecondary,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'finance.expense.recentExpenses'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExpenseHistoryScreen(),
                          ),
                        ),
                        child: Text('finance.seeAll'.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    SurfaceCard(
                      color: surface,
                      borderColor: border,
                      child: AppEmptyState(
                        message: 'finance.noRecentExpenses'.tr,
                        icon: Icons.receipt_long_outlined,
                      ),
                    )
                  else
                    ...expenses.take(5).map((expense) {
                      final accent = _categoryColor(expense.category);
                      return ExpenseItem(
                        icon: _categoryIcon(expense.category),
                        iconColor: accent,
                        title: expense.title,
                        subtitle: [
                          expense.expenseDate,
                          if (expense.category?.trim().isNotEmpty == true)
                            expense.category!,
                        ].join(' · '),
                        amount: FinanceMoneyFormatter.signed(
                          expense.amount,
                          expense.currency,
                          debit: true,
                        ),
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpenseDetailScreen.fromEntity(
                              expense,
                              onEdit: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddExpenseScreen(expense: expense),
                                ),
                              ),
                              onDeleted: () =>
                                  controller.deleteExpense(expense.expenseId),
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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
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
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
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

IconData _categoryIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
      return Icons.restaurant_outlined;
    case 'TRANSPORT':
      return Icons.directions_car_outlined;
    case 'STUDY':
      return Icons.menu_book_outlined;
    case 'BILLS':
    case 'UTILITIES':
      return Icons.bolt_outlined;
    case 'HEALTH':
      return Icons.favorite_border_rounded;
    case 'SHOPPING':
      return Icons.shopping_bag_outlined;
    case 'ENTERTAINMENT':
      return Icons.play_circle_outline_rounded;
    default:
      return Icons.receipt_long_outlined;
  }
}

Color _categoryColor(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
      return AppColors.growthAccent;
    case 'TRANSPORT':
      return AppColors.brandPrimary;
    case 'STUDY':
      return AppColors.productivityAccent;
    case 'BILLS':
    case 'UTILITIES':
      return AppColors.financeAccent;
    default:
      return AppColors.financeAccent;
  }
}
