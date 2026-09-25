import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ExpenseSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color primary;

  const ExpenseSearchField({
    super.key,
    required this.hintText,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.search_rounded, color: textMuted, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.2),
        ),
      ),
    );
  }
}

class ExpenseFilterBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color inverseText;

  const ExpenseFilterBar({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onChanged,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.inverseText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: selected ? null : Border.all(color: border, width: 1),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: selected ? inverseText : textPrimary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ExpenseHeaderButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const ExpenseHeaderButton({
    super.key,
    required this.icon,
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
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}

class ExpenseDateHeader extends StatelessWidget {
  final String text;
  final Color color;

  const ExpenseDateHeader({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExpenseHistoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const ExpenseHistoryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.surface,
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
          borderRadius: BorderRadius.circular(15),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.financeAccent
                            : textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Icon(
                      Icons.chevron_right_rounded,
                      color: textMuted,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
