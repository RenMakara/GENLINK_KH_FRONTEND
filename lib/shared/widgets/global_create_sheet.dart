import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/typography/app_typography.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_creation_flow.dart';
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
  final VoidCallback? onClose;
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
    this.onClose,
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

  static OverlayEntry? _activeComposerOverlay;
  static Completer<void>? _activeComposerCompleter;
  static FocusNode? _activeEditorFocusNode;

  static bool get isComposerPopupOpen => _activeComposerOverlay != null;

  static void closeComposerPopup() {
    final entry = _activeComposerOverlay;
    _activeComposerOverlay = null;
    if (entry != null) {
      try {
        if (entry.mounted) {
          entry.remove();
        }
      } catch (_) {}
    }
    if (_activeComposerCompleter != null && !_activeComposerCompleter!.isCompleted) {
      _activeComposerCompleter!.complete();
    }
    _activeComposerCompleter = null;
    if (_activeEditorFocusNode != null && _activeEditorFocusNode!.canRequestFocus) {
      if (!_activeEditorFocusNode!.hasFocus) {
        _activeEditorFocusNode!.requestFocus();
      }
    }
    _activeEditorFocusNode = null;
  }

  static Future<void> show(
    BuildContext context, {
    bool fromPostComposer = false,
    Rect? anchorRect,
    FocusNode? focusNode,
    VoidCallback? onSelectMedia,
    VoidCallback? onSelectPoll,
    VoidCallback? onSelectCelebration,
    VoidCallback? onSelectDiscussion,
    VoidCallback? onSelectJob,
    VoidCallback? onSelectDocument,
    VoidCallback? onSelectEvent,
  }) {
    if (fromPostComposer) {
      // If already open, toggle close
      if (isComposerPopupOpen) {
        closeComposerPopup();
        return Future.value();
      }

      final overlay = Overlay.maybeOf(context, rootOverlay: false) ??
          Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) return Future.value();

      _activeEditorFocusNode = focusNode;
      final completer = Completer<void>();
      _activeComposerCompleter = completer;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (overlayContext) {
          return Material(
            type: MaterialType.transparency,
            child: DefaultTextStyle(
              style: const TextStyle(
                decoration: TextDecoration.none,
                fontFamily: AppTypography.englishFontFamily,
                fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: closeComposerPopup,
                      child: Container(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  GlobalCreateSheet(
                    fromPostComposer: true,
                    anchorRect: anchorRect,
                    onClose: closeComposerPopup,
                    onSelectMedia: onSelectMedia,
                    onSelectPoll: onSelectPoll,
                    onSelectCelebration: onSelectCelebration,
                    onSelectDiscussion: onSelectDiscussion,
                    onSelectJob: onSelectJob,
                    onSelectDocument: onSelectDocument,
                    onSelectEvent: onSelectEvent,
                  ),
                ],
              ),
            ),
          );
        },
      );

      _activeComposerOverlay = entry;
      overlay.insert(entry);

      return completer.future;
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

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _navigate(BuildContext context, Widget screen, {String? routeName}) {
    _close(context);
    Get.to(
      () => screen,
      routeName: routeName,
      transition: Transition.cupertino,
    );
  }

  void _openPostCreator(BuildContext context) {
    _close(context);
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
    _close(context);
    CommunityCreationFlow.openCreateStory(context);
  }

  void _openQuiz(BuildContext context) {
    _close(context);
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
    _close(context);
    final dialogTitle = _tr('create.actionChallenge', 'Challenge');
    final dialogDesc = _tr(
      'create.dialogChallengeDesc',
      'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.',
    );
    final doneText = _tr('common.done', 'Done');

    GenLinkConfirmDialog.showSuccess(
      context: context,
      title: dialogTitle,
      message: dialogDesc,
      confirmLabel: doneText,
      icon: Icons.emoji_events_outlined,
    );
  }

  static void showShortContentDialog(
    BuildContext context, {
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? iconBg,
    Color? iconBorder,
    bool? isDark,
  }) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isDarkEffective = isDark ?? (theme.brightness == Brightness.dark);
    final dialogBg = surface ?? (isDarkEffective ? const Color(0xFF1E2023) : colors.surface);
    final borderEffective = border ?? (isDarkEffective ? const Color(0x1FFFFFFF) : const Color(0x12000000));
    final iconBgEffective = iconBg ?? (isDarkEffective ? const Color(0xFF282A2E) : const Color(0xFFEEF0F3));
    final iconBorderEffective = iconBorder ?? (isDarkEffective ? const Color(0x26FFFFFF) : const Color(0x18000000));

    const sheet = GlobalCreateSheet();
    sheet._showShortContentDialog(
      context,
      dialogBg,
      textPrimary ?? colors.primaryText,
      textSecondary ?? colors.secondaryText,
      borderEffective,
      iconBgEffective,
      iconBorderEffective,
      isDarkEffective,
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
    _close(context);
    final dialogTitle = _tr('create.actionShortContent', 'Short Content');
    final dialogDesc = _tr(
      'create.dialogShortContentDesc',
      'Create and share a short video directly to the GenLink Short Content feed.',
    );
    final createShortContentText = _tr(
      'shortContent.create',
      'Create Short Content',
    );
    final cancelText = _tr('common.cancel', 'Cancel');

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
                          _FeatureRow(
                            icon: Icons.article_outlined,
                            title: _tr('create.actionPost', 'Post'),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _openPostCreator(context),
                          ),
                          _FeatureRow(
                            icon: Icons.amp_stories_outlined,
                            title: _tr('create.actionStory', 'Story'),
                            rowBg: rowBg,
                            border: border,
                            iconBg: iconBg,
                            iconBorder: iconBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            onTap: () => _openStoryCreator(context),
                          ),
                          _FeatureRow(
                            icon: Icons.event_outlined,
                            title: _tr('create.actionEvent', 'Event'),
                            rowBg: rowBg,
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
                          _FeatureRow(
                            icon: Icons.forum_outlined,
                            title: _tr('create.actionDiscussion', 'Discussion'),
                            rowBg: rowBg,
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
                          _FeatureRow(
                            icon: Icons.flag_outlined,
                            title: _tr('create.actionGoal', 'Goal'),
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
                          _FeatureRow(
                            icon: Icons.receipt_long_outlined,
                            title: _tr('create.actionExpense', 'Expense'),
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
                          _FeatureRow(
                            icon: Icons.quiz_outlined,
                            title: _tr('create.actionQuiz', 'Quiz'),
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
        ? const Color(0xFA15181E)
        : const Color(0xFDF8FAFC);
    final glassBorder = isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x1A000000);
    final textPrimary = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final rowDivider = isDark
        ? const Color(0x1FFFFFFF)
        : const Color(0x0F000000);
    final iconBg = isDark
        ? const Color(0x1AFFFFFF)
        : const Color(0x0A000000);
    final iconBorder = isDark
        ? const Color(0x24FFFFFF)
        : const Color(0x12000000);
    final dialogBg = isDark ? const Color(0xFF181A20) : Colors.white;
    final dialogBorder = isDark ? const Color(0xFF282B35) : const Color(0xFFE2E4EA);

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

    final popupWidth = (screenWidth * 0.58).clamp(210.0, 230.0);
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
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: popupWidth,
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: glassBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
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
                      padding: const EdgeInsets.fromLTRB(12, 9, 8, 7),
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
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _tr(
                                    'create.subtitle',
                                    'What would you like to create?',
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
                              canRequestFocus: false,
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _close(context),
                              child: Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0x20FFFFFF)
                                      : const Color(0x0E000000),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: textSecondary,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, thickness: 0.5, color: rowDivider),

                    // Options in one continuous list (excluding redundant Post)
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ComposerGlassOption(
                              icon: Icons.amp_stories_outlined,
                              title: _tr('create.actionStory', 'Story'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _openStoryCreator(context),
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
                                _close(context);
                                if (onSelectEvent != null) {
                                  onSelectEvent!();
                                } else {
                                  Get.to(
                                    () => const CreateEventScreen(),
                                    routeName: '/CreateEventScreen',
                                    transition: Transition.cupertino,
                                  );
                                }
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
                                _close(context);
                                if (onSelectDiscussion != null) {
                                  onSelectDiscussion!();
                                } else {
                                  Get.to(
                                    () => const CreateDiscussionScreen(),
                                    routeName: '/CreateDiscussionScreen',
                                    transition: Transition.cupertino,
                                  );
                                }
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.flag_outlined,
                              title: _tr('create.actionGoal', 'Goal'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _navigate(
                                context,
                                const productivity_goal.CreateGoalScreen(),
                                routeName: '/CreateGoalScreen',
                              ),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.check_circle_outline_rounded,
                              title: _tr('create.actionTodo', 'To-Do'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _navigate(
                                context,
                                const CreateTaskScreen(),
                                routeName: '/CreateTaskScreen',
                              ),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.local_fire_department_outlined,
                              title: _tr('create.actionHabit', 'Habit'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _navigate(
                                context,
                                const CreateHabitScreen(),
                                routeName: '/CreateHabitScreen',
                              ),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.receipt_long_outlined,
                              title: _tr('create.actionExpense', 'Expense'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _navigate(
                                context,
                                const AddExpenseScreen(),
                                routeName: '/AddExpenseScreen',
                              ),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.savings_outlined,
                              title: _tr('create.actionSavingGoal', 'Saving Goal'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _navigate(
                                context,
                                const finance_saving_goal.CreateGoalScreen(),
                                routeName: '/CreateSavingGoalScreen',
                              ),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.pie_chart_outline_rounded,
                              title: _tr('create.actionBudget', 'Budget'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _navigate(
                                context,
                                const SetBudgetScreen(),
                                routeName: '/SetBudgetScreen',
                              ),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.quiz_outlined,
                              title: _tr('create.actionQuiz', 'Quiz'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _openQuiz(context),
                            ),
                            Divider(height: 1, thickness: 0.5, color: rowDivider, indent: 8, endIndent: 8),
                            _ComposerGlassOption(
                              icon: Icons.emoji_events_outlined,
                              title: _tr('create.actionChallenge', 'Challenge'),
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              iconBg: iconBg,
                              iconBorder: iconBorder,
                              isDark: isDark,
                              onTap: () => _showChallengeDialog(
                                context,
                                dialogBg,
                                textPrimary,
                                textSecondary,
                                dialogBorder,
                                iconBg,
                                iconBorder,
                                isDark,
                              ),
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: SizedBox(
              width: popupWidth,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Opacity(
                    opacity: val,
                    child: Transform.scale(
                      scale: 0.92 + (0.08 * val),
                      alignment: Alignment(
                        ((pointerLocalX / popupWidth) * 2 - 1).clamp(-1.0, 1.0),
                        placeAbove ? 1.0 : -1.0,
                      ),
                      child: child,
                    ),
                  );
                },
                child: positionedChild,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color rowBg;
  final Color border;
  final Color iconBg;
  final Color iconBorder;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.rowBg,
    required this.border,
    required this.iconBg,
    required this.iconBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.englishFontFamily,
                      fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
                      color: textPrimary,
                      fontSize: 14.5,
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
        canRequestFocus: false,
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
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7.5),
                  border: Border.all(color: iconBorder, width: 0.7),
                ),
                child: Icon(
                  icon,
                  color: textPrimary.withValues(alpha: 0.90),
                  size: 14.5,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.englishFontFamily,
                    fontFamilyFallback: GlobalCreateSheet.fontFallbacks,
                    color: textPrimary,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.25,
                    height: 1.25,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary.withValues(alpha: 0.40),
                size: 15,
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
