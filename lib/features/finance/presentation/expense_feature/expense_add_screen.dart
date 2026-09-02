import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_add_widget.dart';

/// Add and edit Expense form.  The same screen is used for both operations so
/// update semantics stay identical to the backend's PUT contract.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final FinanceExpenseEntity? expense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();

  final _categoryValues = <String>[
    'FOOD',
    'TRANSPORT',
    'STUDY',
    'BILLS',
    'HEALTH',
  ];
  final _paymentValues = <String>['CASH', 'CARD', 'ABA'];

  late List<ExpenseCategoryItem> categories;
  late List<ExpensePaymentItem> payments;
  late int selectedCategory;
  late int selectedPayment;
  late DateTime selectedDate;
  late bool _paidFromWallet;

  ExpenseController get controller => Get.find<ExpenseController>();
  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController.text = expense?.title ?? '';
    _noteController.text = expense?.description ?? '';
    _amountController.text = expense == null ? '' : _amountText(expense.amount);
    selectedDate = _parseDate(expense?.expenseDate) ?? DateTime.now();
    _paidFromWallet = expense?.paidFromWallet ?? false;

    final category = expense?.category?.trim().toUpperCase();
    if (category == null || category.isEmpty) {
      _categoryValues.insert(0, '');
    }
    if (category != null &&
        category.isNotEmpty &&
        !_categoryValues.contains(category)) {
      _categoryValues.add(category);
    }
    selectedCategory = category == null || category.isEmpty
        ? 0
        : _categoryValues
              .indexOf(category)
              .clamp(0, _categoryValues.length - 1);

    final payment = expense?.paymentMethod?.trim().toUpperCase();
    if (payment == null || payment.isEmpty) {
      _paymentValues.insert(0, '');
    }
    if (payment != null &&
        payment.isNotEmpty &&
        !_paymentValues.contains(payment)) {
      _paymentValues.add(payment);
    }
    selectedPayment = payment == null || payment.isEmpty
        ? 0
        : _paymentValues.indexOf(payment).clamp(0, _paymentValues.length - 1);

    categories = _categoryValues.map(_categoryItem).toList(growable: false);
    payments = _paymentValues.map(_paymentItem).toList(growable: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  ExpenseCategoryItem _categoryItem(String value) {
    return ExpenseCategoryItem(
      name: _categoryLabel(value),
      icon: _categoryIcon(value),
      color: _categoryColor(value),
    );
  }

  ExpensePaymentItem _paymentItem(String value) {
    return ExpensePaymentItem(
      name: _paymentLabel(value),
      icon: _paymentIcon(value),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => selectedDate = picked);
  }

  Future<void> _saveExpense() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty) {
      _showValidation('finance.expense.enterTitle'.tr);
      return;
    }
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showValidation('finance.expense.enterAmount'.tr);
      return;
    }

    FocusScope.of(context).unfocus();
    controller.clearMutationError();
    final category = _optional(_categoryValues[selectedCategory]);
    final payment = _paymentValues[selectedPayment];
    final date = _apiDate(selectedDate);
    final success = isEditing
        ? await controller.updateExpense(
            existing: widget.expense!,
            title: title,
            amount: amount,
            expenseDate: date,
            category: category,
            description: _optional(_noteController.text),
            paymentMethod: _optional(payment),
            paidFromWallet: _paidFromWallet,
          )
        : await controller.createExpense(
            title: title,
            amount: amount,
            expenseDate: date,
            category: category,
            description: _optional(_noteController.text),
            paymentMethod: _optional(payment),
            paidFromWallet: _paidFromWallet,
          );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else if (controller.mutationErrorMessage.value != null) {
      _showValidation(controller.mutationErrorMessage.value!);
    }
  }

  void _showValidation(String message) {
    Get.snackbar(
      'finance.expense.validationError'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
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
    final currency = isEditing
        ? widget.expense!.currency
        : controller.selectedCurrency.value;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  AppBackButton(),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'finance.expense.edit'.tr
                          : 'finance.expense.add'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _CurrencyBadge(currency: currency, primary: primary),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpenseAmountSection(
                      controller: _amountController,
                      currencySymbol: currency == FinanceCurrency.khr
                          ? '៛'
                          : '\$',
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      primary: primary,
                    ),
                    const SizedBox(height: 24),
                    ExpenseSectionLabel(
                      title: 'finance.expense.description'.tr,
                      subtitle: 'finance.expense.descriptionHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseInputField(
                      controller: _titleController,
                      hint: 'finance.expense.titleHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 20),
                    ExpenseSectionLabel(
                      title: 'finance.expense.note'.tr,
                      subtitle: 'common.optional'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseInputField(
                      controller: _noteController,
                      hint: 'finance.expense.noteHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.notes_outlined,
                    ),
                    const SizedBox(height: 22),
                    ExpenseSectionLabel(
                      title: 'finance.expense.category'.tr,
                      subtitle: 'finance.expense.categoryHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseCategorySelector(
                      categories: categories,
                      selectedCategory: selectedCategory,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onChanged: (index) =>
                          setState(() => selectedCategory = index),
                    ),
                    const SizedBox(height: 22),
                    ExpenseSectionLabel(
                      title: 'finance.expense.date'.tr,
                      subtitle: 'finance.expense.dateHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseDateSelector(
                      date: _displayDate(selectedDate),
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 22),
                    ExpenseSectionLabel(
                      title: 'finance.expense.paymentMethod'.tr,
                      subtitle: 'finance.expense.paymentHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpensePaymentSelector(
                      payments: payments,
                      selectedPayment: selectedPayment,
                      surface: surface,
                      border: border,
                      primary: primary,
                      textPrimary: textPrimary,
                      onChanged: (index) =>
                          setState(() => selectedPayment = index),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        'finance.expense.paidFromWallet'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'finance.expense.walletDebitHelper'.tr,
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                      value: _paidFromWallet,
                      onChanged: (value) =>
                          setState(() => _paidFromWallet = value),
                      activeThumbColor: primary,
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final submitting = isEditing
                          ? controller.isUpdateSubmitting.value
                          : controller.isCreateSubmitting.value;
                      final error = controller.mutationErrorMessage.value;
                      return Column(
                        children: [
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: submitting ? null : _saveExpense,
                              icon: submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 19),
                              label: Text(
                                isEditing
                                    ? 'finance.expense.save'.tr
                                    : 'finance.expense.save'.tr,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: inverseText,
                                disabledBackgroundColor: primary.withValues(
                                  alpha: .45,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String value) => switch (value) {
    '' => 'finance.expense.optional'.tr,
    'FOOD' => 'finance.expense.food'.tr,
    'TRANSPORT' => 'finance.expense.transport'.tr,
    'STUDY' => 'finance.expense.study'.tr,
    'BILLS' => 'finance.expense.bills'.tr,
    'HEALTH' => 'finance.expense.health'.tr,
    _ => value,
  };

  String _paymentLabel(String value) => switch (value) {
    '' => 'finance.expense.optional'.tr,
    'CASH' => 'Cash',
    'CARD' => 'Card',
    'ABA' => 'ABA',
    _ => value,
  };

  IconData _categoryIcon(String value) => switch (value) {
    'FOOD' => Icons.restaurant_outlined,
    'TRANSPORT' => Icons.directions_car_outlined,
    'STUDY' => Icons.menu_book_outlined,
    'BILLS' => Icons.receipt_long_outlined,
    'HEALTH' => Icons.favorite_border_rounded,
    _ => Icons.more_horiz_rounded,
  };

  Color _categoryColor(String value) => switch (value) {
    'FOOD' => AppColors.growthAccent,
    'TRANSPORT' => AppColors.brandPrimary,
    'STUDY' => AppColors.productivityAccent,
    'BILLS' => AppColors.financeAccent,
    'HEALTH' => AppColors.productivityAccent,
    _ => AppColors.success,
  };

  IconData? _paymentIcon(String value) => switch (value) {
    'CASH' => Icons.payments_outlined,
    'CARD' => Icons.credit_card_outlined,
    'ABA' => Icons.account_balance_outlined,
    '' => null,
    _ => null,
  };

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _amountText(double value) => value.toStringAsFixed(2);
}

class _CurrencyBadge extends StatelessWidget {
  const _CurrencyBadge({required this.currency, required this.primary});

  final FinanceCurrency currency;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        currency.apiValue,
        style: TextStyle(color: primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
