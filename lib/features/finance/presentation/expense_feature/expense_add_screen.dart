import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/widget/expense_add_widget.dart';
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

  // CATEGORIES
  final List<ExpenseCategoryItem> categories = [
    ExpenseCategoryItem(
      name: 'finance.expense.food'.tr,
      icon: Icons.restaurant_outlined,
      color: AppColors.growthAccent,
    ),
    ExpenseCategoryItem(
      name: 'finance.expense.transport'.tr,
      icon: Icons.directions_car_outlined,
      color: AppColors.brandPrimary,
    ),
    ExpenseCategoryItem(
      name: 'finance.expense.study'.tr,
      icon: Icons.menu_book_outlined,
      color: AppColors.productivityAccent,
    ),
    ExpenseCategoryItem(
      name: 'finance.expense.bills'.tr,
      icon: Icons.receipt_long_outlined,
      color: AppColors.financeAccent,
    ),
    ExpenseCategoryItem(
      name: 'finance.expense.health'.tr,
      icon: Icons.favorite_border_rounded,
      color: AppColors.productivityAccent,
    ),
    ExpenseCategoryItem(
      name: 'finance.expense.other'.tr,
      icon: Icons.more_horiz_rounded,
      color: AppColors.success,
    ),
  ];

  // PAYMENT METHODS
  final List<ExpensePaymentItem> payments = const [
    ExpensePaymentItem(name: 'Cash', icon: Icons.payments_outlined),
    ExpensePaymentItem(name: 'Card', icon: Icons.credit_card_outlined),
    ExpensePaymentItem(name: 'ABA', icon: Icons.account_balance_outlined),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // DATE PICKER
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

  // DATE FORMAT
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

  // BUILD
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // COLORS
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
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  ExpenseBackButton(
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

            // CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AMOUNT
                    ExpenseAmountSection(
                      controller: _amountController,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      primary: primary,
                    ),

                    const SizedBox(height: 26),

                    // DESCRIPTION
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
                      prefixIcon: Icons.edit_note_outlined,
                    ),

                    const SizedBox(height: 23),

                    // CATEGORY
                    ExpenseSectionLabel(
                      title: 'finance.expense.category'.tr,
                      subtitle: 'finance.expense.categoryHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 11),

                    ExpenseCategorySelector(
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

                    // NOTE
                    ExpenseSectionLabel(
                      title: 'finance.expense.note'.tr,
                      subtitle: 'finance.expense.optional'.tr,
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

                    const SizedBox(height: 23),

                    // DATE
                    ExpenseSectionLabel(
                      title: 'finance.expense.date'.tr,
                      subtitle: 'finance.expense.dateHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 9),

                    ExpenseDateSelector(
                      date: _formatDate(selectedDate),
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _selectDate,
                    ),

                    const SizedBox(height: 23),

                    // PAYMENT
                    ExpenseSectionLabel(
                      title: 'finance.expense.paymentMethod'.tr,
                      subtitle: 'finance.expense.paymentHelper'.tr,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 11),

                    ExpensePaymentSelector(
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

                    // SAVE
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

                    // CANCEL
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
