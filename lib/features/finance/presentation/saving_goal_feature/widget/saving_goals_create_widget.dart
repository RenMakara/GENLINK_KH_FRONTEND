import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

/// ============================================================
/// BACK BUTTON
/// ============================================================

class CreateGoalBackButton extends StatelessWidget {
  final Color background;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const CreateGoalBackButton({
    super.key,
    required this.background,
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
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor, width: 1),
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

/// ============================================================
/// SECTION LABEL
/// ============================================================

class CreateGoalSectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color textPrimary;
  final Color textMuted;

  const CreateGoalSectionLabel({
    super.key,
    required this.title,
    this.subtitle,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: TextStyle(color: textMuted, fontSize: 11)),
        ],
      ],
    );
  }
}

/// ============================================================
/// TITLE FIELD
/// ============================================================

class CreateGoalTitleField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final Color textColor;
  final Color hintColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color focusedColor;

  const CreateGoalTitleField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.textColor,
    required this.hintColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.focusedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor, fontSize: 14),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusedColor, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// TARGET AMOUNT
/// ============================================================

class CreateGoalAmountSection extends StatelessWidget {
  final String label;
  final String hintText;
  final String currencySymbol;

  final TextEditingController controller;

  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onChanged;

  const CreateGoalAmountSection({
    super.key,
    required this.label,
    required this.hintText,
    required this.currencySymbol,
    required this.controller,
    required this.textPrimary,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  currencySymbol,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: textMuted.withValues(alpha: 0.45),
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.financeAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// DATE SELECTOR
/// ============================================================

class CreateGoalDateSelector extends StatelessWidget {
  final String label;
  final String date;
  final bool selected;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const CreateGoalDateSelector({
    super.key,
    required this.label,
    required this.date,
    required this.selected,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: textMuted,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      date,
                      style: TextStyle(
                        color: selected ? textPrimary : textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// MONTHLY SAVING PLAN
/// ============================================================

class CreateGoalMonthlyPlan extends StatelessWidget {
  final String title;
  final String subtitle;
  final String monthlySaving;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  const CreateGoalMonthlyPlan({
    super.key,
    required this.title,
    required this.subtitle,
    required this.monthlySaving,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.financeAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppColors.financeAccent,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          Text(
            monthlySaving,
            style: const TextStyle(
              color: AppColors.financeAccent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// SAVING TIP
/// ============================================================

class CreateGoalSavingTip extends StatelessWidget {
  final String message;
  final Color textSecondary;

  const CreateGoalSavingTip({
    super.key,
    required this.message,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.financeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.financeAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: AppColors.financeAccent,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// CREATE BUTTON
/// ============================================================

class CreateGoalButton extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const CreateGoalButton({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
