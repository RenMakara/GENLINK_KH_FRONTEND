import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_match_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_custom_card.dart';
import '../widgets/quiz_gradient_button.dart';
import '../widgets/quiz_icon_container.dart';
import '../widgets/quiz_option_tile.dart';

class MultiplayerQuizScreen extends GetView<QuizMatchController> {
  const MultiplayerQuizScreen({super.key});

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
            child: AppBackButton(onPressed: _leave),
          ),
        ),
        leadingWidth: 74,
        title: Text(
          'quiz.multiplayerQuiz'.tr,
          style: TextStyle(color: QuizThemeColors.heading),
        ),
      ),
      body: Obx(() => _buildBody(context, controller.phase.value)),
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
    return Obx(() {
      final quizzes = quizController.quizzes;
      if (quizController.isQuizListLoading.value && quizzes.isEmpty) {
        return _centeredLoader('quiz.loadingMultiplayer'.tr);
      }
      if (quizzes.isEmpty) {
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

      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'quiz.chooseMultiplayerQuiz'.tr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: QuizThemeColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'quiz.chooseMultiplayerQuizDescription'.tr,
            style: TextStyle(color: QuizThemeColors.body, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final quiz in quizzes) ...[
            QuizCustomCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => controller.startMatch(quiz.quizId),
              child: Row(
                children: [
                  QuizIconContainer(
                    icon: Icons.people_alt_outlined,
                    accentColor: QuizThemeColors.primary,
                    size: 46,
                    iconSize: 24,
                    borderRadius: AppRadius.lg,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: QuizThemeColors.heading,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quiz.questionCount} · ${quiz.xpReward} XP',
                          style: TextStyle(color: QuizThemeColors.body),
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
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    });
  }

  Widget _buildMatchmaking(BuildContext context, QuizMatchPhase phase) {
    final message = switch (phase) {
      QuizMatchPhase.connecting => 'quiz.connectingToMatch'.tr,
      QuizMatchPhase.matchmaking => 'quiz.findingOpponent'.tr,
      _ => 'quiz.waitingForOpponent'.tr,
    };
    return _centeredLoader(message, showCancel: true);
  }

  Widget _buildLoadingMatch(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildOpponentCard(context),
        const SizedBox(height: AppSpacing.xl),
        _centeredLoader('quiz.loadingMatchQuestions'.tr),
      ],
    );
  }

  Widget _buildPlaying(BuildContext context, QuizMatchPhase phase) {
    final question = controller.currentQuestion;
    if (question == null) return _centeredLoader('common.loading'.tr);
    final selected = controller.selectedOptionId.value;
    final isSubmitting = phase == QuizMatchPhase.submitting;
    final isTimeout = phase == QuizMatchPhase.timeout;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: _buildScoreBar(context),
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
              color: QuizThemeColors.gold,
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'quiz.questionOfTotal'.trParams({
                        'current': '${controller.currentQuestionIndex.value + 1}',
                        'total': '${controller.questions.length}',
                      }),
                      style: TextStyle(
                        color: QuizThemeColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildTimer(context),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              QuizCustomCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: QuizThemeColors.heading,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < question.options.length; index++)
                QuizOptionTile(
                  label: question.options[index].text,
                  index: index,
                  isSelected: selected == question.options[index].id,
                  onTap: isSubmitting || isTimeout
                      ? null
                      : () => controller.selectAnswer(
                          question.options[index].id,
                        ),
                ),
              if (isTimeout)
                _statusBanner(
                  context,
                  icon: Icons.timer_off_outlined,
                  text: 'quiz.answerTimedOut'.tr,
                  color: QuizThemeColors.incorrect,
                ),
              if (isSubmitting)
                _statusBanner(
                  context,
                  icon: Icons.check_circle_outline,
                  text: 'quiz.answerSubmitted'.tr,
                  color: QuizThemeColors.correct,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinishing(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildOpponentCard(context),
        const SizedBox(height: AppSpacing.xl),
        _centeredLoader('quiz.calculatingResult'.tr),
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
    final title = isTie
        ? 'quiz.matchTie'.tr
        : isWinner
        ? 'quiz.matchWon'.tr
        : 'quiz.matchLost'.tr;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Icon(
          isTie || isWinner ? Icons.emoji_events_outlined : Icons.flag_outlined,
          size: 64,
          color: isTie || isWinner
              ? QuizThemeColors.gold
              : QuizThemeColors.muted,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: QuizThemeColors.heading,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildScoreBar(context),
        const SizedBox(height: AppSpacing.lg),
        QuizCustomCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                'quiz.xpEarned'.tr,
                style: TextStyle(color: QuizThemeColors.body),
              ),
              const SizedBox(height: 8),
              Text(
                '+$reward XP',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: QuizThemeColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        QuizGradientButton(
          label: 'quiz.playAgain'.tr,
          icon: Icons.replay_rounded,
          onPressed: controller.retry,
        ),
        const SizedBox(height: AppSpacing.sm),
        QuizGradientButton(
          label: 'quiz.backToDashboard'.tr,
          isOutlined: true,
          onPressed: () => Get.offNamed(AppRoutes.quizDashboard),
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

  Widget _buildOpponentCard(BuildContext context) {
    final opponent = controller.opponent;
    return QuizCustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: QuizThemeColors.primaryLight,
            child: Icon(Icons.person_outline, color: QuizThemeColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'quiz.opponent'.tr,
                  style: TextStyle(color: QuizThemeColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  opponent?.name?.trim().isNotEmpty == true
                      ? opponent!.name!
                      : 'quiz.waitingForOpponent'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: QuizThemeColors.heading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${controller.opponentScore}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: QuizThemeColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _scoreItem(
            context,
            label: 'quiz.you'.tr,
            score: controller.playerScore,
            color: QuizThemeColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _scoreItem(
            context,
            label: controller.opponent?.name ?? 'quiz.opponent'.tr,
            score: controller.opponentScore,
            color: QuizThemeColors.gold,
          ),
        ),
      ],
    );
  }

  Widget _scoreItem(
    BuildContext context, {
    required String label,
    required int score,
    required Color color,
  }) {
    return QuizCustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: QuizThemeColors.body, fontSize: 12),
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(BuildContext context) {
    final seconds = controller.timeRemaining.value;
    final isLow = seconds <= 5;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLow
            ? QuizThemeColors.incorrectSoft
            : QuizThemeColors.primaryLight,
        border: Border.all(
          color: isLow ? QuizThemeColors.incorrect : QuizThemeColors.primary,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          'quiz.secondsShort'.trParams({'seconds': '$seconds'}),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isLow ? QuizThemeColors.incorrect : QuizThemeColors.primary,
          ),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: QuizThemeColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: QuizThemeColors.heading,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: QuizThemeColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: QuizThemeColors.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: QuizThemeColors.body, height: 1.4),
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
