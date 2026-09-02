import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_gradient_button.dart';

class ReviewSubmitScreen extends GetView<QuizController> {
  const ReviewSubmitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: QuizColors.heading),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Review Answers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(
              () => Row(
                children: [
                  _buildStatusChip(
                    Icons.check_circle_outline,
                    '${controller.answeredCount} Answered',
                    QuizColors.correct,
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(
                    Icons.radio_button_unchecked,
                    '${controller.unansweredCount} Unanswered',
                    QuizColors.incorrect,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
            color: QuizColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QuizColors.border),
            boxShadow: QuizColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAnswered
                      ? const Color(0x2010B981)
                      : const Color(0x20EF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isAnswered
                          ? QuizColors.correct
                          : QuizColors.incorrect,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: QuizColors.heading,
                  ),
                ),
              ),
              Icon(
                isAnswered ? Icons.check_circle : Icons.cancel,
                color: isAnswered ? QuizColors.correct : QuizColors.incorrect,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: QuizColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    '$unanswered question${unanswered > 1 ? "s" : ""} unanswered',
                    style: const TextStyle(
                      fontSize: 13,
                      color: QuizColors.incorrect,
                    ),
                  ),
                ),
              QuizGradientButton(
                label: 'Submit Quiz',
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
