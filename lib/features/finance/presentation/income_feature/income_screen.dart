import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_detail_widget.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        child: Obx(() {
          final incomes = controller.incomes.toList(growable: false);
          final loading = controller.isInitialLoading.value;
          final error = controller.listErrorMessage.value;
          final currency = controller.selectedCurrency.value;
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                Row(
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
                        'finance.income.title'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
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
                      icon: Icon(Icons.compare_arrows_rounded, color: primary),
                    ),
                    _AddIncomeButton(
                      background: primary,
                      iconColor: inverseText,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncomeAddScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  primary: primary,
                  textPrimary: textPrimary,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ExpenseSearchField(
                        controller: _sourceController,
                        hintText: 'finance.income.sourceFilterHint'.tr,
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _applySource,
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
                      textPrimary: textPrimary,
                      textMuted: textMuted,
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
                      textMuted: textMuted,
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
          // Close the payload-backed detail route before editing.  The
          // controller refreshes the authoritative list after PUT, so the
          // user returns to the refreshed list instead of a stale detail card.
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

class _AddIncomeButton extends StatelessWidget {
  const _AddIncomeButton({
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'finance.income.add'.tr,
      onPressed: onTap,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.add_rounded, color: iconColor),
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

IconData _sourceIcon() {
  // The backend treats source as free text rather than a closed enum.  Keep a
  // neutral icon so an unknown/future source never requires a guessed mapping.
  return Icons.trending_up_rounded;
}
