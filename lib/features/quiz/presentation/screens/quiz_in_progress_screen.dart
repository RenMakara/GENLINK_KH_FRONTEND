import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_option_tile.dart';

class QuizInProgressScreen extends GetView<QuizController> {
  const QuizInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: QuizColors.heading),
          onPressed: () => _showQuitDialog(context),
        ),
      ),
      body: Obx(() {
        if (controller.questions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: QuizColors.border),
                  SizedBox(height: 16),
                  Text(
                    'No questions available right now.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: QuizColors.heading),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try picking another category or check back later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: QuizColors.body),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildQuestionCard(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quit Quiz?', style: TextStyle(color: QuizColors.heading)),
        content: const Text('Your progress will be lost.',
            style: TextStyle(color: QuizColors.body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.until((route) =>
                  route.settings.name == '/quiz/dashboard' ||
                  route.settings.name == '/home');
              controller.resetQuiz();
            },
            child: const Text('Quit', style: TextStyle(color: QuizColors.incorrect)),
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
              'Question ${controller.currentQuestionIndex.value + 1} of ${controller.totalQuestions}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: QuizColors.heading),
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
          color: isLow ? const Color(0x20EF4444) : QuizColors.primaryLight,
          border: Border.all(
            color: isLow ? QuizColors.incorrect : QuizColors.primary,
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
                  isLow ? QuizColors.incorrect : QuizColors.primary,
                ),
              ),
            ),
            Text(
              '${time}s',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isLow ? QuizColors.incorrect : QuizColors.primary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuestionCard() {
    return Obx(() {
      if (controller.questions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: QuizColors.primary),
          ),
        );
      }
      final question = controller.questions[controller.currentQuestionIndex.value];
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: QuizColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: QuizColors.border),
          boxShadow: QuizColors.cardShadow,
        ),
        child: Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
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
      final question = controller.questions[controller.currentQuestionIndex.value];
      final selected = controller.selectedAnswers[controller.currentQuestionIndex.value];

      return Column(
        children: List.generate(question.options.length, (i) {
          return QuizOptionTile(
            label: question.options[i].text,
            index: i,
            isSelected: selected == i,
            onTap: () => controller.selectAnswer(controller.currentQuestionIndex.value, i),
          );
        }),
      );
    });
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final isLast = controller.currentQuestionIndex.value == controller.totalQuestions - 1;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: QuizColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.skipQuestion(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuizColors.body,
                    side: const BorderSide(color: QuizColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Skip',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: QuizColors.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (isLast) {
                          Get.toNamed('/quiz/review');
                        } else {
                          controller.nextQuestion();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Review' : 'Next',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
