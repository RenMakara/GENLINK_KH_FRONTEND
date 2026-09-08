import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_gradient_button.dart';

class ReviewSubmitScreen extends GetView<QuizController> {
  const ReviewSubmitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: QuizThemeColors.heading),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'quiz.reviewAnswers'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: QuizThemeColors.heading,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Obx(
              () => Row(
                children: [
                  _buildStatusChip(
                    Icons.check_circle_outline,
                    'quiz.answeredCount'.trParams({
                      'count': '${controller.answeredCount}',
                    }),
                    QuizThemeColors.correct,
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(
                    Icons.radio_button_unchecked,
                    'quiz.unansweredCount'.trParams({
                      'count': '${controller.unansweredCount}',
                    }),
                    QuizThemeColors.incorrect,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: controller.totalQuestions,
              itemBuilder: (context, index) {
                return _buildQuestionRow(index);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionRow(int index) {
    return Obx(() {
      final isAnswered = controller.selectedAnswers.containsKey(index);
      return GestureDetector(
        onTap: () {
          controller.goToQuestion(index);
          Get.back();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: QuizThemeColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: QuizThemeColors.border),
            boxShadow: QuizThemeColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAnswered
                      ? QuizThemeColors.correctSoft
                      : QuizThemeColors.incorrectSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isAnswered
                          ? QuizThemeColors.correct
                          : QuizThemeColors.incorrect,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'quiz.questionNumber'.trParams({'number': '${index + 1}'}),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: QuizThemeColors.heading,
                  ),
                ),
              ),
              Icon(
                isAnswered ? Icons.check_circle : Icons.cancel,
                color: isAnswered
                    ? QuizThemeColors.correct
                    : QuizThemeColors.incorrect,
                size: 24,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBottomBar() {
    final controller = Get.find<QuizController>();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm + 4,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: QuizThemeColors.surface,
        boxShadow: [
          BoxShadow(
            color: QuizThemeColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final unanswered = controller.unansweredCount;
          final isSubmitting = controller.isSubmitting.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unanswered > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'quiz.unansweredWarning'.trParams({'count': '$unanswered'}),
                    style: TextStyle(
                      fontSize: 13,
                      color: QuizThemeColors.incorrect,
                    ),
                  ),
                ),
              if (controller.submitError.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'quiz.submissionFailed'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: QuizThemeColors.incorrect,
                    ),
                  ),
                ),
              QuizGradientButton(
                label: 'quiz.submitQuiz'.tr,
                icon: Icons.send_rounded,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () => _handleSubmit(controller),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _handleSubmit(QuizController controller) async {
    if (controller.isQuizSubmitted.value) return;
    await controller.submitQuiz();
    if (controller.quizResult.value != null) {
      Get.offAndToNamed('/quiz/result');
    }
  }
}
