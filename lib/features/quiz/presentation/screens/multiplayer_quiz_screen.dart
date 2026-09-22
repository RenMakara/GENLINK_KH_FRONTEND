import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_match_controller.dart';
import '../widgets/quiz_gradient_button.dart';
import '../widgets/quiz_multiplayer_widgets.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  const MultiplayerQuizScreen({super.key});

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  final QuizMatchController controller = Get.find<QuizMatchController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'ALL';
  String? _localSelectedOptionId;
  String? _lastQuestionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Scaffold(
      backgroundColor: semantic.background,
      body: SafeArea(
        child: Obx(() => _buildBody(context, controller.phase.value)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizMatchPhase phase) {
    return switch (phase) {
      QuizMatchPhase.idle => _buildQuizSelection(context),
      QuizMatchPhase.connecting ||
      QuizMatchPhase.matchmaking ||
      QuizMatchPhase.waiting => _buildMatchmaking(context, phase),
      QuizMatchPhase.matched || QuizMatchPhase.loadingQuestions =>
        _buildLoadingMatch(context),
      QuizMatchPhase.playing ||
      QuizMatchPhase.submitting ||
      QuizMatchPhase.timeout => _buildPlaying(context, phase),
      QuizMatchPhase.finishing => _buildFinishing(context),
      QuizMatchPhase.completed => _buildCompleted(context),
      QuizMatchPhase.disconnected => _buildDisconnected(context),
      QuizMatchPhase.abandoned => _buildAbandoned(context),
      QuizMatchPhase.error => _buildError(context),
    };
  }

  Widget _buildQuizSelection(BuildContext context) {
    final quizController = Get.find<QuizController>();
    final semantic = context.semanticColors;

    return Obx(() {
      final allQuizzes = quizController.quizzes;
      if (quizController.isQuizListLoading.value && allQuizzes.isEmpty) {
        return _centeredLoader('quiz.loadingMultiplayer'.tr);
      }
      if (allQuizzes.isEmpty) {
        return _emptyState(
          context,
          icon: Icons.quiz_outlined,
          title: 'quiz.noQuizzesAvailable'.tr,
          message: quizController.quizListError.value ??
              'quiz.noQuizzesAvailable'.tr,
          action: QuizGradientButton(
            label: 'common.retry'.tr,
            onPressed: () => quizController.loadQuizzes(),
            height: 50,
          ),
        );
      }

      // Filter quizzes by category and search query
      final filteredQuizzes = allQuizzes.where((q) {
        final matchesCategory = _selectedCategoryId.toUpperCase() == 'ALL' ||
            (q.category ?? '').toUpperCase() == _selectedCategoryId.toUpperCase();
        if (!matchesCategory) return false;

        final query = _searchQuery.trim().toLowerCase();
        if (query.isEmpty) return true;

        final titleMatch = q.title.toLowerCase().contains(query);
        final categoryMatch = (q.category ?? '').toLowerCase().contains(query);
        return titleMatch || categoryMatch;
      }).toList();

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          MultiplayerHeader(
            onBack: _leave,
            title: 'quiz.multiplayerQuiz'.tr,
            subtitle: 'quiz.multiplayerSubtitle'.tr,
          ),
          const SizedBox(height: 12),
          Text(
            'quiz.chooseMultiplayerQuiz'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: semantic.primaryText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'quiz.chooseMultiplayerQuizDescription'.tr,
            style: TextStyle(
              fontSize: 12.5,
              color: semantic.secondaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          MultiplayerQuizSearchBar(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            onClear: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
          const SizedBox(height: 14),
          MultiplayerCategoryFilterChips(
            categories: quizController.categories,
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (catId) =>
                setState(() => _selectedCategoryId = catId),
          ),
          const SizedBox(height: 16),
          if (filteredQuizzes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 44,
                      color: semantic.textMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'quiz.noMatchingQuizzes'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: semantic.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (final quiz in filteredQuizzes) ...[
              MultiplayerQuizCard(
                quiz: quiz,
                onTap: () => controller.startMatch(quiz.quizId),
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 8),
          const MultiplayerDiscoveryCard(),
          const SizedBox(height: 32),
        ],
      );
    });
  }

  Widget _buildMatchmaking(BuildContext context, QuizMatchPhase phase) {
    final semantic = context.semanticColors;
    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.currentUser.value;

    final title = switch (phase) {
      QuizMatchPhase.connecting => 'quiz.connectingToMatch'.tr,
      QuizMatchPhase.matchmaking => 'quiz.findingOpponent'.tr,
      _ => 'quiz.waitingForOpponent'.tr,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  MultiplayerHeader(
                    onBack: _leave,
                    title: 'quiz.multiplayerQuiz'.tr,
                    showTrophy: false,
                  ),
                  const SizedBox(height: 8),
                  MultiplayerMatchupHero(
                    currentUser: currentUser,
                    opponent: controller.opponent,
                    isSearching: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: semantic.primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'quiz.matchmakingSubtitle'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: semantic.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const MultiplayerFeatureHighlightsRow(),
                  const SizedBox(height: 14),
                  const MultiplayerDidYouKnowCard(),
                  const Spacer(),
                  const SizedBox(height: 16),
                  CancelMatchButton(onCancel: _leave),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMatch(BuildContext context) {
    final semantic = context.semanticColors;
    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.currentUser.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  MultiplayerHeader(
                    onBack: _leave,
                    title: 'quiz.multiplayerQuiz'.tr,
                    showTrophy: false,
                  ),
                  const SizedBox(height: 8),
                  MultiplayerMatchupHero(
                    currentUser: currentUser,
                    opponent: controller.opponent,
                    isSearching: false,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'quiz.opponentFound'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: semantic.primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'quiz.preparingMatch'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: semantic.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(color: semantic.primary),
                  const Spacer(),
                  const SizedBox(height: 16),
                  CancelMatchButton(onCancel: _leave),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaying(BuildContext context, QuizMatchPhase phase) {
    final question = controller.currentQuestion;
    if (question == null) return _centeredLoader('common.loading'.tr);

    // Reset local selection when moving to a new question
    if (question.id != _lastQuestionId) {
      _lastQuestionId = question.id;
      _localSelectedOptionId = null;
    }

    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.currentUser.value;
    final quizController =
        Get.isRegistered<QuizController>() ? Get.find<QuizController>() : null;
    final currentQuiz = quizController?.quizzes.firstWhereOrNull(
      (q) => q.quizId == controller.quizId.value,
    );
    final categoryName = currentQuiz?.title ?? currentQuiz?.category;

    final isSubmitting = phase == QuizMatchPhase.submitting;
    final isTimeout = phase == QuizMatchPhase.timeout;
    final selectedOptionId = isSubmitting || isTimeout
        ? controller.selectedOptionId.value ?? _localSelectedOptionId
        : _localSelectedOptionId;

    return Column(
      children: [
        MultiplayerHeader(
          onBack: _leave,
          title: 'quiz.multiplayerQuiz'.tr,
          subtitle: 'quiz.multiplayerGameplaySubtitle'.tr,
          showTrophy: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: MultiplayerScoreboard(
            currentUser: currentUser,
            playerScore: controller.playerScore,
            opponent: controller.opponent,
            opponentScore: controller.opponentScore,
          ),
        ),
        if (controller.opponentAnswered.value)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: _statusBanner(
              context,
              icon: Icons.bolt_outlined,
              text: 'quiz.opponentAnswered'.tr,
              color: AppColors.growthAccent,
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              MultiplayerProgressAndTimer(
                currentIndex: controller.currentQuestionIndex.value,
                totalQuestions: controller.questions.length,
                timeRemaining: controller.timeRemaining.value,
                totalDuration:
                    QuizMatchController.defaultQuestionDurationSeconds,
              ),
              const SizedBox(height: 14),
              MultiplayerQuestionCard(
                category: categoryName,
                question: question.question,
                hint: 'quiz.chooseCorrectAnswer'.tr,
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < question.options.length; index++)
                MultiplayerOptionTile(
                  label: question.options[index].text,
                  index: index,
                  isSelected: selectedOptionId == question.options[index].id,
                  isDisabled: isSubmitting || isTimeout,
                  onTap: () {
                    setState(() {
                      _localSelectedOptionId = question.options[index].id;
                    });
                  },
                ),
              if (isTimeout) ...[
                const SizedBox(height: 8),
                _statusBanner(
                  context,
                  icon: Icons.timer_off_outlined,
                  text: 'quiz.answerTimedOut'.tr,
                  color: AppColors.danger,
                ),
              ],
              if (isSubmitting) ...[
                const SizedBox(height: 8),
                _statusBanner(
                  context,
                  icon: Icons.check_circle_outline,
                  text: 'quiz.answerSubmitted'.tr,
                  color: AppColors.success,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            8,
            AppSpacing.lg,
            12,
          ),
          child: MultiplayerSubmitButton(
            isEnabled:
                _localSelectedOptionId != null && !isSubmitting && !isTimeout,
            isSubmitting: isSubmitting,
            onSubmit: () {
              if (_localSelectedOptionId != null) {
                controller.selectAnswer(_localSelectedOptionId!);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinishing(BuildContext context) {
    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.currentUser.value;

    return Column(
      children: [
        MultiplayerHeader(
          onBack: _leave,
          title: 'quiz.multiplayerQuiz'.tr,
          showTrophy: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: MultiplayerScoreboard(
            currentUser: currentUser,
            playerScore: controller.playerScore,
            opponent: controller.opponent,
            opponentScore: controller.opponentScore,
          ),
        ),
        const Spacer(),
        _centeredLoader('quiz.calculatingResult'.tr),
        const Spacer(),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    final event = controller.matchEvent.value;
    final userId = controller.currentUserId;
    final winnerId = event?.winnerId;
    final isTie = winnerId == null;
    final isWinner = !isTie && userId != null && winnerId == userId;
    final reward = isTie ? 20 : isWinner ? 50 : 0;

    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.currentUser.value;

    return Column(
      children: [
        MultiplayerHeader(
          onBack: _leave,
          title: 'quiz.multiplayerQuiz'.tr,
          showTrophy: false,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              const SizedBox(height: 6),
              MultiplayerResultBanner(
                isWinner: isWinner,
                isTie: isTie,
              ),
              const SizedBox(height: 18),
              MultiplayerScoreboard(
                currentUser: currentUser,
                playerScore: controller.playerScore,
                opponent: controller.opponent,
                opponentScore: controller.opponentScore,
                highlightWinner: true,
                isWinner: isWinner,
                isTie: isTie,
              ),
              const SizedBox(height: 14),
              MultiplayerXpCard(xp: reward),
              const SizedBox(height: 14),
              const MultiplayerMotivationalCard(),
              const SizedBox(height: 22),
              QuizGradientButton(
                label: 'quiz.playAgain'.tr,
                icon: Icons.replay_rounded,
                onPressed: controller.retry,
              ),
              const SizedBox(height: 10),
              QuizGradientButton(
                label: 'quiz.backToDashboard'.tr,
                icon: Icons.home_rounded,
                isOutlined: true,
                onPressed: () {
                  Get.until(
                    (route) =>
                        route.settings.name == AppRoutes.quizDashboard ||
                        route.settings.name == AppRoutes.home ||
                        route.isFirst,
                  );
                  if (Get.currentRoute != AppRoutes.quizDashboard) {
                    Get.offNamed(AppRoutes.quizDashboard);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnected(BuildContext context) {
    return _emptyState(
      context,
      icon: Icons.cloud_off_outlined,
      title: 'quiz.matchDisconnected'.tr,
      message: 'quiz.matchReconnectMessage'.tr,
      action: QuizGradientButton(
        label: 'common.retry'.tr,
        icon: Icons.refresh_rounded,
        onPressed: controller.retry,
        height: 50,
      ),
    );
  }

  Widget _buildAbandoned(BuildContext context) {
    return _emptyState(
      context,
      icon: Icons.flag_outlined,
      title: 'quiz.matchAbandoned'.tr,
      message: 'quiz.matchAbandonedMessage'.tr,
      action: QuizGradientButton(
        label: 'common.retry'.tr,
        onPressed: controller.retry,
        height: 50,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return _emptyState(
      context,
      icon: Icons.error_outline,
      title: 'quiz.multiplayerError'.tr,
      message: controller.errorMessage.value ?? 'quiz.requestFailed'.tr,
      action: QuizGradientButton(
        label: 'common.retry'.tr,
        onPressed: controller.retry,
        height: 50,
      ),
    );
  }

  Widget _statusBanner(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredLoader(String message, {bool showCancel = false}) {
    final semantic = context.semanticColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: semantic.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: semantic.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showCancel) ...[
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: _leave, child: Text('common.cancel'.tr)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
  }) {
    final semantic = context.semanticColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: semantic.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: semantic.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: semantic.secondaryText, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            action,
          ],
        ),
      ),
    );
  }

  void _leave() {
    final currentPhase = controller.phase.value;
    if (currentPhase == QuizMatchPhase.completed ||
        currentPhase == QuizMatchPhase.error ||
        currentPhase == QuizMatchPhase.idle) {
      Get.back();
      return;
    }
    controller.leaveMatch().whenComplete(() => Get.back());
  }
}

