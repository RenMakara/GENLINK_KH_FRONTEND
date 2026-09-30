import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../domain/models/quiz_models.dart';
import '../controllers/quiz_controller.dart';
import '../quiz_colors.dart';
import '../widgets/quiz_result_decorations.dart';

class ResultScreen extends GetView<QuizController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _returnToDashboard();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        body: SafeArea(
          child: Obx(() {
            final result = controller.quizResult.value;
            if (result == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'quiz.loadingResults'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // 1. Confetti background
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CelebrationConfettiWidget(height: 380),
                ),

                // 2. Main scrollable content
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTopNavigation(context),
                      const SizedBox(height: 12),
                      _buildHeroSection(context, result),
                      const SizedBox(height: 22),
                      _buildProgressAndMascotSection(context, result),
                      const SizedBox(height: 22),
                      _buildSummaryGrid(result),
                      const SizedBox(height: 18),
                      _buildReviewAnswersCard(context),
                      const SizedBox(height: 14),
                      _buildPrimaryActionCard(context),
                      const SizedBox(height: 8),
                      _buildBackToDashboardButton(context),
                      const SizedBox(height: 18),
                      _buildFooterMotivation(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _returnToDashboard() {
    controller.resetQuiz();
    Get.until(
      (route) =>
          route.settings.name == AppRoutes.quizDashboard ||
          route.settings.name == AppRoutes.home ||
          route.isFirst,
    );
    if (Get.currentRoute != AppRoutes.quizDashboard) {
      Get.offNamed(AppRoutes.quizDashboard);
    }
  }

  // ---------------------------------------------------------------------------
  // Top Navigation Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Pill: Next Question / Keep going!
        GestureDetector(
          onTap: _returnToDashboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Next Question',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                      ),
                    ),
                    Text(
                      'Keep going!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Right Pill: Home
        GestureDetector(
          onTap: _returnToDashboard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.home_outlined,
                  size: 18,
                  color: Color(0xFF0F172A),
                ),
                SizedBox(width: 6),
                Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Trophy & Congratulations Banner
  // ---------------------------------------------------------------------------
  Widget _buildHeroSection(BuildContext context, QuizResult result) {
    final isHigh = result.accuracyPercent >= 80;
    return Column(
      children: [
        // Golden 3D Trophy
        const GoldenTrophyWidget(size: 114),
        const SizedBox(height: 12),

        // "Quiz Completed!" Gradient Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x387C3AED),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            'Quiz Completed!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Main Congratulations Heading
        Text(
          isHigh ? 'Great Job!' : 'Great Job!',
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),

        // Subtitles
        const Text(
          "You've completed this quiz!",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Keep learning, keep growing!',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mid Section: Tip Card + Center Progress Ring + Mascot Robot
  // ---------------------------------------------------------------------------
  Widget _buildProgressAndMascotSection(BuildContext context, QuizResult result) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Tip Card
        Expanded(
          flex: 5,
          child: Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('💡', style: TextStyle(fontSize: 13)),
                SizedBox(height: 3),
                Text(
                  'Every\nquestion\nmakes you\nsmarter!',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Center Circular Score Ring
        Expanded(
          flex: 7,
          child: Center(
            child: SizedBox(
              width: 122,
              height: 122,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 122,
                    height: 122,
                    child: CircularProgressIndicator(
                      value: result.accuracyPercent.clamp(0, 100).toDouble() / 100,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${result.accuracyPercent}%',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'quiz.correctRatio'.trParams({
                          'correct': '${result.correct}',
                          'total': '${result.total}',
                        }),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Right Mascot & Speech Bubble
        Expanded(
          flex: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speech bubble
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x302563EB),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'You can do\neven better!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '✦',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Speech bubble arrow tail pointing down
                  CustomPaint(
                    size: const Size(12, 6),
                    painter: _BubbleTailPainter(color: const Color(0xFF2563EB)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Robot Mascot
              const RobotMascotWidget(width: 46, height: 52),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2x2 Stats Grid
  // ---------------------------------------------------------------------------
  Widget _buildSummaryGrid(QuizResult result) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 94,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Correct
        _buildStatCard(
          icon: Icons.check_rounded,
          iconBgColor: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          value: '${result.correct}',
          valueColor: const Color(0xFF16A34A),
          title: 'quiz.correct'.tr,
          subtitle: 'Nice work!',
        ),

        // 2. Incorrect
        _buildStatCard(
          icon: Icons.close_rounded,
          iconBgColor: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFFEF4444),
          value: '${result.wrong}',
          valueColor: const Color(0xFFEF4444),
          title: 'quiz.wrong'.tr,
          subtitle: 'Keep practicing!',
        ),

        // 3. Average Time / Time Taken
        _buildStatCard(
          icon: Icons.timer_outlined,
          iconBgColor: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          value: 'quiz.secondsShort'.trParams({
            'seconds': '${result.timeTakenSeconds}',
          }),
          valueColor: const Color(0xFF6366F1),
          title: 'quiz.timeTaken'.tr,
          subtitle: 'Per question',
        ),

        // 4. XP Earned
        _buildStatCard(
          icon: Icons.star_rounded,
          iconBgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFF59E0B),
          value: '+${result.xpEarned}',
          valueColor: const Color(0xFFD97706),
          title: 'quiz.xpEarned'.tr,
          subtitle: 'Keep going!',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Review Answers Card
  // ---------------------------------------------------------------------------
  Widget _buildReviewAnswersCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAnswerBreakdown(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6E4FA), width: 1.3),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.remove_red_eye_rounded,
                  size: 22,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'quiz.reviewAnswers'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'See what you got right and learn from mistakes',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Primary Action Button ("Next Question" / Continue)
  // ---------------------------------------------------------------------------
  Widget _buildPrimaryActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x402563EB),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _returnToDashboard,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Next Question',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Continue your learning journey',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToDashboardButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _returnToDashboard,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dashboard_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                'quiz.backToDashboard'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer Motivation & Bottom Decor
  // ---------------------------------------------------------------------------
  Widget _buildFooterMotivation(BuildContext context) {
    return Column(
      children: [
        const Text(
          '"Small steps create big progress."',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        const Icon(
          Icons.favorite_rounded,
          size: 16,
          color: Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            BookStackGradCapWidget(width: 58, height: 48),
            SproutPlantWidget(width: 58, height: 48),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Answer Breakdown Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showAnswerBreakdown(BuildContext context) {
    final questions = controller.questions.toList(growable: false);
    final selectedAnswers = Map<String, String>.from(
      controller.selectedAnswers,
    );
    final results =
        controller.quizResult.value?.results ?? const <QuizQuestionResult>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'quiz.answerBreakdown'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _buildAnswerReviewItem(
                    index,
                    questions[index],
                    selectedAnswers,
                    results,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerReviewItem(
    int index,
    QuizQuestion question,
    Map<String, String> selectedAnswers,
    List<QuizQuestionResult> results,
  ) {
    final qResult = results.firstWhereOrNull(
      (result) => result.questionId == question.id,
    );
    final selectedId = qResult?.selectedOptionId ?? selectedAnswers[question.id];
    final correctId = qResult?.correctOptionId;
    final selectedIndex = _optionIndex(question, selectedId);
    final correctIndex = _optionIndex(question, correctId);
    final wasAnswered = selectedId != null && selectedIndex != null;
    final isCorrect = qResult?.correct == true;

    final statusColor = !wasAnswered
        ? QuizThemeColors.gold
        : isCorrect
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: !wasAnswered
            ? const Color(0xFFFEF3C7).withValues(alpha: 0.5)
            : isCorrect
            ? const Color(0xFFDCFCE7).withValues(alpha: 0.5)
            : const Color(0xFFFEE2E2).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                !wasAnswered
                    ? Icons.help_outline
                    : isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 20,
                color: statusColor,
              ),
              const Spacer(),
              Text(
                !wasAnswered
                    ? 'quiz.skipped'.tr
                    : isCorrect
                    ? 'quiz.correct'.tr
                    : 'quiz.incorrect'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(question.options.length, (optionIndex) {
            final option = question.options[optionIndex];
            final isSelected = selectedIndex == optionIndex;
            final isCorrectOption =
                correctIndex != null && correctIndex == optionIndex;
            final optionColor = isCorrectOption
                ? const Color(0xFF16A34A)
                : isSelected
                ? const Color(0xFFEF4444)
                : const Color(0xFF475569);

            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCorrectOption
                    ? const Color(0xFFDCFCE7)
                    : isSelected
                    ? const Color(0xFFFEE2E2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCorrectOption || isSelected
                      ? optionColor
                      : const Color(0xFFE2E8F0),
                  width: isCorrectOption || isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrectOption
                          ? const Color(0xFF16A34A)
                          : isSelected
                          ? const Color(0xFFEF4444)
                          : Colors.transparent,
                      border: isCorrectOption || isSelected
                          ? null
                          : Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + optionIndex),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCorrectOption || isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: optionColor,
                      ),
                    ),
                  ),
                  if (isCorrectOption)
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int? _optionIndex(QuizQuestion question, String? optionId) {
    if (optionId == null) return null;
    final index = question.options.indexWhere((option) => option.id == optionId);
    return index < 0 ? null : index;
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
