import 'package:flutter/material.dart';

/// ============================================================================
/// BUDGET MODEL
/// ============================================================================

class BudgetCategory {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  double amount;

  BudgetCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });
}

/// ============================================================================
/// MONTH SELECTOR
/// ============================================================================

class MonthSelector extends StatelessWidget {
  final String month;
  final Color background;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const MonthSelector({
    super.key,
    required this.month,
    required this.background,
    required this.textColor,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: iconColor, size: 19),

              const SizedBox(width: 10),

              Text(
                month,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: iconColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// BUDGET CATEGORY ROW
/// ============================================================================

class BudgetCategoryRow extends StatefulWidget {
  final BudgetCategory category;
  final double percentage;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color iconBackground;

  final ValueChanged<double> onChanged;
  final VoidCallback? onDelete;

  const BudgetCategoryRow({
    super.key,
    required this.category,
    required this.percentage,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconBackground,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<BudgetCategoryRow> createState() => _BudgetCategoryRowState();
}

class _BudgetCategoryRowState extends State<BudgetCategoryRow> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.category.amount.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant BudgetCategoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.category != widget.category) {
      final newValue = widget.category.amount.toStringAsFixed(0);

      if (controller.text != newValue) {
        controller.text = newValue;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ============================================================
              // ICON
              // ============================================================
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.category.icon,
                  size: 18,
                  color: widget.category.color,
                ),
              ),

              const SizedBox(width: 11),

              // ============================================================
              // TITLE
              // ============================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      widget.category.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // ============================================================
              // AMOUNT
              // ============================================================
              Container(
                width: 90,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: widget.iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Text(
                      '\$',
                      style: TextStyle(
                        color: widget.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.right,
                        textInputAction: TextInputAction.done,

                        // Same text color before/after clicking
                        style: TextStyle(
                          color: widget.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),

                        // Same cursor color
                        cursorColor: widget.textPrimary,

                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,

                          // No black background when focused
                          filled: false,

                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),

                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0;
                          widget.onChanged(amount);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ============================================================
              // DELETE
              // ============================================================
              if (widget.onDelete != null) ...[
                const SizedBox(width: 4),

                IconButton(
                  onPressed: widget.onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: widget.textMuted,
                    size: 19,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // ================================================================
          // PROGRESS
          // ================================================================
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: widget.percentage,
                    minHeight: 4,
                    backgroundColor: widget.iconBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.category.color,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                width: 35,
                child: Text(
                  '${(widget.percentage * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: widget.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
