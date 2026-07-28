import 'package:flutter/material.dart';

class PeriodButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Color textPrimary;
  final Color textMuted;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color borderColor;
  final Color backgroundColor;

  const PeriodButton({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.textPrimary,
    required this.textMuted,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: selected ? null : Border.all(color: borderColor, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? selectedTextColor : textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
