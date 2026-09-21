import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gamified_components.dart';

/// Redesigned Quiz Home Dashboard Screen adhering to the
/// "Modern Gamified Soft 3D Card UI" design language.
class QuizDashboardScreen extends GetView<QuizController> {
  const QuizDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: const QuizGamifiedHeader(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile / XP Hero Card with 3D Trophy
              Obx(() => QuizXpHeroCard(stats: controller.userStats.value)),
              const SizedBox(height: 14),

              // 2. Quiz Statistics Card (Completed | Available)
              Obx(() => QuizStatsCard(
                    completedCount: controller.quizHistory.length,
                    availableCount: controller.quizzes.length,
                  )),
              const SizedBox(height: 20),

              // 3. Choose Your Challenge Section (2x2 Grid)
              _buildChallengeGridSection(context),
              const SizedBox(height: 22),

              // 4. Categories Section (Horizontally Scrollable)
              _buildCategoriesSection(context),
              const SizedBox(height: 20),

              // 5. Motivational Quiz CTA Card
              QuizMotivationCard(
                onTap: () => Get.toNamed(AppRoutes.quizCategories),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. "Choose Your Challenge" Section with 2x2 Grid
  Widget _buildChallengeGridSection(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'quiz.chooseYourChallenge'.tr,
                style: textTheme.titleMedium?.copyWith(
                  color: semantic.primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.quizCategories),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'quiz.seeAll'.tr,
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid using IntrinsicHeight Rows to adapt naturally to Khmer wrapping
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Single Quiz
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.singleQuiz'.tr,
                  description: 'quiz.playAloneSubtitle'.tr,
                  icon: const Soft3DSingleQuizIcon(size: 46),
                  gradientColors: const [
                    Color(0xFFECFDF5),
                    Color(0xFFD1FAE5),
                  ],
                  darkGradientColors: [
                    const Color(0xFF064E3B).withValues(alpha: 0.35),
                    const Color(0xFF022C22).withValues(alpha: 0.35),
                  ],
                  borderColor: const Color(0xFFA7F3D0),
                  darkBorderColor:
                      const Color(0xFF059669).withValues(alpha: 0.5),
                  onTap: () => Get.toNamed(AppRoutes.quizCategories),
                ),
              ),
              const SizedBox(width: 12),

              // 2. 1v1 Multiplayer Quiz
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.multiplayer1v1'.tr,
                  description: 'quiz.multiplayer1v1Subtitle'.tr,
                  icon: const Soft3DMultiplayerIcon(size: 46),
                  gradientColors: const [
                    Color(0xFFFFF7ED),
                    Color(0xFFFFEDD5),
                  ],
                  darkGradientColors: [
                    const Color(0xFF7C2D12).withValues(alpha: 0.35),
                    const Color(0xFF431407).withValues(alpha: 0.35),
                  ],
                  borderColor: const Color(0xFFFED7AA),
                  darkBorderColor:
                      const Color(0xFFEA580C).withValues(alpha: 0.5),
                  onTap: () => Get.toNamed(AppRoutes.quizMultiplayer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3. Short Content
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.shortContentTitle'.tr,
                  description: 'quiz.shortContentSubtitle'.tr,
                  icon: const Soft3DShortContentIcon(size: 46),
                  gradientColors: const [
                    Color(0xFFEFF6FF),
                    Color(0xFFDBEAFE),
                  ],
                  darkGradientColors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                    const Color(0xFF172554).withValues(alpha: 0.35),
                  ],
                  borderColor: const Color(0xFFBFDBFE),
                  darkBorderColor:
                      const Color(0xFF2563EB).withValues(alpha: 0.5),
                  onTap: () => Get.toNamed(AppRoutes.shortContent),
                ),
              ),
              const SizedBox(width: 12),

              // 4. Learning Progress
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.learningProgress'.tr,
                  description: 'quiz.learningProgressSubtitle'.tr,
                  icon: const Soft3DLearningProgressIcon(size: 46),
                  gradientColors: const [
                    Color(0xFFF5F3FF),
                    Color(0xFFEDE9FE),
                  ],
                  darkGradientColors: [
                    const Color(0xFF581C87).withValues(alpha: 0.35),
                    const Color(0xFF3B0764).withValues(alpha: 0.35),
                  ],
                  borderColor: const Color(0xFFDDD6FE),
                  darkBorderColor:
                      const Color(0xFF7C3AED).withValues(alpha: 0.5),
                  onTap: () => Get.toNamed(AppRoutes.leaderboard),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 4. Categories Section with Horizontal Scroll & Active State
  Widget _buildCategoriesSection(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      if (controller.isQuizListLoading.value && controller.quizzes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: semantic.primary),
          ),
        );
      }

      if (controller.quizListError.value != null &&
          controller.quizzes.isEmpty) {
        return QuizCustomCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.quizListError.value!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: semantic.primaryText,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => controller.loadQuizzes(),
                child: Text('common.retry'.tr),
              ),
            ],
          ),
        );
      }

      final categoriesList = controller.categories;
      final selectedCat = controller.selectedCategory.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'quiz.categories'.tr,
                  style: textTheme.titleMedium?.copyWith(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.quizCategories),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'quiz.seeAll'.tr,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: categoriesList.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                // First card is the "All Categories" option
                if (index == 0) {
                  final isAllSelected = selectedCat == null;
                  return QuizCategoryCard(
                    label: 'quiz.allCategories'.tr,
                    icon: Icons.star_rounded,
                    isSelected: isAllSelected,
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () {
                      controller.selectedCategory.value = null;
                      Get.toNamed(AppRoutes.quizCategories);
                    },
                  );
                }

                final cat = categoriesList[index - 1];
                final isSelected = selectedCat?.id == cat.id;
                final accentColor = _colorForCategory(cat.colorIndex);
                final icon = _resolveCategoryIcon(cat);

                return QuizCategoryCard(
                  label: cat.name,
                  icon: icon,
                  isSelected: isSelected,
                  accentColor: accentColor,
                  onTap: () {
                    controller.selectCategory(cat);
                    controller.startQuiz();
                    Get.toNamed(AppRoutes.quizInProgress);
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  IconData _resolveCategoryIcon(QuizCategory cat) {
    final lowerId = cat.id.toLowerCase();
    final lowerName = cat.name.toLowerCase();

    if (lowerId.contains('finance') ||
        lowerName.contains('finance') ||
        lowerName.contains('ហិរញ្ញ')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (lowerId.contains('tech') ||
        lowerName.contains('tech') ||
        lowerName.contains('បច្ចេកវិទ្យា')) {
      return Icons.laptop_mac_rounded;
    }
    if (lowerId.contains('health') ||
        lowerName.contains('health') ||
        lowerName.contains('សុខភាព') ||
        lowerId.contains('growth') ||
        lowerName.contains('growth') ||
        lowerName.contains('លូតលាស់')) {
      return Icons.spa_rounded;
    }
    if (lowerId.contains('science') || lowerName.contains('វិទ្យាសាស្ត្រ')) {
      return Icons.science_rounded;
    }
    if (lowerId.contains('business') || lowerName.contains('អាជីវកម្ម')) {
      return Icons.business_center_rounded;
    }

    return switch (cat.icon) {
      'account_balance_wallet' => Icons.account_balance_wallet_rounded,
      'devices' => Icons.laptop_mac_rounded,
      'biotech' => Icons.science_rounded,
      'museum' => Icons.museum_rounded,
      'public' => Icons.public_rounded,
      'functions' => Icons.functions_rounded,
      'menu_book' => Icons.menu_book_rounded,
      _ => Icons.school_rounded,
    };
  }

  Color _colorForCategory(int colorIndex) {
    return switch (colorIndex % 4) {
      0 => AppColors.brandPrimary,
      1 => AppColors.productivityAccent,
      2 => AppColors.success,
      _ => AppColors.warning,
    };
  }
}
