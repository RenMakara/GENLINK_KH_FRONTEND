import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../design_system/colors/app_colors.dart';
import '../../design_system/typography/app_typography.dart';
import '../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../features/community/presentation/screens/create_discussion_screen.dart';
import '../../features/community/presentation/screens/create_event_screen.dart';
import '../../features/community/presentation/screens/create_post_screen.dart';
import '../../features/community/presentation/widgets/story_creation_picker_sheet.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart'
    as finance_goal;
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart'
    as productivity_goal;
import '../../features/community/presentation/screens/create_opportunity_screen.dart';
import '../../features/productivity/presentation/screens/create_habit_screen.dart';
import '../../features/productivity/presentation/screens/create_task_screen.dart';

class GlobalCreateSheet extends StatelessWidget {
  final bool fromPostComposer;
  final VoidCallback? onSelectMedia;
  final VoidCallback? onSelectPoll;
  final VoidCallback? onSelectCelebration;
  final VoidCallback? onSelectDiscussion;
  final VoidCallback? onSelectJob;
  final VoidCallback? onSelectDocument;
  final VoidCallback? onSelectEvent;

  const GlobalCreateSheet({
    super.key,
    this.fromPostComposer = false,
    this.onSelectMedia,
    this.onSelectPoll,
    this.onSelectCelebration,
    this.onSelectDiscussion,
    this.onSelectJob,
    this.onSelectDocument,
    this.onSelectEvent,
  });

  static const List<String> _fontFallbacks = [
    AppTypography.khmerFontFamily,
    AppTypography.englishFontFamily,
  ];

