import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/models/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';

class QuizController extends GetxController {
  final QuizRepository _quizRepository = Get.find();

  final userStats = UserStats(
    name: 'Thearaa',
    avatarUrl: '',
    level: 12,
    xp: 2800,
    xpToNextLevel: 4000,
    streak: 7,
    coins: 120,
    badges: 5,
    totalQuizzes: 48,
  ).obs;

  final quizzes = <QuizSummary>[].obs;
  final quizHistory = <QuizAttemptSummary>[].obs;
  final categories = <QuizCategory>[].obs;
  final recentCategories = <QuizCategory>[].obs;

  final isQuizListLoading = false.obs;
  final quizListError = RxnString();
  final isQuizLoading = false.obs;
  final quizError = RxnString();
  final submitError = RxnString();

  final quizType = QuizType.random.obs;
  final selectedCategory = Rxn<QuizCategory>();
  final currentQuizId = RxnString();

  final opponent = Opponent(
    name: 'SokHeng',
    avatarUrl: '',
    level: 10,
    winRate: 68,
  ).obs;

  final isFindingOpponent = true.obs;
  final opponentSearchProgress = 0.0.obs;

  final questions = <QuizQuestion>[].obs;
  final selectedAnswers = <int, int>{}.obs;
  final currentQuestionIndex = 0.obs;
  int get totalQuestions => questions.length;
  final timePerQuestion = 15;
  final timeRemaining = 15.obs;

  Timer? _questionTimer;
  Timer? _matchmakingTimer;
  bool _matchmakingCancelled = false;
  DateTime? _quizStartTime;

  final quizResult = Rxn<QuizResult>();
  final isQuizSubmitted = false.obs;
  final isSubmitting = false.obs;
  final isRewardClaimed = false.obs;
  final showRewardAnimation = false.obs;

