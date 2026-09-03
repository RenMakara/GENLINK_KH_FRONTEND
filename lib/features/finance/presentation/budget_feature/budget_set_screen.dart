import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';

/// Create/edit form for the backend Budget contract.
///
/// Category names are intentionally free text. The backend accepts no fixed
/// category enum, so the client sends the exact user-entered value and only
/// keeps icon/subtitle decoration local to this screen.
class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key, this.budget});

  final FinanceBudgetEntity? budget;

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _CategoryDraft {
  _CategoryDraft({required String name, required double amount})
    : name = TextEditingController(text: name),
      amount = TextEditingController(
        text: amount == 0 ? '' : amount.toStringAsFixed(2),
      );

  final TextEditingController name;
  final TextEditingController amount;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  late final BudgetController controller;
  late final TextEditingController totalController;
  late int month;
  late int year;
  late List<_CategoryDraft> categories;

  @override
  void initState() {
    super.initState();
    controller = Get.find<BudgetController>();
    final existing = widget.budget;
    month = existing?.month ?? controller.selectedMonth.value;
    year = existing?.year ?? controller.selectedYear.value;
    totalController = TextEditingController(
      text: existing == null ? '' : existing.totalBudget.toStringAsFixed(2),
    );
    categories = (existing?.categories ?? const <FinanceCategoryBudget>[])
        .map(
          (item) =>
              _CategoryDraft(name: item.category, amount: item.allocatedAmount),
        )
        .toList();
  }

  @override
  void dispose() {
    totalController.dispose();
    for (final category in categories) {
      category.dispose();
    }
    super.dispose();
  }

  bool get isEditing => widget.budget != null;

  FinanceCurrency get formCurrency =>
      widget.budget?.currency ?? controller.selectedCurrency.value;

  String get periodLabel {
    final names = 'date.months'.tr.split(',');
    return month >= 1 && month <= names.length
        ? '${names[month - 1]} $year'
        : '$month/$year';
  }

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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      (isEditing
                              ? 'finance.budget.editBudget'
                              : 'finance.budget.setBudget')
                          .tr,
                      style: TextStyle(
                        color: text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                children: [
                  _FieldLabel(
                    label: 'finance.budget.currency'.tr,
                    color: muted,
                  ),
                  const SizedBox(height: 6),

                  _ReadOnlyField(
                    text: formCurrency.apiValue,
                    color: text,
                    muted: muted,
                    surface: secondary,
                    border: border,
                  ),

                  const SizedBox(height: 16),

                  _FieldLabel(
                    label: 'finance.budget.budgetPeriod'.tr,
                    color: muted,
                  ),
                  const SizedBox(height: 6),

                  InkWell(
                    onTap: _pickPeriod,
                    borderRadius: BorderRadius.circular(12),
                    child: _ReadOnlyField(
                      text: periodLabel,
                      color: text,
                      muted: muted,
                      surface: surface,
                      border: border,
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _FieldLabel(
                    label: 'finance.budget.totalBudget'.tr,
                    color: muted,
                  ),
                  const SizedBox(height: 6),

                  _InputField(
                    controller: totalController,
                    hint: '0.00',
                    color: text,
                    muted: muted,
                    surface: surface,
                    border: border,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'finance.budget.categoryBudgets'.tr,
                          style: TextStyle(
                            color: text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      InkWell(
                        onTap: _addCategory,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 17, color: primary),
                              const SizedBox(width: 4),
                              Text(
                                'finance.budget.addCategory'.tr,
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (categories.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.category_outlined, size: 30, color: muted),
                          const SizedBox(height: 8),
                          Text(
                            'finance.budget.noCategories'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...categories.asMap().entries.map(
                      (entry) => _CategoryEditor(
                        draft: entry.value,
                        index: entry.key,
                        text: text,
                        muted: muted,
                        surface: surface,
                        border: border,
                        currency: formCurrency,
                        onDelete: () => _removeCategory(entry.key),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Save button
                  Obx(() {
                    final submitting =
                        controller.isCreateSubmitting.value ||
                        controller.isUpdateSubmitting.value;

                    final error = controller.mutationErrorMessage.value;

                    return Column(
                      children: [
                        if (error != null) ...[
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                          const SizedBox(height: 8),
                        ],

                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: submitting ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: inverse,
                              disabledBackgroundColor: secondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('finance.budget.saveBudget'.tr),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(year, month, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() {
        month = picked.month;
        year = picked.year;
      });
    }
  }

  void _addCategory() {
    setState(() {
      categories.add(_CategoryDraft(name: '', amount: 0));
    });
  }

  void _removeCategory(int index) {
    final draft = categories.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    final total = double.tryParse(totalController.text.trim());
    final allocations = <FinanceBudgetAllocation>[];
    for (final draft in categories) {
      allocations.add(
        FinanceBudgetAllocation(
          category: draft.name.text.trim(),
          allocatedAmount: double.tryParse(draft.amount.text.trim()) ?? 0,
        ),
      );
    }
    final success = isEditing
        ? await controller.updateBudget(
            existing: widget.budget!,
            totalBudget: total ?? 0,
            categories: allocations,
            month: month,
            year: year,
          )
        : await controller.createBudget(
            totalBudget: total ?? 0,
            categories: allocations,
          );
    if (success && mounted) Navigator.pop(context, true);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.text,
    required this.color,
    required this.muted,
    required this.surface,
    required this.border,
    this.icon,
  });

  final String text;
  final Color color;
  final Color muted;
  final Color surface;
  final Color border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: muted, size: 19),
            const SizedBox(width: 9),
          ],
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          if (icon != null) ...[
            const Spacer(),
            Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          ],
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.color,
    required this.muted,
    required this.surface,
    required this.border,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final Color color;
  final Color muted;
  final Color surface;
  final Color border;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
}

class _CategoryEditor extends StatelessWidget {
  const _CategoryEditor({
    required this.draft,
    required this.index,
    required this.text,
    required this.muted,
    required this.surface,
    required this.border,
    required this.currency,
    required this.onDelete,
  });

  final _CategoryDraft draft;
  final int index;
  final Color text;
  final Color muted;
  final Color surface;
  final Color border;
  final FinanceCurrency currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: draft.name,
              style: TextStyle(color: text, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'finance.budget.category'.tr,
                labelStyle: TextStyle(color: muted, fontSize: 12),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: draft.amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: currency == FinanceCurrency.usd ? r'$' : '៛',
                labelStyle: TextStyle(color: muted, fontSize: 12),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: muted, size: 20),
            tooltip: '${'finance.budget.category'.tr} ${index + 1}',
          ),
        ],
      ),
    );
  }
}
