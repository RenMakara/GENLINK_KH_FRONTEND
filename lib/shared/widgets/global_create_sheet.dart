import 'package:flutter/material.dart';
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
/// Styled strictly in GenLink KH's Black & White / Dark Charcoal visual design.
class GlobalCreateSheet extends StatelessWidget {
  final bool fromPostComposer;

  const GlobalCreateSheet({super.key, this.fromPostComposer = false});

  /// Presents the modal bottom sheet.
  static Future<void> show(BuildContext context, {bool fromPostComposer = false}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border, width: 0.8),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_outlined, color: textPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'create.actionChallenge'.tr.isNotEmpty && 'create.actionChallenge'.tr != 'create.actionChallenge'
                    ? 'create.actionChallenge'.tr
                    : 'Challenge',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.',
          style: TextStyle(color: textSecondary, fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'common.done'.tr.isNotEmpty && 'common.done'.tr != 'common.done'
                  ? 'common.done'.tr
                  : 'Done',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border, width: 0.8),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.video_library_outlined, color: textPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'create.actionShortContent'.tr.isNotEmpty && 'create.actionShortContent'.tr != 'create.actionShortContent'
                    ? 'create.actionShortContent'.tr
                    : 'Short Content',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Create and share short video clips or reels directly to your Story or Community feed.',
          style: TextStyle(color: textSecondary, fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              CommunityCreationFlow.openCreateStory();
            },
            child: Text(
              'create.actionStory'.tr.isNotEmpty && 'create.actionStory'.tr != 'create.actionStory'
                  ? 'create.actionStory'.tr
                  : 'Open Story Creator',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'common.cancel'.tr.isNotEmpty && 'common.cancel'.tr != 'common.cancel'
                  ? 'common.cancel'.tr
                  : 'Cancel',
              style: TextStyle(color: textSecondary),
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

    final sheetBg = isDark ? const Color(0xFF14171C) : Colors.white;
    final itemBg = isDark ? const Color(0xFF1B1F26) : const Color(0xFFF4F6F9);
    final iconBoxBg = isDark ? const Color(0xFF242933) : const Color(0xFFE8ECF2);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF9096A2) : const Color(0xFF666D7A);
    final border = isDark ? const Color(0xFF282E3A) : const Color(0xFFE1E5EC);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight, maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: border, width: 1),
              left: BorderSide(color: border, width: 1),
              right: BorderSide(color: border, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag Handle ──
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 10),
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
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: border, thickness: 0.8),

                // ── Scrollable Feature Grid ──
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
                      Row(
                        children: [
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.article_outlined,
                              title: 'create.actionPost'.tr.isNotEmpty &&
                                      'create.actionPost'.tr != 'create.actionPost'
                                  ? 'create.actionPost'.tr
                                  : 'Post',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _openPostCreator(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.amp_stories_outlined,
                              title: 'create.actionStory'.tr.isNotEmpty &&
                                      'create.actionStory'.tr != 'create.actionStory'
                                  ? 'create.actionStory'.tr
                                  : 'Story',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _openStoryCreator(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.event_outlined,
                              title: 'create.actionEvent'.tr.isNotEmpty &&
                                      'create.actionEvent'.tr != 'create.actionEvent'
                                  ? 'create.actionEvent'.tr
                                  : 'Event',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const CreateEventScreen(),
                                routeName: '/CreateEventScreen',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.forum_outlined,
                              title: 'create.actionDiscussion'.tr.isNotEmpty &&
                                      'create.actionDiscussion'.tr != 'create.actionDiscussion'
                                  ? 'create.actionDiscussion'.tr
                                  : 'Discussion',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const CreateDiscussionScreen(),
                                routeName: '/CreateDiscussionScreen',
                              ),
                            ),
                          ),
                        ],
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
                      Row(
                        children: [
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.flag_outlined,
                              title: 'create.actionGoal'.tr.isNotEmpty &&
                                      'create.actionGoal'.tr != 'create.actionGoal'
                                  ? 'create.actionGoal'.tr
                                  : 'Goal',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const CreateGoalScreen(),
                                routeName: '/CreateGoalScreen',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'create.actionTodo'.tr.isNotEmpty &&
                                      'create.actionTodo'.tr != 'create.actionTodo'
                                  ? 'create.actionTodo'.tr
                                  : 'To-Do',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const CreateTaskScreen(),
                                routeName: '/CreateTaskScreen',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.local_fire_department_outlined,
                              title: 'create.actionHabit'.tr.isNotEmpty &&
                                      'create.actionHabit'.tr != 'create.actionHabit'
                                  ? 'create.actionHabit'.tr
                                  : 'Habit',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const CreateHabitScreen(),
                                routeName: '/CreateHabitScreen',
                              ),
                            ),
                          ),
                        ],
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
                      Row(
                        children: [
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.receipt_long_outlined,
                              title: 'create.actionExpense'.tr.isNotEmpty &&
                                      'create.actionExpense'.tr != 'create.actionExpense'
                                  ? 'create.actionExpense'.tr
                                  : 'Expense',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const AddExpenseScreen(),
                                routeName: '/AddExpenseScreen',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.savings_outlined,
                              title: 'create.actionSavingGoal'.tr.isNotEmpty &&
                                      'create.actionSavingGoal'.tr != 'create.actionSavingGoal'
                                  ? 'create.actionSavingGoal'.tr
                                  : 'Saving Goal',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const CreateGoalScreen(),
                                routeName: '/CreateGoalScreen',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.pie_chart_outline_rounded,
                              title: 'create.actionBudget'.tr.isNotEmpty &&
                                      'create.actionBudget'.tr != 'create.actionBudget'
                                  ? 'create.actionBudget'.tr
                                  : 'Budget',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const SetBudgetScreen(),
                                routeName: '/SetBudgetScreen',
                              ),
                            ),
                          ),
                        ],
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
                      Row(
                        children: [
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.quiz_outlined,
                              title: 'create.actionQuiz'.tr.isNotEmpty &&
                                      'create.actionQuiz'.tr != 'create.actionQuiz'
                                  ? 'create.actionQuiz'.tr
                                  : 'Quiz',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _navigate(
                                context,
                                const InvestingQuizScreen(),
                                routeName: '/InvestingQuizScreen',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.emoji_events_outlined,
                              title: 'create.actionChallenge'.tr.isNotEmpty &&
                                      'create.actionChallenge'.tr != 'create.actionChallenge'
                                  ? 'create.actionChallenge'.tr
                                  : 'Challenge',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _showChallengeDialog(
                                context,
                                sheetBg,
                                textPrimary,
                                textSecondary,
                                border,
                                isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompactCreateCard(
                              icon: Icons.video_library_outlined,
                              title: 'create.actionShortContent'.tr.isNotEmpty &&
                                      'create.actionShortContent'.tr != 'create.actionShortContent'
                                  ? 'create.actionShortContent'.tr
                                  : 'Short Content',
                              surface: itemBg,
                              border: border,
                              textPrimary: textPrimary,
                              iconBg: iconBoxBg,
                              onTap: () => _showShortContentDialog(
                                context,
                                sheetBg,
                                textPrimary,
                                textSecondary,
                                border,
                                isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Clean, compact grid create option card with icon and title.
class _CompactCreateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color iconBg;
  final VoidCallback onTap;

  const _CompactCreateCard({
    required this.icon,
    required this.title,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
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
                    border: Border.all(
                      color: border.withValues(alpha: 0.6),
                      width: 0.6,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
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
