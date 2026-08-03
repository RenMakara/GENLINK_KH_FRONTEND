import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class InvestingQuizScreen extends StatefulWidget {
  const InvestingQuizScreen({super.key});

  @override
  State<InvestingQuizScreen> createState() => _InvestingQuizScreenState();
}

class _InvestingQuizScreenState extends State<InvestingQuizScreen> {
  int? selectedAnswer;

  final List<String> answers = [
    'Buying a single stock to maximize gains',
    'Spreading investments across asset classes',
    'Keeping all savings in a bank account',
    'Only investing in government bonds',
  ];

  final int correctAnswer = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────
              // HEADER
              // ─────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Quiz · Investing',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────
              // PROGRESS
              // ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Question 2 of 5',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+100 XP',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: 0.40,
                  minHeight: 6,
                  backgroundColor: surfaceSecondary,
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────
              // QUESTION CARD
              // ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUESTION 2',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'What is the best strategy for managing investment risks as a beginner?',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─────────────────────────────────────────
              // ANSWERS
              // ─────────────────────────────────────────
              ...List.generate(answers.length, (index) {
                final isSelected = selectedAnswer == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnswerOption(
                    text: answers[index],
                    selected: isSelected,
                    background: isSelected ? primary : surface,
                    borderColor: isSelected ? primary : border,
                    textPrimary: isSelected ? textInverse : textPrimary,
                    radioColor: isSelected
                        ? textInverse.withValues(alpha: 0.9)
                        : textMuted,
                    onTap: () {
                      setState(() {
                        selectedAnswer = index;
                      });
                    },
                  ),
                );
              }),

              const SizedBox(height: 16),

              // ─────────────────────────────────────────
              // NEXT BUTTON
              // ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedAnswer == null
                      ? null
                      : () {
                          _showResult(
                            context,
                            textPrimary,
                            textSecondary,
                            surface,
                            primary,
                            textInverse,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: surfaceSecondary,
                    foregroundColor: textInverse,
                    disabledForegroundColor: textMuted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Next →',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // RESULT DIALOG
  // ─────────────────────────────────────────────────────────

  void _showResult(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color surface,
    Color primary,
    Color textInverse,
  ) {
    final correct = selectedAnswer == correctAnswer;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            correct ? 'Correct! 🎉' : 'Not quite',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            correct
                ? 'Great job! Diversifying your investments helps reduce risk.'
                : 'The best answer is to spread investments across different asset classes.',
            style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Continue',
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANSWER OPTION
// ─────────────────────────────────────────────────────────────

class _AnswerOption extends StatelessWidget {
  final String text;
  final bool selected;
  final Color background;
  final Color borderColor;
  final Color textPrimary;
  final Color radioColor;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.text,
    required this.selected,
    required this.background,
    required this.borderColor,
    required this.textPrimary,
    required this.radioColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected
                      ? radioColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: radioColor,
                    width: selected ? 1.5 : 1.2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 14, color: textPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
