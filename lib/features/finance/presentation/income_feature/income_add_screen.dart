import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_add_widget.dart';

/// Add/edit Income form using the documented full-replacement PUT contract.
class IncomeAddScreen extends StatefulWidget {
  const IncomeAddScreen({super.key, this.income});

  final FinanceIncomeEntity? income;

  @override
  State<IncomeAddScreen> createState() => _IncomeAddScreenState();
}

class _IncomeAddScreenState extends State<IncomeAddScreen> {
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late DateTime _selectedDate;

  IncomeController get controller => Get.find<IncomeController>();
  bool get isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    _titleController.text = income?.title ?? '';
    _sourceController.text = income?.source ?? '';
    _descriptionController.text = income?.description ?? '';
    _amountController.text = income == null
        ? ''
        : income.amount.toStringAsFixed(2);
    _selectedDate = _parseDate(income?.incomeDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty) {
      _showValidation('finance.income.enterTitle'.tr);
      return;
    }
    if (amount == null || !amount.isFinite || amount <= 0) {
      _showValidation('finance.income.enterAmount'.tr);
      return;
    }

    FocusScope.of(context).unfocus();
    controller.clearMutationError();
    final date = _apiDate(_selectedDate);
    final success = isEditing
        ? await controller.updateIncome(
            existing: widget.income!,
            title: title,
            amount: amount,
            incomeDate: date,
            source: _optional(_sourceController.text),
            description: _optional(_descriptionController.text),
          )
        : await controller.createIncome(
            title: title,
            amount: amount,
            incomeDate: date,
            source: _optional(_sourceController.text),
            description: _optional(_descriptionController.text),
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
      'finance.income.validationError'.tr,
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
        ? widget.income!.currency
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
                          ? 'finance.income.edit'.tr
                          : 'finance.income.add'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
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
                          : r'$',
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      primary: primary,
                    ),
                    const SizedBox(height: 22),
                    ExpenseSectionLabel(
                      title: 'finance.income.titleField'.tr,
                      subtitle: 'finance.income.titleHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseInputField(
                      controller: _titleController,
                      hint: 'finance.income.titleHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 20),
                    ExpenseSectionLabel(
                      title: 'finance.income.source'.tr,
                      subtitle: 'finance.income.sourceHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseInputField(
                      controller: _sourceController,
                      hint: 'finance.income.sourceHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.label_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    ExpenseSectionLabel(
                      title: 'finance.income.description'.tr,
                      subtitle: 'finance.income.optional'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseInputField(
                      controller: _descriptionController,
                      hint: 'finance.income.descriptionHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.notes_outlined,
                    ),
                    const SizedBox(height: 20),
                    ExpenseSectionLabel(
                      title: 'finance.income.date'.tr,
                      subtitle: 'finance.income.dateHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),
                    ExpenseDateSelector(
                      date: _displayDate(_selectedDate),
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 24),
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
                              onPressed: submitting ? null : _save,
                              icon: submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 19),
                              label: Text('finance.income.save'.tr),
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

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
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
