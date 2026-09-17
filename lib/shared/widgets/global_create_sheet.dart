import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/typography/app_typography.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_opportunity_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_creation_picker_sheet.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart'
    as finance_saving_goal;
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart'
    as productivity_goal;
import 'package:genlink_frontend/features/productivity/presentation/screens/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_task_screen.dart';

class GlobalCreateSheet extends StatelessWidget {
  final bool fromPostComposer;
  final Rect? anchorRect;
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
    this.anchorRect,
    this.onSelectMedia,
    this.onSelectPoll,
    this.onSelectCelebration,
    this.onSelectDiscussion,
    this.onSelectJob,
    this.onSelectDocument,
    this.onSelectEvent,
  });

  static const List<String> fontFallbacks = [
    AppTypography.khmerFontFamily,
    AppTypography.englishFontFamily,
  ];

  static Future<void> show(
    BuildContext context, {
    bool fromPostComposer = false,
    Rect? anchorRect,
    VoidCallback? onSelectMedia,
    VoidCallback? onSelectPoll,
    VoidCallback? onSelectCelebration,
    VoidCallback? onSelectDiscussion,
    VoidCallback? onSelectJob,
    VoidCallback? onSelectDocument,
    VoidCallback? onSelectEvent,
  }) {
    if (fromPostComposer) {
      return Navigator.of(context, rootNavigator: false).push<void>(
        _ComposerAttachmentPopupRoute(
          anchorRect: anchorRect,
          builder: (popupContext) => GlobalCreateSheet(
            fromPostComposer: true,
            anchorRect: anchorRect,
            onSelectMedia: onSelectMedia,
            onSelectPoll: onSelectPoll,
            onSelectCelebration: onSelectCelebration,
            onSelectDiscussion: onSelectDiscussion,
            onSelectJob: onSelectJob,
            onSelectDocument: onSelectDocument,
            onSelectEvent: onSelectEvent,
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (_) => GlobalCreateSheet(
        fromPostComposer: false,
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

  static String _tr(String key, String fallback) {
    final tr = key.tr;
    return (tr.isNotEmpty && tr != key) ? tr : fallback;
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

  void _openQuiz(BuildContext context) {
    Navigator.of(context).pop();
    Get.toNamed(AppRoutes.quizDashboard);
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
    final dialogTitle = _tr('create.actionChallenge', 'Challenge');
    final dialogDesc = _tr(
      'create.dialogChallengeDesc',
      'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.',
    );
    final doneText = _tr('common.done', 'Done');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 0.8),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
        title: Row(
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
              child: Icon(
                Icons.emoji_events_outlined,
                color: textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dialogTitle,
                style: TextStyle(
                  fontFamily: AppTypography.englishFontFamily,
                  fontFamilyFallback: fontFallbacks,
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          dialogDesc,
          style: TextStyle(
            fontFamily: AppTypography.englishFontFamily,
            fontFamilyFallback: fontFallbacks,
            color: textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFFE4E6EB)
                  : const Color(0xFF18191B),
              foregroundColor: isDark
                  ? const Color(0xFF18191A)
                  : const Color(0xFFFFFFFF),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              doneText,
              style: TextStyle(
                fontFamily: AppTypography.englishFontFamily,
                fontFamilyFallback: fontFallbacks,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
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

    final sheetBg = isDark ? const Color(0xF2141618) : const Color(0xF7FFFFFF);
    final rowBg = isDark ? const Color(0xFF1E2023) : const Color(0xFFF7F8FA);
    final textPrimary = colors.primaryText;
    final textSecondary = colors.secondaryText;
    final border = isDark ? const Color(0x1FFFFFFF) : const Color(0x12000000);
    final sheetBorder = isDark
        ? const Color(0x2EFFFFFF)
        : const Color(0x1F000000);
    final iconBg = isDark ? const Color(0xFF282A2E) : const Color(0xFFEEF0F3);
    final iconBorder = isDark
        ? const Color(0x26FFFFFF)
        : const Color(0x18000000);
    final dialogBg = isDark ? const Color(0xFF1E2023) : colors.surface;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight, maxWidth: 520),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                    color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
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
                    // Drag Handle
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

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('create.title', 'Create'),
                                  style: TextStyle(
                                    fontFamily: AppTypography.englishFontFamily,
                                    fontFamilyFallback: fontFallbacks,
                                    color: textPrimary,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _tr(
                                    'create.subtitle',
                                    'What would you like to create?',
                                  ),
                                  style: TextStyle(
                                    fontFamily: AppTypography.englishFontFamily,
                                    fontFamilyFallback: fontFallbacks,
                                    color: textSecondary,
                                    fontSize: 12.5,
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                          // ── COMMUNITY ──────────────────────
                          _CategoryHeader(
                            title: _tr(
                              'create.categoryCommunity',
                              'COMMUNITY',
                            ).toUpperCase(),
                            textColor: isDark
                                ? const Color(0xFFE2E4E8)
                                : const Color(0xFF2C3036),
                            isCommunity: true,
                          ),
                          _FeatureRow(
                            icon: Icons.article_outlined,
                            title: _tr('create.actionPost', 'Post'),
                            subtitle: _tr(
                              'create.actionPostDesc',
                              'Share an update with your network',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            isCommunity: true,
                            onTap: () => _openPostCreator(context),
                          ),
                          _FeatureRow(
                            icon: Icons.amp_stories_outlined,
                            title: _tr('create.actionStory', 'Story'),
                            subtitle: _tr(
                              'create.actionStoryDesc',
                              'Share photo or video to your story',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            isCommunity: true,
                            onTap: () => _openStoryCreator(context),
                          ),
                          _FeatureRow(
                            icon: Icons.event_outlined,
                            title: _tr('create.actionEvent', 'Event'),
                            subtitle: _tr(
                              'create.actionEventDesc',
                              'Host an event or community meetup',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            isCommunity: true,
                            onTap: () => _navigate(
                              context,
                              const CreateEventScreen(),
                              routeName: '/CreateEventScreen',
                            ),
                          ),
                          _FeatureRow(
                            icon: Icons.forum_outlined,
                            title: _tr('create.actionDiscussion', 'Discussion'),
                            subtitle: _tr(
                              'create.actionDiscussionDesc',
                              'Start a topic in the forum',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            isCommunity: true,
                            onTap: () => _navigate(
                              context,
                              const CreateDiscussionScreen(),
                              routeName: '/CreateDiscussionScreen',
                            ),
                          ),

                          // ── PRODUCTIVITY ───────────────────
                          _CategoryHeader(
                            title: _tr(
                              'create.categoryProductivity',
                              'PRODUCTIVITY',
                            ).toUpperCase(),
                            textColor: textSecondary,
                          ),
                          _FeatureRow(
                            icon: Icons.flag_outlined,
                            title: _tr('create.actionGoal', 'Goal'),
                            subtitle: _tr(
                              'create.actionGoalDesc',
                              'Set a personal or skill goal',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _navigate(
                              context,
                              const productivity_goal.CreateGoalScreen(),
                              routeName: '/CreateGoalScreen',
                            ),
                          ),
                          _FeatureRow(
                            icon: Icons.check_circle_outline_rounded,
                            title: _tr('create.actionTodo', 'To-Do'),
                            subtitle: _tr(
                              'create.actionTodoDesc',
                              'Add a task to your daily plan',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _navigate(
                              context,
                              const CreateTaskScreen(),
                              routeName: '/CreateTaskScreen',
                            ),
                          ),
                          _FeatureRow(
                            icon: Icons.local_fire_department_outlined,
                            title: _tr('create.actionHabit', 'Habit'),
                            subtitle: _tr(
                              'create.actionHabitDesc',
                              'Build a daily or weekly routine',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _navigate(
                              context,
                              const CreateHabitScreen(),
                              routeName: '/CreateHabitScreen',
                            ),
                          ),

                          // ── FINANCIAL ──────────────────────
                          _CategoryHeader(
                            title: _tr(
                              'create.categoryFinancial',
                              'FINANCIAL',
                            ).toUpperCase(),
                            textColor: textSecondary,
                          ),
                          _FeatureRow(
                            icon: Icons.receipt_long_outlined,
                            title: _tr('create.actionExpense', 'Expense'),
                            subtitle: _tr(
                              'create.actionExpenseDesc',
                              'Log your daily spending',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _navigate(
                              context,
                              const AddExpenseScreen(),
                              routeName: '/AddExpenseScreen',
                            ),
                          ),
                          _FeatureRow(
                            icon: Icons.savings_outlined,
                            title: _tr(
                              'create.actionSavingGoal',
                              'Saving Goal',
                            ),
                            subtitle: _tr(
                              'create.actionSavingGoalDesc',
                              'Create a target to save money',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _navigate(
                              context,
                              const finance_saving_goal.CreateGoalScreen(),
                              routeName: '/CreateSavingGoalScreen',
                            ),
                          ),
                          _FeatureRow(
                            icon: Icons.pie_chart_outline_rounded,
                            title: _tr('create.actionBudget', 'Budget'),
                            subtitle: _tr(
                              'create.actionBudgetDesc',
                              'Allocate monthly budget limits',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _navigate(
                              context,
                              const SetBudgetScreen(),
                              routeName: '/SetBudgetScreen',
                            ),
                          ),

                          // ── ENTERTAINMENT ──────────────────
                          _CategoryHeader(
                            title: _tr(
                              'create.categoryEntertainment',
                              'ENTERTAINMENT',
                            ).toUpperCase(),
                            textColor: textSecondary,
                          ),
                          _FeatureRow(
                            icon: Icons.quiz_outlined,
                            title: _tr('create.actionQuiz', 'Quiz'),
                            subtitle: _tr(
                              'create.actionQuizDesc',
                              'Test knowledge and earn XP',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _openQuiz(context),
                          ),
                          _FeatureRow(
                            icon: Icons.emoji_events_outlined,
                            title: _tr('create.actionChallenge', 'Challenge'),
                            subtitle: _tr(
                              'create.actionChallengeDesc',
                              'Join and complete daily challenges',
                            ),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
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

    final glassBg = isDark
        ? const Color(0xEE16181D)
        : const Color(0xF4FBFBFB);
    final glassBorder = isDark
        ? const Color(0x2EFFFFFF)
        : const Color(0x1A000000);
    final textPrimary = isDark
        ? const Color(0xFFF0F2F5)
        : const Color(0xFF141619);
    final textSecondary = isDark
        ? const Color(0xFF949BA6)
        : const Color(0xFF6B7280);
    final rowDivider = isDark
        ? const Color(0x18FFFFFF)
        : const Color(0x0F000000);
    final iconBg = isDark
        ? const Color(0x18FFFFFF)
        : const Color(0x0A000000);
    final iconBorder = isDark
        ? const Color(0x20FFFFFF)
        : const Color(0x10000000);

    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    // Resolve the anchor rectangle of the '+' button
    final resolvedAnchor = anchorRect ??
        Rect.fromLTWH(
          screenWidth - 12 - 38,
          screenHeight - bottomInset - safeBottom - 8 - 34,
          38,
          34,
        );

    const gap = 3.0;
    const pointerHeight = 5.0;
    const pointerWidth = 9.0;

    final availableAbove = resolvedAnchor.top - safeTop - 8.0;
    final availableBelow =
        screenHeight - bottomInset - safeBottom - resolvedAnchor.bottom - 8.0;

    // Intelligently decide whether to place above or below
    final bool placeAbove =
        availableAbove >= 180.0 || availableAbove >= availableBelow;

    final popupWidth = (screenWidth * 0.54).clamp(195.0, 212.0);
    final popupRight = (screenWidth - resolvedAnchor.right).clamp(
      8.0,
      (screenWidth - popupWidth - 8.0).clamp(8.0, double.infinity),
    );
    final popupLeft = screenWidth - popupRight - popupWidth;
    final pointerGlobalX = resolvedAnchor.center.dx;
    final pointerLocalX =
        (pointerGlobalX - popupLeft).clamp(14.0, popupWidth - 14.0);

    final double maxPopupHeight;
    if (placeAbove) {
      maxPopupHeight =
          (availableAbove - gap - pointerHeight).clamp(140.0, 340.0);
    } else {
      maxPopupHeight =
          (availableBelow - gap - pointerHeight).clamp(140.0, 340.0);
    }

    final popupContent = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: popupWidth,
        maxHeight: maxPopupHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: popupWidth,
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glassBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontFamily: AppTypography.englishFontFamily,
                  fontFamilyFallback: fontFallbacks,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 7, 6, 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tr('create.title', 'Create'),
                                  style: TextStyle(
                                    fontFamily: AppTypography.englishFontFamily,
                                    fontFamilyFallback: fontFallbacks,
                                    color: textPrimary,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _tr(
                                    'create.subtitleMore',
                                    'More ways to share and connect.',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTypography.englishFontFamily,
                                    fontFamilyFallback: fontFallbacks,
                                    color: textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0x18FFFFFF)
                                      : const Color(0x0A000000),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: textSecondary,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, thickness: 0.5, color: rowDivider),

                    // 7 Options
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ComposerGlassOption(
                              icon: Icons.poll_outlined,
                              title: _tr('community.poll', 'Poll'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                onSelectPoll?.call();
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.forum_outlined,
                              title: _tr('create.actionDiscussion', 'Discussion'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                if (onSelectDiscussion != null) {
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
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.celebration_outlined,
                              title: _tr('community.celebration', 'Celebration'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                onSelectCelebration?.call();
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.work_outline_rounded,
                              title: _tr('community.job', 'Job'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                if (onSelectJob != null) {
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
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.description_outlined,
                              title: _tr('community.document', 'Document'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                onSelectDocument?.call();
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.photo_library_outlined,
                              title: _tr('community.media', 'Media'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                onSelectMedia?.call();
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.event_outlined,
                              title: _tr('create.actionEvent', 'Event'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () {
                                Navigator.of(context).pop();
                                if (onSelectEvent != null) {
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
    );

    // Build column with pointer
    final Widget positionedChild;
    if (placeAbove) {
      positionedChild = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          popupContent,
          Transform.translate(
            offset: const Offset(0, -0.8),
            child: Padding(
              padding: EdgeInsets.only(
                left: (pointerLocalX - (pointerWidth / 2))
                    .clamp(8.0, popupWidth - pointerWidth - 8.0),
              ),
              child: CustomPaint(
                size: const Size(pointerWidth, pointerHeight),
                painter: _TrianglePainter(
                  color: glassBg,
                  borderColor: glassBorder,
                  pointingDown: true,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      positionedChild = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, 0.8),
            child: Padding(
              padding: EdgeInsets.only(
                left: (pointerLocalX - (pointerWidth / 2))
                    .clamp(8.0, popupWidth - pointerWidth - 8.0),
              ),
              child: CustomPaint(
                size: const Size(pointerWidth, pointerHeight),
                painter: _TrianglePainter(
                  color: glassBg,
                  borderColor: glassBorder,
                  pointingDown: false,
                ),
              ),
            ),
          ),
          popupContent,
        ],
      );
    }

    return Stack(
      children: [
        Positioned(
          right: popupRight,
          bottom: placeAbove
              ? (screenHeight - resolvedAnchor.top + gap)
              : null,
          top: placeAbove
              ? null
              : (resolvedAnchor.bottom + gap),
          child: SizedBox(
            width: popupWidth,
            child: positionedChild,
          ),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  final bool isCommunity;

  const _CategoryHeader({
    required this.title,
    required this.textColor,
    this.isCommunity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 2,
        top: isCommunity ? 4 : 14,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.englishFontFamily,
          fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
          color: textColor,
          fontSize: isCommunity ? 11.5 : 11.0,
          fontWeight: isCommunity ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color rowBg;
  final Color border;
  final Color iconBg;
  final Color iconBorder;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final bool isCommunity;

  const _FeatureRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.rowBg,
    required this.border,
    required this.iconBg,
    required this.iconBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    this.isCommunity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: textPrimary.withValues(alpha: 0.08),
          highlightColor: textPrimary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
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
                  child: Icon(
                    icon,
                    color: textPrimary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.englishFontFamily,
                          fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight:
                              isCommunity ? FontWeight.w700 : FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.englishFontFamily,
                            fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
                            color: textSecondary,
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary.withValues(alpha: 0.55),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerGlassOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconBg;
  final Color iconBorder;
  final bool isDark;
  final VoidCallback onTap;

  const _ComposerGlassOption({
    required this.icon,
    required this.title,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconBg,
    required this.iconBorder,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: textPrimary.withValues(alpha: 0.08),
        highlightColor: textPrimary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: iconBorder, width: 0.6),
                ),
                child: Icon(
                  icon,
                  color: textPrimary.withValues(alpha: 0.88),
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.englishFontFamily,
                    fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.25,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withValues(alpha: 0.35),
                size: 14.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointingDown;

  _TrianglePainter({
    required this.color,
    required this.borderColor,
    this.pointingDown = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    if (pointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
      canvas.drawPath(path, paint);

      final borderPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
      canvas.drawPath(borderPath, borderPaint);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);

      final borderPath = Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.pointingDown != pointingDown;
}

class _ComposerAttachmentPopupRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  final Rect? anchorRect;

  _ComposerAttachmentPopupRoute({
    required this.builder,
    this.anchorRect,
    super.settings,
  });

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.16);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          fontFamily: AppTypography.englishFontFamily,
          fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
        ),
        child: builder(context),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        alignment: const Alignment(0.85, 0.95),
        child: child,
      ),
    );
  }
}
