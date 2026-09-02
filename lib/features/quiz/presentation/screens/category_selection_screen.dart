import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quiz_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';

class CategorySelectionScreen extends GetView<QuizController> {
  const CategorySelectionScreen({super.key});

  void _navigateAfterCategory() {
    if (controller.quizType.value == QuizType.single) {
      _chooseQuizAndStart();
    } else {
      controller.startMatchmaking();
      Get.toNamed('/quiz/matchmaking');
    }
  }

  Future<void> _chooseQuizAndStart() async {
    final category = controller.selectedCategory.value;
    final categoryName = category?.name ?? '';
    final categoryValue = category?.id ?? '';
    List<QuizSummary> options;
    try {
      options = await controller.loadQuizOptions(categoryValue);
    } catch (_) {
      options = const [];
    }

    if (options.isEmpty) {
      Get.snackbar(
<<<<<<< Updated upstream
        'No quizzes',
        'No quizzes found for $categoryName yet.',
=======
        'quiz.noQuizzes'.tr,
        'quiz.noQuizzesForCategory'.trParams({'category': categoryName}),
>>>>>>> Stashed changes
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (options.length == 1) {
      controller.startSelectedQuiz(options.first.quizId);
      Get.toNamed('/quiz/in-progress');
      return;
    }

    final selected = await showModalBottomSheet<QuizSummary>(
      context: Get.context!,
      backgroundColor: QuizColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  'quiz.chooseQuiz'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: QuizColors.heading,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final quiz = options[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.quiz_outlined,
                        color: QuizColors.primary,
                      ),
                      title: Text(
                        quiz.title.isEmpty
                            ? 'quiz.quizFallbackTitle'.trParams({
                                'number': '${index + 1}',
                              })
                            : quiz.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: QuizColors.heading,
                        ),
                      ),
                      subtitle: Text(
<<<<<<< Updated upstream
                        (quiz['difficulty'] as String?) ?? '',
=======
                        _difficultyLabel(quiz.difficulty),
>>>>>>> Stashed changes
                        style: const TextStyle(
                          fontSize: 12,
                          color: QuizColors.body,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, quiz),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    controller.startSelectedQuiz(selected.quizId);
    Get.toNamed('/quiz/in-progress');
  }

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
        title: Text(
          'quiz.chooseQuizCategory'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isQuizListLoading.value && controller.quizzes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: QuizColors.primary),
          );
        }

        if (controller.quizListError.value != null &&
            controller.quizzes.isEmpty) {
          return _buildRetryState(
            'quiz.couldNotLoadQuizzes'.tr,
            () => controller.loadQuizzes(),
          );
        }

        if (controller.quizzes.isEmpty) {
          return _buildRetryState(
            'quiz.noQuizzesAvailable'.tr,
            () => controller.loadQuizzes(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              Text(
                'quiz.recentlyPlayed'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: QuizColors.heading,
                ),
              ),
              const SizedBox(height: 12),
              _buildRecentList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRetryState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 48, color: QuizColors.border),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: QuizColors.heading,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return 'quiz.difficultyEasy'.tr;
      case 'MEDIUM':
        return 'quiz.difficultyMedium'.tr;
      case 'HARD':
        return 'quiz.difficultyHard'.tr;
      default:
        return difficulty;
    }
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.categories.length,
      itemBuilder: (context, index) {
        final cat = controller.categories[index];
        final bgColor = QuizColors.categoryColors[cat.colorIndex];
        final iconColor = QuizColors.categoryIconColors[cat.colorIndex];
        return GestureDetector(
          onTap: () {
            controller.selectCategory(cat);
            _navigateAfterCategory();
          },
          child: QuizCustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.category, color: iconColor, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: QuizColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
<<<<<<< Updated upstream
                  '${cat.questionCount} Questions',
=======
                  'quiz.questionsCount'.trParams({
                    'count': '${cat.questionCount}',
                  }),
>>>>>>> Stashed changes
                  style: const TextStyle(fontSize: 13, color: QuizColors.body),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentList() {
    return Obx(() {
      return Column(
        children: controller.recentCategories.map((cat) {
          final bgColor = QuizColors.categoryColors[cat.colorIndex];
          final iconColor = QuizColors.categoryIconColors[cat.colorIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuizCustomCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.star, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: QuizColors.heading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.65,
                            backgroundColor: QuizColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              QuizColors.primary,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      controller.selectCategory(cat);
                      _navigateAfterCategory();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: QuizColors.gradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'common.continue'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
