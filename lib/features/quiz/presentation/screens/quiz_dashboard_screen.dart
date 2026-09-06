import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/quiz_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';
import '../widgets/quiz_section_header.dart';
import '../../../../app/routes/app_routes.dart';

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
            onPressed: () {},
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
            _buildQuickPlayCards(),
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
        glass: true,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: AppAvatar(
                    imageUrl: stats.avatarUrl,
                    name: stats.name,
                    size: 52,
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
              style: textTheme.bodySmall?.copyWith(
                color: QuizThemeColors.body,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsRow(BuildContext context) {
    return Obx(() {
      final stats = controller.userStats.value;
      final textTheme = Theme.of(context).textTheme;
      return QuizCustomCard(
        glass: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: QuizThemeColors.gold,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.streak == null
                            ? '-'
                            : 'quiz.days'.trParams({
                                'count': '${stats.streak}',
                              }),
                        style: textTheme.titleMedium?.copyWith(
                          color: stats.streak == null
                              ? QuizThemeColors.disabled
                              : QuizThemeColors.heading,
                        ),
                      ),
                      Text(
                        'quiz.activeStreak'.tr,
                        style: textTheme.labelSmall?.copyWith(
                          color: QuizThemeColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 36, color: QuizThemeColors.border),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: QuizThemeColors.gold,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stats.coins ?? '-'}',
                        style: textTheme.titleMedium?.copyWith(
                          color: stats.coins == null
                              ? QuizThemeColors.disabled
                              : QuizThemeColors.heading,
                        ),
                      ),
                      Text(
                        'quiz.coins'.tr,
                        style: textTheme.labelSmall?.copyWith(
                          color: QuizThemeColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickPlayCards() {
    return Row(
      children: [
        Expanded(
          child: _buildQuizTypeCard(
            Icons.person_outline,
            'quiz.singleQuiz'.tr,
            'quiz.playAlone'.tr,
            QuizThemeColors.correct,
            QuizType.single,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuizTypeCard(
            Icons.group_outlined,
            'quiz.randomQuiz'.tr,
            'quiz.findOpponent'.tr,
            QuizThemeColors.primary,
            QuizType.random,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizTypeCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    QuizType type,
  ) {
    return GestureDetector(
      onTap: () {
        controller.setQuizType(type);
        Get.toNamed('/quiz/categories');
      },
      child: QuizCustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: QuizThemeColors.heading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: QuizThemeColors.body),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningProgress(BuildContext context) {
    return QuizCustomCard(
      glass: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: QuizThemeColors.correctSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.trending_up,
              color: QuizThemeColors.correct,
              size: 24,
            ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    backgroundColor: QuizThemeColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      QuizThemeColors.correct,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'quiz.percentComplete'.trParams({'percent': '72'}),
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
  }

  Widget _buildCategoriesPreview() {
    return Obx(() {
      if (controller.isQuizListLoading.value && controller.quizzes.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
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
                  'quiz.couldNotLoadQuizzes'.tr,
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

      if (controller.quizzes.isEmpty) {
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
            onAction: () => Get.toNamed('/quiz/categories'),
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
                final bgColor = QuizThemeColors.categoryColors[cat.colorIndex];
                final iconColor =
                    QuizThemeColors.categoryIconColors[cat.colorIndex];
                return SizedBox(
                  width: 130,
                  child: QuizCustomCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(14),
                    onTap: () {
                      controller.selectCategory(cat);
                      if (controller.quizType.value == QuizType.single) {
                        controller.startQuiz();
                        Get.toNamed('/quiz/in-progress');
                      } else {
                        controller.startMatchmaking();
                        Get.toNamed('/quiz/matchmaking');
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.star, color: iconColor, size: 20),
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
      glass: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => Get.toNamed(AppRoutes.leaderboard),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: QuizThemeColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.emoji_events,
                color: QuizThemeColors.gold,
                size: 26,
              ),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: scheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildBottomAction() {
    return QuizGradientButton(
      label: 'quiz.startNewQuiz'.tr,
      icon: Icons.play_arrow_rounded,
      onPressed: () => Get.toNamed('/quiz/categories'),
    );
  }
}
