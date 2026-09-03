import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_history_widget.dart'
    hide ExpenseHeaderButton;
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/cash_flow_feature/cash_flow_screen.dart';

/// Minimal backend-driven Income list and entry point for Income CRUD.
class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _sourceController = TextEditingController();
  final _scrollController = ScrollController();

  IncomeController get controller => Get.find<IncomeController>();
  FinanceController get financeController => Get.find<FinanceController>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 280) {
      controller.loadNextPage();
    }
  }

  Future<void> _applySource() async {
    FocusScope.of(context).unfocus();
    await controller.selectSource(_sourceController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Same colors as BudgetScreen
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final incomes = controller.incomes.toList(growable: false);
          final loading = controller.isInitialLoading.value;
          final error = controller.listErrorMessage.value;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                // HEADER
                Row(
                  children: [
                    AppBackButton(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'finance.income.title'.tr,
                        style: TextStyle(
                          color: text,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    IconButton(
                      tooltip: 'finance.cashFlow.title'.tr,
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashFlowScreen(),
                        ),
                      ),
                      icon: Icon(Icons.compare_arrows_rounded, color: text),
                    ),

                    IconButton(
                      tooltip: 'finance.income.add'.tr,
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncomeAddScreen(),
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

                // CURRENCY BAR
                // Same color setup as BudgetScreen
                _CurrencyBar(
                  value: controller.selectedCurrency.value,
                  onChanged: controller.selectCurrency,
                  text: text,
                  muted: muted,
                  secondary: secondary,
                  border: border,
                  primary: primary,
                ),

                const SizedBox(height: 14),

                // SOURCE FILTER
                Row(
                  children: [
                    Expanded(
                      child: ExpenseSearchField(
                        controller: _sourceController,
                        hintText: 'finance.income.sourceFilterHint'.tr,
                        surface: surface,
                        border: border,
                        textPrimary: text,
                        textMuted: muted,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(width: 8),

                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _applySource,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: text,
                          backgroundColor: surface,
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('finance.income.apply'.tr),
                      ),
                    ),
                  ],
                ),

                if (controller.selectedSource.value != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        _sourceController.clear();
                        controller.selectSource(null);
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text('finance.income.clearSource'.tr),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // CONTENT
                if (loading && incomes.isEmpty)
                  const SizedBox(height: 280, child: AppLoader())
                else if (error != null && incomes.isEmpty)
                  SizedBox(
                    height: 280,
                    child: AppEmptyState(
                      message: error,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        expanded: false,
                        onPressed: controller.loadInitial,
                      ),
                    ),
                  )
                else if (incomes.isEmpty)
                  SizedBox(
                    height: 280,
                    child: AppEmptyState(
                      message: 'finance.income.empty'.tr,
                      icon: Icons.trending_up_rounded,
                    ),
                  )
                else ...[
                  ...incomes.map(
                    (income) => ExpenseHistoryCard(
                      icon: _sourceIcon(),
                      iconColor: AppColors.financeAccent,
                      iconBackground: AppColors.financeAccent.withValues(
                        alpha: .12,
                      ),
                      title: income.title,
                      subtitle: [
                        income.incomeDate,
                        if (income.source?.trim().isNotEmpty == true)
                          income.source!,
                      ].join(' · '),
                      amount: FinanceMoneyFormatter.signed(
                        income.amount,
                        income.currency,
                        debit: false,
                      ),
                      isPositive: true,
                      surface: surface,
                      border: border,
                      textPrimary: text,
                      textMuted: muted,
                      onTap: () => _openDetail(income),
                    ),
                  ),

                  if (controller.isLoadingMore.value)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: AppLoader(size: 22),
                    ),

                  if (controller.paginationErrorMessage.value != null)
                    _PaginationError(
                      message: controller.paginationErrorMessage.value!,
                      onRetry: controller.loadNextPage,
                      textMuted: muted,
                    ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  void _openDetail(FinanceIncomeEntity income) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeDetailScreen.fromEntity(
          income,
          onEdit: () {
            Navigator.pop(context);
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => IncomeAddScreen(income: income),
              ),
            );
          },
          onDeleted: () => controller.deleteIncome(income.incomeId),
        ),
      ),
    );
  }
}

// CURRENCY BAR
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
                // SLIDING SELECTED BACKGROUND
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

                // CURRENCY OPTIONS
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

// PAGINATION ERROR

class _PaginationError extends StatelessWidget {
  const _PaginationError({
    required this.message,
    required this.onRetry,
    required this.textMuted,
  });

  final String message;
  final VoidCallback onRetry;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            message,
            style: TextStyle(color: textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
      ],
    );
  }
}

// INCOME ICON
IconData _sourceIcon() {
  return Icons.trending_up_rounded;
}
