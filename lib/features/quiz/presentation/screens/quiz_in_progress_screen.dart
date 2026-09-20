import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_option_tile.dart';
import '../widgets/quiz_custom_card.dart';

class QuizInProgressScreen extends GetView<QuizController> {
  const QuizInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: QuizThemeColors.heading),
          onPressed: () => _showQuitDialog(context),
        ),
      ),
      body: Obx(() {
        if (controller.isQuizLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: QuizThemeColors.primary),
          );
        }

        if (controller.quizError.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: QuizThemeColors.incorrect,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'quiz.couldNotLoadQuiz'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: QuizThemeColors.heading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      final quizId = controller.currentQuizId.value;
                      if (quizId != null) {
                        controller.startSelectedQuiz(quizId);
                      } else {
                        controller.startQuiz();
                      }
                    },
                    child: Text('common.retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.questions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: QuizThemeColors.border),
                  const SizedBox(height: 16),
                  Text(
                    'quiz.noQuestionsAvailable'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: QuizThemeColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'quiz.pickAnotherCategory'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: QuizThemeColors.body),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    _buildQuestionCard(context),
                    const SizedBox(height: 20),
                    _buildOptionsList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        );
      }),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.squircle),
        ),
        title: Text(
          'quiz.quitQuizTitle'.tr,
          style: TextStyle(color: QuizThemeColors.heading),
        ),
        content: Text(
          'quiz.quitQuizMessage'.tr,
          style: TextStyle(color: QuizThemeColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr),
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
              style: TextStyle(color: QuizThemeColors.incorrect),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              'quiz.questionOfTotal'.trParams({
                'current': '${controller.currentQuestionIndex.value + 1}',
                'total': '${controller.totalQuestions}',
              }),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: QuizThemeColors.heading,
              ),
            ),
            const Spacer(),
            _buildTimer(),
          ],
        ),
      );
    });
  }

  Widget _buildTimer() {
    return Obx(() {
      final time = controller.timeRemaining.value;
      final fraction = time / controller.timePerQuestion;
      final isLow = time <= 5;

      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLow
              ? QuizThemeColors.incorrectSoft
              : QuizThemeColors.primaryLight,
          border: Border.all(
            color: isLow ? QuizThemeColors.incorrect : QuizThemeColors.primary,
            width: 3,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLow ? QuizThemeColors.incorrect : QuizThemeColors.primary,
                ),
              ),
            ),
            Text(
              'quiz.secondsShort'.trParams({'seconds': '$time'}),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isLow
                    ? QuizThemeColors.incorrect
                    : QuizThemeColors.primary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuestionCard(BuildContext context) {
    return Obx(() {
      if (controller.questions.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: QuizThemeColors.primary),
          ),
        );
      }
      final question =
          controller.questions[controller.currentQuestionIndex.value];
      return QuizCustomCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          question.question,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: QuizThemeColors.heading,
            height: 1.4,
          ),
        ),
      );
    });
  }

  Widget _buildOptionsList() {
    return Obx(() {
      if (controller.questions.isEmpty) {
        return const SizedBox.shrink();
      }
      final question =
          controller.questions[controller.currentQuestionIndex.value];
      final selected = controller.selectedOptionIndexForQuestion(
        controller.currentQuestionIndex.value,
      );

      return Column(
        children: List.generate(question.options.length, (i) {
          return QuizOptionTile(
            label: question.options[i].text,
            index: i,
            isSelected: selected == i,
            onTap: () =>
                controller.selectAnswer(question.id, question.options[i].id),
          );
        }),
      );
    });
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final isLast =
          controller.currentQuestionIndex.value ==
          controller.totalQuestions - 1;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'common.skip'.tr,
                  height: 52,
                  radius: AppRadius.pill,
                  onPressed: () => controller.skipQuestion(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: isLast ? 'quiz.review'.tr : 'common.next'.tr,
                  icon: isLast ? null : Icons.arrow_forward,
                  height: 52,
                  radius: AppRadius.pill,
                  onPressed: () {
                    if (isLast) {
                      controller.skipQuestion();
                    } else {
                      controller.nextQuestion();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