  static Future<void> show(
    BuildContext context, {
    bool fromPostComposer = false,
    VoidCallback? onSelectMedia,
    VoidCallback? onSelectPoll,
    VoidCallback? onSelectCelebration,
    VoidCallback? onSelectDiscussion,
    VoidCallback? onSelectJob,
    VoidCallback? onSelectDocument,
    VoidCallback? onSelectEvent,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (_) => GlobalCreateSheet(
        fromPostComposer: fromPostComposer,
        onSelectMedia: onSelectMedia,
        onSelectPoll: onSelectPoll,
        onSelectCelebration: onSelectCelebration,
        onSelectDiscussion: onSelectDiscussion,
        onSelectJob: onSelectJob,
        onSelectDocument: onSelectDocument,
        onSelectEvent: onSelectEvent,
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen, {String? routeName}) {
    Navigator.of(context).pop();
    Get.to(
      () => screen,
      routeName: routeName,
      transition: Transition.cupertino,
    );
  }

  void _openPostCreator(BuildContext context) {
    Navigator.of(context).pop();
    final currentRoute = Get.currentRoute;
    final modalName = ModalRoute.of(context)?.settings.name;
    final isAlreadyInPostComposer =
        fromPostComposer ||
        currentRoute == '/CreatePostScreen' ||
        modalName == '/CreatePostScreen';

    if (!isAlreadyInPostComposer) {
      Get.to(
        () => const CreatePostScreen(),
        routeName: '/CreatePostScreen',
        transition: Transition.cupertino,
      );
    }
  }

  void _openStoryCreator(BuildContext context) {
    Navigator.of(context).pop();
    StoryCreationPickerSheet.show(context);
  }

  void _showChallengeDialog(
    BuildContext context,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color border,
    Color iconBg,
    Color iconBorder,
    bool isDark,
  ) {
    Navigator.of(context).pop();
    final dialogTitle =
        'create.actionChallenge'.tr.isNotEmpty &&
            'create.actionChallenge'.tr != 'create.actionChallenge'
        ? 'create.actionChallenge'.tr
        : 'Challenge';
    final dialogDesc =
        'create.dialogChallengeDesc'.tr.isNotEmpty &&
            'create.dialogChallengeDesc'.tr != 'create.dialogChallengeDesc'
        ? 'create.dialogChallengeDesc'.tr
        : 'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.';
    final doneText =
        'common.done'.tr.isNotEmpty && 'common.done'.tr != 'common.done'
        ? 'common.done'.tr
        : 'Done';

    GenLinkConfirmDialog.showSuccess(
      context: context,
      title: dialogTitle,
      message: dialogDesc,
      confirmLabel: doneText,
      icon: Icons.emoji_events_outlined,
    );
  }

  void _showShortContentDialog(
    BuildContext context,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color border,
    Color iconBg,
    Color iconBorder,
    bool isDark,
  ) async {
    Navigator.of(context).pop();
    final dialogTitle =
        'create.actionShortContent'.tr.isNotEmpty &&
            'create.actionShortContent'.tr != 'create.actionShortContent'
        ? 'create.actionShortContent'.tr
        : 'Short Content';
    final dialogDesc =
        'create.dialogShortContentDesc'.tr.isNotEmpty &&
            'create.dialogShortContentDesc'.tr !=
                'create.dialogShortContentDesc'
        ? 'create.dialogShortContentDesc'.tr
        : 'Create and share a short video directly to the GenLink Short Content feed.';
    final createShortContentText =
        'shortContent.create'.tr.isNotEmpty &&
            'shortContent.create'.tr != 'shortContent.create'
        ? 'shortContent.create'.tr
        : 'Create Short Content';
    final cancelText =
        'common.cancel'.tr.isNotEmpty && 'common.cancel'.tr != 'common.cancel'
        ? 'common.cancel'.tr
        : 'Cancel';

    final confirmed = await GenLinkConfirmDialog.showConfirm(
      context: context,
      title: dialogTitle,
      message: dialogDesc,
      cancelLabel: cancelText,
      confirmLabel: createShortContentText,
      icon: Icons.video_library_outlined,
    );

    if (confirmed == true) {
      Get.toNamed(AppRoutes.shortContentCreate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fromPostComposer) {
      return _buildPostComposerGlassMenu(context);
    }
    return _buildGlobalSheet(context);
  }

  Widget _buildGlobalSheet(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xF218191A) : const Color(0xF8FFFFFF);
    final dialogBg = colors.surface;
    final cardBg = isDark ? const Color(0xFF242526) : const Color(0xFFF7F8FA);
    final textPrimary = colors.primaryText;
    final textSecondary = colors.secondaryText;
    final border = colors.borderSubtle;
    final sheetBorder = isDark
        ? const Color(0x29FFFFFF)
        : const Color(0x1F000000);
    final iconBg = isDark ? const Color(0xFF2D2F33) : const Color(0xFFEEF0F3);
    final iconBorder = isDark
        ? const Color(0xFF383A3D)
        : const Color(0xFFE2E5E9);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight, maxWidth: 640),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: sheetBorder, width: 0.8),
                  left: BorderSide(color: sheetBorder, width: 0.8),
                  right: BorderSide(color: sheetBorder, width: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'create.title'.tr.isNotEmpty &&
                                          'create.title'.tr != 'create.title'
                                      ? 'create.title'.tr
                                      : 'Create',
                                  style: TextStyle(
                                    fontFamily: AppTypography.englishFontFamily,
                                    fontFamilyFallback: _fontFallbacks,
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'create.subtitle'.tr.isNotEmpty &&
                                          'create.subtitle'.tr !=
                                              'create.subtitle'
                                      ? 'create.subtitle'.tr
                                      : 'What would you like to create?',
                                  style: TextStyle(
                                    fontFamily: AppTypography.englishFontFamily,
                                    fontFamilyFallback: _fontFallbacks,
                                    color: textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.close_rounded,
                                  color: textSecondary,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: border, thickness: 0.8),

                    Flexible(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        children: [
                          _CategoryHeader(
                            title:
                                'create.categoryCommunity'.tr.isNotEmpty &&
                                    'create.categoryCommunity'.tr !=
                                        'create.categoryCommunity'
                                ? 'create.categoryCommunity'.tr.toUpperCase()
                                : 'COMMUNITY',
                            textColor: textSecondary,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _CommunityFeatureCard(
                                    icon: Icons.article_outlined,
                                    title:
                                        'create.actionPost'.tr.isNotEmpty &&
                                            'create.actionPost'.tr !=
                                                'create.actionPost'
                                        ? 'create.actionPost'.tr
                                        : 'Post',
                                    description:
                                        'create.actionPostDesc'.tr.isNotEmpty &&
                                            'create.actionPostDesc'.tr !=
                                                'create.actionPostDesc'
                                        ? 'create.actionPostDesc'.tr
                                        : 'Share an update with your network',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                    onTap: () => _openPostCreator(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _CommunityFeatureCard(
                                    icon: Icons.amp_stories_outlined,
                                    title:
                                        'create.actionStory'.tr.isNotEmpty &&
                                            'create.actionStory'.tr !=
                                                'create.actionStory'
                                        ? 'create.actionStory'.tr
                                        : 'Story',
                                    description:
                                        'create.actionStoryDesc'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionStoryDesc'.tr !=
                                                'create.actionStoryDesc'
                                        ? 'create.actionStoryDesc'.tr
                                        : 'Share photo or video to your story',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                    onTap: () => _openStoryCreator(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _CommunityFeatureCard(
                                    icon: Icons.event_outlined,
                                    title:
                                        'create.actionEvent'.tr.isNotEmpty &&
                                            'create.actionEvent'.tr !=
                                                'create.actionEvent'
                                        ? 'create.actionEvent'.tr
                                        : 'Event',
                                    description:
                                        'create.actionEventDesc'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionEventDesc'.tr !=
                                                'create.actionEventDesc'
                                        ? 'create.actionEventDesc'.tr
                                        : 'Host an event or community meetup',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const CreateEventScreen(),
                                      routeName: '/CreateEventScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _CommunityFeatureCard(
                                    icon: Icons.forum_outlined,
                                    title:
                                        'create.actionDiscussion'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionDiscussion'.tr !=
                                                'create.actionDiscussion'
                                        ? 'create.actionDiscussion'.tr
                                        : 'Discussion',
                                    description:
                                        'create.actionDiscussionDesc'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionDiscussionDesc'.tr !=
                                                'create.actionDiscussionDesc'
                                        ? 'create.actionDiscussionDesc'.tr
                                        : 'Start a topic in the forum',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const CreateDiscussionScreen(),
                                      routeName: '/CreateDiscussionScreen',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _CategoryHeader(
                            title:
                                'create.categoryProductivity'.tr.isNotEmpty &&
                                    'create.categoryProductivity'.tr !=
                                        'create.categoryProductivity'
                                ? 'create.categoryProductivity'.tr.toUpperCase()
                                : 'PRODUCTIVITY',
                            textColor: textSecondary,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.flag_outlined,
                                    title:
                                        'create.actionGoal'.tr.isNotEmpty &&
                                            'create.actionGoal'.tr !=
                                                'create.actionGoal'
                                        ? 'create.actionGoal'.tr
                                        : 'Goal',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const productivity_goal.CreateGoalScreen(),
                                      routeName: '/CreateGoalScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.check_circle_outline_rounded,
                                    title:
                                        'create.actionTodo'.tr.isNotEmpty &&
                                            'create.actionTodo'.tr !=
                                                'create.actionTodo'
                                        ? 'create.actionTodo'.tr
                                        : 'To-Do',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const CreateTaskScreen(),
                                      routeName: '/CreateTaskScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.local_fire_department_outlined,
                                    title:
                                        'create.actionHabit'.tr.isNotEmpty &&
                                            'create.actionHabit'.tr !=
                                                'create.actionHabit'
                                        ? 'create.actionHabit'.tr
                                        : 'Habit',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const CreateHabitScreen(),
                                      routeName: '/CreateHabitScreen',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _CategoryHeader(
                            title:
                                'create.categoryFinancial'.tr.isNotEmpty &&
                                    'create.categoryFinancial'.tr !=
                                        'create.categoryFinancial'
                                ? 'create.categoryFinancial'.tr.toUpperCase()
                                : 'FINANCIAL',
                            textColor: textSecondary,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.receipt_long_outlined,
                                    title:
                                        'create.actionExpense'.tr.isNotEmpty &&
                                            'create.actionExpense'.tr !=
                                                'create.actionExpense'
                                        ? 'create.actionExpense'.tr
                                        : 'Expense',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const AddExpenseScreen(),
                                      routeName: '/AddExpenseScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.savings_outlined,
                                    title:
                                        'create.actionSavingGoal'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionSavingGoal'.tr !=
                                                'create.actionSavingGoal'
                                        ? 'create.actionSavingGoal'.tr
                                        : 'Saving Goal',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const finance_goal.CreateGoalScreen(),
                                      routeName: '/CreateGoalScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.pie_chart_outline_rounded,
                                    title:
                                        'create.actionBudget'.tr.isNotEmpty &&
                                            'create.actionBudget'.tr !=
                                                'create.actionBudget'
                                        ? 'create.actionBudget'.tr
                                        : 'Budget',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const SetBudgetScreen(),
                                      routeName: '/SetBudgetScreen',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _CategoryHeader(
                            title:
                                'create.categoryEntertainment'.tr.isNotEmpty &&
                                    'create.categoryEntertainment'.tr !=
                                        'create.categoryEntertainment'
                                ? 'create.categoryEntertainment'.tr
                                      .toUpperCase()
                                : 'ENTERTAINMENT',
                            textColor: textSecondary,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.quiz_outlined,
                                    title:
                                        'create.actionQuiz'.tr.isNotEmpty &&
                                            'create.actionQuiz'.tr !=
                                                'create.actionQuiz'
                                        ? 'create.actionQuiz'.tr
                                        : 'Quiz',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Get.toNamed(AppRoutes.quizDashboard);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.emoji_events_outlined,
                                    title:
                                        'create.actionChallenge'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionChallenge'.tr !=
                                                'create.actionChallenge'
                                        ? 'create.actionChallenge'.tr
                                        : 'Challenge',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _showChallengeDialog(
                                      context,
                                      dialogBg,
                                      textPrimary,
                                      textSecondary,
                                      border,
                                      iconBg,
                                      iconBorder,
                                      isDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.video_library_outlined,
                                    title:
                                        'create.actionShortContent'
                                                .tr
                                                .isNotEmpty &&
                                            'create.actionShortContent'.tr !=
                                                'create.actionShortContent'
                                        ? 'create.actionShortContent'.tr
                                        : 'Short Content',
                                    cardBg: cardBg,
                                    border: border,
                                    iconBg: iconBg,
                                    iconBorder: iconBorder,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _showShortContentDialog(
                                      context,
                                      dialogBg,
                                      textPrimary,
                                      textSecondary,
                                      border,
                                      iconBg,
                                      iconBorder,
                                      isDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostComposerGlassMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final glassBg = isDark ? const Color(0xE814161A) : const Color(0xF2F7F8FA);
    final glassBorder = isDark
        ? const Color(0x2EFFFFFF)
        : const Color(0x1F000000);
    final textPrimary = isDark
        ? const Color(0xFFF0F2F5)
        : const Color(0xFF141619);
    final textSecondary = isDark
        ? const Color(0xFF98A2B3)
        : const Color(0xFF667085);
    final pillBg = isDark ? const Color(0x16FFFFFF) : const Color(0x0A000000);
    final pillBorder = isDark
        ? const Color(0x1CFFFFFF)
        : const Color(0x0F000000);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + safeBottom + 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.78,
            maxWidth: 420,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: glassBorder, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.48 : 0.12,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag indicator
                        Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Header (Title + Close Button)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'create.title'.tr.isNotEmpty &&
                                        'create.title'.tr != 'create.title'
                                    ? 'create.title'.tr
                                    : 'Create',
                                style: TextStyle(
                                  fontFamily: AppTypography.englishFontFamily,
                                  fontFamilyFallback: _fontFallbacks,
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.of(context).pop(),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Pill options list
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _GlassPillOption(
                                  icon: Icons.poll_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  title:
                                      'community.poll'.tr.isNotEmpty &&
                                          'community.poll'.tr !=
                                              'community.poll'
                                      ? 'community.poll'.tr
                                      : 'Poll',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onSelectPoll?.call();
                                  },
                                ),
                                _GlassPillOption(
                                  icon: Icons.forum_rounded,
                                  iconColor: const Color(0xFF3B82F6),
                                  title:
                                      'create.actionDiscussion'.tr.isNotEmpty &&
                                          'create.actionDiscussion'.tr !=
                                              'create.actionDiscussion'
                                      ? 'create.actionDiscussion'.tr
                                      : 'Discussion',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    if (onSelectDiscussion != null) {
                                      Navigator.of(context).pop();
                                      onSelectDiscussion!();
                                    } else {
                                      _navigate(
                                        context,
                                        const CreateDiscussionScreen(),
                                        routeName: '/CreateDiscussionScreen',
                                      );
                                    }
                                  },
                                ),
                                _GlassPillOption(
                                  icon: Icons.celebration_rounded,
                                  iconColor: const Color(0xFFEC4899),
                                  title:
                                      'community.celebration'.tr.isNotEmpty &&
                                          'community.celebration'.tr !=
                                              'community.celebration'
                                      ? 'community.celebration'.tr
                                      : 'Celebration',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onSelectCelebration?.call();
                                  },
                                ),
                                _GlassPillOption(
                                  icon: Icons.work_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  title:
                                      'community.job'.tr.isNotEmpty &&
                                          'community.job'.tr != 'community.job'
                                      ? 'community.job'.tr
                                      : 'Job',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    if (onSelectJob != null) {
                                      Navigator.of(context).pop();
                                      onSelectJob!();
                                    } else {
                                      _navigate(
                                        context,
                                        const CreateOpportunityScreen(),
                                        routeName: '/CreateOpportunityScreen',
                                      );
                                    }
                                  },
                                ),
                                _GlassPillOption(
                                  icon: Icons.description_rounded,
                                  iconColor: const Color(0xFF06B6D4),
                                  title:
                                      'community.document'.tr.isNotEmpty &&
                                          'community.document'.tr !=
                                              'community.document'
                                      ? 'community.document'.tr
                                      : 'Document',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onSelectDocument?.call();
                                  },
                                ),
                                _GlassPillOption(
                                  icon: Icons.photo_library_rounded,
                                  iconColor: const Color(0xFF8B5CF6),
                                  title:
                                      'community.media'.tr.isNotEmpty &&
                                          'community.media'.tr !=
                                              'community.media'
                                      ? 'community.media'.tr
                                      : 'Media',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onSelectMedia?.call();
                                  },
                                ),
                                _GlassPillOption(
                                  icon: Icons.event_available_rounded,
                                  iconColor: const Color(0xFFF97316),
                                  title:
                                      'create.actionEvent'.tr.isNotEmpty &&
                                          'create.actionEvent'.tr !=
                                              'create.actionEvent'
                                      ? 'create.actionEvent'.tr
                                      : 'Event',
                                  pillBg: pillBg,
                                  pillBorder: pillBorder,
                                  textPrimary: textPrimary,
                                  isDark: isDark,
                                  onTap: () {
                                    if (onSelectEvent != null) {
                                      Navigator.of(context).pop();
                                      onSelectEvent!();
                                    } else {
                                      _navigate(
                                        context,
                                        const CreateEventScreen(),
                                        routeName: '/CreateEventScreen',
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPillOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Color pillBg;
  final Color pillBorder;
  final Color textPrimary;
  final bool isDark;

  const _GlassPillOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.pillBg,
    required this.pillBorder,
    required this.textPrimary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: pillBorder, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: iconColor.withValues(alpha: 0.12),
          highlightColor: iconColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.englishFontFamily,
                      fontFamilyFallback: GlobalCreateSheet._fontFallbacks,
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final Color textColor;

  const _CategoryHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.englishFontFamily,
          fontFamilyFallback: const [
            AppTypography.khmerFontFamily,
            AppTypography.englishFontFamily,
          ],
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CommunityFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color cardBg;
  final Color border;
  final Color iconBg;
  final Color iconBorder;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _CommunityFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.cardBg,
    required this.border,
    required this.iconBg,
    required this.iconBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: textPrimary.withValues(alpha: 0.08),
          highlightColor: textPrimary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconBorder, width: 0.8),
                  ),
                  child: Icon(icon, color: textPrimary, size: 20),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.englishFontFamily,
                        fontFamilyFallback: const [
                          AppTypography.khmerFontFamily,
                          AppTypography.englishFontFamily,
                        ],
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.englishFontFamily,
                        fontFamilyFallback: const [
                          AppTypography.khmerFontFamily,
                          AppTypography.englishFontFamily,
                        ],
                        color: textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color cardBg;
  final Color border;
  final Color iconBg;
  final Color iconBorder;
  final Color textPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _GridFeatureCard({
    required this.icon,
    required this.title,
    required this.cardBg,
    required this.border,
    required this.iconBg,
    required this.iconBorder,
    required this.textPrimary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: textPrimary.withValues(alpha: 0.08),
          highlightColor: textPrimary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconBorder, width: 0.8),
                  ),
                  child: Icon(icon, color: textPrimary, size: 19),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.englishFontFamily,
                    fontFamilyFallback: const [
                      AppTypography.khmerFontFamily,
                      AppTypography.englishFontFamily,
                    ],
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
