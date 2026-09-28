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

              // 2. Quiz Statistics Section (Completed Quizzes | Available Quizzes)
              Obx(() => QuizStatsCard(
                    completedCount: controller.quizHistory.length,
                    availableCount: controller.quizzes.length,
                    onCompletedTap: () => Get.toNamed(AppRoutes.leaderboard),
                    onAvailableTap: () => Get.toNamed(AppRoutes.quizCategories),
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
              child: Row(
                children: [
                  const Text('🎯 ', style: TextStyle(fontSize: 18)),
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
                ],
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
              // 1. Single Quiz (Goals Green)
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.singleQuiz'.tr,
                  description: 'quiz.playAloneSubtitle'.tr,
                  icon: const Soft3DSingleQuizIcon(size: 44),
                  badgeText: 'quiz.buildYourKnowledge'.tr,
                  badgeIcon: Icons.school_rounded,
                  badgeIconColor: const Color(0xFF047857),
                  watermark: const QuizLeafWatermark(),
                  gradientColors: const [
                    Color(0xFF55E59B),
                    Color(0xFF13AF6A),
                  ],
                  darkGradientColors: const [
                    Color(0xFF107347),
                    Color(0xFF094C2E),
                  ],
                  glowColor: const Color(0xFF13AF6A),
                  borderColor: Colors.white.withValues(alpha: 0.24),
                  darkBorderColor: Colors.white.withValues(alpha: 0.18),
                  onTap: () => Get.toNamed(AppRoutes.quizCategories),
                ),
              ),
              const SizedBox(width: 12),

              // 2. 1v1 Multiplayer Quiz (Habits Orange)
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.multiplayer1v1'.tr,
                  description: 'quiz.multiplayer1v1Subtitle'.tr,
                  icon: const Soft3DMultiplayerIcon(size: 44),
                  badgeText: 'quiz.challengeFriendsTag'.tr,
                  badgeIcon: Icons.local_fire_department_rounded,
                  badgeIconColor: const Color(0xFFEA580C),
                  watermark: const QuizStarWatermark(),
                  gradientColors: const [
                    Color(0xFFFFA26B),
                    Color(0xFFF9683A),
                  ],
                  darkGradientColors: const [
                    Color(0xFFB44420),
                    Color(0xFF7A270D),
                  ],
                  glowColor: const Color(0xFFF9683A),
                  borderColor: Colors.white.withValues(alpha: 0.24),
                  darkBorderColor: Colors.white.withValues(alpha: 0.18),
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
              // 3. Short Content (Tasks Blue)
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.shortContentTitle'.tr,
                  description: 'quiz.shortContentSubtitle'.tr,
                  icon: const Soft3DShortContentIcon(size: 44),
                  badgeText: 'quiz.learnSomethingNew'.tr,
                  badgeIcon: Icons.lightbulb_rounded,
                  badgeIconColor: const Color(0xFFD97706),
                  watermark: const QuizWaveWatermark(),
                  gradientColors: const [
                    Color(0xFF5292F7),
                    Color(0xFF2563EB),
                  ],
                  darkGradientColors: const [
                    Color(0xFF1E40AF),
                    Color(0xFF172554),
                  ],
                  glowColor: const Color(0xFF2563EB),
                  borderColor: Colors.white.withValues(alpha: 0.24),
                  darkBorderColor: Colors.white.withValues(alpha: 0.18),
                  onTap: () => Get.toNamed(AppRoutes.shortContent),
                ),
              ),
              const SizedBox(width: 12),

              // 4. Learning Progress (Focus Purple)
              Expanded(
                child: QuizChallengeCard(
                  title: 'quiz.learningProgress'.tr,
                  description: 'quiz.learningProgressSubtitle'.tr,
                  icon: const Soft3DLearningProgressIcon(size: 44),
                  badgeText: 'quiz.seeYourGrowth'.tr,
                  badgeIcon: Icons.insights_rounded,
                  badgeIconColor: const Color(0xFF7C3AED),
                  watermark: const QuizBarChartWatermark(),
                  gradientColors: const [
                    Color(0xFFC084FC),
                    Color(0xFF7E3FF2),
                  ],
                  darkGradientColors: const [
                    Color(0xFF6B21A8),
                    Color(0xFF3B0764),
                  ],
                  glowColor: const Color(0xFF7E3FF2),
                  borderColor: Colors.white.withValues(alpha: 0.24),
                  darkBorderColor: Colors.white.withValues(alpha: 0.18),
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
                child: Row(
                  children: [
                    const Text('📁 ', style: TextStyle(fontSize: 18)),
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
                  ],
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
            height: 106,
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
                final accentColor = _colorForCategory(cat, index - 1);
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

    if (lowerId.contains('food') ||
        lowerName.contains('food') ||
        lowerName.contains('ម្ហូប') ||
        lowerName.contains('អាហារ')) {
      return Icons.restaurant_rounded;
    }
    if (lowerId.contains('environment') ||
        lowerName.contains('environment') ||
        lowerName.contains('បរិស្ថាន') ||
        lowerId.contains('nature') ||
        lowerName.contains('ធម្មជាតិ')) {
      return Icons.eco_rounded;
    }
    if (lowerId.contains('tech') ||
        lowerName.contains('tech') ||
        lowerName.contains('បច្ចេកវិទ្យា')) {
      return Icons.code_rounded;
    }
    if (lowerId.contains('business') || lowerName.contains('អាជីវកម្ម')) {
      return Icons.business_center_rounded;
    }
    if (lowerId.contains('finance') ||
        lowerName.contains('finance') ||
        lowerName.contains('ហិរញ្ញ')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (lowerId.contains('general') || lowerName.contains('ទូទៅ')) {
      return Icons.school_rounded;
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

    return switch (cat.icon) {
      'restaurant' => Icons.restaurant_rounded,
      'account_balance_wallet' => Icons.account_balance_wallet_rounded,
      'devices' => Icons.laptop_mac_rounded,
      'code' => Icons.code_rounded,
      'eco' => Icons.eco_rounded,
      'nature' => Icons.eco_rounded,
      'biotech' => Icons.science_rounded,
      'museum' => Icons.museum_rounded,
      'public' => Icons.public_rounded,
      'functions' => Icons.functions_rounded,
      'menu_book' => Icons.menu_book_rounded,
      _ => Icons.school_rounded,
    };
  }

  Color _colorForCategory(QuizCategory cat, int index) {
    final lowerId = cat.id.toLowerCase();
    final lowerName = cat.name.toLowerCase();

    if (lowerId.contains('general') || lowerName.contains('ទូទៅ')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (lowerId.contains('business') || lowerName.contains('អាជីវកម្ម')) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (lowerId.contains('food') ||
        lowerName.contains('food') ||
        lowerName.contains('ម្ហូប') ||
        lowerName.contains('អាហារ')) {
      return const Color(0xFFF43F5E); // Rose
    }
    if (lowerId.contains('environment') ||
        lowerName.contains('environment') ||
        lowerName.contains('បរិស្ថាន') ||
        lowerId.contains('nature') ||
        lowerName.contains('ធម្មជាតិ')) {
      return const Color(0xFF10B981); // Emerald Green
    }
    if (lowerId.contains('tech') || lowerName.contains('បច្ចេកវិទ្យា')) {
      return const Color(0xFF0284C7); // Sky Blue
    }
    if (lowerId.contains('finance') || lowerName.contains('ហិរញ្ញ')) {
      return const Color(0xFF10B981); // Emerald Green
    }
    if (lowerId.contains('science') || lowerName.contains('វិទ្យាសាស្ត្រ')) {
      return const Color(0xFF06B6D4); // Cyan
    }

    return switch (index % 5) {
      0 => const Color(0xFF8B5CF6),
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFFF43F5E),
      3 => const Color(0xFF10B981),
      _ => const Color(0xFF0284C7),
    };
  }
}
