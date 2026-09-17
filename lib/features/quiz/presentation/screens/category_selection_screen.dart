import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../controllers/quiz_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_icon_container.dart';
import '../widgets/quiz_section_header.dart';

class CategorySelectionScreen extends GetView<QuizController> {
  const CategorySelectionScreen({super.key});

  void _navigateAfterCategory() {
    _chooseQuizAndStart();
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
        'quiz.noQuizzes'.tr,
        'quiz.noQuizzesForCategory'.trParams({'category': categoryName}),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (options.length == 1) {
      controller.startSelectedQuiz(options.first.quizId);
      Get.toNamed(AppRoutes.quizInProgress);
      return;
    }

    final selected = await showModalBottomSheet<QuizSummary>(
      context: Get.context!,
      backgroundColor: QuizThemeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                  color: QuizThemeColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'quiz.chooseQuiz'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: QuizThemeColors.heading,
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
                      leading: Icon(
                        Icons.quiz_outlined,
                        color: QuizThemeColors.primary,
                      ),
                      title: Text(
                        quiz.title.isEmpty
                            ? 'quiz.quizFallbackTitle'.trParams({
                                'number': '${index + 1}',
                              })
                            : quiz.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: QuizThemeColors.heading,
                        ),
                      ),
                      subtitle: Text(
                        _difficultyLabel(quiz.difficulty),
                        style: TextStyle(
                          fontSize: 12,
                          color: QuizThemeColors.body,
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
    Get.toNamed(AppRoutes.quizInProgress);
  }

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
          'quiz.chooseQuizCategory'.tr,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: QuizThemeColors.heading),
        ),
      ),
      body: Obx(() {
        if (controller.isQuizListLoading.value && controller.quizzes.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: QuizThemeColors.primary),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              QuizSectionHeader(title: 'quiz.recentlyPlayed'.tr),
              const SizedBox(height: AppSpacing.sm + 4),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: QuizThemeColors.border),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                Get.context!,
              ).textTheme.titleMedium?.copyWith(color: QuizThemeColors.heading),
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.categories.length,
      itemBuilder: (context, index) {
        final cat = controller.categories[index];
        final iconColor = QuizThemeColors.categoryIconColors[cat.colorIndex];
        return QuizCustomCard(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          onTap: () {
            controller.selectCategory(cat);
            _navigateAfterCategory();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QuizIconContainer(
                icon: Icons.category,
                accentColor: iconColor,
                size: 50,
                iconSize: 26,
                borderRadius: AppRadius.lg,
              ),
              const SizedBox(height: 14),
              Text(
                cat.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: QuizThemeColors.heading,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'quiz.questionsCount'.trParams({
                  'count': '${cat.questionCount}',
                }),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: QuizThemeColors.body),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentList() {
    return Obx(() {
      return Column(
        children: controller.recentCategories.map((cat) {
          final iconColor = QuizThemeColors.categoryIconColors[cat.colorIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuizCustomCard(
              padding: const EdgeInsets.all(AppSpacing.sm + 6),
              child: Row(
                children: [
                  QuizIconContainer(
                    icon: Icons.star,
                    accentColor: iconColor,
                    size: 44,
                    iconSize: 22,
                    borderRadius: AppRadius.md,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: Theme.of(Get.context!).textTheme.titleSmall
                              ?.copyWith(color: QuizThemeColors.heading),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'quiz.questionsCount'.trParams({
                            'count': '${cat.questionCount}',
                          }),
                          style: Theme.of(Get.context!).textTheme.bodySmall
                              ?.copyWith(color: QuizThemeColors.body),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: 'common.continue'.tr,
                    expanded: false,
                    height: 44,
                    radius: AppRadius.pill,
                    onPressed: () {
                      controller.selectCategory(cat);
                      _navigateAfterCategory();
                    },
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
