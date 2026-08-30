import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../design_system/radius/app_radius.dart';
import '../../features/community/presentation/screens/create_discussion_screen.dart';
import '../../features/community/presentation/screens/create_event_screen.dart';
import '../../features/community/presentation/screens/create_post_screen.dart';
import '../../features/community/presentation/widgets/community_creation_flow.dart';
import '../../features/community/presentation/widgets/story_creation_picker_sheet.dart';
import '../../features/finance/presentation/screens/budget_feature/screens/set_budget_screen.dart';
import '../../features/finance/presentation/screens/expense_feature/screens/expense_add_screen.dart';
import '../../features/finance/presentation/screens/learn_feature/screens/investing_quiz.dart';
import '../../features/finance/presentation/screens/Saving Goal Feature/screens/saving_goals_create.dart';
import '../../features/productivity/presentation/screens/create_habit_screen.dart';
import '../../features/productivity/presentation/screens/create_task_screen.dart';

/// Global "Create" Bottom Sheet for GenLink KH.
///
/// Features exclusively the 13 approved features organized into 4 categories:
/// - COMMUNITY (2x2 grid): Post, Story, Event, Discussion
/// - PRODUCTIVITY (3-col grid): Goal, To-Do, Habit
/// - FINANCIAL (3-col grid): Expense, Saving Goal, Budget
/// - ENTERTAINMENT (3-col grid): Quiz, Challenge, Short Content
///
/// Visual Style:
/// - Clean UI with subtle glass effect (translucent surfaces, thin borders, soft highlights)
/// - Neutral card surfaces with small, restrained colorful accents on icon containers only
/// - Full dynamic support for Light Mode and Dark Mode
/// - Localization-ready for both English and Khmer with overflow-proof responsive sizing
class GlobalCreateSheet extends StatelessWidget {
  final bool fromPostComposer;

  const GlobalCreateSheet({super.key, this.fromPostComposer = false});

  /// Accent Color Palette for Icon Containers (Subtle & Restrained)
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color accentPinkPurple = Color(0xFFEC4899);

