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
      controller.startQuiz();
      Get.toNamed('/quiz/in-progress');
    } else {
      controller.startMatchmaking();
      Get.toNamed('/quiz/matchmaking');
    }
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: QuizColors.body,
                  ),
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
                        Text(cat.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: QuizColors.heading)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.65,
                            backgroundColor: QuizColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(QuizColors.primary),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
