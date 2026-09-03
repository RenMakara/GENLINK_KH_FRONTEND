import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_history_widget.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

/// Server-backed Expense history. Search remains intentionally local to the
/// loaded pages because the backend contract does not expose a search query.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  static const _categoryValues = <String?>[
    null,
    'FOOD',
    'TRANSPORT',
    'STUDY',
    'BILLS',
    'HEALTH',
    'OTHER',
  ];

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _selectedCategory = 0;

  ExpenseController get controller => Get.find<ExpenseController>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 280) {
      controller.loadNextPage();
    }
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
          final allExpenses = controller.expenses.toList(growable: false);
          final query = _searchController.text.trim().toLowerCase();
          final visible = query.isEmpty
              ? allExpenses
              : allExpenses
                    .where((expense) {
                      return expense.title.toLowerCase().contains(query) ||
                          (expense.category?.toLowerCase().contains(query) ??
                              false) ||
                          (expense.description?.toLowerCase().contains(query) ??
                              false);
                    })
                    .toList(growable: false);

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        AppBackButton(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'finance.expense.history'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _CurrencyChoice(
                          selected: controller.selectedCurrency.value,
                          onChanged: controller.selectCurrency,
                          surface: surface,
                          border: border,
                          primary: primary,
                          textPrimary: textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ExpenseSearchField(
                      controller: _searchController,
                      hintText: 'finance.expense.searchHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      primary: primary,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ExpenseFilterBar(
                      filters: _categoryValues.map(_categoryLabel).toList(),
                      selectedIndex: _selectedCategory,
                      primary: primary,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      inverseText: inverseText,
                      onChanged: (index) {
                        setState(() => _selectedCategory = index);
                        controller.selectCategory(_categoryValues[index]);
                      },
                    ),
                  ),
                ),
                if (controller.isInitialLoading.value && allExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppLoader(message: 'common.loading'.tr),
                  )
                else if (controller.listErrorMessage.value != null &&
                    allExpenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
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
                else if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      message: 'finance.expense.noFilteredExpenses'.tr,
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) => _expenseCard(
                        context,
                        visible[index],
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ),
                  ),
                if (controller.isLoadingMore.value)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (controller.paginationErrorMessage.value != null)
                  SliverToBoxAdapter(
                    child: AppEmptyState(
                      message: controller.paginationErrorMessage.value!,
                      action: AppButton.text(
                        label: 'common.retry'.tr,
                        onPressed: controller.loadNextPage,
                      ),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _expenseCard(
    BuildContext context,
    FinanceExpenseEntity expense, {
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final accent = _categoryColor(expense.category);
    final subtitle = [
      expense.expenseDate,
      if (expense.category?.trim().isNotEmpty == true) expense.category!,
    ].join(' · ');
    return ExpenseHistoryCard(
      icon: _categoryIcon(expense.category),
      iconColor: accent,
      iconBackground: accent.withValues(alpha: .12),
      title: expense.title,
      subtitle: subtitle,
      amount: FinanceMoneyFormatter.signed(
        expense.amount,
        expense.currency,
        debit: true,
      ),
      isPositive: false,
      surface: surface,
      border: border,
      textPrimary: textPrimary,
      textMuted: textMuted,
      onTap: () => _openDetail(context, expense),
    );
  }

  void _openDetail(BuildContext context, FinanceExpenseEntity expense) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen.fromEntity(
          expense,
          onEdit: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(expense: expense),
              ),
            );
          },
          onDeleted: () => controller.deleteExpense(expense.expenseId),
        ),
      ),
    );
  }
}

class _CurrencyChoice extends StatelessWidget {
  const _CurrencyChoice({
    required this.selected,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textPrimary,
  });

  final FinanceCurrency selected;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color surface;
  final Color border;
  final Color primary;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FinanceCurrency.values.map((currency) {
          final isSelected = currency == selected;
          return GestureDetector(
            onTap: () => onChanged(currency),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currency.apiValue,
                style: TextStyle(
                  color: isSelected ? Colors.white : textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String _categoryLabel(String? category) {
  switch (category) {
    case null:
      return 'finance.expense.all'.tr;
    case 'FOOD':
      return 'finance.expense.food'.tr;
    case 'TRANSPORT':
      return 'finance.expense.transport'.tr;
    case 'STUDY':
      return 'finance.expense.study'.tr;
    case 'BILLS':
      return 'finance.expense.bills'.tr;
    case 'HEALTH':
      return 'finance.expense.health'.tr;
    case 'OTHER':
      return 'finance.expense.other'.tr;
    default:
      return category;
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
