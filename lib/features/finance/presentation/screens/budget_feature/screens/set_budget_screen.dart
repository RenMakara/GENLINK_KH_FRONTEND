import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final TextEditingController foodController = TextEditingController(
    text: '300',
  );

  final TextEditingController transportController = TextEditingController(
    text: '150',
  );

  final TextEditingController studyController = TextEditingController(
    text: '150',
  );

  final TextEditingController billsController = TextEditingController(
    text: '300',
  );

  String selectedMonth = 'June 2026';

  @override
  void initState() {
    super.initState();

    foodController.addListener(_updateTotal);
    transportController.addListener(_updateTotal);
    studyController.addListener(_updateTotal);
    billsController.addListener(_updateTotal);
  }

  @override
  void dispose() {
    foodController.removeListener(_updateTotal);
    transportController.removeListener(_updateTotal);
    studyController.removeListener(_updateTotal);
    billsController.removeListener(_updateTotal);

    foodController.dispose();
    transportController.dispose();
    studyController.dispose();
    billsController.dispose();

    super.dispose();
  }

  void _updateTotal() {
    if (mounted) {
      setState(() {});
    }
  }

  double _getAmount(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;
  }

  double get totalBudget {
    return _getAmount(foodController) +
        _getAmount(transportController) +
        _getAmount(studyController) +
        _getAmount(billsController);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final surfaceSecondary = isDark
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

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // HEADER
              // =========================================================
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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

                  const SizedBox(width: 8),

                  Text(
                    'Set Budget',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================================================
              // MONTH SELECTOR
              // =========================================================
              _MonthSelector(
                month: selectedMonth,
                background: surfaceSecondary,
                textColor: textPrimary,
                iconColor: textSecondary,
                borderColor: border,
                onTap: _selectMonth,
              ),

              const SizedBox(height: 22),

              // =========================================================
              // TOTAL BUDGET
              // =========================================================
              Center(
                child: Column(
                  children: [
                    Text(
                      '\$${totalBudget.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 32,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Monthly total budget',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =========================================================
              // CATEGORY ALLOCATION
              // =========================================================
              _CategoryAllocationCard(
                surface: surface,
                border: border,
                titleColor: textPrimary,
                children: [
                  _BudgetCategoryRow(
                    icon: Icons.fastfood_outlined,
                    title: 'Food & Drink',
                    controller: foodController,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconBackground: surfaceSecondary,
                    border: border,
                  ),

                  _BudgetCategoryRow(
                    icon: Icons.menu_rounded,
                    title: 'Transport',
                    controller: transportController,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconBackground: surfaceSecondary,
                    border: border,
                  ),

                  _BudgetCategoryRow(
                    icon: Icons.edit_outlined,
                    title: 'Study',
                    controller: studyController,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconBackground: surfaceSecondary,
                    border: border,
                  ),

                  _BudgetCategoryRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Bills',
                    controller: billsController,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    iconBackground: surfaceSecondary,
                    border: border,
                    last: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =========================================================
              // SAVE BUTTON
              // =========================================================
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    foregroundColor: isDark
                        ? AppColors.darkTextInverse
                        : AppColors.lightTextInverse,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Budget',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MONTH PICKER
  // ================================================================

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

  // ================================================================
  // SAVE
  // ================================================================

  void _saveBudget() {
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Budget saved successfully',
          style: TextStyle(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ============================================================================
// MONTH SELECTOR
// ============================================================================

class _MonthSelector extends StatelessWidget {
  final String month;
  final Color background;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _MonthSelector({
    required this.month,
    required this.background,
    required this.textColor,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            Text(
              month,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Icon(Icons.calendar_today_outlined, color: iconColor, size: 15),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CATEGORY ALLOCATION CARD
// ============================================================================

class _CategoryAllocationCard extends StatelessWidget {
  final Color surface;
  final Color border;
  final Color titleColor;
  final List<Widget> children;

  const _CategoryAllocationCard({
    required this.surface,
    required this.border,
    required this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        children: [
          // =========================================================
          // CARD TITLE
          // =========================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category Allocation',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          ...children,
        ],
      ),
    );
  }
}

// ============================================================================
// CATEGORY ROW
// ============================================================================

class _BudgetCategoryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final TextEditingController controller;

  final Color textPrimary;
  final Color textSecondary;
  final Color iconBackground;
  final Color border;

  final bool last;

  const _BudgetCategoryRow({
    required this.icon,
    required this.title,
    required this.controller,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconBackground,
    required this.border,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: border, width: 0.8)),
      ),
      child: Row(
        children: [
          // =========================================================
          // ICON
          // =========================================================
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: textSecondary),
          ),

          const SizedBox(width: 11),

          // =========================================================
          // TITLE
          // =========================================================
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // =========================================================
          // AMOUNT
          // =========================================================
          SizedBox(
            width: 75,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                color: textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              cursorColor: AppColors.financeAccent,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                prefixText: '\$',
                prefixStyle: TextStyle(
                  color: textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
