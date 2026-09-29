import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../domain/entities/finance_entities.dart';

/// Reusable USD ↔ KHR segmented currency switch/toggle for GenLink Finance.
///
/// Features smooth animated sliding indicator, light/dark mode support,
/// and optional compact sizing for dense navigation headers.
class FinanceCurrencySelector extends StatelessWidget {
  const FinanceCurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
    this.compact = false,
  });

  final FinanceCurrency selectedCurrency;
  final ValueChanged<FinanceCurrency> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUsd = selectedCurrency == FinanceCurrency.usd;

    final selectedBg = isDark ? semantic.surfaceElevated : semantic.primary;
    final selectedText = isDark ? semantic.primaryText : semantic.textInverse;
    final unselectedText = semantic.secondaryText;

    final width = compact ? 112.0 : 154.0;
    final height = compact ? 32.0 : 38.0;
    final pillWidth = compact ? 52.0 : 73.0;
    final pillHeight = compact ? 26.0 : 32.0;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isUsd ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: pillWidth,
              height: pillHeight,
              decoration: BoxDecoration(
                color: selectedBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _CurrencyChoiceItem(
                  label: 'USD',
                  selected: isUsd,
                  selectedTextColor: selectedText,
                  unselectedTextColor: unselectedText,
                  compact: compact,
                  onTap: () => onChanged(FinanceCurrency.usd),
                ),
              ),
              Expanded(
                child: _CurrencyChoiceItem(
                  label: 'KHR',
                  selected: !isUsd,
                  selectedTextColor: selectedText,
                  unselectedTextColor: unselectedText,
                  compact: compact,
                  onTap: () => onChanged(FinanceCurrency.khr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyChoiceItem extends StatelessWidget {
  const _CurrencyChoiceItem({
    required this.label,
    required this.selected,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          color: selected ? selectedTextColor : unselectedTextColor,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        child: Text(label),
      ),
    ),
  );
}
