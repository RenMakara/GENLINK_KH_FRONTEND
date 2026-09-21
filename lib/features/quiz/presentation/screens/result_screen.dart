import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';
import '../widgets/quiz_icon_container.dart';

class ResultScreen extends GetView<QuizController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Obx(() {
            final result = controller.quizResult.value;
            if (result == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: QuizThemeColors.primary),
                    const SizedBox(height: 20),
                    Text(
                      'quiz.loadingResults'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        color: QuizThemeColors.body,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                _buildTrophyBanner(context, result),
                const SizedBox(height: AppSpacing.md),
                _buildScoreRing(context, result),
                const SizedBox(height: 28),
                _buildSummaryGrid(result),
                const SizedBox(height: 28),
                QuizGradientButton(
                  label: 'quiz.reviewAnswers'.tr,
                  icon: Icons.visibility_outlined,
                  isOutlined: true,
                  onPressed: () => _showAnswerBreakdown(context),
                ),
                const SizedBox(height: 14),
                QuizGradientButton(
                  label: 'quiz.backToDashboard'.tr,
                  icon: Icons.dashboard_outlined,
                  onPressed: _returnToDashboard,
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _returnToDashboard() {
    controller.resetQuiz();
    Get.offNamed(AppRoutes.quizDashboard);
  }

  void _showAnswerBreakdown(BuildContext context) {
    final questions = controller.questions.toList(growable: false);
    final selectedAnswers = Map<String, String>.from(
      controller.selectedAnswers,
    );
    final results =
        controller.quizResult.value?.results ?? const <QuizQuestionResult>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: QuizThemeColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: QuizThemeColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'quiz.answerBreakdown'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: QuizThemeColors.heading,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _buildAnswerReviewItem(
                    index,
                    questions[index],
                    selectedAnswers,
                    results,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerReviewItem(
    int index,
    QuizQuestion question,
    Map<String, String> selectedAnswers,
    List<QuizQuestionResult> results,
  ) {
    final qResult = results.firstWhereOrNull(
      (result) => result.questionId == question.id,
    );
    final selectedId = qResult?.selectedOptionId ?? selectedAnswers[question.id];
    final correctId = qResult?.correctOptionId;
    final selectedIndex = _optionIndex(question, selectedId);
    final correctIndex = _optionIndex(question, correctId);
    final wasAnswered = selectedId != null && selectedIndex != null;
    final isCorrect = qResult?.correct == true;

    final statusColor = !wasAnswered
        ? QuizThemeColors.gold
        : isCorrect
        ? QuizThemeColors.correct
        : QuizThemeColors.incorrect;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: !wasAnswered
            ? QuizThemeColors.warningSoft
            : isCorrect
            ? QuizThemeColors.correctSoft
            : QuizThemeColors.incorrectSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                !wasAnswered
                    ? Icons.help_outline
                    : isCorrect
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 18,
                color: statusColor,
              ),
              const Spacer(),
              Text(
                !wasAnswered
                    ? 'quiz.skipped'.tr
                    : isCorrect
                    ? 'quiz.correct'.tr
                    : 'quiz.incorrect'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(question.options.length, (optionIndex) {
            final option = question.options[optionIndex];
            final isSelected = selectedIndex == optionIndex;
            final isCorrectOption =
                correctIndex != null && correctIndex == optionIndex;
            final optionColor = isCorrectOption
                ? QuizThemeColors.correct
                : isSelected
                ? QuizThemeColors.incorrect
                : QuizThemeColors.body;

            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCorrectOption
                    ? QuizThemeColors.correctSoft
                    : isSelected
                    ? QuizThemeColors.incorrectSoft
                    : QuizThemeColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrectOption || isSelected
                      ? optionColor
                      : QuizThemeColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrectOption
                          ? QuizThemeColors.correct
                          : isSelected
                          ? QuizThemeColors.incorrect
                          : Colors.transparent,
                      border: isCorrectOption || isSelected
                          ? null
                          : Border.all(color: QuizThemeColors.border),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + optionIndex),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCorrectOption || isSelected
                              ? QuizThemeColors.onPrimary
                              : QuizThemeColors.body,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: optionColor,
                      ),
                    ),
                  ),
                  if (isCorrectOption)
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: QuizThemeColors.correct,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int? _optionIndex(QuizQuestion question, String? optionId) {
    if (optionId == null) return null;
    final index = question.options.indexWhere((option) => option.id == optionId);
    return index < 0 ? null : index;
  }

  Widget _buildTrophyBanner(BuildContext context, QuizResult result) {
    final isHigh = result.accuracyPercent >= 80;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trophyAccent = isHigh
        ? QuizThemeColors.gold
        : QuizThemeColors.medalSilver;
    return QuizCustomCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          QuizIconContainer(
            icon: Icons.emoji_events,
            accentColor: trophyAccent,
            size: 92,
            iconSize: 50,
            borderRadius: AppRadius.xl,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isHigh ? 'quiz.excellentWork'.tr : 'quiz.quizComplete'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHigh ? 'quiz.youCrushedIt'.tr : 'quiz.keepPracticing'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing(BuildContext context, QuizResult result) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = result.accuracyPercent >= 80
        ? QuizThemeColors.correct
        : QuizThemeColors.primary;
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: result.accuracyPercent.clamp(0, 100).toDouble() / 100,
                strokeWidth: 12,
                backgroundColor: scheme.outlineVariant.withValues(
                  alpha: scheme.brightness == Brightness.dark ? 0.72 : 0.58,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${result.accuracyPercent}%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'quiz.correctRatio'.trParams({
                    'correct': '${result.correct}',
                    'total': '${result.total}',
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(QuizResult result) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 126,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryTile(
          Icons.check_circle_rounded,
          'quiz.correct'.tr,
          '${result.correct}',
          QuizThemeColors.correct,
        ),
        _buildSummaryTile(
          Icons.cancel_rounded,
          'quiz.wrong'.tr,
          '${result.wrong}',
          QuizThemeColors.incorrect,
        ),
        _buildSummaryTile(
          Icons.timer_outlined,
          'quiz.timeTaken'.tr,
          'quiz.secondsShort'.trParams({
            'seconds': '${result.timeTakenSeconds}',
          }),
          QuizThemeColors.primary,
        ),
        _buildSummaryTile(
          Icons.star_rounded,
          'quiz.xpEarned'.tr,
          '+${result.xpEarned}',
          QuizThemeColors.primary,
        ),
      ],
    );
  }

  Widget _buildSummaryTile(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return QuizCustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          QuizIconContainer(
            icon: icon,
            accentColor: color,
            size: 34,
            iconSize: 18,
            borderRadius: AppRadius.md,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: QuizThemeColors.body,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
