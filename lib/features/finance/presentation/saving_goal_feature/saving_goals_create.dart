import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/widget/saving_goals_create_widget.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();

  // ==========================================================
  // STATE
  // ==========================================================

  DateTime? selectedDate;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SELECT DATE
  // ==========================================================

  Future<void> _selectDate() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
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

    if (pickedDate == null) return;

    setState(() {
      selectedDate = pickedDate;
    });
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'finance.savingGoal.selectTargetDate'.tr;
    }

    const List<String> months = [
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

  // ==========================================================
  // MONTHLY SAVING
  // ==========================================================

  String _monthlySaving() {
    final double? amount = double.tryParse(
      _amountController.text.replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      return '\$0/month';
    }

    if (selectedDate == null) {
      return '\$0/month';
    }

    final DateTime now = DateTime.now();

    int months =
        (selectedDate!.year - now.year) * 12 + selectedDate!.month - now.month;

    if (selectedDate!.day < now.day) {
      months--;
    }

    if (months < 1) {
      months = 1;
    }

    final double monthly = amount / months;

    return '\$${monthly.toStringAsFixed(0)}/month';
  }

  // ==========================================================
  // CREATE GOAL
  // ==========================================================

  void _createGoal() {
    final String title = _titleController.text.trim();

    final double? amount = double.tryParse(
      _amountController.text.replaceAll(',', ''),
    );

    if (title.isEmpty) {
      _showMessage('finance.savingGoal.enterTitle'.tr);
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('finance.savingGoal.enterAmount'.tr);
      return;
    }

    if (selectedDate == null) {
      _showMessage('finance.savingGoal.selectDateError'.tr);
      return;
    }

    final Map<String, dynamic> goal = {
      'title': title,
      'targetAmount': amount,
      'targetDate': selectedDate,
      'savedAmount': 0.0,
    };

    Navigator.pop(context, goal);
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    Get.snackbar(
      'finance.savingGoal.validationError'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // ========================================================
    // COLORS
    // ========================================================

    final Color bg = isDark
        ? AppColors.darkBgPrimary
        : AppColors.lightBgPrimary;

    final Color surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final Color textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final Color textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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

    // ========================================================
    // TEXT
    // ========================================================

    final String screenTitle = 'finance.savingGoal.create'.tr;

    final String goalTitleLabel = 'finance.savingGoal.title'.tr;

    final String goalTitleHint = 'finance.savingGoal.titleHint'.tr;

    final String targetAmountLabel = 'finance.savingGoal.targetAmount'.tr;

    final String targetAmountHint = '0';

    final String currencySymbol = '\$';

    final String targetDateLabel = 'finance.savingGoal.targetDate'.tr;

    final String monthlyPlanTitle = 'finance.savingGoal.monthlyPlan'.tr;

    final String monthlyPlanSubtitle =
        'finance.savingGoal.recommendedAmount'.tr;

    final String savingTipText =
        selectedDate == null || _amountController.text.isEmpty
        ? 'finance.savingGoal.setAmountAndDate'.tr
        : 'finance.savingGoal.saveApproximately'.tr
              .replaceFirst('{amount}', _monthlySaving())
              .replaceFirst('{date}', _formatDate(selectedDate));

    final String createButtonText = 'finance.savingGoal.createButton'.tr;

    // ========================================================
    // SCREEN
    // ========================================================

    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
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

                  const SizedBox(width: 13),

                  Expanded(
                    child: Text(
                      screenTitle,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // TITLE
                    // ==================================================
                    CreateGoalTitleField(
                      label: goalTitleLabel,
                      hintText: goalTitleHint,
                      controller: _titleController,
                      textColor: textPrimary,
                      hintColor: textMuted,
                      surfaceColor: surface,
                      borderColor: border,
                      focusedColor: primary,
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // AMOUNT
                    // ==================================================
                    CreateGoalAmountSection(
                      label: targetAmountLabel,
                      hintText: targetAmountHint,
                      currencySymbol: currencySymbol,
                      controller: _amountController,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onChanged: () {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // DATE
                    // ==================================================
                    CreateGoalDateSelector(
                      label: targetDateLabel,
                      date: _formatDate(selectedDate),
                      selected: selectedDate != null,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTap: _selectDate,
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // MONTHLY PLAN
                    // ==================================================
                    CreateGoalMonthlyPlan(
                      title: monthlyPlanTitle,
                      subtitle: monthlyPlanSubtitle,
                      monthlySaving: _monthlySaving(),
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // TIP
                    // ==================================================
                    CreateGoalSavingTip(
                      message: savingTipText,
                      textSecondary: textSecondary,
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // CREATE BUTTON
                    // ==================================================
                    CreateGoalButton(
                      text: createButtonText,
                      background: primary,
                      foreground: inverseText,
                      onTap: _createGoal,
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
