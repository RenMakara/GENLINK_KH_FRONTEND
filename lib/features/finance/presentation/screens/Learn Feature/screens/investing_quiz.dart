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

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: textPrimary,
          ),
        ),

        title: Text(
          'Quiz · Investing',
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // PROGRESS
              // =================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Q2 of 5',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      '+100 XP',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: .40,
                  minHeight: 5,
                  backgroundColor: surfaceSecondary,
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // QUESTION CARD
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: border),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUESTION 2',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'What is the best strategy for managing '
                      'investment risks as a beginner?',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // ANSWERS
              // =================================================
              ...List.generate(answers.length, (index) {
                final isSelected = selectedAnswer == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),

                  child: _AnswerOption(
                    text: answers[index],
                    selected: isSelected,
                    background: isSelected ? primary : surface,
                    border: isSelected ? primary : border,
                    textPrimary: isSelected ? textInverse : textPrimary,
                    textMuted: isSelected
                        ? textInverse.withValues(alpha: .75)
                        : textMuted,
                    onTap: () {
                      setState(() {
                        selectedAnswer = index;
                      });
                    },
                  ),
                );
              }),

              const SizedBox(height: 10),

              // =================================================
              // NEXT
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 44,

                child: ElevatedButton(
                  onPressed: selectedAnswer == null
                      ? null
                      : () {
                          _showResult(
                            context,
                            isDark,
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  child: Text(
                    'Next →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // RESULT
  // ===========================================================

  void _showResult(
    BuildContext context,
    bool isDark,
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
                ? 'Great job! Diversifying your investments '
                      'helps reduce risk.'
                : 'The best answer is to spread investments '
                      'across different asset classes.',
            style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: Text(
                'Continue',
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
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

// =============================================================
// ANSWER OPTION
// =============================================================

class _AnswerOption extends StatelessWidget {
  final String text;
  final bool selected;

  final Color background;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  final VoidCallback onTap;

  const _AnswerOption({
    required this.text,
    required this.selected,
    required this.background,
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
        borderRadius: BorderRadius.circular(11),

        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),

          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: border),
          ),

          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,

                decoration: BoxDecoration(
                  color: selected
                      ? textMuted.withValues(alpha: .25)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? textMuted
                        : textMuted.withValues(alpha: .50),
                  ),
                ),

                child: selected
                    ? Icon(Icons.check_rounded, size: 11, color: textPrimary)
                    : null,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
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
