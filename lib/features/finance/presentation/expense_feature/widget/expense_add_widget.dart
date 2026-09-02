import 'package:flutter/material.dart';
import 'package:get/get.dart';

// CATEGORY MODEL
class ExpenseCategoryItem {
  final String name;
  final IconData? icon;
  final Color color;

  const ExpenseCategoryItem({
    required this.name,
    this.icon,
    required this.color,
  });
}

// PAYMENT MODEL
class ExpensePaymentItem {
  final String name;
  final IconData? icon;

  const ExpensePaymentItem({required this.name, this.icon});
}

// BACK BUTTON
class ExpenseBackButton extends StatelessWidget {
  final Color color;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const ExpenseBackButton({
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

// AMOUNT SECTION
class ExpenseAmountSection extends StatelessWidget {
  final TextEditingController controller;

  /// The API supports separate USD/KHR balances.  Keep the amount field's
  /// affordance aligned with the selected currency instead of always showing
  /// a dollar sign.  USD remains the default for existing callers.
  final String currencySymbol;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color primary;

  const ExpenseAmountSection({
    super.key,
    required this.controller,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'finance.expense.amount'.tr,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        Container(
          height: 72,
          width: double.infinity,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              // CURRENCY
              Container(
                width: 60,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                ),
                child: Center(
                  child: Text(
                    currencySymbol,
                    style: TextStyle(
                      color: primary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              Container(width: 1, height: 36, color: border),

              // AMOUNT INPUT
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  cursorColor: primary,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: textMuted.withValues(alpha: 0.45),
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),

                    filled: false,
                    fillColor: Colors.transparent,

                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,

                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // ICON
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Icon(
                  Icons.payments_outlined,
                  color: textMuted.withValues(alpha: 0.45),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// SECTION LABEL
class ExpenseSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  final Color textPrimary;
  final Color textMuted;

  const ExpenseSectionLabel({
    super.key,
    required this.title,
    required this.subtitle,
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
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// INPUT FIELD
class ExpenseInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final IconData prefixIcon;

  final int maxLines;

  const ExpenseInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.prefixIcon,
  }) : maxLines = 1;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: textPrimary,

      style: TextStyle(
        color: textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: TextStyle(
          color: textMuted.withValues(alpha: 0.65),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),

        prefixIcon: Icon(prefixIcon, color: textMuted, size: 19),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),

        filled: true,
        fillColor: surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
      ),
    );
  }
}

// CATEGORY SELECTOR
class ExpenseCategorySelector extends StatelessWidget {
  final List<ExpenseCategoryItem> categories;
  final int selectedCategory;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final ValueChanged<int> onChanged;

  const ExpenseCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        final bool selected = selectedCategory == index;

        return GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? item.color.withValues(alpha: 0.10) : surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? item.color : border,
                width: selected ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 17,
                    color: selected ? item.color : textMuted,
                  ),
                  const SizedBox(width: 6),
                ],

                Flexible(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? item.color : textPrimary,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

// DATE SELECTOR
class ExpenseDateSelector extends StatelessWidget {
  final String date;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const ExpenseDateSelector({
    super.key,
    required this.date,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: textMuted,
                  size: 18,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'finance.expense.expenseDate'.tr,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// PAYMENT SELECTOR
class ExpensePaymentSelector extends StatelessWidget {
  final List<ExpensePaymentItem> payments;
  final int selectedPayment;

  final Color surface;
  final Color border;
  final Color primary;
  final Color textPrimary;

  final ValueChanged<int> onChanged;

  const ExpensePaymentSelector({
    super.key,
    required this.payments,
    required this.selectedPayment,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textPrimary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: false,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(payments.length, (index) {
          final item = payments[index];
          final bool selected = selectedPayment == index;

          // Index 0 = Optional
          final bool isOptional = index == 0 && item.name == 'Optional';

          return Padding(
            padding: EdgeInsets.only(
              right: index < payments.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.10) : surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? primary : border,
                    width: selected ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isOptional) ...[
                      Icon(
                        item.icon,
                        size: 17,
                        color: selected ? primary : textPrimary,
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      item.name,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected ? primary : textPrimary,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
