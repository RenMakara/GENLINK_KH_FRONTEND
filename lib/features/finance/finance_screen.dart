import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/cash_flow_feature/cash_flow_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/widgets/finance_insights_widgets.dart';
import 'package:genlink_frontend/features/finance/presentation/finance_tools_feature/finance_tools_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/learn_finance_feature/learn_finance.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_screen.dart';
import 'package:genlink_frontend/features/finance/widgets/finance_widget.dart';
import '../home/presentation/widgets/home_header_actions.dart';

class FinanceScreen extends GetView<FinanceController> {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final dashboard = controller.dashboard.value;
      return Scaffold(
        backgroundColor: semantic.background,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.reload,
            color: AppColors.financeAccent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                _FinanceHeader(
                  selectedCurrency: controller.selectedCurrency.value,
                  onCurrencyChanged: controller.selectCurrency,
                ),
                const SizedBox(height: 16),
                if (dashboard != null && controller.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.reload,
                            child: Text('common.retry'.tr),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (controller.isLoading.value && dashboard == null)
                  SizedBox(
                    height: 480,
                    child: AppLoader(message: 'finance.loadingDashboard'.tr),
                  )
                else if (dashboard == null)
                  SizedBox(
                    height: 480,
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
    final semantic = context.semanticColors;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'finance.greetingMorning'.tr
        : (hour < 17
              ? 'finance.greetingAfternoon'.tr
              : 'finance.greetingEvening'.tr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: semantic.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'finance.title'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'finance.subtitle'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: semantic.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppHeaderNotificationButton(),
          ],
        ),
        const SizedBox(height: 14),
        _CurrencySelector(
          selectedCurrency: selectedCurrency,
          onChanged: onCurrencyChanged,
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.selectedCurrency,
    required this.onChanged,
  });

  final FinanceCurrency selectedCurrency;
  final ValueChanged<FinanceCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUsd = selectedCurrency == FinanceCurrency.usd;

    final selectedBg = isDark ? semantic.surfaceElevated : semantic.primary;
    final selectedText = isDark ? semantic.primaryText : semantic.textInverse;
    final unselectedText = semantic.secondaryText;

    return Container(
      width: 154,
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isUsd ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 73,
              height: 32,
              decoration: BoxDecoration(
                color: selectedBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _CurrencyChoice(
                  label: 'USD',
                  selected: isUsd,
                  selectedTextColor: selectedText,
                  unselectedTextColor: unselectedText,
                  onTap: () => onChanged(FinanceCurrency.usd),
                ),
              ),
              Expanded(
                child: _CurrencyChoice(
                  label: 'KHR',
                  selected: !isUsd,
                  selectedTextColor: selectedText,
                  unselectedTextColor: unselectedText,
                  onTap: () => onChanged(FinanceCurrency.khr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyChoice extends StatelessWidget {
  const _CurrencyChoice({
    required this.label,
    required this.selected,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: 32,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: TextStyle(
                color: selected ? selectedTextColor : unselectedTextColor,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
              child: Text(label),
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
    final semantic = context.semanticColors;

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
          surfaceSecondary: semantic.surfaceElevated,
          periodLabel: _monthLabel(dashboard.month.month, dashboard.month.year),
          balance: balance,
          onViewDetails: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const CashFlowScreen()),
          ),
        ),
        const SizedBox(height: 18),

        _QuickActionsSection(quickActions: dashboard.quickActions),
        const SizedBox(height: 18),

        _MonthlySpendingCard(dashboard: dashboard),
        const SizedBox(height: 18),

        _SavingsCard(saving: dashboard.saving, currency: dashboard.currency),
        const SizedBox(height: 18),

        _RecentExpenses(
          expenses: dashboard.recentExpenses,
          currency: dashboard.currency,
        ),
        const SizedBox(height: 18),

        FinanceInsightsSummaryCard(
          currency: dashboard.currency,
          month: dashboard.month.month,
          year: dashboard.month.year,
          onOpen: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const FinanceToolsScreen()),
          ),
        ),
        const SizedBox(height: 16),

        _LearnFinanceCard(isDark: isDark),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.quickActions});

  final List<String> quickActions;

  void _openAllActionsSheet(BuildContext context) {
    final semantic = context.semanticColors;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: semantic.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        final allActions = [
          (
            Icons.receipt_long_rounded,
            'finance.Expense'.tr,
            AppColors.danger,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              );
            },
          ),
          (
            Icons.bar_chart_rounded,
            'finance.Budget'.tr,
            AppColors.productivityAccent,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              );
            },
          ),
          (
            Icons.savings_rounded,
            'finance.saveGoal'.tr,
            AppColors.financeAccent,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
              );
            },
          ),
          (
            Icons.account_balance_wallet_rounded,
            'finance.ewallet'.tr,
            AppColors.brandPrimary,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const EWalletScreen()),
              );
            },
          ),
          (
            Icons.trending_up_rounded,
            'finance.income.title'.tr,
            AppColors.success,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const IncomeScreen()),
              );
            },
          ),
          (
            Icons.compare_arrows_rounded,
            'finance.cashFlow.title'.tr,
            AppColors.financeAccent,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const CashFlowScreen()),
              );
            },
          ),
          (
            Icons.lightbulb_outline_rounded,
            'finance.smartInsight'.tr,
            AppColors.growthAccent,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const FinanceToolsScreen(initialIndex: 0),
                ),
              );
            },
          ),
          (
            Icons.tune_rounded,
            'finance.tools.title'.tr,
            AppColors.brandPrimary,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const FinanceToolsScreen(initialIndex: 1),
                ),
              );
            },
          ),
          (
            Icons.menu_book_rounded,
            'finance.learn'.tr,
            AppColors.growthAccent,
            () {
              Navigator.pop(sheetContext);
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const LearnFinanceScreen()),
              );
            },
          ),
        ];

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: semantic.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: semantic.borderStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'finance.allActions'.tr,
                        style: TextStyle(
                          color: semantic.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < allActions.length; i += 3)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                for (int j = 0; j < 3; j++)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: j == 0 ? 0 : 5,
                                        right: j == 2 ? 0 : 5,
                                      ),
                                      child: i + j < allActions.length
                                          ? QuickAction(
                                              icon: allActions[i + j].$1,
                                              title: allActions[i + j].$2,
                                              accent: allActions[i + j].$3,
                                              background: semantic.surfaceElevated,
                                              border: semantic.borderSubtle,
                                              textColor: semantic.primaryText,
                                              onTap: allActions[i + j].$4,
                                              maxLines: 2,
                                              fontSize: 12.5,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    final primaryActions = [
      (
        Icons.receipt_long_rounded,
        'finance.Expense'.tr,
        AppColors.danger,
        () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseScreen()),
        ),
      ),
      (
        Icons.bar_chart_rounded,
        'finance.Budget'.tr,
        AppColors.productivityAccent,
        () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const BudgetScreen()),
        ),
      ),
      (
        Icons.savings_rounded,
        'finance.saveGoal'.tr,
        AppColors.financeAccent,
        () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
        ),
      ),
      (
        Icons.account_balance_wallet_rounded,
        'finance.ewallet'.tr,
        AppColors.brandPrimary,
        () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const EWalletScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.quickActions'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: semantic.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openAllActionsSheet(context),
              child: Text(
                'finance.seeAll'.tr,
                style: TextStyle(
                  color: semantic.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < primaryActions.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: primaryActions[index].$1,
                  title: primaryActions[index].$2,
                  accent: primaryActions[index].$3,
                  background: semantic.surface,
                  border: semantic.borderSubtle,
                  textColor: semantic.primaryText,
                  onTap: primaryActions[index].$4,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MonthlySpendingCard extends StatelessWidget {
  const _MonthlySpendingCard({required this.dashboard});

  final FinanceDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
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
      'LIMIT_REACHED' => AppColors.danger,
      'WARNING' => AppColors.warning,
      _ => AppColors.growthAccent,
    };

    final topCategory = categories.isNotEmpty ? categories.first : null;
    final topCategoryPercent = (topCategory != null && month.spent > 0)
        ? ((topCategory.amount / month.spent) * 100).round()
        : 100;

    return AppCard(
      color: semantic.surface,
      borderColor: semantic.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: This Month & Period Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'finance.monthlySpending'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _monthLabel(month.month, month.year),
                style: TextStyle(
                  color: semantic.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Stats Row with Donut Chart
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.totalSpending'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: semantic.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        FinanceMoneyFormatter.format(
                          month.spent,
                          month.currency,
                        ),
                        style: TextStyle(
                          color: semantic.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FinanceTrendBadge(
                      metric: FinanceTrendMetric.expense,
                      currency: month.currency,
                      month: month.month,
                      year: month.year,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DonutChart(
                size: 82,
                strokeWidth: 9,
                backgroundColor: semantic.surfaceElevated,
                segments: [
                  for (var index = 0; index < categories.length; index++)
                    DonutSegment(
                      value: month.spent <= 0
                          ? 0
                          : (categories[index].amount / month.spent)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                      color: colors[index % colors.length],
                    ),
                  if (categories.isEmpty && month.spent > 0)
                    const DonutSegment(
                      value: 1.0,
                      color: AppColors.growthAccent,
                    ),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${usage != null ? (usage * 100).round() : 100}%',
                      style: TextStyle(
                        color: semantic.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _compactMoney(month.spent, month.currency),
                      style: TextStyle(
                        color: semantic.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: semantic.borderSubtle),
          const SizedBox(height: 12),

          // Top Category Row with Chevron
          if (topCategory != null) ...[
            InkWell(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.growthAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localizedCategoryName(topCategory.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: semantic.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          FinanceMoneyFormatter.format(
                            topCategory.amount,
                            topCategory.currency,
                          ),
                          style: TextStyle(
                            color: semantic.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$topCategoryPercent%',
                      style: TextStyle(
                        color: semantic.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: semantic.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Text(
              'finance.noCategorySpending'.tr,
              style: TextStyle(color: semantic.textMuted, fontSize: 12),
            ),

          // Budget status bar if budget set
          if (usage != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: usage,
                minHeight: 6,
                backgroundColor: semantic.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(budgetColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: semantic.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(usage * 100).round()}%',
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (month.budgetRemaining != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${'finance.remaining'.tr}: ${FinanceMoneyFormatter.format(month.budgetRemaining!, month.currency)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: semantic.textMuted, fontSize: 11.5),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.saving, required this.currency});

  final FinanceSavingProgress saving;
  final FinanceCurrency currency;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final progress = (saving.progressPercent / 100).clamp(0.0, 1.0).toDouble();
    final hasGoals = saving.activeGoals > 0 || saving.totalTarget > 0;

    return AppCard(
      color: semantic.surface,
      borderColor: semantic.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'finance.savings'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
                ),
                child: Text(
                  'finance.seeAll'.tr,
                  style: TextStyle(
                    color: semantic.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasGoals) ...[
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: semantic.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: semantic.borderSubtle),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.laptop_mac_rounded,
                      size: 22,
                      color: semantic.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'finance.emergencyFund'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: semantic.primaryText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${saving.progressPercent.clamp(0, 100)}%',
                            style: TextStyle(
                              color: semantic.primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: semantic.surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.financeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'finance.fundProgress'.trParams({
                                'saved': FinanceMoneyFormatter.format(
                                  saving.totalSaved,
                                  currency,
                                ),
                                'target': FinanceMoneyFormatter.format(
                                  saving.totalTarget,
                                  currency,
                                ),
                              }),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: semantic.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'finance.activeGoals'.trParams({
                              'count': '${saving.activeGoals}',
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: semantic.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: semantic.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.savings_outlined,
                      size: 20,
                      color: semantic.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'finance.noSavingGoals'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: semantic.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavingGoalsScreen(),
                      ),
                    ),
                    child: Text(
                      'finance.saveGoal'.tr,
                      style: const TextStyle(
                        color: AppColors.financeAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({required this.expenses, required this.currency});

  final List<FinanceRecentExpense> expenses;
  final FinanceCurrency currency;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.recentTransactions'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: semantic.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              ),
              child: Text(
                'finance.seeAll'.tr,
                style: TextStyle(
                  color: semantic.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (expenses.isEmpty)
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: semantic.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: semantic.borderSubtle),
            ),
            child: AppEmptyState(
              message: 'finance.noRecentExpenses'.tr,
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < expenses.length; index++) ...[
                _buildTransactionRow(
                  context,
                  expenses[index],
                  currency,
                  semantic,
                  isDark,
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    FinanceRecentExpense expense,
    FinanceCurrency currency,
    AppSemanticColors semantic,
    bool isDark,
  ) {
    final category = expense.category?.trim();
    final subtitle = [
      expense.expenseDate,
      if (category != null && category.isNotEmpty)
        _localizedCategoryName(category),
    ].join(' · ');

    final iconBg = AppColors.danger.withValues(alpha: isDark ? 0.18 : 0.10);
    const iconColor = AppColors.danger;

    return Transaction(
      title: expense.title,
      subtitle: subtitle,
      amount: FinanceMoneyFormatter.signed(
        expense.amount,
        currency,
        debit: true,
      ),
      icon: Icons.arrow_outward_rounded,
      iconColor: iconColor,
      background: semantic.surface,
      iconBackground: iconBg,
      border: semantic.borderSubtle,
      textPrimary: semantic.primaryText,
      textMuted: semantic.textMuted,
      amountColor: semantic.primaryText,
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const ExpenseScreen()),
      ),
    );
  }
}

class _LearnFinanceCard extends StatelessWidget {
  const _LearnFinanceCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return InkWell(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const LearnFinanceScreen()),
      ),
      borderRadius: BorderRadius.circular(AppRadius.squircle),
      child: AppCard(
        color: semantic.surface,
        borderColor: semantic.borderSubtle,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'finance.learn'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'finance.learning.open'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: semantic.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 20,
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
    default:
      return category;
  }
}
