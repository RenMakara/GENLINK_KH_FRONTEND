import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/cash_flow_feature/cash_flow_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/learn_finance_feature/learn_finance.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import 'package:genlink_frontend/features/finance/widgets/finance_widget.dart';

/// Finance home. The dashboard, Income, Cash Flow, and Expense flows are
/// backed by the Finance API; other linked modules keep their phase boundaries.
class FinanceScreen extends GetView<FinanceController> {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    return Obx(() {
      final dashboard = controller.dashboard.value;
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                _FinanceHeader(
                  selectedCurrency: controller.selectedCurrency.value,
                  onCurrencyChanged: controller.selectCurrency,
                ),
                const SizedBox(height: 18),
                if (controller.isLoading.value && dashboard == null)
                  SizedBox(
                    height: 500,
                    child: AppLoader(message: 'finance.loadingDashboard'.tr),
                  )
                else if (dashboard == null)
                  SizedBox(
                    height: 500,
                    child: AppEmptyState(
                      message:
                          controller.errorMessage.value ?? 'common.error'.tr,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        expanded: false,
                        onPressed: controller.reload,
                      ),
                    ),
                  )
                else
                  _FinanceDashboardContent(
                    dashboard: dashboard,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  final FinanceCurrency selectedCurrency;
  final ValueChanged<FinanceCurrency> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 12),
        _CurrencySelector(
          selectedCurrency: selectedCurrency,
          onChanged: onCurrencyChanged,
          background: surface,
          selectedBackground: surfaceSecondary,
          border: border,
          textColor: textPrimary,
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.selectedCurrency,
    required this.onChanged,
    required this.background,
    required this.selectedBackground,
    required this.border,
    required this.textColor,
  });

