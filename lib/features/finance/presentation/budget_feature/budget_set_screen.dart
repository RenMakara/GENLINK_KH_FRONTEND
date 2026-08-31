import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/widget/budget_set_widget.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  String selectedMonth = 'June 2026';

  final List<BudgetCategory> categories = [
    BudgetCategory(
      icon: Icons.fastfood_outlined,
      title: 'Food & Drink',
      subtitle: 'Meals, coffee and snacks',
      amount: 300,
      color: AppColors.growthAccent,
    ),
    BudgetCategory(
      icon: Icons.directions_bus_outlined,
      title: 'Transport',
      subtitle: 'Taxi, fuel and public transport',
      amount: 150,
      color: AppColors.brandPrimary,
    ),
    BudgetCategory(
      icon: Icons.menu_book_outlined,
      title: 'Study',
      subtitle: 'Books, courses and supplies',
      amount: 150,
      color: AppColors.productivityAccent,
    ),
    BudgetCategory(
      icon: Icons.receipt_long_outlined,
      title: 'Bills',
      subtitle: 'Phone, internet and utilities',
      amount: 300,
      color: AppColors.financeAccent,
    ),
  ];

  double get totalBudget {
    return categories.fold(0, (total, category) => total + category.amount);
  }

  double percentage(double amount) {
    if (totalBudget <= 0) return 0;

    return amount / totalBudget;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final secondarySurface = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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

      // =====================================================================
      // SAVE BUTTON
      // =====================================================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: border, width: 0.7)),
          ),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: totalBudget > 0 ? _saveBudget : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: secondarySurface,
                foregroundColor: inverseText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 19),
                  const SizedBox(width: 7),
                  Text(
                    'finance.budget.saveBudget'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================================
              // HEADER
              // =================================================================
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textPrimary,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      'finance.budget.setBudget'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =================================================================
              // BUDGET PERIOD
              // =================================================================
              Text(
                'finance.budget.budgetPeriod'.tr,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              MonthSelector(
                month: selectedMonth,
                background: surface,
                textColor: textPrimary,
                iconColor: primary,
                borderColor: border,
                onTap: _selectMonth,
              ),

              const SizedBox(height: 20),

              // =================================================================
              // TOTAL BUDGET
              // =================================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: primary,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 11),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'finance.budget.monthlyBudget'.tr,
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              selectedMonth,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      '\$${totalBudget.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.3,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'finance.budget.totalBudget'.tr,
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),

                    const SizedBox(height: 15),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: totalBudget > 0 ? 1 : 0,
                        minHeight: 6,
                        backgroundColor: secondarySurface,
                        valueColor: AlwaysStoppedAnimation(primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // =================================================================
              // CATEGORY HEADER
              // =================================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'finance.budget.categoryBudgets'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Text(
                    '${categories.length} ${'finance.budget.categories'.tr}',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =================================================================
              // CATEGORY LIST
              // =================================================================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < categories.length; i++) ...[
                      BudgetCategoryRow(
                        category: categories[i],
                        percentage: percentage(categories[i].amount),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                        iconBackground: secondarySurface,

                        onChanged: (value) {
                          setState(() {
                            categories[i].amount = value;
                          });
                        },

                        onDelete: categories.length > 1
                            ? () => _deleteCategory(i)
                            : null,
                      ),

                      if (i != categories.length - 1)
                        Divider(height: 1, color: border),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =================================================================
              // ADD CATEGORY
              // =================================================================
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddCategory,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: primary, size: 20),

                        const SizedBox(width: 7),

                        Text(
                          'finance.budget.category'.tr,
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =================================================================
              // TIP
              // =================================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: primary,
                      size: 19,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'finance.budget.categoryAllocation'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'finance.budget.considerReducingSpending'.tr,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ADD CATEGORY
  // ===========================================================================

  Future<void> _showAddCategory() async {
    final nameController = TextEditingController();
    final subtitleController = TextEditingController();
    final amountController = TextEditingController();

    IconData selectedIcon = Icons.category_outlined;

    final result = await showModalBottomSheet<BudgetCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final surface = isDark
            ? AppColors.darkSurfacePrimary
            : AppColors.lightSurfacePrimary;

        final secondarySurface = isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.lightSurfaceSecondary;

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

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =======================================================
                      // HANDLE
                      // =======================================================
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'finance.budget.categoryBudgets'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'finance.budget.budgetPeriod'.tr,
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),

                      const SizedBox(height: 20),

                      // =======================================================
                      // CATEGORY NAME
                      // =======================================================
                      Text(
                        'finance.budget.category'.tr,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Entertainment',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          filled: true,
                          fillColor: secondarySurface,
                          prefixIcon: Icon(
                            selectedIcon,
                            color: primary,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =======================================================
                      // DESCRIPTION
                      // =======================================================
                      Text(
                        'Description',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller: subtitleController,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Movies, games and hobbies',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          filled: true,
                          fillColor: secondarySurface,
                          prefixIcon: Icon(
                            Icons.notes_outlined,
                            color: primary,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =======================================================
                      // BUDGET AMOUNT
                      // =======================================================
                      Text(
                        'finance.budget.budgetAmount'.tr,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          filled: true,
                          fillColor: secondarySurface,
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            color: textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =======================================================
                      // ADD BUTTON
                      // =======================================================
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();

                            final subtitle = subtitleController.text.trim();

                            final amount =
                                double.tryParse(amountController.text.trim()) ??
                                0;

                            if (name.isEmpty || amount <= 0) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              BudgetCategory(
                                icon: selectedIcon,
                                title: name,
                                subtitle: subtitle.isEmpty
                                    ? 'Custom budget category'
                                    : subtitle,
                                amount: amount,
                                color: primary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: inverseText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'finance.budget.category'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    subtitleController.dispose();
    amountController.dispose();

    if (result == null) return;

    setState(() {
      categories.add(result);
    });
  }

  // ===========================================================================
  // DELETE CATEGORY
  // ===========================================================================

  void _deleteCategory(int index) {
    final category = categories[index];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Remove category?',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Remove "${category.title}" from this budget?',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  categories.removeAt(index);
                });
              },
              child: Text(
                'Remove',
                style: TextStyle(color: primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MONTH PICKER
  // ===========================================================================

  Future<void> _selectMonth() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, 1),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.financeAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedMonth = '${_monthName(picked.month)} ${picked.year}';
    });
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  void _saveBudget() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'finance.budget.budgetSaved'.tr,
          style: const TextStyle(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
