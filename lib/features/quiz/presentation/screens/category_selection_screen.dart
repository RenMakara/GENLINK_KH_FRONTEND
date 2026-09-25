import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/quiz_category_widgets.dart';
import '../widgets/quiz_section_header.dart';

/// Redesigned Choose Quiz Category Screen adhering to the
/// "Modern Gamified Soft 3D Card UI" design language.
class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final QuizController controller = Get.find<QuizController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    if (!mounted) return;

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
      context: context,
      backgroundColor: context.semanticColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        final semantic = sheetContext.semanticColors;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: semantic.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'quiz.chooseQuiz'.tr,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    color: semantic.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (listContext, index) {
                    final quiz = options[index];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: semantic.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.quiz_rounded,
                          color: semantic.primary,
                          size: 20,
                        ),
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
                          color: semantic.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        _difficultyLabel(quiz.difficulty),
                        style: TextStyle(
                          fontSize: 12,
                          color: semantic.secondaryText,
                        ),
                      ),
                      onTap: () => Navigator.pop(sheetContext, quiz),
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

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppBackButton(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'quiz.chooseQuizCategory'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'quiz.categoryHeaderSubtitle'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: semantic.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const GraduationBooksIllustration(width: 72, height: 56),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isQuizListLoading.value && controller.quizzes.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: semantic.primary),
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

        final allCategories = controller.categories;
        var filteredCategories = _searchQuery.trim().isEmpty
            ? allCategories.toList()
            : allCategories
                .where((cat) => cat.name
                    .toLowerCase()
                    .contains(_searchQuery.trim().toLowerCase()))
                .toList();

        if (_selectedFilter == 'popular') {
          filteredCategories.sort((a, b) => b.questionCount.compareTo(a.questionCount));
        } else if (_selectedFilter == 'new') {
          filteredCategories = filteredCategories.reversed.toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Search Bar with Clear & Filter Sliders
              QuizCategorySearchBar(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                onClear: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
              const SizedBox(height: 14),

              // 2. Category Filter Chips Row ([All] [Popular] [New] [Favorites])
              QuizCategoryFilterChips(
                selectedFilter: _selectedFilter,
                onFilterSelected: (val) {
                  setState(() {
                    _selectedFilter = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 3. 2-Column Soft 3D Category Grid & Full-Width Finance Card
              _buildCategoryGrid(filteredCategories),
              const SizedBox(height: 24),

              // 4. Recently Played Section
              QuizSectionHeader(
                title: 'quiz.recentlyPlayed'.tr,
                actionLabel: controller.recentCategories.isNotEmpty
                    ? 'quiz.seeAll'.tr
                    : null,
                onAction: controller.recentCategories.isNotEmpty
                    ? () {}
                    : null,
              ),
              const SizedBox(height: 12),
              _buildRecentSection(),
              const SizedBox(height: 20),

              // 5. 1v1 Multiplayer Promotional Challenge Card
              const QuizMultiplayerChallengeCard(),
              const SizedBox(height: 28),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRetryState(String message, VoidCallback onRetry) {
    final semantic = context.semanticColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: semantic.borderSubtle),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: semantic.primaryText),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'common.retry'.tr,
                style: TextStyle(color: semantic.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<QuizCategory> categories) {
    final semantic = context.semanticColors;

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: semantic.backgroundSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 28,
                  color: semantic.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'quiz.noMatchingCategories'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: semantic.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'quiz.noMatchingCategoriesSubtitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: semantic.secondaryText,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedFilter = 'all';
                  });
                },
                child: Text(
                  'quiz.clearFilter'.tr,
                  style: TextStyle(
                    color: AppColors.productivityAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final financeIndex = categories.indexWhere(
      (c) =>
          c.id.toUpperCase().contains('FINANCE') ||
          c.name.toUpperCase().contains('FINANCE') ||
          c.name.contains('ហិរញ្ញ'),
    );
    final hasSpecialFinance = categories.length > 3 && financeIndex != -1;
    final gridCategories = hasSpecialFinance
        ? [
            for (int i = 0; i < categories.length; i++)
              if (i != financeIndex) categories[i]
          ]
        : categories;
    final financeCategory = hasSpecialFinance ? categories[financeIndex] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossAxisCount = isTablet ? 3 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;
        const targetHeight = 142.0;
        final childAspectRatio = itemWidth / targetHeight;

        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: gridCategories.length,
              itemBuilder: (context, index) {
                final cat = gridCategories[index];
                return QuizCategoryCard(
                  category: cat,
                  onTap: () {
                    controller.selectCategory(cat);
                    _navigateAfterCategory();
                  },
                );
              },
            ),
            if (financeCategory != null) ...[
              const SizedBox(height: spacing),
              QuizCategoryCard(
                category: financeCategory,
                isFullWidth: true,
                onTap: () {
                  controller.selectCategory(financeCategory);
                  _navigateAfterCategory();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRecentSection() {
    return Obx(() {
      if (controller.recentCategories.isEmpty) {
        return const QuizEmptyRecentlyPlayedCard();
      }

      return Column(
        children: controller.recentCategories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuizRecentlyPlayedCard(
              category: cat,
              onContinue: () {
                controller.selectCategory(cat);
                _navigateAfterCategory();
              },
            ),
          );
        }).toList(),
      );
    });
  }
}
