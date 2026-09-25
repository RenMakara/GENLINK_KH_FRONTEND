import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({super.key, required this.budget});

  final FinanceBudgetEntity budget;

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
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            Row(
              children: [
                AppBackButton(),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'finance.budget.title'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                InkWell(
                  onTap: () => _edit(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Icon(Icons.edit_outlined, size: 19, color: primary),
                  ),
                ),

                const SizedBox(width: 8),

                InkWell(
                  onTap: () => _delete(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SummaryCard(
              budget: budget,
              surface: surface,
              secondary: secondary,
              text: text,
              muted: muted,
              border: border,
            ),

            const SizedBox(height: 20),

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
                          _CategoryDetail(
                            category: budget.categories[i],
                            currency: budget.currency,
                            text: text,
                            muted: muted,
                            secondary: secondary,
                            color: _categoryColor(i),
                          ),
                          if (i != budget.categories.length - 1)
                            Divider(height: 1, color: border),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context) {
    Navigator.pop(context);
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => SetBudgetScreen(budget: budget)),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'finance.budget.deleteBudget'.tr,
      message: 'finance.budget.deleteBudgetHint'.tr,
      confirmLabel: 'finance.expense.delete'.tr,
      cancelLabel: 'finance.expense.cancel'.tr,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await Get.find<BudgetController>().deleteBudget(
      budgetId: budget.budgetId,
    );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      final error = Get.find<BudgetController>().mutationErrorMessage.value;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'common.error'.tr)));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.budget,
    required this.surface,
    required this.secondary,
    required this.text,
    required this.muted,
    required this.border,
  });

  final FinanceBudgetEntity budget;
  final Color surface;
  final Color secondary;
  final Color text;
  final Color muted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final progress = budget.totalBudget <= 0
        ? 0.0
        : (budget.spentAmount / budget.totalBudget).clamp(0.0, 1.0);
    final statusColor = _statusColor(budget.status);
    return Container(
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
              Text(
                '${budget.month}/${budget.year}',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                budget.currency.apiValue,
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Text(
                budget.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'finance.budget.totalBudget'.tr,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            FinanceMoneyFormatter.format(budget.totalBudget, budget.currency),
            style: TextStyle(
              color: text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: secondary,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                label: 'finance.budget.spent'.tr,
                value: FinanceMoneyFormatter.format(
                  budget.spentAmount,
                  budget.currency,
                ),
                text: text,
                muted: muted,
              ),
              _Stat(
                label: 'finance.budget.remaining'.tr,
                value: FinanceMoneyFormatter.format(
                  budget.remainingAmount,
                  budget.currency,
                ),
                text: text,
                muted: muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.text,
    required this.muted,
  });
  final String label;
  final String value;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: text, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.category,
    required this.currency,
    required this.text,
    required this.muted,
    required this.secondary,
    required this.color,
  });

  final FinanceCategoryBudget category;
  final FinanceCurrency currency;
  final Color text;
  final Color muted;
  final Color secondary;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = category.allocatedAmount <= 0
        ? 0.0
        : (category.spentAmount / category.allocatedAmount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category.category,
                  style: TextStyle(color: text, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                FinanceMoneyFormatter.format(
                  category.remainingAmount,
                  currency,
                ),
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: secondary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 6),
          Text(
            '${FinanceMoneyFormatter.format(category.spentAmount, currency)} / ${FinanceMoneyFormatter.format(category.allocatedAmount, currency)}',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'LIMIT_REACHED':
      return AppColors.danger;
    case 'WARNING':
      return AppColors.warning;
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
