import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_feature_card.dart';

class QuizDashboardScreen extends GetView<QuizController> {
  const QuizDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              children: [
                AppBackButton(
                  onPressed: () {
                    if (Get.previousRoute.isNotEmpty) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quiz.title'.tr,
                        style: textTheme.headlineSmall?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'quiz.headerSubtitle'.tr,
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppHeaderActionButton(
                  icon: Icons.notifications_outlined,
                  tooltip: 'notification.title'.tr,
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserProgressCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildStatsRow(context),
            const SizedBox(height: AppSpacing.md),
            _buildQuizModesSection(context),
            const SizedBox(height: AppSpacing.lg),
            _buildCategoriesPreview(context),
            const SizedBox(height: AppSpacing.lg),
            _buildLeaderboardBanner(context),
            const SizedBox(height: AppSpacing.lg),
            _buildBottomAction(context),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'quiz.footerQuote'.tr,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: semantic.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// 1. User Profile & Learning Dashboard Card
  Widget _buildUserProgressCard(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final stats = controller.userStats.value;
      final xpRemaining =
          (stats.xpToNextLevel - stats.xp).clamp(0, stats.xpToNextLevel);

      return Container(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        decoration: BoxDecoration(
          color: isDark ? semantic.surface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? semantic.borderSubtle
                : semantic.borderSubtle.withValues(alpha: 0.8),
            width: 1.0,
          ),
          boxShadow: isDark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with clean border ring
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AppAvatar(
                      imageUrl: stats.avatarUrl,
                      name: stats.name,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Greeting and Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quiz.dashboardGreeting'.trParams({'name': stats.name}),
                        style: textTheme.titleMedium?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Level badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? semantic.surfaceElevated
                                  : const Color(0xFF1F2328),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'quiz.level'.trParams({'level': '${stats.level}'}),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          // Explorer status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(
                                alpha: isDark ? 0.20 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.success.withValues(
                                  alpha: isDark ? 0.35 : 0.25,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🌱 ',
                                  style: TextStyle(fontSize: 10.5),
                                ),
                                Text(
                                  'quiz.explorer'.tr,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF166534),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Achievement Shield Badge
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(
                        alpha: isDark ? 0.35 : 0.24,
                      ),
                      width: 1.2,
                    ),
                    boxShadow: isDark
                        ? const []
                        : [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stats.levelProgress,
                backgroundColor: isDark
                    ? semantic.surfaceElevated
                    : const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.success,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            // XP Metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${stats.xp} / ${stats.xpToNextLevel} XP',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.secondaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'quiz.xpToNextLevel'.trParams({'xp': '$xpRemaining'}),
                  style: textTheme.bodySmall?.copyWith(
                    color: semantic.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// 2. Compact Statistics Row (Completed | Available)
  Widget _buildStatsRow(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final completed = controller.quizHistory.length;
      final available = controller.quizzes.length;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? semantic.surface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? semantic.borderSubtle
                : semantic.borderSubtle.withValues(alpha: 0.8),
            width: 1.0,
          ),
          boxShadow: isDark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.task_alt_rounded,
                accentColor: AppColors.success,
                value: '$completed',
                label: 'quiz.completedQuizzes'.tr,
                semantic: semantic,
                isDark: isDark,
                textTheme: textTheme,
              ),
            ),
            Container(
              width: 1,
              height: 38,
              color: isDark
                  ? semantic.borderSubtle
                  : semantic.borderSubtle.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatItem(
                icon: Icons.library_books_rounded,
                accentColor: AppColors.brandPrimary,
                value: '$available',
                label: 'quiz.availableQuizzes'.tr,
                semantic: semantic,
                isDark: isDark,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color accentColor,
    required String value,
    required String label,
    required AppSemanticColors semantic,
    required bool isDark,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
              width: 0.8,
            ),
          ),
          child: Icon(icon, size: 22, color: accentColor),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: semantic.primaryText,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: semantic.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3. Quiz Modes Section (Single, Multiplayer, Short Content, Progress)
  Widget _buildQuizModesSection(BuildContext context) {
    return Obx(() {
      final completed = controller.quizHistory.length;
      final available = controller.quizzes.length;

      return Column(
        children: [
          QuizFeatureCard(
            title: 'quiz.singleQuiz'.tr,
            description: 'quiz.playAloneSubtitle'.tr,
            icon: Icons.person_rounded,
            accentColor: AppColors.success,
            onTap: () => Get.toNamed(AppRoutes.quizCategories),
          ),
          const SizedBox(height: 12),
          QuizFeatureCard(
            title: 'quiz.multiplayerQuiz'.tr,
            description: 'quiz.playAgainstOpponent'.tr,
            icon: Icons.people_alt_rounded,
            accentColor: AppColors.warning,
            onTap: () => Get.toNamed(AppRoutes.quizMultiplayer),
          ),
          const SizedBox(height: 12),
          QuizFeatureCard(
            title: 'shortContent.title'.tr,
            description: 'shortContent.subtitle'.tr,
            icon: Icons.smart_display_rounded,
            accentColor: AppColors.brandPrimary,
            onTap: () => Get.toNamed(AppRoutes.shortContent),
          ),
          const SizedBox(height: 12),
          QuizFeatureCard(
            title: 'quiz.learningProgress'.tr,
            description: 'quiz.completedAndAvailable'.trParams({
              'completed': '$completed',
              'available': '$available',
            }),
            icon: Icons.bar_chart_rounded,
            accentColor: AppColors.productivityAccent,
            onTap: () => Get.toNamed(AppRoutes.leaderboard),
          ),
        ],
      );
    });
  }

  /// 4. Categories Section with Horizontal Scroll & Active State
  Widget _buildCategoriesPreview(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

      if (controller.quizzes.isEmpty || controller.categories.isEmpty) {
        return QuizCustomCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            'quiz.noQuizzesAvailable'.tr,
            style: TextStyle(fontSize: 14, color: semantic.secondaryText),
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
              Text(
                'quiz.categories'.tr,
                style: textTheme.titleMedium?.copyWith(
                  color: semantic.primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
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
                        style: textTheme.labelLarge?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: semantic.primaryText,
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
                // First card is the "All" category option
                if (index == 0) {
                  final isAllSelected = selectedCat == null;
                  return _buildCategoryChip(
                    label: 'quiz.allCategories'.tr,
                    icon: Icons.star_rounded,
                    isSelected: isAllSelected,
                    accentColor: AppColors.productivityAccent,
                    semantic: semantic,
                    isDark: isDark,
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

                return _buildCategoryChip(
                  label: cat.name,
                  icon: icon,
                  isSelected: isSelected,
                  accentColor: accentColor,
                  semantic: semantic,
                  isDark: isDark,
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

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required AppSemanticColors semantic,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 90,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.22 : 0.10)
                  : (isDark ? semantic.surface : Colors.white),
              borderRadius: BorderRadius.circular(AppRadius.squircle),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isDark
                        ? semantic.borderSubtle
                        : semantic.borderSubtle.withValues(alpha: 0.8)),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isDark || !isSelected
                  ? const []
                  : [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: isDark ? 0.30 : 0.16)
                        : (isDark
                            ? semantic.surfaceElevated
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? accentColor : semantic.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? accentColor : semantic.primaryText,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _resolveCategoryIcon(QuizCategory cat) {
    final lowerId = cat.id.toLowerCase();
    final lowerName = cat.name.toLowerCase();

    if (lowerId.contains('finance') ||
        lowerName.contains('finance') ||
        lowerName.contains('ហិរញ្ញ')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lowerId.contains('tech') ||
        lowerName.contains('tech') ||
        lowerName.contains('បច្ចេកវិទ្យា')) {
      return Icons.devices_rounded;
    }
    if (lowerId.contains('health') ||
        lowerName.contains('health') ||
        lowerName.contains('សុខភាព')) {
      return Icons.favorite_border_rounded;
    }
    if (lowerId.contains('life') ||
        lowerName.contains('skill') ||
        lowerName.contains('ជំនាញ')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (lowerId.contains('science') || lowerName.contains('វិទ្យាសាស្ត្រ')) {
      return Icons.biotech_outlined;
    }
    if (lowerId.contains('business') || lowerName.contains('អាជីវកម្ម')) {
      return Icons.business_center_outlined;
    }

    return switch (cat.icon) {
      'account_balance_wallet' => Icons.account_balance_wallet_outlined,
      'devices' => Icons.devices_rounded,
      'biotech' => Icons.biotech_outlined,
      'museum' => Icons.museum_outlined,
      'public' => Icons.public_rounded,
      'functions' => Icons.functions_rounded,
      'menu_book' => Icons.menu_book_outlined,
      _ => Icons.school_outlined,
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

  /// 5. Promotional Leaderboard Banner
  Widget _buildLeaderboardBanner(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.leaderboard),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Color.alphaBlend(
                        AppColors.productivityAccent.withValues(alpha: 0.22),
                        semantic.surface,
                      ),
                      Color.alphaBlend(
                        AppColors.brandPrimary.withValues(alpha: 0.12),
                        semantic.surface,
                      ),
                    ]
                  : const [
                      Color(0xFFEDE9FE),
                      Color(0xFFF5F3FF),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.productivityAccent.withValues(
                alpha: isDark ? 0.35 : 0.22,
              ),
              width: 1.0,
            ),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: AppColors.productivityAccent.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.productivityAccent.withValues(
                          alpha: isDark ? 0.30 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 13,
                            color: AppColors.productivityAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'quiz.leaderboard'.tr,
                            style: const TextStyle(
                              color: AppColors.productivityAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'quiz.rankGlobally'.tr,
                      style: textTheme.titleMedium?.copyWith(
                        color: semantic.primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quiz.rankGloballySubtitle'.tr,
                      style: textTheme.bodySmall?.copyWith(
                        color: semantic.secondaryText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 3D Trophy Badge + Forward Action
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? semantic.surfaceElevated : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? semantic.borderSubtle
                            : semantic.borderSubtle.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: semantic.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 6. Primary CTA: Start New Quiz
  Widget _buildBottomAction(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? semantic.primaryText : const Color(0xFF18191B),
          foregroundColor: isDark ? semantic.background : Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: () => Get.toNamed(AppRoutes.quizCategories),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isDark ? semantic.background : Colors.white)
                    .withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 19,
                color: isDark ? semantic.background : Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'quiz.startNewQuiz'.tr,
              style: TextStyle(
                color: isDark ? semantic.background : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
