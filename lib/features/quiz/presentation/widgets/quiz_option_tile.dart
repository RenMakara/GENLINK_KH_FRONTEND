import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../quiz_colors.dart';

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.index,
    required this.isSelected,
    this.isCorrect,
    this.onTap,
    this.showResult = false,
  });

  final String label;
  final int index;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback? onTap;
  final bool showResult;

  String get _optionLetter => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bgColor = scheme.surface;
    Color borderColor = scheme.outlineVariant;
    Color textColor = scheme.onSurface;
    Color radioColor = scheme.outlineVariant;
    Widget? suffixIcon;

    if (showResult && isCorrect != null) {
      if (isCorrect!) {
        bgColor = QuizThemeColors.correctSoft;
        borderColor = QuizThemeColors.correct;
        textColor = QuizThemeColors.correct;
        radioColor = QuizThemeColors.correct;
        suffixIcon = Icon(
          Icons.check_circle,
          color: QuizThemeColors.correct,
          size: 22,
        );
      } else if (isSelected) {
        bgColor = QuizThemeColors.incorrectSoft;
        borderColor = QuizThemeColors.incorrect;
        textColor = QuizThemeColors.incorrect;
        radioColor = QuizThemeColors.incorrect;
        suffixIcon = Icon(
          Icons.cancel,
          color: QuizThemeColors.incorrect,
          size: 22,
        );
      }
    } else if (isSelected) {
      bgColor = scheme.primary.withValues(alpha: 0.08);
      borderColor = scheme.primary;
      textColor = scheme.primary;
      radioColor = scheme.primary;
    }

    return GestureDetector(
      onTap: showResult ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor,
            width: isSelected || (showResult && isCorrect != null) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected && !showResult
                      ? scheme.primary
                      : radioColor,
                  width: 2,
                ),
                color: isSelected && !showResult
                    ? scheme.primary
                    : Colors.transparent,
              ),
              child: isSelected && !showResult
                  ? Center(
                      child: Icon(
                        Icons.circle,
                        size: 14,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Center(
                      child: Text(
                        _optionLetter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: radioColor,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm + 6),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            ?suffixIcon,
          ],
        ),
      ),
    );
  }
}
