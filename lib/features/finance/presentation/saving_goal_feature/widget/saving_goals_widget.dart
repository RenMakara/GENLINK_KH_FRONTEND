import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class SavingGoalsHeader extends StatelessWidget {
  final String title;
  final Color textPrimary;
  final VoidCallback? onBack;

  const SavingGoalsHeader({
    super.key,
    required this.title,
    required this.textPrimary,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SavingGoalsBackButton(
          color: Colors.transparent,
          iconColor: textPrimary,
          borderColor: Colors.transparent,
          onTap: onBack ?? () => Navigator.pop(context),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// TOTAL SAVED CARD
/// ============================================================

class TotalSavedCard extends StatelessWidget {
  final String title;
  final String totalSaved;
  final String subtitle;

  final String incomeTitle;
  final String incomeValue;

  final String expenseTitle;
  final String expenseValue;

  final Color primary;
  final Color textInverse;

  const TotalSavedCard({
    super.key,
    required this.title,
    required this.totalSaved,
    required this.subtitle,
    required this.incomeTitle,
    required this.incomeValue,
    required this.expenseTitle,
    required this.expenseValue,
    required this.primary,
    required this.textInverse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textInverse.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            totalSaved,
            style: TextStyle(
              color: textInverse,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: TextStyle(
              color: textInverse.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SummaryItem(
                  title: incomeTitle,
                  value: incomeValue,
                  textInverse: textInverse,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: SummaryItem(
                  title: expenseTitle,
                  value: expenseValue,
                  textInverse: textInverse,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// SUMMARY ITEM
/// ============================================================

class SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color textInverse;

  const SummaryItem({
    super.key,
    required this.title,
    required this.value,
    required this.textInverse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: textInverse.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textInverse.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style: TextStyle(
              color: textInverse,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// SECTION TITLE
/// ============================================================

class SavingGoalsSectionTitle extends StatelessWidget {
  final String title;
  final Color textPrimary;

  const SavingGoalsSectionTitle({
    super.key,
    required this.title,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// ============================================================
/// ACTIVE SAVING GOAL CARD
/// ============================================================

class SavingGoalCard extends StatelessWidget {
  final String title;
  final String progress;
  final String subtitle;

  final double percent;

  final Color color;
  final Color surface;
  final Color secondarySurface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const SavingGoalCard({
    super.key,
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.percent,
    required this.color,
    required this.surface,
    required this.secondarySurface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                SavingGoalProgressCircle(
                  percent: percent,
                  color: color,
                  secondarySurface: secondarySurface,
                  textPrimary: textPrimary,
                ),

                const SizedBox(width: 14),

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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        progress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(Icons.chevron_right_rounded, color: textMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// PROGRESS CIRCLE
/// ============================================================

class SavingGoalProgressCircle extends StatelessWidget {
  final double percent;

  final Color color;
  final Color secondarySurface;
  final Color textPrimary;

  const SavingGoalProgressCircle({
    super.key,
    required this.percent,
    required this.color,
    required this.secondarySurface,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final safePercent = percent.clamp(0.0, 1.0);

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: safePercent,
              strokeWidth: 5,
              backgroundColor: secondarySurface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),

          Text(
            '${(safePercent * 100).round()}%',
            style: TextStyle(
              color: textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// COMPLETED GOAL CARD
/// ============================================================

class CompletedGoalCard extends StatelessWidget {
  final String title;
  final String amount;

  final Color textPrimary;
  final Color textMuted;
  final Color surface;
  final Color border;

  const CompletedGoalCard({
    super.key,
    required this.title,
    required this.amount,
    required this.textPrimary,
    required this.textMuted,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Text(
              amount,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// NEW GOAL BUTTON
/// ============================================================

class NewGoalButton extends StatelessWidget {
  final String title;

  final Color primary;
  final Color textInverse;

  final VoidCallback onPressed;

  const NewGoalButton({
    super.key,
    required this.title,
    required this.primary,
    required this.textInverse,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,

        icon: Icon(Icons.add_rounded, color: textInverse, size: 22),

        label: Text(
          title,
          style: TextStyle(
            color: textInverse,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textInverse,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// BACK BUTTON
/// ============================================================

class SavingGoalsBackButton extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final Color borderColor;

  final VoidCallback onTap;

  const SavingGoalsBackButton({
    super.key,
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
