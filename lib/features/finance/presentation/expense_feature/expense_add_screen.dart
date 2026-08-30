import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController(text: '0.00');

  int selectedCategory = 0;
  int selectedPayment = 0;

  final categories = ['food', 'transport', 'study', 'bills', 'health', 'other'];

  final payments = ['cash', 'card', 'aba'];

  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // DATE PICKER
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: AppColors.darkPrimary)
                : ColorScheme.light(primary: AppColors.lightPrimary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  // FORMAT DATE
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // SAVE EXPENSE
  void _saveExpense() {
    final amount = _amountController.text.trim();
    final title = _titleController.text.trim();

    if (amount.isEmpty || amount == '0.00') {
      Get.snackbar(
        'finance.expense.validationError'.tr,
        'finance.expense.enterAmount'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (title.isEmpty) {
      Get.snackbar(
        'finance.expense.validationError'.tr,
        'finance.expense.enterTitle'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // THEME COLORS
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
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),

                  const SizedBox(width: 4),

                  Text(
                    'finance.expense.add'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AMOUNT
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '\$',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 4),

                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),

                          Container(
                            width: 60,
                            height: 3,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // TITLE
                    _Label('finance.expense.description'.tr, textPrimary),

                    const SizedBox(height: 8),

                    _InputField(
                      controller: _titleController,
                      hint: 'finance.expense.titleHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 18),

                    // CATEGORY
                    _Label('finance.expense.category'.tr, textPrimary),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(categories.length, (i) {
                        final selected = selectedCategory == i;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = i;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? primary : surface,
                              borderRadius: BorderRadius.circular(20),
                              border: selected
                                  ? null
                                  : Border.all(color: border),
                            ),
                            child: Text(
                              'finance.expense.${categories[i]}'.tr,
                              style: TextStyle(
                                color: selected ? inverseText : textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    // NOTE
                    _Label('finance.expense.note'.tr, textPrimary),

                    const SizedBox(height: 8),

                    _InputField(
                      controller: _noteController,
                      hint: 'finance.expense.noteHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 18),

                    // DATE
                    _Label('finance.expense.date'.tr, textPrimary),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: textMuted,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                _formatDate(selectedDate),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // PAYMENT METHOD
                    _Label('finance.expense.paymentMethod'.tr, textPrimary),

                    const SizedBox(height: 10),

                    Row(
                      children: List.generate(payments.length, (i) {
                        final selected = selectedPayment == i;

                        return Padding(
                          padding: EdgeInsets.only(
                            right: i < payments.length - 1 ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPayment = i;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? primary : surface,
                                borderRadius: BorderRadius.circular(12),
                                border: selected
                                    ? null
                                    : Border.all(color: border),
                              ),
                              child: Text(
                                'finance.expense.${payments[i]}'.tr,
                                style: TextStyle(
                                  color: selected ? inverseText : textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: inverseText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'finance.expense.save'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LABEL
class _Label extends StatelessWidget {
  final String text;
  final Color color;

  const _Label(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}

// INPUT FIELD
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
      ),
    );
  }
}