  final FinanceCurrency selectedCurrency;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color background;
  final Color selectedBackground;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CurrencyChoice(
            currency: FinanceCurrency.usd,
            selected: selectedCurrency == FinanceCurrency.usd,
            onTap: () => onChanged(FinanceCurrency.usd),
            selectedBackground: selectedBackground,
            border: border,
            textColor: textColor,
          ),
          _CurrencyChoice(
            currency: FinanceCurrency.khr,
            selected: selectedCurrency == FinanceCurrency.khr,
            onTap: () => onChanged(FinanceCurrency.khr),
            selectedBackground: selectedBackground,
            border: border,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _CurrencyChoice extends StatelessWidget {
  const _CurrencyChoice({
    required this.currency,
    required this.selected,
    required this.onTap,
    required this.selectedBackground,
    required this.border,
    required this.textColor,
  });

  final FinanceCurrency currency;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBackground;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: currency.apiValue,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected ? Border.all(color: border) : null,
          ),
          child: Text(
            currency.apiValue,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceDashboardContent extends StatelessWidget {
  const _FinanceDashboardContent({
    required this.dashboard,
    required this.isDark,
  });

  final FinanceDashboardEntity dashboard;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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

    final balance = dashboard.wallet == null
        ? '—'
        : FinanceMoneyFormatter.format(
            dashboard.currency == FinanceCurrency.usd
                ? dashboard.wallet!.balanceUsd
                : dashboard.wallet!.balanceKhr,
            dashboard.currency,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BalanceCard(
          isDark: isDark,
          surfaceSecondary: surfaceSecondary,
          periodLabel: _monthLabel(dashboard.month.month, dashboard.month.year),
          balance: balance,
        ),
        const SizedBox(height: 16),

        _QuickActions(
          quickActions: dashboard.quickActions,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
        ),
        const SizedBox(height: 16),

        _MonthlySpendingCard(
          dashboard: dashboard,
          surface: surface,
          surfaceSecondary: surfaceSecondary,
          textPrimary: textPrimary,
          textMuted: textMuted,
          border: border,
        ),
        const SizedBox(height: 16),

        _SavingsCard(
          saving: dashboard.saving,
          currency: dashboard.currency,
          surface: surface,
          surfaceSecondary: surfaceSecondary,
          textPrimary: textPrimary,
          textMuted: textMuted,
          border: border,
        ),
        const SizedBox(height: 22),

        _InsightCard(
          tip: dashboard.financialTip,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 24),

        _RecentExpenses(
          expenses: dashboard.recentExpenses,
          currency: dashboard.currency,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(height: 16),

        _LearnFinanceCard(
          surface: surface,
          textPrimary: textPrimary,
          textMuted: textMuted,
          isDark: isDark,
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class _MonthlySpendingCard extends StatelessWidget {
  const _MonthlySpendingCard({
    required this.dashboard,
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
  });

  final FinanceDashboardEntity dashboard;
  final Color surface;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textMuted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final month = dashboard.month;
    final categories = dashboard.topCategories.take(4).toList(growable: false);
    final colors = [
      AppColors.growthAccent,
      AppColors.brandPrimary,
      AppColors.financeAccent,
      AppColors.productivityAccent,
    ];
    final budgetTotal = month.budgetTotal;
    final usage = budgetTotal == null || budgetTotal <= 0
        ? null
        : (month.spent / budgetTotal).clamp(0.0, 1.0).toDouble();
    final budgetColor = switch (month.budgetStatus) {
      'LIMIT_REACHED' => Colors.redAccent,
      'WARNING' => Colors.orangeAccent,
      _ => AppColors.growthAccent,
    };

    return AppCard(
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
                      _monthLabel(month.month, month.year),
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FinanceMoneyFormatter.format(month.spent, month.currency),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              DonutChart(
                size: 68,
                strokeWidth: 8,
                backgroundColor: surfaceSecondary,
                segments: [
                  for (var index = 0; index < categories.length; index++)
                    DonutSegment(
                      value: month.spent <= 0
                          ? 0
                          : (categories[index].amount / month.spent)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                      color: colors[index],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            Text(
              'finance.noCategorySpending'.tr,
              style: TextStyle(color: textMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (var index = 0; index < categories.length; index++)
                  Legend(
                    color: colors[index],
                    title: categories[index].category,
                    textColor: textMuted,
                  ),
              ],
            ),
          if (usage != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: usage,
                minHeight: 6,
                backgroundColor: surfaceSecondary,
                valueColor: AlwaysStoppedAnimation(budgetColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'finance.spendingOf'.trParams({
                    'spent': FinanceMoneyFormatter.format(
                      month.spent,
                      month.currency,
                    ),
                    'limit': FinanceMoneyFormatter.format(
                      budgetTotal!,
                      month.currency,
                    ),
                  }),
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                Text(
                  '${(usage * 100).round()}%',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (month.budgetRemaining != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${'finance.remaining'.tr}: ${FinanceMoneyFormatter.format(month.budgetRemaining!, month.currency)}',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'finance.noBudget'.tr,
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({
    required this.saving,
    required this.currency,
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
  });

  final FinanceSavingProgress saving;
  final FinanceCurrency currency;
  final Color surface;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textMuted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final progress = (saving.progressPercent / 100).clamp(0.0, 1.0).toDouble();
    final hasGoals = saving.activeGoals > 0 || saving.totalTarget > 0;

    return AppCard(
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
                      'finance.savings'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasGoals
                          ? 'finance.fundProgress'.trParams({
                              'saved': FinanceMoneyFormatter.format(
                                saving.totalSaved,
                                currency,
                              ),
                              'target': FinanceMoneyFormatter.format(
                                saving.totalTarget,
                                currency,
                              ),
                            })
                          : 'finance.noSavingGoals'.tr,
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              DonutChart(
                size: 52,
                strokeWidth: 7,
                backgroundColor: surfaceSecondary,
                segments: hasGoals
                    ? const [
                        DonutSegment(value: 1, color: AppColors.financeAccent),
                      ]
                    : const [],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: surfaceSecondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.financeAccent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'finance.complete'.trParams({
                  'percent': '${saving.progressPercent.clamp(0, 100)}',
                }),
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              Text(
                'finance.activeGoals'.trParams({
                  'count': '${saving.activeGoals}',
                }),
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.tip,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String? tip;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final message = tip?.trim();
    return Container(
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
                  message == null || message.isEmpty
                      ? 'finance.noInsight'.tr
                      : message,
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
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.quickActions,
    required this.surface,
    required this.border,
    required this.textPrimary,
  });

  final List<String> quickActions;
  final Color surface;
  final Color border;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback, Color)>[];
    final seen = <String>{};
    for (final action in quickActions) {
      if (!seen.add(action)) continue;
      switch (action) {
        case 'ADD_EXPENSE':
          actions.add((
            Icons.add_rounded,
            'finance.Expense'.tr,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseScreen()),
            ),
            AppColors.brandPrimary,
          ));
        case 'SET_BUDGET':
          actions.add((
            Icons.bar_chart_rounded,
            'finance.Budget'.tr,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
            AppColors.productivityAccent,
          ));
        case 'NEW_SAVING_GOAL':
          actions.add((
            Icons.savings_outlined,
            'finance.saveGoal'.tr,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
            ),
            AppColors.financeAccent,
          ));
        case 'TOP_UP_WALLET':
          actions.add((
            Icons.account_balance_wallet_rounded,
            'finance.ewallet'.tr,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const EWalletScreen()),
            ),
            const Color.fromARGB(255, 75, 148, 174),
          ));
      }
    }

    // Learning is a separate destination and is not part of the dashboard
    // quickActions response; keep its existing entry until that API phase.
    actions.add((
      Icons.trending_up_rounded,
      'finance.Income'.tr,
      () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const IncomeScreen()),
      ),
      AppColors.financeAccent,
    ));
    actions.add((
      Icons.compare_arrows_rounded,
      'finance.cashFlow.title'.tr,
      () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const CashFlowScreen()),
      ),
      AppColors.brandPrimary,
    ));
    actions.add((
      Icons.menu_book_rounded,
      'finance.learn'.tr,
      () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const LearnFinanceScreen()),
      ),
      AppColors.growthAccent,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (icon, title, onTap, accent) = actions[index];
              return SizedBox(
                width: 80,
                child: QuickAction(
                  icon: icon,
                  title: title,
                  accent: accent,
                  background: surface,
                  border: border,
                  textColor: textPrimary,
                  onTap: onTap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({
    required this.expenses,
    required this.currency,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final List<FinanceRecentExpense> expenses;
  final FinanceCurrency currency;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBackground = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              ),
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
        Container(
          height: expenses.isEmpty ? 130 : 300,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: expenses.isEmpty
              ? AppEmptyState(
                  message: 'finance.noRecentExpenses'.tr,
                  icon: Icons.receipt_long_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final category = expense.category?.trim();
                    final subtitle = [
                      expense.expenseDate,
                      if (category != null && category.isNotEmpty) category,
                    ].join(' · ');
                    return Transaction(
                      title: expense.title,
                      subtitle: subtitle,
                      amount: FinanceMoneyFormatter.signed(
                        expense.amount,
                        currency,
                        debit: true,
                      ),
                      icon: _categoryIcon(expense.category),
                      iconColor: AppColors.growthAccent,
                      background: surface,
                      iconBackground: iconBackground,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LearnFinanceCard extends StatelessWidget {
  const _LearnFinanceCard({
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
  });

  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const LearnFinanceScreen()),
      ),
      child: AppCard(
        color: surface,
        borderColor: isDark
            ? AppColors.darkBorderSubtle
            : AppColors.lightBorderSubtle,
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
                    'finance.learning.open'.tr,
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 22,
                color: isDark
                    ? AppColors.darkTextInverse
                    : AppColors.lightTextInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _monthLabel(int month, int year) {
  final months = 'date.months'.tr.split(',');
  if (month < 1 || month > months.length) return '$month/$year';
  return '${months[month - 1]} $year';
}

IconData _categoryIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
      return Icons.restaurant_outlined;
    case 'TRANSPORT':
      return Icons.directions_car_outlined;
    case 'BILLS':
    case 'UTILITIES':
      return Icons.bolt_outlined;
    case 'SHOPPING':
      return Icons.shopping_bag_outlined;
    case 'ENTERTAINMENT':
      return Icons.play_circle_outline_rounded;
    default:
      return Icons.receipt_long_outlined;
  }
}