  /// Presents the modal bottom sheet.
  static Future<void> show(BuildContext context, {bool fromPostComposer = false}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (_) => GlobalCreateSheet(fromPostComposer: fromPostComposer),
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
    final isAlreadyInPostComposer = fromPostComposer ||
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
    bool isDark,
  ) {
    Navigator.of(context).pop();
    final dialogTitle = 'create.actionChallenge'.tr.isNotEmpty &&
            'create.actionChallenge'.tr != 'create.actionChallenge'
        ? 'create.actionChallenge'.tr
        : 'Challenge';
    final dialogDesc = 'create.dialogChallengeDesc'.tr.isNotEmpty &&
            'create.dialogChallengeDesc'.tr != 'create.dialogChallengeDesc'
        ? 'create.dialogChallengeDesc'.tr
        : 'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.';
    final doneText = 'common.done'.tr.isNotEmpty && 'common.done'.tr != 'common.done'
        ? 'common.done'.tr
        : 'Done';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                color: accentPurple.withValues(alpha: isDark ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentPurple.withValues(alpha: isDark ? 0.32 : 0.22),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: accentPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dialogTitle,
                style: TextStyle(
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
            color: textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              doneText,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShortContentDialog(
    BuildContext context,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color border,
    bool isDark,
  ) {
    Navigator.of(context).pop();
    final dialogTitle = 'create.actionShortContent'.tr.isNotEmpty &&
            'create.actionShortContent'.tr != 'create.actionShortContent'
        ? 'create.actionShortContent'.tr
        : 'Short Content';
    final dialogDesc = 'create.dialogShortContentDesc'.tr.isNotEmpty &&
            'create.dialogShortContentDesc'.tr != 'create.dialogShortContentDesc'
        ? 'create.dialogShortContentDesc'.tr
        : 'Create and share short video clips or reels directly to your Story or Community feed.';
    final openStoryText = 'create.openStoryCreator'.tr.isNotEmpty &&
            'create.openStoryCreator'.tr != 'create.openStoryCreator'
        ? 'create.openStoryCreator'.tr
        : ('create.actionStory'.tr.isNotEmpty && 'create.actionStory'.tr != 'create.actionStory'
            ? 'create.actionStory'.tr
            : 'Open Story Creator');
    final cancelText = 'common.cancel'.tr.isNotEmpty && 'common.cancel'.tr != 'common.cancel'
        ? 'common.cancel'.tr
        : 'Cancel';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                color: accentPink.withValues(alpha: isDark ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentPink.withValues(alpha: isDark ? 0.32 : 0.22),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                color: accentPink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dialogTitle,
                style: TextStyle(
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
            color: textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              CommunityCreationFlow.openCreateStory();
            },
            child: Text(
              openStoryText,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              cancelText,
              style: TextStyle(
                color: textSecondary,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Palette adapting dynamically to theme
    final sheetBg = isDark
        ? const Color(0xF212151D) // Translucent deep charcoal
        : const Color(0xF8FFFFFF); // Translucent clean white
    final dialogBg = isDark ? const Color(0xFF181C26) : Colors.white;
    final cardBg = isDark
        ? const Color(0x661E232F) // Subtle neutral glass surface
        : const Color(0xCCF4F6FA); // Subtle light neutral glass surface
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark
        ? const Color(0x2EFFFFFF) // Thin subtle white border in dark mode
        : const Color(0x18000000); // Thin subtle border in light mode
    final sheetBorder = isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x14000000);

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    // ── Drag Handle ──
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

                    // ── Header (Title, Subtitle, Close Button) ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'create.title'.tr.isNotEmpty && 'create.title'.tr != 'create.title'
                                      ? 'create.title'.tr
                                      : 'Create',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'create.subtitle'.tr.isNotEmpty && 'create.subtitle'.tr != 'create.subtitle'
                                      ? 'create.subtitle'.tr
                                      : 'What would you like to create?',
                                  style: TextStyle(
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

                    // ── Scrollable Feature Sections ──
                    Flexible(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        children: [
                          // ── 1. COMMUNITY (2x2 Grid) ──
                          _CategoryHeader(
                            title: 'create.categoryCommunity'.tr.isNotEmpty &&
                                    'create.categoryCommunity'.tr != 'create.categoryCommunity'
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
                                    accentColor: accentBlue,
                                    title: 'create.actionPost'.tr.isNotEmpty &&
                                            'create.actionPost'.tr != 'create.actionPost'
                                        ? 'create.actionPost'.tr
                                        : 'Post',
                                    description: 'create.actionPostDesc'.tr.isNotEmpty &&
                                            'create.actionPostDesc'.tr != 'create.actionPostDesc'
                                        ? 'create.actionPostDesc'.tr
                                        : 'Share an update with your network',
                                    cardBg: cardBg,
                                    border: border,
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
                                    accentColor: accentPurple,
                                    title: 'create.actionStory'.tr.isNotEmpty &&
                                            'create.actionStory'.tr != 'create.actionStory'
                                        ? 'create.actionStory'.tr
                                        : 'Story',
                                    description: 'create.actionStoryDesc'.tr.isNotEmpty &&
                                            'create.actionStoryDesc'.tr != 'create.actionStoryDesc'
                                        ? 'create.actionStoryDesc'.tr
                                        : 'Share photo or video to your story',
                                    cardBg: cardBg,
                                    border: border,
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
                                    accentColor: accentOrange,
                                    title: 'create.actionEvent'.tr.isNotEmpty &&
                                            'create.actionEvent'.tr != 'create.actionEvent'
                                        ? 'create.actionEvent'.tr
                                        : 'Event',
                                    description: 'create.actionEventDesc'.tr.isNotEmpty &&
                                            'create.actionEventDesc'.tr != 'create.actionEventDesc'
                                        ? 'create.actionEventDesc'.tr
                                        : 'Host an event or community meetup',
                                    cardBg: cardBg,
                                    border: border,
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
                                    accentColor: accentCyan,
                                    title: 'create.actionDiscussion'.tr.isNotEmpty &&
                                            'create.actionDiscussion'.tr != 'create.actionDiscussion'
                                        ? 'create.actionDiscussion'.tr
                                        : 'Discussion',
                                    description: 'create.actionDiscussionDesc'.tr.isNotEmpty &&
                                            'create.actionDiscussionDesc'.tr != 'create.actionDiscussionDesc'
                                        ? 'create.actionDiscussionDesc'.tr
                                        : 'Start a topic in the forum',
                                    cardBg: cardBg,
                                    border: border,
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

                          // ── 2. PRODUCTIVITY (3-col Grid) ──
                          _CategoryHeader(
                            title: 'create.categoryProductivity'.tr.isNotEmpty &&
                                    'create.categoryProductivity'.tr != 'create.categoryProductivity'
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
                                    accentColor: accentGreen,
                                    title: 'create.actionGoal'.tr.isNotEmpty &&
                                            'create.actionGoal'.tr != 'create.actionGoal'
                                        ? 'create.actionGoal'.tr
                                        : 'Goal',
                                    cardBg: cardBg,
                                    border: border,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const CreateGoalScreen(),
                                      routeName: '/CreateGoalScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.check_circle_outline_rounded,
                                    accentColor: accentBlue,
                                    title: 'create.actionTodo'.tr.isNotEmpty &&
                                            'create.actionTodo'.tr != 'create.actionTodo'
                                        ? 'create.actionTodo'.tr
                                        : 'To-Do',
                                    cardBg: cardBg,
                                    border: border,
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
                                    accentColor: accentOrange,
                                    title: 'create.actionHabit'.tr.isNotEmpty &&
                                            'create.actionHabit'.tr != 'create.actionHabit'
                                        ? 'create.actionHabit'.tr
                                        : 'Habit',
                                    cardBg: cardBg,
                                    border: border,
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

                          // ── 3. FINANCIAL (3-col Grid) ──
                          _CategoryHeader(
                            title: 'create.categoryFinancial'.tr.isNotEmpty &&
                                    'create.categoryFinancial'.tr != 'create.categoryFinancial'
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
                                    accentColor: accentAmber,
                                    title: 'create.actionExpense'.tr.isNotEmpty &&
                                            'create.actionExpense'.tr != 'create.actionExpense'
                                        ? 'create.actionExpense'.tr
                                        : 'Expense',
                                    cardBg: cardBg,
                                    border: border,
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
                                    accentColor: accentGreen,
                                    title: 'create.actionSavingGoal'.tr.isNotEmpty &&
                                            'create.actionSavingGoal'.tr != 'create.actionSavingGoal'
                                        ? 'create.actionSavingGoal'.tr
                                        : 'Saving Goal',
                                    cardBg: cardBg,
                                    border: border,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const CreateGoalScreen(),
                                      routeName: '/CreateGoalScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.pie_chart_outline_rounded,
                                    accentColor: accentPurple,
                                    title: 'create.actionBudget'.tr.isNotEmpty &&
                                            'create.actionBudget'.tr != 'create.actionBudget'
                                        ? 'create.actionBudget'.tr
                                        : 'Budget',
                                    cardBg: cardBg,
                                    border: border,
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

                          // ── 4. ENTERTAINMENT (3-col Grid) ──
                          _CategoryHeader(
                            title: 'create.categoryEntertainment'.tr.isNotEmpty &&
                                    'create.categoryEntertainment'.tr != 'create.categoryEntertainment'
                                ? 'create.categoryEntertainment'.tr.toUpperCase()
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
                                    accentColor: accentPinkPurple,
                                    title: 'create.actionQuiz'.tr.isNotEmpty &&
                                            'create.actionQuiz'.tr != 'create.actionQuiz'
                                        ? 'create.actionQuiz'.tr
                                        : 'Quiz',
                                    cardBg: cardBg,
                                    border: border,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _navigate(
                                      context,
                                      const InvestingQuizScreen(),
                                      routeName: '/InvestingQuizScreen',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.emoji_events_outlined,
                                    accentColor: accentPurple,
                                    title: 'create.actionChallenge'.tr.isNotEmpty &&
                                            'create.actionChallenge'.tr != 'create.actionChallenge'
                                        ? 'create.actionChallenge'.tr
                                        : 'Challenge',
                                    cardBg: cardBg,
                                    border: border,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _showChallengeDialog(
                                      context,
                                      dialogBg,
                                      textPrimary,
                                      textSecondary,
                                      border,
                                      isDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GridFeatureCard(
                                    icon: Icons.video_library_outlined,
                                    accentColor: accentPink,
                                    title: 'create.actionShortContent'.tr.isNotEmpty &&
                                            'create.actionShortContent'.tr != 'create.actionShortContent'
                                        ? 'create.actionShortContent'.tr
                                        : 'Short Content',
                                    cardBg: cardBg,
                                    border: border,
                                    textPrimary: textPrimary,
                                    isDark: isDark,
                                    onTap: () => _showShortContentDialog(
                                      context,
                                      dialogBg,
                                      textPrimary,
                                      textSecondary,
                                      border,
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
}

/// Category section title header.
class _CategoryHeader extends StatelessWidget {
  final String title;
  final Color textColor;

  const _CategoryHeader({
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// 2-Column Community Feature Card (Post, Story, Event, Discussion).
///
/// Features subtle glass surface with an accent-tinted icon container,
/// primary title, and secondary description.
class _CommunityFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final Color cardBg;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _CommunityFeatureCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.cardBg,
    required this.border,
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
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.03),
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
          splashColor: accentColor.withValues(alpha: 0.12),
          highlightColor: accentColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Accent-tinted icon container
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: isDark ? 0.28 : 0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 20,
                  ),
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
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        height: 1.25,
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

/// 3-Column Grid Feature Card (Productivity, Financial, Entertainment).
///
/// Features subtle glass surface with an accent-tinted icon container
/// and multi-line responsive title that never clips in Khmer or English.
class _GridFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final Color cardBg;
  final Color border;
  final Color textPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _GridFeatureCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.cardBg,
    required this.border,
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
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.03),
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
          splashColor: accentColor.withValues(alpha: 0.12),
          highlightColor: accentColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accent-tinted icon container
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: isDark ? 0.28 : 0.20),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 19,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.2,
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
