import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/quiz_question_card.dart';

/// Redesigned Single Quiz screen adhering to modern iOS learning app UX.
/// Features a compact iOS header with close button, question counter,
/// and circular countdown timer; a thin horizontal progress bar;
/// a rounded question card; stacked answer options with clear states;
/// compact answer feedback; and a sticky bottom action bar ("មុន" & "បន្ទាប់").
class QuizInProgressScreen extends GetView<QuizController> {
  const QuizInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Scaffold(
      backgroundColor: semantic.background,
      body: Obx(() {
        if (controller.isQuizLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.success,
              strokeWidth: 3,
            ),
          );
        }

        if (controller.quizError.value != null) {
          return _buildErrorView(context);
        }

        if (controller.questions.isEmpty) {
          return _buildEmptyView(context);
        }

        final currentIndex = controller.currentQuestionIndex.value;
        final question = controller.questions[currentIndex];
        final selectedIndex = controller.selectedOptionIndexForQuestion(currentIndex);

        final categoryName = controller.selectedCategory.value?.name ??
            (controller.quizzes
                .firstWhereOrNull(
                  (q) => q.quizId == controller.currentQuizId.value,
                )
                ?.category ??
                'quiz.quizLabel'.tr);

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Header
              _buildTopHeader(context, categoryName: categoryName),

              // 2. Quiz Progress Indicator
              _buildQuizProgress(context),

              const SizedBox(height: 8),

              // Main Quiz Content (Question, Answers, Feedback)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // 3. Question Card
                      QuizQuestionCard(
                        question: question.question,
                        category: categoryName,
                      ),

                      const SizedBox(height: 20),

                      // 4. Answer Options
                      _buildOptionsList(question, selectedIndex),

                      // 5. Answer Feedback Card
                      _buildAnswerFeedback(
                        context,
                        question: question,
                        selectedIndex: selectedIndex,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 6. Bottom Sticky Action Area
              _buildBottomBar(context),
            ],
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. TOP HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopHeader(
    BuildContext context, {
    required String categoryName,
  }) {
    final semantic = context.semanticColors;
    final currentIndex = controller.currentQuestionIndex.value;
    final totalQuestions = controller.totalQuestions;
    final isKhmer = Get.locale?.languageCode == 'km';

    final progressLabel = isKhmer
        ? 'quiz.questionProgressKhmer'.trParams({
            'current': '${currentIndex + 1}',
            'total': '$totalQuestions',
          })
        : 'quiz.questionOfTotal'.trParams({
            'current': '${currentIndex + 1}',
            'total': '$totalQuestions',
          });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Left: Back/Close button
          Semantics(
            label: 'common.close'.tr,
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showQuitDialog(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: semantic.surface,
                    border: Border.all(color: semantic.borderSubtle),
                    boxShadow: semantic.cardShadow,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: semantic.primaryText,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Center/Left: "សំណួរ 1 ក្នុង 3" with optional small "Quiz" subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: semantic.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: semantic.primaryText,
                    fontFamilyFallback: const [
                      AppTypography.khmerFontFamily,
                      AppTypography.englishFontFamily,
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right: Compact circular countdown timer
          _buildTimer(context),
        ],
      ),
    );
  }

  // Compact circular countdown timer
  Widget _buildTimer(BuildContext context) {
    final semantic = context.semanticColors;

    return Obx(() {
      final time = controller.timeRemaining.value;
      final totalTime = controller.timePerQuestion;
      final fraction = totalTime > 0 ? (time / totalTime).clamp(0.0, 1.0) : 0.0;
      final isLow = time <= 5;
      final accentColor = isLow ? AppColors.danger : AppColors.success;

      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLow
              ? AppColors.danger.withValues(alpha: 0.10)
              : semantic.surface,
          border: Border.all(
            color: isLow
                ? AppColors.danger.withValues(alpha: 0.35)
                : semantic.borderSubtle,
          ),
          boxShadow: semantic.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 2.5,
                backgroundColor: isLow
                    ? AppColors.danger.withValues(alpha: 0.15)
                    : semantic.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            Text(
              '$time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isLow ? AppColors.danger : semantic.primaryText,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. QUIZ PROGRESS INDICATOR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuizProgress(BuildContext context) {
    final semantic = context.semanticColors;
    final currentIndex = controller.currentQuestionIndex.value;
    final totalQuestions = controller.totalQuestions;
    final progress =
        totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentIndex + 1} / $totalQuestions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: semantic.secondaryText,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: semantic.borderSubtle,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.success),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ANSWER OPTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOptionsList(QuizQuestion question, int? selectedIndex) {
    final isGradedImmediately = question.correctIndex != null;

    return Column(
      children: List.generate(question.options.length, (i) {
        final option = question.options[i];
        final isSelected = selectedIndex == i;

        final bool? isOptionCorrect;
        final bool showResult;

        if (isGradedImmediately && selectedIndex != null) {
          showResult = true;
          isOptionCorrect = i == question.correctIndex;
        } else {
          showResult = false;
          isOptionCorrect = null;
        }

        return QuizOptionTile(
          label: option.text,
          index: i,
          isSelected: isSelected,
          isCorrect: isOptionCorrect,
          showResult: showResult,
          onTap: () => controller.selectAnswer(question.id, option.id),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. ANSWER FEEDBACK CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAnswerFeedback(
    BuildContext context, {
    required QuizQuestion question,
    required int? selectedIndex,
  }) {
    if (selectedIndex == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGradedImmediately = question.correctIndex != null;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String? subtitle;

    if (isGradedImmediately) {
      final isCorrect = selectedIndex == question.correctIndex;
      if (isCorrect) {
        bgColor = isDark
            ? AppColors.success.withValues(alpha: 0.20)
            : AppColors.success.withValues(alpha: 0.08);
        borderColor = AppColors.success.withValues(alpha: 0.4);
        iconColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        title = 'quiz.correctFeedback'.tr;
        subtitle = null;
      } else {
        bgColor = isDark
            ? AppColors.danger.withValues(alpha: 0.20)
            : AppColors.danger.withValues(alpha: 0.08);
        borderColor = AppColors.danger.withValues(alpha: 0.4);
        iconColor = AppColors.danger;
        icon = Icons.cancel_rounded;
        title = 'quiz.incorrectFeedback'.tr;
        final correctOptionText = (question.correctIndex! >= 0 &&
                question.correctIndex! < question.options.length)
            ? question.options[question.correctIndex!].text
            : null;
        subtitle = correctOptionText != null
            ? '${'quiz.correct'.tr}: $correctOptionText'
            : null;
      }
    } else {
      // Standard quiz flow (answers graded upon final submission)
      bgColor = isDark
          ? AppColors.success.withValues(alpha: 0.14)
          : AppColors.success.withValues(alpha: 0.06);
      borderColor = AppColors.success.withValues(alpha: 0.3);
      iconColor = AppColors.success;
      icon = Icons.task_alt_rounded;
      title = 'quiz.answeredSelectedNote'.tr;
      subtitle = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    height: 1.3,
                    fontFamilyFallback: const [
                      AppTypography.khmerFontFamily,
                      AppTypography.englishFontFamily,
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. BOTTOM ACTION AREA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final semantic = context.semanticColors;
    final currentIndex = controller.currentQuestionIndex.value;
    final totalQuestions = controller.totalQuestions;
    final isLast = currentIndex == totalQuestions - 1;
    final canGoBack = currentIndex > 0;
    final isAnswered = controller.isQuestionAnswered(currentIndex);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: semantic.surface,
        border: Border(
          top: BorderSide(color: semantic.borderSubtle, width: 1),
        ),
        boxShadow: semantic.navigationShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // LEFT: "មុន" (Previous)
            Expanded(
              flex: 1,
              child: AppButton.secondary(
                label: 'quiz.previous'.tr,
                icon: Icons.arrow_back_rounded,
                height: 52,
                radius: AppRadius.pill,
                onPressed: canGoBack
                    ? () => controller.goToQuestion(currentIndex - 1)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // RIGHT: "បន្ទាប់" (Next / Review)
            Expanded(
              flex: 2,
              child: AppButton(
                label: isLast ? 'quiz.review'.tr : 'quiz.next'.tr,
                icon: isLast
                    ? Icons.assignment_turned_in_outlined
                    : Icons.arrow_forward_rounded,
                height: 52,
                radius: AppRadius.pill,
                onPressed: isAnswered
                    ? () {
                        if (isLast) {
                          controller.skipQuestion();
                        } else {
                          controller.nextQuestion();
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGS & FALLBACK VIEWS
  // ─────────────────────────────────────────────────────────────────────────

  void _showQuitDialog(BuildContext context) {
    final semantic = context.semanticColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: semantic.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.squircle),
        ),
        title: Text(
          'quiz.quitQuizTitle'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: semantic.primaryText,
          ),
        ),
        content: Text(
          'quiz.quitQuizMessage'.tr,
          style: TextStyle(
            fontSize: 14,
            color: semantic.secondaryText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr,
              style: TextStyle(
                color: semantic.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.until(
                (route) =>
                    route.settings.name == '/quiz/dashboard' ||
                    route.settings.name == '/home',
              );
              controller.resetQuiz();
            },
            child: Text(
              'quiz.quit'.tr,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final semantic = context.semanticColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'quiz.couldNotLoadQuiz'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: semantic.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'common.retry'.tr,
              height: 48,
              radius: AppRadius.pill,
              onPressed: () {
                final quizId = controller.currentQuizId.value;
                if (quizId != null) {
                  controller.startSelectedQuiz(quizId);
                } else {
                  controller.startQuiz();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final semantic = context.semanticColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 56,
              color: semantic.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'quiz.noQuestionsAvailable'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: semantic.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'quiz.pickAnotherCategory'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: semantic.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
