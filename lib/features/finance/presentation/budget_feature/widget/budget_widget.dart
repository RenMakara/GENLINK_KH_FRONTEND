import 'package:flutter/material.dart';

/// ============================================================================
/// CATEGORY BUDGET ROW
/// ============================================================================

class CategoryBudgetRow extends StatelessWidget {
  final String title;
  final String amount;
  final String percent;
  final double progress;
  final Color color;
  final Color textPrimary;
  final Color textMuted;
  final Color secondarySurface;
  final VoidCallback onTap;

  const CategoryBudgetRow({
    super.key,
    required this.title,
    required this.amount,
    required this.percent,
    required this.progress,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
    required this.secondarySurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            children: [
              Row(
                children: [
                  // CATEGORY DOT
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // TITLE
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // AMOUNT
                  Text(
                    amount,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 7),

                  // PERCENT
                  Text(
                    percent,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(width: 1),

                  // ARROW
                  Icon(Icons.chevron_right_rounded, color: textMuted, size: 19),
                ],
              ),

              const SizedBox(height: 8),

              // PROGRESS
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: secondarySurface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// BUDGET PROGRESS RING
/// ============================================================================

class BudgetProgressRing extends StatelessWidget {
  final double progress;
  final int percentage;
  final Color color;
  final Color backgroundColor;
  final Color textPrimary;
  final Color textMuted;

  const BudgetProgressRing({
    super.key,
    required this.progress,
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // BACKGROUND RING
          SizedBox(
            width: 82,
            height: 82,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
            ),
          ),

          // PROGRESS
          SizedBox(
            width: 82,
            height: 82,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),

          // CENTER CONTENT
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 1),

              Text(
                'USED',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
