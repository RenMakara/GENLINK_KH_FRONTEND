import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '0.00',
  );

  int selectedCategory = 0;
  int selectedPayment = 0;

  DateTime selectedDate = DateTime.now();

  // ===========================================================================
  // CATEGORIES
  // ===========================================================================

  final List<_CategoryItem> categories = [
    _CategoryItem(
      name: 'finance.expense.food'.tr,
      icon: Icons.restaurant_outlined,
      color: AppColors.growthAccent,
    ),
    _CategoryItem(
      name: 'finance.expense.transport'.tr,
      icon: Icons.directions_car_outlined,
      color: AppColors.brandPrimary,
    ),
    _CategoryItem(
      name: 'finance.expense.study'.tr,
      icon: Icons.menu_book_outlined,
      color: AppColors.productivityAccent,
    ),
    _CategoryItem(
      name: 'finance.expense.bills'.tr,
      icon: Icons.receipt_long_outlined,
      color: AppColors.financeAccent,
    ),
    _CategoryItem(
      name: 'finance.expense.health'.tr,
      icon: Icons.favorite_border_rounded,
      color: AppColors.productivityAccent,
    ),
    _CategoryItem(
      name: 'finance.expense.other'.tr,
      icon: Icons.more_horiz_rounded,
      color: AppColors.success,
    ),
  ];

  // ===========================================================================
  // PAYMENT METHODS
  // ===========================================================================

  final List<_PaymentItem> payments = const [
    _PaymentItem(name: 'Cash', icon: Icons.payments_outlined),
    _PaymentItem(name: 'Card', icon: Icons.credit_card_outlined),
    _PaymentItem(name: 'ABA', icon: Icons.account_balance_outlined),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // DATE PICKER
  // ===========================================================================

  Future<void> _selectDate() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
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

  // ===========================================================================
  // DATE FORMAT
  // ===========================================================================

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

  // ===========================================================================
  // SAVE EXPENSE
  // ===========================================================================

  void _saveExpense() {
    final String amount = _amountController.text.trim();
    final String title = _titleController.text.trim();

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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color bg = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final Color surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final Color textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final Color textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final Color border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final Color primary = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    final Color inverseText = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // =================================================================
            // HEADER
            // =================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  _BackButton(
                    color: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'finance.expense.add'.tr,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =================================================================
            // CONTENT
            // =================================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // AMOUNT
                    // =========================================================
                    _AmountSection(
                      controller: _amountController,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      primary: primary,
                    ),

                    const SizedBox(height: 26),

                    // =========================================================
                    // DESCRIPTION
                    // =========================================================
                    _SectionLabel(
                      title: 'finance.expense.description'.tr,
                      subtitle: 'finance.expense.descriptionHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    const SizedBox(height: 9),

                    _InputField(
                      controller: _titleController,
                      hint: 'finance.expense.titleHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.edit_note_outlined,
                    ),

                    const SizedBox(height: 23),

                    // =========================================================
                    // CATEGORY
                    // =========================================================
                    _SectionLabel(
                      title: 'finance.expense.category'.tr,
                      subtitle: 'finance.expense.categoryHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 11),

                    _CategorySelector(
                      categories: categories,
                      selectedCategory: selectedCategory,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onChanged: (index) {
                        setState(() {
                          selectedCategory = index;
                        });
                      },
                    ),

                    const SizedBox(height: 23),

                    // =========================================================
                    // NOTE
                    // =========================================================
                    _SectionLabel(
                      title: 'finance.expense.note'.tr,
                      subtitle: 'finance.expense.optional'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 9),

                    _InputField(
                      controller: _noteController,
                      hint: 'finance.expense.noteHint'.tr,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      prefixIcon: Icons.notes_outlined,
                    ),

                    const SizedBox(height: 23),

                    // =========================================================
                    // DATE
                    // =========================================================
                    _SectionLabel(
                      title: 'finance.expense.date'.tr,
                      subtitle: 'finance.expense.dateHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 9),

                    _DateSelector(
                      date: _formatDate(selectedDate),
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _selectDate,
                    ),

                    const SizedBox(height: 23),

                    // =========================================================
                    // PAYMENT
                    // =========================================================
                    _SectionLabel(
                      title: 'finance.expense.paymentMethod'.tr,
                      subtitle: 'finance.expense.paymentHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 11),

                    _PaymentSelector(
                      payments: payments,
                      selectedPayment: selectedPayment,
                      surface: surface,
                      border: border,
                      primary: primary,
                      textPrimary: textPrimary,
                      onChanged: (index) {
                        setState(() {
                          selectedPayment = index;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    // =========================================================
                    // SAVE
                    // =========================================================
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _saveExpense,
                        icon: const Icon(Icons.check_rounded, size: 19),
                        label: Text(
                          'finance.expense.save'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: inverseText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // =========================================================
                    // CANCEL
                    // =========================================================
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: textMuted,
                        ),
                        label: Text(
                          'finance.expense.cancel'.tr,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: surface,
                          foregroundColor: textPrimary,
                          side: BorderSide(color: border, width: 1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
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

// =============================================================================
// CATEGORY MODEL
// =============================================================================

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}

// =============================================================================
// PAYMENT MODEL
// =============================================================================

class _PaymentItem {
  final String name;
  final IconData icon;

  const _PaymentItem({required this.name, required this.icon});
}

// =============================================================================
// BACK BUTTON
// =============================================================================

class _BackButton extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _BackButton({
    required this.color,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: iconColor,
            size: 17,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AMOUNT SECTION
// =============================================================================

class _AmountSection extends StatelessWidget {
  final TextEditingController controller;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color primary;

  const _AmountSection({
    required this.controller,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'finance.expense.amount'.tr,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        Container(
          height: 72,
          width: double.infinity,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              // ===============================================================
              // CURRENCY
              // ===============================================================
              Container(
                width: 60,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                ),
                child: Center(
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: primary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              Container(width: 1, height: 36, color: border),

              // ===============================================================
              // AMOUNT INPUT
              // ===============================================================
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  cursorColor: primary,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: textMuted.withValues(alpha: 0.45),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),

                    // IMPORTANT:
                    // No focus background.
                    // No focus border.
                    // Everything stays exactly the same.
                    filled: false,
                    fillColor: Colors.transparent,

                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,

                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // ===============================================================
              // ICON
              // ===============================================================
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.payments_outlined,
                  color: textMuted.withValues(alpha: 0.45),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SECTION LABEL
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textMuted;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// INPUT FIELD
// =============================================================================

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final IconData prefixIcon;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: textPrimary,

      style: TextStyle(
        color: textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: TextStyle(
          color: textMuted.withValues(alpha: 0.65),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),

        // ===============================================================
        // ICON
        // ===============================================================
        prefixIcon: Icon(prefixIcon, color: textMuted, size: 19),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),

        // ===============================================================
        // SAME COLOR
        // ===============================================================
        filled: true,
        fillColor: surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),

        // ===============================================================
        // BORDER
        // ===============================================================
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
      ),
    );
  }
}

// =============================================================================
// CATEGORY SELECTOR
// =============================================================================

class _CategorySelector extends StatelessWidget {
  final List<_CategoryItem> categories;
  final int selectedCategory;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<int> onChanged;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        final bool selected = selectedCategory == index;

        return GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? item.color.withValues(alpha: 0.10) : surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? item.color : border,
                width: selected ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 17,
                  color: selected ? item.color : textMuted,
                ),

                const SizedBox(width: 6),

                Flexible(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? item.color : textPrimary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// DATE SELECTOR
// =============================================================================

class _DateSelector extends StatelessWidget {
  final String date;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  const _DateSelector({
    required this.date,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: textMuted,
                  size: 18,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'finance.expense.expenseDate'.tr,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PAYMENT SELECTOR
// =============================================================================

class _PaymentSelector extends StatelessWidget {
  final List<_PaymentItem> payments;
  final int selectedPayment;
  final Color surface;
  final Color border;
  final Color primary;
  final Color textPrimary;
  final ValueChanged<int> onChanged;

  const _PaymentSelector({
    required this.payments,
    required this.selectedPayment,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textPrimary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(payments.length, (index) {
        final item = payments[index];
        final bool selected = selectedPayment == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < payments.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 50,
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.10) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? primary : border,
                    width: selected ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 17,
                      color: selected ? primary : textPrimary,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      item.name,
                      style: TextStyle(
                        color: selected ? primary : textPrimary,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
