import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_learning_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

/// Quiz screen backed by the lesson quiz and submit endpoints.
class InvestingQuizScreen extends StatefulWidget {
  const InvestingQuizScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<InvestingQuizScreen> createState() => _InvestingQuizScreenState();
}

class _InvestingQuizScreenState extends State<InvestingQuizScreen> {
  FinanceLearningController get controller =>
      Get.find<FinanceLearningController>();

  final Map<String, String> _selectedAnswers = <String, String>{};
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    controller.loadQuiz(widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: Text('finance.learning.quiz'.tr),
      ),
      body: Obx(() {
        final error = controller.quizErrorMessage.value;
        if (controller.isQuizLoading.value &&
            controller.quizQuestions.isEmpty) {
          return const AppLoader();
        }
        if (error != null && controller.quizQuestions.isEmpty) {
          return _QuizError(message: error, onRetry: _reload);
        }
        if (controller.quizQuestions.isEmpty) {
          return _QuizError(
            message: 'finance.learning.noQuiz'.tr,
            onRetry: _reload,
          );
        }
        final questions = controller.quizQuestions.toList(growable: false);
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              Text(
                'finance.learning.quizQuestions'.trParams({
                  'count': '${questions.length}',
                }),
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ...questions.asMap().entries.map(
                (entry) => _QuestionCard(
                  number: entry.key + 1,
                  question: entry.value,
                  selectedOption: _selectedAnswers[entry.value.questionId],
                  surface: surface,
                  border: border,
                  text: text,
                  muted: muted,
                  primary: primary,
                  onSelected: (option) => setState(() {
                    _selectedAnswers[entry.value.questionId] = option;
                    _validationMessage = null;
                  }),
                ),
              ),
              if (_validationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (controller.mutationErrorMessage.value != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.mutationErrorMessage.value!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              AppButton(
                label: 'finance.learning.quizSubmit'.tr,
                loading: controller.isQuizSubmitting.value,
                icon: Icons.send_rounded,
                onPressed: _submit,
              ),
              if (controller.quizResult.value != null) ...[
                const SizedBox(height: 18),
                _ResultCard(
                  result: controller.quizResult.value!,
                  surface: surface,
                  border: border,
                  text: text,
                  muted: muted,
                  primary: primary,
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Future<void> _reload() async {
    _selectedAnswers.clear();
    setState(() => _validationMessage = null);
    await controller.loadQuiz(widget.lessonId);
  }

  Future<void> _submit() async {
    final questions = controller.quizQuestions;
    if (questions.any(
      (question) => !_selectedAnswers.containsKey(question.questionId),
    )) {
      setState(() {
        _validationMessage = 'finance.learning.selectAllAnswers'.tr;
      });
      return;
    }
    final answers = questions
        .map(
          (question) => FinanceLearningQuizAnswerEntity(
            questionId: question.questionId,
            selectedOption: _selectedAnswers[question.questionId]!,
          ),
        )
        .toList(growable: false);
    await controller.submitQuiz(lessonId: widget.lessonId, answers: answers);
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.selectedOption,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onSelected,
  });

  final int number;
  final FinanceLearningQuizQuestionEntity question;
  final String? selectedOption;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            '${'finance.learning.question'.tr} $number',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: TextStyle(
              color: text,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...question.options.map((option) {
            final isSelected = selectedOption == option.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onSelected(option.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? primary : border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? primary : muted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${option.key}. ${option.text}',
                            style: TextStyle(color: text, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  final FinanceLearningQuizResultEntity result;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            result.passed
                ? 'finance.learning.quizPassed'.tr
                : 'finance.learning.quizNotPassed'.tr,
            style: TextStyle(
              color: result.passed ? primary : text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${'finance.learning.score'.tr}: ${result.score}% · '
            '${'finance.learning.correctAnswers'.tr}: '
            '${result.correctCount}/${result.totalQuestions}',
            style: TextStyle(color: text, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            '${'finance.learning.xpEarned'.tr}: ${result.xpEarned}',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          if (result.learningBudgetCredited != 0) ...[
            const SizedBox(height: 5),
            Text(
              '${'finance.learning.walletReward'.tr}: '
              '${FinanceMoneyFormatter.format(result.learningBudgetCredited, FinanceCurrency.usd)}',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
          if (result.results.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...result.results.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${item.correct ? '✓' : '✕'} ${item.explanation}'
                  '${!item.correct && item.correctOption != null ? ' '
                            '(${item.correctOption})' : ''}',
                  style: TextStyle(color: text, fontSize: 13, height: 1.35),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizError extends StatelessWidget {
  const _QuizError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
          ],
        ),
      ),
    );
  }
}