  final leaderboard = <LeaderboardEntry>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadQuizzes();
    loadQuizHistory();
    _loadLeaderboard();
  }

  @override
  void onClose() {
    _questionTimer?.cancel();
    _matchmakingTimer?.cancel();
    super.onClose();
  }

  Future<void> loadQuizzes({String? category, String? difficulty}) async {
    isQuizListLoading.value = true;
    quizListError.value = null;

    try {
      final list = await _quizRepository.getQuizzes(
        category: _apiValue(category),
        difficulty: _apiValue(difficulty),
      );
      quizzes.assignAll(list);
      if (category == null && difficulty == null) {
        categories.assignAll(_buildCategories(list));
        recentCategories.assignAll(_recentCategoriesFromHistory(quizHistory));
      }
      _debugQuizLog(
        'Quiz list loaded: quizzes=${list.length}, categories=${categories.length}',
      );
    } catch (e) {
      _debugQuizLog('Quiz list error: $e');
      quizListError.value = e.toString();
      if (category == null && difficulty == null) {
        categories.clear();
      }
    } finally {
      isQuizListLoading.value = false;
    }
  }

  Future<void> loadQuizHistory() async {
    try {
      final history = await _quizRepository.getQuizHistory();
      quizHistory.assignAll(history);
      recentCategories.assignAll(_recentCategoriesFromHistory(history));
    } catch (_) {
      quizHistory.clear();
      recentCategories.clear();
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final entries = await _quizRepository.getLeaderboard(
        'OVERALL_XP',
        'ALL_TIME',
      );
      leaderboard.value = entries;
    } catch (_) {}
  }

  void selectCategory(QuizCategory cat) {
    selectedCategory.value = cat;
  }

  void setQuizType(QuizType type) {
    quizType.value = type;
  }

  void startMatchmaking() {
    _matchmakingCancelled = false;
    isFindingOpponent.value = true;
    opponentSearchProgress.value = 0.0;
    _fetchFirstQuizForSelectedCategory();

    _matchmakingTimer?.cancel();
    _matchmakingTimer = Timer.periodic(const Duration(milliseconds: 80), (
      timer,
    ) {
      opponentSearchProgress.value += 0.015;
      if (opponentSearchProgress.value >= 1.0) {
        opponentSearchProgress.value = 1.0;
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 300), () {
          isFindingOpponent.value = false;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!_matchmakingCancelled && questions.isNotEmpty) {
            Get.toNamed('/quiz/opponent-found');
          }
        });
      }
    });
  }

  Future<void> _fetchFirstQuizForSelectedCategory() async {
    try {
      isQuizLoading.value = true;
      quizError.value = null;
      final quizzesList = await _quizRepository.getQuizzes(
        category: selectedCategory.value?.id,
      );

      if (quizzesList.isEmpty) {
        currentQuizId.value = null;
        questions.clear();
        return;
      }

      final quiz = quizzesList.first;
      currentQuizId.value = quiz.quizId;
      questions.value = await _quizRepository.getQuizDetails(quiz.quizId);
    } catch (e) {
      quizError.value = e.toString();
      questions.clear();
    } finally {
      isQuizLoading.value = false;
    }
  }

  Future<List<QuizSummary>> loadQuizOptions(String category) {
    return _quizRepository.getQuizzes(category: category);
  }

  Future<void> startSelectedQuiz(String quizId) async {
    try {
      isQuizLoading.value = true;
      quizError.value = null;
      submitError.value = null;
      currentQuizId.value = quizId;
      questions.value = await _quizRepository.getQuizDetails(quizId);
      selectedAnswers.clear();
      currentQuestionIndex.value = 0;
      isQuizSubmitted.value = false;
      quizResult.value = null;
      _quizStartTime = DateTime.now();
      if (questions.isNotEmpty) {
        _startQuestionTimer();
      }
    } catch (e) {
      quizError.value = e.toString();
      questions.clear();
    } finally {
      isQuizLoading.value = false;
    }
  }

  void cancelMatchmaking() {
    _matchmakingCancelled = true;
    _matchmakingTimer?.cancel();
    isFindingOpponent.value = true;
    opponentSearchProgress.value = 0.0;
  }

  Future<void> startQuiz() async {
    currentQuestionIndex.value = 0;
    selectedAnswers.clear();
    isQuizSubmitted.value = false;
    quizResult.value = null;
    submitError.value = null;
    _quizStartTime = DateTime.now();
    await _fetchFirstQuizForSelectedCategory();
    if (questions.isNotEmpty) {
      _startQuestionTimer();
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    timeRemaining.value = timePerQuestion;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeRemaining.value--;
      if (timeRemaining.value <= 0) {
        nextQuestion();
      }
    });
  }

  void selectAnswer(int questionIndex, int optionIndex) {
    selectedAnswers[questionIndex] = optionIndex;
  }

  void nextQuestion() {
    _questionTimer?.cancel();
    if (currentQuestionIndex.value < totalQuestions - 1) {
      currentQuestionIndex.value++;
      _startQuestionTimer();
    }
  }

  void skipQuestion() {
    _questionTimer?.cancel();
    nextQuestion();
  }

  void goToQuestion(int index) {
    _questionTimer?.cancel();
    currentQuestionIndex.value = index;
  }

  int get answeredCount => selectedAnswers.length;
  int get unansweredCount => totalQuestions - answeredCount;

  Future<void> submitQuiz() async {
    if (isQuizSubmitted.value ||
        isSubmitting.value ||
        currentQuizId.value == null) {
      return;
    }

    isSubmitting.value = true;
    submitError.value = null;
    _questionTimer?.cancel();

    final answersPayload = <Map<String, String>>[];
    for (var i = 0; i < totalQuestions; i++) {
      final selectedOptionIndex = selectedAnswers[i];
      if (selectedOptionIndex == null) continue;
      answersPayload.add({
        'questionId': questions[i].id,
        'selectedOptionId': questions[i].options[selectedOptionIndex].id,
      });
    }

    try {
      final result = await _quizRepository.submitQuizAttempt(
        currentQuizId.value!,
        answersPayload,
      );
      final elapsedSeconds = _quizStartTime == null
          ? 0
          : DateTime.now().difference(_quizStartTime!).inSeconds;
      quizResult.value = result.copyWith(timeTakenSeconds: elapsedSeconds);
      isQuizSubmitted.value = true;
      await loadQuizHistory();
    } catch (e) {
      submitError.value = e.toString();
    } finally {
      isSubmitting.value = false;
    }
  }

  void claimReward() {
    if (quizResult.value == null) return;
    isRewardClaimed.value = true;

    final stats = userStats.value;
    final result = quizResult.value!;
    userStats.value = UserStats(
      name: stats.name,
      avatarUrl: stats.avatarUrl,
      level: stats.level,
      xp: stats.xp + result.xpEarned,
      xpToNextLevel: stats.xpToNextLevel,
      streak: stats.streak,
      coins: stats.coins + result.coinsEarned,
      badges: stats.badges,
      totalQuizzes: stats.totalQuizzes + 1,
    );
  }

  void resetQuiz() {
    _matchmakingCancelled = true;
    isQuizSubmitted.value = false;
    isSubmitting.value = false;
    isRewardClaimed.value = false;
    showRewardAnimation.value = false;
    quizResult.value = null;
    currentQuizId.value = null;
    submitError.value = null;
    quizError.value = null;
    selectedAnswers.clear();
    currentQuestionIndex.value = 0;
    selectedCategory.value = null;
    _questionTimer?.cancel();
    _matchmakingTimer?.cancel();
  }

  List<QuizCategory> _buildCategories(List<QuizSummary> quizList) {
    final totalsByCategory = <String, int>{};
    var totalQuestionCount = 0;
    for (final quiz in quizList) {
      totalQuestionCount += quiz.questionCount;
      final category = quiz.category;
      if (category == null || category.isEmpty) continue;
      totalsByCategory[category] =
          (totalsByCategory[category] ?? 0) + quiz.questionCount;
    }

    if (totalsByCategory.isEmpty && quizList.isNotEmpty) {
      return [
        QuizCategory(
          id: '',
          name: 'quiz.allQuizzes'.tr,
          icon: 'quiz',
          questionCount: totalQuestionCount,
          colorIndex: 0,
        ),
      ];
    }

    var colorIndex = 0;
    return totalsByCategory.entries
        .map((entry) {
          return QuizCategory(
            id: entry.key,
            name: _labelFromApiValue(entry.key),
            icon: _iconForCategory(entry.key),
            questionCount: entry.value,
            colorIndex: colorIndex++ % 4,
          );
        })
        .toList(growable: false);
  }

  List<QuizCategory> _recentCategoriesFromHistory(
    List<QuizAttemptSummary> history,
  ) {
    final byId = {for (final category in categories) category.id: category};
    final seen = <String>{};
    final recent = <QuizCategory>[];

    for (final attempt in history) {
      final quiz = quizzes.firstWhereOrNull(
        (item) => item.quizId == attempt.quizId,
      );
      final category = quiz?.category;
      if (category == null || seen.contains(category)) continue;
      final existing = byId[category];
      if (existing == null) continue;
      recent.add(existing);
      seen.add(category);
      if (recent.length == 2) break;
    }

    return recent;
  }

  String? _apiValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim().toUpperCase().replaceAll(' ', '_');
  }

  String _labelFromApiValue(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _iconForCategory(String category) {
    return switch (category.toUpperCase()) {
      'SCIENCE' => 'biotech',
      'HISTORY' => 'museum',
      'TECH' || 'TECHNOLOGY' => 'devices',
      'GEOGRAPHY' => 'public',
      'MATH' || 'MATHEMATICS' => 'functions',
      'LITERATURE' => 'menu_book',
      'FINANCE' => 'account_balance_wallet',
      _ => 'quiz',
    };
  }

  void _debugQuizLog(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
