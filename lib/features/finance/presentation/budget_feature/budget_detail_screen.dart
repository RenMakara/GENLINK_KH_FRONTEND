import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/widget/budget_detail_widget.dart';

class BudgetDetailScreen extends StatefulWidget {
  final String category;
  final double spent;
  final double budget;
  final Color categoryColor;

  const BudgetDetailScreen({
    super.key,
    required this.category,
    required this.spent,
    required this.budget,
    required this.categoryColor,
  });

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  late double budgetAmount;

  @override
  void initState() {
    super.initState();
    budgetAmount = widget.budget;
  }

  // ===========================================================================
  // CALCULATIONS
  // ===========================================================================

  double get spent => widget.spent;

  double get remaining => budgetAmount - spent;

  double get progress {
    if (budgetAmount <= 0) return 0;

    return (spent / budgetAmount).clamp(0.0, 1.0);
  }

  int get percentage {
    if (budgetAmount <= 0) return 0;

    return ((spent / budgetAmount) * 100).round();
  }

  bool get isOverBudget => spent > budgetAmount;

  String money(double value) {
    return '\$${value.abs().toStringAsFixed(2)}';
  }

  String displayRemaining() {
    if (remaining < 0) {
      return '-${money(remaining)}';
    }

    return money(remaining);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

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
      body: SafeArea(
        child: Column(
          children: [
            // =================================================================
            // HEADER
            // =================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
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

                  Expanded(
                    child: Text(
                      widget.category,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      _showEditBudgetSheet(
                        context,
                        surface: surface,
                        secondarySurface: secondarySurface,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        textMuted: textMuted,
                        border: border,
                        primary: primary,
                        inverseText: inverseText,
                      );
                    },
                    icon: Icon(Icons.edit_outlined, color: primary, size: 17),
                    label: Text(
                      'finance.budget.editBudget'.tr,
                      style: TextStyle(
                        color: primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // BUDGET SUMMARY
                    // =========================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          // ---------------------------------------------------
                          // CATEGORY HEADER
                          // ---------------------------------------------------
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: widget.categoryColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _categoryIcon(widget.category),
                                  color: widget.categoryColor,
                                  size: 22,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.category,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      'finance.budget.monthlyBudget'.tr,
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // STATUS
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isOverBudget
                                      ? Colors.redAccent.withValues(alpha: 0.10)
                                      : AppColors.success.withValues(
                                          alpha: 0.10,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isOverBudget
                                      ? 'finance.budget.overBudget'.tr
                                      : 'finance.budget.onTrack'.tr,
                                  style: TextStyle(
                                    color: isOverBudget
                                        ? Colors.redAccent
                                        : AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // ---------------------------------------------------
                          // REMAINING
                          // ---------------------------------------------------
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'finance.budget.remaining'.tr,
                              style: TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              displayRemaining(),
                              style: TextStyle(
                                color: isOverBudget
                                    ? Colors.redAccent
                                    : textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${money(budgetAmount)} '
                              '${'finance.budget.monthlyBudget'.tr}',
                              style: TextStyle(color: textMuted, fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ---------------------------------------------------
                          // PROGRESS
                          // ---------------------------------------------------
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: secondarySurface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudget
                                    ? Colors.redAccent
                                    : widget.categoryColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$percentage% '
                                '${'finance.budget.used'.tr}',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),

                              Text(
                                '${money(spent)} '
                                '${'finance.budget.spent'.tr}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ---------------------------------------------------
                          // STATS
                          // ---------------------------------------------------
                          Row(
                            children: [
                              Expanded(
                                child: BudgetStatCell(
                                  label: 'finance.budget.limit'.tr,
                                  value: money(budgetAmount),
                                  color: textPrimary,
                                  textMuted: textMuted,
                                ),
                              ),

                              Container(width: 1, height: 34, color: border),

                              Expanded(
                                child: BudgetStatCell(
                                  label: 'finance.budget.spent'.tr,
                                  value: money(spent),
                                  color: widget.categoryColor,
                                  textMuted: textMuted,
                                ),
                              ),

                              Container(width: 1, height: 34, color: border),

                              Expanded(
                                child: BudgetStatCell(
                                  label: 'finance.budget.left'.tr,
                                  value: displayRemaining(),
                                  color: isOverBudget
                                      ? Colors.redAccent
                                      : textPrimary,
                                  textMuted: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // =========================================================
                    // OVER BUDGET WARNING
                    // =========================================================
                    if (isOverBudget) ...[
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 19,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                '${'finance.budget.overBudget'.tr}: '
                                '${money(spent - budgetAmount)}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // =========================================================
                    // EXPENSE HEADER
                    // =========================================================
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'finance.budget.expenses'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        Text(
                          '4 ${'finance.budget.expenses'.tr}',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // =========================================================
                    // EXPENSE 1
                    // =========================================================
                    BudgetExpenseRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'Grab Food',
                      subtitle: 'Jun 28 · 12:30 PM',
                      amount: '-\$8.50',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _showExpenseDetails(
                          context,
                          title: 'Grab Food',
                          amount: '-\$8.50',
                          date: 'June 28, 2026',
                          time: '12:30 PM',
                          surface: surface,
                          secondarySurface: secondarySurface,
                          border: border,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          primary: primary,
                        );
                      },
                    ),

                    // =========================================================
                    // EXPENSE 2
                    // =========================================================
                    BudgetExpenseRow(
                      icon: Icons.lunch_dining_outlined,
                      title: 'Lunch Box',
                      subtitle: 'Jun 27 · 12:15 PM',
                      amount: '-\$4.20',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _showExpenseDetails(
                          context,
                          title: 'Lunch Box',
                          amount: '-\$4.20',
                          date: 'June 27, 2026',
                          time: '12:15 PM',
                          surface: surface,
                          secondarySurface: secondarySurface,
                          border: border,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          primary: primary,
                        );
                      },
                    ),

                    // =========================================================
                    // EXPENSE 3
                    // =========================================================
                    BudgetExpenseRow(
                      icon: Icons.restaurant_outlined,
                      title: 'Phnom Penh Kitchen',
                      subtitle: 'Jun 26 · 7:20 PM',
                      amount: '-\$12.00',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _showExpenseDetails(
                          context,
                          title: 'Phnom Penh Kitchen',
                          amount: '-\$12.00',
                          date: 'June 26, 2026',
                          time: '7:20 PM',
                          surface: surface,
                          secondarySurface: secondarySurface,
                          border: border,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          primary: primary,
                        );
                      },
                    ),

                    // =========================================================
                    // EXPENSE 4
                    // =========================================================
                    BudgetExpenseRow(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Market Grocery',
                      subtitle: 'Jun 23 · 5:45 PM',
                      amount: '-\$28.50',
                      surface: surface,
                      secondarySurface: secondarySurface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: () {
                        _showExpenseDetails(
                          context,
                          title: 'Market Grocery',
                          amount: '-\$28.50',
                          date: 'June 23, 2026',
                          time: '5:45 PM',
                          surface: surface,
                          secondarySurface: secondarySurface,
                          border: border,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          primary: primary,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // =========================================================
                    // ADJUST BUDGET BUTTON
                    // =========================================================
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showEditBudgetSheet(
                            context,
                            surface: surface,
                            secondarySurface: secondarySurface,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            border: border,
                            primary: primary,
                            inverseText: inverseText,
                          );
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: primary,
                        ),
                        label: Text(
                          'finance.budget.adjustBudget'.tr,
                          style: TextStyle(
                            color: primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CATEGORY ICON
  // ===========================================================================

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
      case 'food':
        return Icons.restaurant_outlined;

      case 'transport':
        return Icons.directions_car_outlined;

      case 'study':
        return Icons.school_outlined;

      case 'bills':
        return Icons.receipt_long_outlined;

      case 'shopping':
        return Icons.shopping_bag_outlined;

      case 'entertainment':
        return Icons.movie_outlined;

      case 'health':
        return Icons.health_and_safety_outlined;

      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // ===========================================================================
  // EDIT BUDGET SHEET
  // ===========================================================================

  void _showEditBudgetSheet(
    BuildContext context, {
    required Color surface,
    required Color secondarySurface,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color border,
    required Color primary,
    required Color inverseText,
  }) {
    final controller = TextEditingController(
      text: budgetAmount.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final enteredAmount = double.tryParse(controller.text.trim());

            final validAmount = enteredAmount != null && enteredAmount > 0;

            final amountRemaining = enteredAmount != null
                ? enteredAmount - spent
                : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HANDLE
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

                  const SizedBox(height: 22),

                  Text(
                    'finance.budget.adjustBudget'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${'finance.budget.monthlyBudget'.tr} · '
                    '${widget.category}',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'finance.budget.budgetAmount'.tr,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // INPUT
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    onChanged: (_) {
                      setSheetState(() {});
                    },
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: secondarySurface,
                      hintText: '0',
                      hintStyle: TextStyle(color: textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PREVIEW
                  if (validAmount)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secondarySurface,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            amountRemaining >= 0
                                ? Icons.check_circle_outline_rounded
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: amountRemaining >= 0
                                ? AppColors.success
                                : Colors.redAccent,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              amountRemaining >= 0
                                  ? '${money(amountRemaining)} '
                                        '${'finance.budget.remainingForMonth'.tr}'
                                  : '${'finance.budget.overBudget'.tr}.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // QUICK AMOUNTS
                  Row(
                    children: [
                      BudgetQuickAmount(
                        amount: 100,
                        controller: controller,
                        secondarySurface: secondarySurface,
                        textPrimary: textPrimary,
                        border: border,
                        onChanged: () => setSheetState(() {}),
                      ),

                      const SizedBox(width: 8),

                      BudgetQuickAmount(
                        amount: 200,
                        controller: controller,
                        secondarySurface: secondarySurface,
                        textPrimary: textPrimary,
                        border: border,
                        onChanged: () => setSheetState(() {}),
                      ),

                      const SizedBox(width: 8),

                      BudgetQuickAmount(
                        amount: 300,
                        controller: controller,
                        secondarySurface: secondarySurface,
                        textPrimary: textPrimary,
                        border: border,
                        onChanged: () => setSheetState(() {}),
                      ),

                      const SizedBox(width: 8),

                      BudgetQuickAmount(
                        amount: 500,
                        controller: controller,
                        secondarySurface: secondarySurface,
                        textPrimary: textPrimary,
                        border: border,
                        onChanged: () => setSheetState(() {}),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // SAVE
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text.trim());

                        if (value == null || value <= 0) {
                          Get.snackbar(
                            'finance.budget.invalidAmount'.tr,
                            'finance.budget.enterValidAmount'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                          );
                          return;
                        }

                        setState(() {
                          budgetAmount = value;
                        });

                        Navigator.pop(sheetContext);

                        Get.snackbar(
                          'finance.budget.budgetSaved'.tr,
                          '${widget.category}: '
                          '\$${value.toStringAsFixed(2)}',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: inverseText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'finance.budget.saveBudget'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // EXPENSE DETAILS
  // ===========================================================================

  void _showExpenseDetails(
    BuildContext context, {
    required String title,
    required String amount,
    required String date,
    required String time,
    required Color surface,
    required Color secondarySurface,
    required Color border,
    required Color textPrimary,
    required Color textMuted,
    required Color primary,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HANDLE
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 24),

                // ICON
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: secondarySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: textPrimary,
                    size: 27,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  amount,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 22),

                // CATEGORY
                BudgetDetailRow(
                  icon: Icons.category_outlined,
                  label: 'finance.budget.category'.tr,
                  value: widget.category,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  secondarySurface: secondarySurface,
                ),

                // DATE
                BudgetDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'finance.budget.date'.tr,
                  value: date,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  secondarySurface: secondarySurface,
                ),

                // TIME
                BudgetDetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'finance.budget.time'.tr,
                  value: time,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  secondarySurface: secondarySurface,
                ),

                const SizedBox(height: 18),

                // EDIT EXPENSE
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      Get.snackbar(
                        'finance.budget.editExpense'.tr,
                        'Connect this action to your transaction controller.',
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, size: 18, color: primary),
                    label: Text(
                      'finance.budget.editExpense'.tr,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
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
