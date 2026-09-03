import 'package:flutter/material.dart';

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
    Color bgColor = QuizColors.surface;
    Color borderColor = QuizColors.border;
    Color textColor = QuizColors.heading;
    Color radioColor = QuizColors.border;
    Widget? suffixIcon;

    if (showResult && isCorrect != null) {
      if (isCorrect!) {
        bgColor = const Color(0xFFD1FAE5);
        borderColor = QuizColors.correct;
        textColor = const Color(0xFF065F46);
        radioColor = QuizColors.correct;
        suffixIcon = const Icon(
          Icons.check_circle,
          color: QuizColors.correct,
          size: 22,
        );
      } else if (isSelected) {
        bgColor = const Color(0xFFFEE2E2);
        borderColor = QuizColors.incorrect;
        textColor = const Color(0xFF991B1B);
        radioColor = QuizColors.incorrect;
        suffixIcon = const Icon(
          Icons.cancel,
          color: QuizColors.incorrect,
          size: 22,
        );
      }
    } else if (isSelected) {
      bgColor = QuizColors.primaryLight;
      borderColor = QuizColors.primary;
      textColor = QuizColors.primary;
      radioColor = QuizColors.primary;
    }

    return GestureDetector(
      onTap: showResult ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
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
                      ? QuizColors.primary
                      : radioColor,
                  width: 2,
                ),
                color: isSelected && !showResult
                    ? QuizColors.primary
                    : Colors.transparent,
              ),
              child: isSelected && !showResult
                  ? const Center(
                      child: Icon(Icons.circle, size: 14, color: Colors.white),
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
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
