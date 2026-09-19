import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: QuizThemeColors.heading),
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
                return _buildQuestionRow(context, index);
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

  Widget _buildQuestionRow(BuildContext context, int index) {
    return Obx(() {
      final isAnswered = controller.isQuestionAnswered(index);
      return QuizCustomCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.sm + 6,
        ),
        onTap: () {
          controller.goToQuestion(index);
          Get.back();
        },
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAnswered
                    ? QuizThemeColors.correctSoft
                    : QuizThemeColors.incorrectSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isAnswered
                        ? QuizThemeColors.correct
                        : QuizThemeColors.incorrect,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 6),
            Expanded(
              child: Text(
                'quiz.questionNumber'.trParams({'number': '${index + 1}'}),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: QuizThemeColors.heading),
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
                    controller.submitError.value!,
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
      Get.offAndToNamed(AppRoutes.quizResult);
    }
  }
}
