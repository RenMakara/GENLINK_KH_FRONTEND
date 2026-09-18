import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';
import '../widgets/quiz_icon_container.dart';
import '../widgets/quiz_section_header.dart';

class QuizDashboardScreen extends GetView<QuizController> {
  const QuizDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizThemeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Center(
            child: AppBackButton(
              onPressed: () {
                if (Get.previousRoute.isNotEmpty) {
                  Get.back();
                } else {
                  Get.offAllNamed(AppRoutes.home);
                }
              },
            ),
          ),
        ),
        leadingWidth: 74,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: QuizThemeColors.heading,
            ),
            onPressed: () => Get.toNamed(AppRoutes.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.md),
            _buildStatsRow(context),
            const SizedBox(height: AppSpacing.lg),
            _buildStartCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildMultiplayerCard(context),
            const SizedBox(height: AppSpacing.lg),
            _buildLearningProgress(context),
            const SizedBox(height: AppSpacing.lg),
            _buildCategoriesPreview(),
            const SizedBox(height: AppSpacing.lg),
            _buildLeaderboardCard(context),
            const SizedBox(height: AppSpacing.lg),
            _buildBottomAction(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final stats = controller.userStats.value;
      final textTheme = Theme.of(context).textTheme;
      return QuizCustomCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: QuizThemeColors.primary.withValues(alpha: 0.34),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: QuizThemeColors.primary.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AppAvatar(
                      imageUrl: stats.avatarUrl,
                      name: stats.name,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quiz.dashboardGreeting'.trParams({'name': stats.name}),
                        style: textTheme.titleLarge?.copyWith(
                          color: QuizThemeColors.heading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: QuizThemeColors.gradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'quiz.level'.trParams({'level': '${stats.level}'}),
                          style: textTheme.labelSmall?.copyWith(
                            color: QuizThemeColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.levelProgress,
                backgroundColor: QuizThemeColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  QuizThemeColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${stats.xp} / ${stats.xpToNextLevel} XP',
              style: textTheme.bodySmall?.copyWith(color: QuizThemeColors.body),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsRow(BuildContext context) {
    return Obx(() {
      final completed = controller.quizHistory.length;
      final available = controller.quizzes.length;
      final textTheme = Theme.of(context).textTheme;
      return QuizCustomCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildCount(
                icon: Icons.task_alt_rounded,
                value: '$completed',
                label: 'quiz.completedQuizzes'.tr,
                textTheme: textTheme,
              ),
            ),
            Container(width: 1, height: 36, color: QuizThemeColors.border),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCount(
                icon: Icons.library_books_outlined,
                value: '$available',
                label: 'quiz.availableQuizzes'.tr,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCount({
    required IconData icon,
    required String value,
    required String label,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        QuizIconContainer(
          icon: icon,
          accentColor: QuizThemeColors.primary,
          size: 38,
          iconSize: 21,
          borderRadius: AppRadius.md,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  color: QuizThemeColors.heading,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: QuizThemeColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartCard(BuildContext context) {
    return QuizCustomCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Get.toNamed(AppRoutes.quizCategories),
      child: Row(
        children: [
          QuizIconContainer(
            icon: Icons.person_outline,
            accentColor: QuizThemeColors.correct,
            size: 46,
            iconSize: 24,
            borderRadius: AppRadius.lg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz.singleQuiz'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: QuizThemeColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'quiz.playAlone'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: QuizThemeColors.body),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: QuizThemeColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProgress(BuildContext context) {
    return Obx(() {
      final completed = controller.quizHistory.length;
      final available = controller.quizzes.length;
      return QuizCustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            QuizIconContainer(
              icon: Icons.trending_up,
              accentColor: QuizThemeColors.correct,
              size: 46,
              iconSize: 24,
              borderRadius: AppRadius.lg,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'quiz.learningProgress'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: QuizThemeColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'quiz.completedAndAvailable'.trParams({
                      'completed': '$completed',
                      'available': '$available',
                    }),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuizThemeColors.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMultiplayerCard(BuildContext context) {
    return QuizCustomCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Get.toNamed(AppRoutes.quizMultiplayer),
      child: Row(
        children: [
          QuizIconContainer(
            icon: Icons.people_alt_outlined,
            accentColor: QuizThemeColors.gold,
            size: 46,
            iconSize: 24,
            borderRadius: AppRadius.lg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz.multiplayerQuiz'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: QuizThemeColors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'quiz.playAgainstOpponent'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuizThemeColors.body,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: QuizThemeColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesPreview() {
    return Obx(() {
      if (controller.isQuizListLoading.value && controller.quizzes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(color: QuizThemeColors.primary),
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
                    color: QuizThemeColors.heading,
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
            style: TextStyle(fontSize: 14, color: QuizThemeColors.body),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuizSectionHeader(
            title: 'quiz.categories'.tr,
            actionLabel: 'quiz.seeAll'.tr,
            onAction: () => Get.toNamed(AppRoutes.quizCategories),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = controller.categories[index];
                final iconColor =
                    QuizThemeColors.categoryIconColors[cat.colorIndex];
                return SizedBox(
                  width: 130,
                  child: QuizCustomCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(14),
                    onTap: () {
                      controller.selectCategory(cat);
                      controller.startQuiz();
                      Get.toNamed(AppRoutes.quizInProgress);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QuizIconContainer(
                          icon: Icons.star,
                          accentColor: iconColor,
                          size: 38,
                          iconSize: 20,
                          borderRadius: AppRadius.md,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: QuizThemeColors.heading,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return QuizCustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => Get.toNamed(AppRoutes.leaderboard),
      child: Row(
        children: [
          QuizIconContainer(
            icon: Icons.emoji_events,
            accentColor: QuizThemeColors.gold,
            size: 48,
            iconSize: 26,
            borderRadius: AppRadius.lg,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz.viewLeaderboard'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'quiz.rankGlobally'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          QuizIconContainer(
            icon: Icons.arrow_forward,
            accentColor: scheme.primary,
            size: 36,
            iconSize: 20,
            borderRadius: AppRadius.md,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return QuizGradientButton(
      label: 'quiz.startNewQuiz'.tr,
      icon: Icons.play_arrow_rounded,
      onPressed: () => Get.toNamed(AppRoutes.quizCategories),
    );
  }
}
