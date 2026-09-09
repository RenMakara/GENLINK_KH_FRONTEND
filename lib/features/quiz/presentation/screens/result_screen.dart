import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../../domain/models/quiz_models.dart';
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
                _buildTrophyBanner(context),
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
                  label: 'quiz.claimReward'.tr,
                  icon: Icons.card_giftcard,
                  onPressed: () {
                    Get.offAndToNamed('/quiz/claim-reward');
                  },
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    controller.resetQuiz();
                    Get.until(
                      (route) =>
                          route.settings.name == '/quiz/dashboard' ||
                          route.settings.name == '/home',
                    );
                  },
                  child: Text(
                    'quiz.backToDashboard'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QuizThemeColors.body,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showAnswerBreakdown(BuildContext context) {
    final questions = controller.questions;
    final selectedAnswers = controller.selectedAnswers;
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
                  itemBuilder: (_, i) => _buildAnswerReviewItem(
                    i,
                    questions[i],
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
    QuizQuestion q,
    Map<int, int> selectedAnswers,
    List<QuizQuestionResult> results,
  ) {
    final selectedIdx = selectedAnswers[index];
    final qResult = results.firstWhereOrNull((r) => r.questionId == q.id);

    final int? correctIndex = qResult != null
        ? q.options.indexWhere((o) => o.id == qResult.correctOptionId)
        : q.correctIndex;
    final selectedIndex = qResult != null
        ? q.options.indexWhere((o) => o.id == qResult.selectedOptionId)
        : selectedIdx;
    final isCorrect = qResult != null
        ? (selectedIndex ?? -1) >= 0 && selectedIndex == correctIndex
        : selectedIdx != null &&
              q.correctIndex != null &&
              selectedIdx == q.correctIndex;
    final wasAnswered = qResult != null
        ? (selectedIndex ?? -1) >= 0
        : selectedIdx != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: wasAnswered
            ? (isCorrect
                  ? QuizThemeColors.correctSoft
                  : QuizThemeColors.incorrectSoft)
            : QuizThemeColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: wasAnswered
              ? (isCorrect
                    ? QuizThemeColors.correct
                    : QuizThemeColors.incorrect)
              : QuizThemeColors.gold,
        ),
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
                  color: wasAnswered
                      ? (isCorrect
                            ? QuizThemeColors.correctSoft
                            : QuizThemeColors.incorrectSoft)
                      : QuizThemeColors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: wasAnswered
                          ? (isCorrect
                                ? QuizThemeColors.correct
                                : QuizThemeColors.incorrect)
                          : QuizThemeColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                wasAnswered
                    ? (isCorrect ? Icons.check_circle : Icons.cancel)
                    : Icons.help_outline,
                size: 18,
                color: wasAnswered
                    ? (isCorrect
                          ? QuizThemeColors.correct
                          : QuizThemeColors.incorrect)
                    : QuizThemeColors.gold,
              ),
              const Spacer(),
              Text(
                wasAnswered
                    ? (isCorrect ? 'quiz.correct'.tr : 'quiz.incorrect'.tr)
                    : 'quiz.skipped'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: wasAnswered
                      ? (isCorrect
                            ? QuizThemeColors.correct
                            : QuizThemeColors.incorrect)
                      : QuizThemeColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: QuizThemeColors.heading,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(q.options.length, (oi) {
            final optionLabel = String.fromCharCode(65 + oi);
            final isSelected = selectedIndex == oi;
            final isCorrectOption = correctIndex != null && correctIndex == oi;

            Color bgColor;
            Color textColor;
            Color borderColor;
            if (isCorrectOption) {
              bgColor = QuizThemeColors.correctSoft;
              textColor = QuizThemeColors.correct;
              borderColor = QuizThemeColors.correct;
            } else if (isSelected && !isCorrectOption) {
              bgColor = QuizThemeColors.incorrectSoft;
              textColor = QuizThemeColors.incorrect;
              borderColor = QuizThemeColors.incorrect;
            } else {
              bgColor = QuizThemeColors.background;
              textColor = QuizThemeColors.body;
              borderColor = QuizThemeColors.border;
            }

            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
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
                        optionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: (isCorrectOption || isSelected)
                              ? QuizThemeColors.onPrimary
                              : QuizThemeColors.body,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.options[oi].text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isCorrectOption)
                    Icon(Icons.check, size: 16, color: QuizThemeColors.correct),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int _correctCount(QuizResult result) {
    if (result.results.isNotEmpty) {
      return result.results.where((r) => r.correct).length;
    }
    return result.correct;
  }

  int _totalCount(QuizResult result) => result.total;

  int _accuracy(QuizResult result) {
    final total = _totalCount(result);
    if (total == 0) return 0;
    return (_correctCount(result) * 100 / total).round();
  }

  Widget _buildTrophyBanner(BuildContext context) {
    return Obx(() {
      final result = controller.quizResult.value;
      final isHigh = result != null && _accuracy(result) >= 80;
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
    });
  }

  Widget _buildScoreRing(BuildContext context, QuizResult result) {
    final correct = _correctCount(result);
    final total = _totalCount(result);
    final accuracy = _accuracy(result);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = accuracy >= 80
        ? QuizThemeColors.correct
        : QuizThemeColors.primary;
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(
                      alpha: scheme.brightness == Brightness.dark ? 0.16 : 0.08,
                    ),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              height: 160,
              child: CircularProgressIndicator(
                value: accuracy / 100,
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
                  '$accuracy%',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'quiz.correctRatio'.trParams({
                    'correct': '$correct',
                    'total': '$total',
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
    final correct = _correctCount(result);
    final total = _totalCount(result);
    final wrong = total - correct;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildSummaryTile(
          Icons.check_circle,
          'quiz.correct'.tr,
          '$correct',
          QuizThemeColors.correct,
        ),
        _buildSummaryTile(
          Icons.cancel,
          'quiz.wrong'.tr,
          '$wrong',
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
          Icons.star,
          'quiz.xpEarned'.tr,
          '+${result.xpEarned}',
          QuizThemeColors.primary,
        ),
        _buildSummaryTile(
          Icons.monetization_on,
          'quiz.coinsEarned'.tr,
          '+${result.coinsEarned}',
          QuizThemeColors.gold,
        ),
        _buildSummaryTile(
          Icons.military_tech,
          'quiz.badges'.tr,
          '0',
          QuizThemeColors.gold,
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
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QuizIconContainer(
            icon: icon,
            accentColor: color,
            size: 36,
            iconSize: 20,
            borderRadius: AppRadius.md,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: QuizThemeColors.body),
          ),
        ],
      ),
    );
  }
}
