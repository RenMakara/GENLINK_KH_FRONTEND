import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../../domain/models/quiz_models.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';

class ResultScreen extends GetView<QuizController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(() {
            final result = controller.quizResult.value;
            if (result == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: QuizColors.primary),
                    const SizedBox(height: 20),
                    Text(
                      'quiz.loadingResults'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        color: QuizColors.body,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                _buildTrophyBanner(),
                const SizedBox(height: 24),
                _buildScoreRing(result),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QuizColors.body,
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
          decoration: const BoxDecoration(
            color: QuizColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: QuizColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'quiz.answerBreakdown'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: QuizColors.heading,
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
            ? (isCorrect ? const Color(0x1510B981) : const Color(0x15EF4444))
            : const Color(0x15F59E0B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: wasAnswered
              ? (isCorrect ? const Color(0x3010B981) : const Color(0x30EF4444))
              : const Color(0x30F59E0B),
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
                            ? const Color(0x3010B981)
                            : const Color(0x30EF4444))
                      : const Color(0x30F59E0B),
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
                                ? QuizColors.correct
                                : QuizColors.incorrect)
                          : const Color(0xFFF59E0B),
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
                    ? (isCorrect ? QuizColors.correct : QuizColors.incorrect)
                    : const Color(0xFFF59E0B),
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
                      ? (isCorrect ? QuizColors.correct : QuizColors.incorrect)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: QuizColors.heading,
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
              bgColor = const Color(0x1510B981);
              textColor = QuizColors.correct;
              borderColor = const Color(0x3010B981);
            } else if (isSelected && !isCorrectOption) {
              bgColor = const Color(0x15EF4444);
              textColor = QuizColors.incorrect;
              borderColor = const Color(0x30EF4444);
            } else {
              bgColor = QuizColors.background;
              textColor = QuizColors.body;
              borderColor = QuizColors.border;
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
                          ? QuizColors.correct
                          : isSelected
                          ? QuizColors.incorrect
                          : Colors.transparent,
                      border: isCorrectOption || isSelected
                          ? null
                          : Border.all(color: QuizColors.border),
                    ),
                    child: Center(
                      child: Text(
                        optionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: (isCorrectOption || isSelected)
                              ? Colors.white
                              : QuizColors.body,
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
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: QuizColors.correct,
                    ),
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

  Widget _buildTrophyBanner() {
    return Obx(() {
      final result = controller.quizResult.value;
      final isHigh = result != null && _accuracy(result) >= 80;
      return Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isHigh
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                    : [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: isHigh
                      ? const Color(0x40FFC107)
                      : const Color(0x20000000),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isHigh ? 'quiz.excellentWork'.tr : 'quiz.quizComplete'.tr,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: QuizColors.heading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHigh ? 'quiz.youCrushedIt'.tr : 'quiz.keepPracticing'.tr,
            style: const TextStyle(fontSize: 14, color: QuizColors.body),
          ),
        ],
      );
    });
  }

  Widget _buildScoreRing(QuizResult result) {
    final correct = _correctCount(result);
    final total = _totalCount(result);
    final accuracy = _accuracy(result);
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
                value: accuracy / 100,
                strokeWidth: 12,
                backgroundColor: QuizColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  accuracy >= 80 ? QuizColors.correct : QuizColors.primary,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$accuracy%',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: QuizColors.heading,
                  ),
                ),
                Text(
                  'quiz.correctRatio'.trParams({
                    'correct': '$correct',
                    'total': '$total',
                  }),
                  style: const TextStyle(fontSize: 13, color: QuizColors.body),
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
          QuizColors.correct,
        ),
        _buildSummaryTile(
          Icons.cancel,
          'quiz.wrong'.tr,
          '$wrong',
          QuizColors.incorrect,
        ),
        _buildSummaryTile(
          Icons.timer_outlined,
          'quiz.timeTaken'.tr,
          'quiz.secondsShort'.trParams({
            'seconds': '${result.timeTakenSeconds}',
          }),
          const Color(0xFF6366F1),
        ),
        _buildSummaryTile(
          Icons.star,
          'quiz.xpEarned'.tr,
          '+${result.xpEarned}',
          QuizColors.primary,
        ),
        _buildSummaryTile(
          Icons.monetization_on,
          'quiz.coinsEarned'.tr,
          '+${result.coinsEarned}',
          QuizColors.gold,
        ),
        _buildSummaryTile(
          Icons.military_tech,
          'quiz.badges'.tr,
          '0',
          const Color(0xFFF59E0B),
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
          Icon(icon, color: color, size: 22),
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
            style: const TextStyle(fontSize: 11, color: QuizColors.body),
          ),
        ],
      ),
    );
  }
}
