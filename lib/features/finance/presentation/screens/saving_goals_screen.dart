import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class SavingGoalsScreen extends StatelessWidget {
  const SavingGoalsScreen({super.key});

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
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
                        'Saving Goals',
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

                  // TOTAL SAVED CARD
                  _TotalSavedCard(
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    surfaceSecondary: surfaceSecondary,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // ACTIVE GOALS
                  _SavingGoalCard(
                    title: 'Emergency Fund',
                    saved: 1240,
                    target: 3000,
                    targetDate: 'Dec 2026',
                    icon: Icons.shield_outlined,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),

                  const SizedBox(height: 8),

                  _SavingGoalCard(
                    title: 'Travel — Japan',
                    saved: 840,
                    target: 2000,
                    targetDate: 'May 2027',
                    icon: Icons.flight_takeoff_rounded,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),

                  const SizedBox(height: 8),

                  _SavingGoalCard(
                    title: 'New MacBook',
                    saved: 400,
                    target: 1500,
                    targetDate: 'Sep 2026',
                    icon: Icons.laptop_mac_rounded,
                    surface: surface,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    border: border,
                  ),

                  const SizedBox(height: 8),

                  // COMPLETED GOALS
                  _CompletedGoalsCard(
                    surface: surface,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    border: border,
                  ),

                  const SizedBox(height: 12),

                  // NEW GOAL BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _showNewGoalSheet(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        foregroundColor: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 20),
                          SizedBox(width: 7),
                          Text(
                            'New Goal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // NEW GOAL SHEET
  void _showNewGoalSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Create New Goal',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              _GoalTextField(
                hint: 'Goal name',
                icon: Icons.flag_outlined,
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              _GoalTextField(
                hint: 'Target amount',
                icon: Icons.attach_money_rounded,
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),

              _GoalTextField(
                hint: 'Target date',
                icon: Icons.calendar_today_outlined,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    foregroundColor: isDark
                        ? AppColors.darkTextInverse
                        : AppColors.lightTextInverse,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Goal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// TOTAL SAVED CARD
class _TotalSavedCard extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceSecondary;
  final bool isDark;

  const _TotalSavedCard({
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfacePrimary : AppColors.lightPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Saved',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '\$2,480',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'Across 3 active goals',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.white.withValues(alpha: 0.58),
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  title: 'Income',
                  value: '+\$6,200',
                  valueColor: AppColors.financeAccent,
                  background: isDark
                      ? AppColors.darkSurfaceSecondary
                      : Colors.white.withValues(alpha: 0.08),
                  titleColor: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.white.withValues(alpha: 0.58),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _SummaryBox(
                  title: 'Expenses',
                  value: '-\$1,379.50',
                  valueColor: isDark ? AppColors.darkTextPrimary : Colors.white,
                  background: isDark
                      ? AppColors.darkSurfaceSecondary
                      : Colors.white.withValues(alpha: 0.08),
                  titleColor: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.white.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SUMMARY BOX
class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final Color background;
  final Color titleColor;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.background,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// SAVING GOAL CARD
class _SavingGoalCard extends StatelessWidget {
  final String title;
  final double saved;
  final double target;
  final String targetDate;
  final IconData icon;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const _SavingGoalCard({
    required this.title,
    required this.saved,
    required this.target,
    required this.targetDate,
    required this.icon,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  double get progress {
    if (target <= 0) return 0;
    return (saved / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          // PROGRESS CIRCLE
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 45,
                  height: 45,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 3,
                    color: AppColors.financeAccent.withValues(alpha: 0.12),
                  ),
                ),
                SizedBox(
                  width: 45,
                  height: 45,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: AppColors.financeAccent,
                  ),
                ),
                Icon(icon, size: 17, color: AppColors.financeAccent),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '\$${_formatAmount(saved)} of \$${_formatAmount(target)}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Target: $targetDate',
                  style: TextStyle(color: textSecondary, fontSize: 8),
                ),

                const SizedBox(height: 6),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.financeAccent.withValues(
                      alpha: 0.10,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.financeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }
}

// COMPLETED GOALS
class _CompletedGoalsCard extends StatelessWidget {
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final Color border;

  const _CompletedGoalsCard({
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Goals',
            style: TextStyle(
              color: textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          _CompletedGoalItem(
            title: 'iPhone Upgrade',
            amount: '\$800',
            textMuted: textMuted,
          ),

          Divider(height: 1, color: border),

          _CompletedGoalItem(
            title: 'Rainy Day Fund',
            amount: '\$500',
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }
}

// COMPLETED GOAL ITEM
class _CompletedGoalItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color textMuted;

  const _CompletedGoalItem({
    required this.title,
    required this.amount,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: AppColors.financeAccent,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              '$title — $amount',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textMuted,
                fontSize: 9,
                decoration: TextDecoration.lineThrough,
                decorationColor: textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TEXT FIELD
class _GoalTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;

  const _GoalTextField({
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 19, color: AppColors.financeAccent),
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.lightSurfacePrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
