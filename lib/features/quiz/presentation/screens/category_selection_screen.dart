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
    final categoryName = controller.selectedCategory.value?.name ?? '';
    List<Map<String, dynamic>> options;
    try {
      options = await controller.loadQuizOptions(categoryName);
    } catch (_) {
      options = const [];
    }

    if (options.isEmpty) {
      Get.snackbar(
        'No quizzes',
        'No quizzes found for $categoryName yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (options.length == 1) {
      controller.startSelectedQuiz(options.first['quizId'] as String);
      Get.toNamed('/quiz/in-progress');
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
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
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Choose a Quiz',
                  style: TextStyle(
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
                        (quiz['title'] as String?) ?? 'Quiz ${index + 1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: QuizColors.heading,
                        ),
                      ),
                      subtitle: Text(
                        (quiz['difficulty'] as String?) ?? '',
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
    controller.startSelectedQuiz(selected['quizId'] as String);
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
        title: const Text(
          'Choose Quiz Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: QuizColors.heading,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryGrid(),
            const SizedBox(height: 24),
            const Text(
              'Recently Played',
              style: TextStyle(
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
      ),
    );
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
                  '${cat.questionCount} Questions',
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
                      child: const Text(
                        'Continue',
                        style: TextStyle(
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
