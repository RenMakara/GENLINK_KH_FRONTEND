import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/widget/saving_goals_create_widget.dart';

class UpdateGoalScreen extends StatefulWidget {
  final String title;
  final double savedAmount;
  final double targetAmount;
  final String targetDate;
  final Color color;

  const UpdateGoalScreen({
    super.key,
    required this.title,
    required this.savedAmount,
    required this.targetAmount,
    required this.targetDate,
    required this.color,
  });

  @override
  State<UpdateGoalScreen> createState() => _UpdateGoalScreenState();
}

class _UpdateGoalScreenState extends State<UpdateGoalScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  // ============================================================
  // DATE
  // ============================================================

  late DateTime _selectedDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.title);

    _amountController = TextEditingController(
      text: widget.targetAmount.toStringAsFixed(0),
    );

    _selectedDate = _parseDate(widget.targetDate);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');

      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      final parsed = DateTime.tryParse(date);

      if (parsed != null) {
        return parsed;
      }
    } catch (_) {}

    return DateTime.now();
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

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

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // MONTHLY SAVING
  // ============================================================

  double _calculateMonthlySaving() {
    final target = double.tryParse(_amountController.text) ?? 0;

    final now = DateTime.now();

    int months =
        (_selectedDate.year - now.year) * 12 +
        (_selectedDate.month - now.month);

    if (months <= 0) {
      months = 1;
    }

    final remaining = target - widget.savedAmount;

    if (remaining <= 0) {
      return 0;
    }

    return remaining / months;
  }

  // ============================================================
  // FORMAT MONEY
  // ============================================================

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return '\$${value.toStringAsFixed(0)}';
    }

    return '\$${value.toStringAsFixed(2)}';
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(primary: widget.color)
                : ColorScheme.light(primary: widget.color),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ============================================================
  // UPDATE GOAL
  // ============================================================

  void _updateGoal() {
    final title = _titleController.text.trim();

    final targetAmount = double.tryParse(_amountController.text.trim());

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a goal name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid target amount.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (targetAmount < widget.savedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target amount cannot be less than '
            'your current saved amount '
            '(\$${widget.savedAmount.toStringAsFixed(0)}).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ==========================================================
    // RETURN UPDATED DATA
    // ==========================================================

    Navigator.pop(context, {
      'title': title,
      'targetAmount': targetAmount,
      'targetDate': _formatDate(_selectedDate),
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ============================================================
    // COLORS
    // ============================================================

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

    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // HEADER
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  CreateGoalBackButton(
                    background: surface,
                    iconColor: textPrimary,
                    borderColor: border,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Goal',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Modify your saving goal',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // CURRENT PROGRESS
                    // =================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.savings_outlined,
                              color: widget.color,
                              size: 22,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Saved',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  _formatMoney(widget.savedAmount),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            'Editing',
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // =================================================
                    // GOAL NAME
                    // =================================================
                    CreateGoalTitleField(
                      label: 'Goal Name',
                      hintText: 'e.g. New Laptop',
                      controller: _titleController,
                      textColor: textPrimary,
                      hintColor: textMuted,
                      surfaceColor: surface,
                      borderColor: border,
                      focusedColor: widget.color,
                    ),

                    const SizedBox(height: 26),

                    // =================================================
                    // TARGET AMOUNT
                    // =================================================
                    CreateGoalAmountSection(
                      label: 'TARGET AMOUNT',
                      hintText: '0',
                      currencySymbol: '\$',
                      controller: _amountController,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onChanged: () {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 26),

                    // =================================================
                    // TARGET DATE
                    // =================================================
                    CreateGoalDateSelector(
                      label: 'Target Date',
                      date: _formatDate(_selectedDate),
                      selected: true,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _selectDate,
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // MONTHLY PLAN
                    // =================================================
                    CreateGoalMonthlyPlan(
                      title: 'Monthly Saving Plan',
                      subtitle: 'Estimated amount needed each month',
                      monthlySaving: _formatMoney(_calculateMonthlySaving()),
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // INFO
                    // =================================================
                    CreateGoalSavingTip(
                      message:
                          'You can change your target amount '
                          'or target date at any time. '
                          'Your existing deposits will not be changed.',
                      textSecondary: textMuted,
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // UPDATE BUTTON
                    // =================================================
                    CreateGoalButton(
                      text: 'Save Changes',
                      background: primary,
                      foreground: textInverse,
                      onTap: _updateGoal,
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // CANCEL BUTTON
                    // =================================================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: textMuted),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
}
