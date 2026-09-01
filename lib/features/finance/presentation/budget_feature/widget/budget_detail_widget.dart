import 'package:flutter/material.dart';

// ============================================================================
// BUDGET STAT CELL
// ============================================================================

class BudgetStatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textMuted;

  const BudgetStatCell({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

// ============================================================================
// BUDGET EXPENSE ROW
// ============================================================================

class BudgetExpenseRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;

  final Color surface;
  final Color secondarySurface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const BudgetExpenseRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: secondarySurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: textMuted),
                ),

                const SizedBox(width: 12),

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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  amount,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(width: 3),

                Icon(Icons.chevron_right_rounded, color: textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BUDGET DETAIL ROW
// ============================================================================

class BudgetDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  final Color textPrimary;
  final Color textMuted;
  final Color secondarySurface;

  const BudgetDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textMuted,
    required this.secondarySurface,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: textMuted),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textMuted, fontSize: 13),
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BUDGET QUICK AMOUNT
// ============================================================================

class BudgetQuickAmount extends StatelessWidget {
  final double amount;
  final TextEditingController controller;

  final Color secondarySurface;
  final Color textPrimary;
  final Color border;

  final VoidCallback onChanged;

  const BudgetQuickAmount({
    super.key,
    required this.amount,
    required this.controller,
    required this.secondarySurface,
    required this.textPrimary,
    required this.border,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          controller.text = amount.toStringAsFixed(0);

          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );

          onChanged();
        },
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: secondarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
