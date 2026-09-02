import 'dart:async';
import 'dart:math';
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

  final categories = <QuizCategory>[
    const QuizCategory(
      id: '1',
      name: 'Science',
      icon: 'biotech',
      questionCount: 120,
      colorIndex: 0,
    ),
    const QuizCategory(
      id: '2',
      name: 'History',
      icon: 'museum',
      questionCount: 95,
      colorIndex: 1,
    ),
    const QuizCategory(
      id: '3',
      name: 'Technology',
      icon: 'devices',
      questionCount: 150,
      colorIndex: 2,
    ),
    const QuizCategory(
      id: '4',
      name: 'Geography',
      icon: 'public',
      questionCount: 80,
      colorIndex: 3,
    ),
    const QuizCategory(
      id: '5',
      name: 'Mathematics',
      icon: 'functions',
      questionCount: 200,
      colorIndex: 0,
    ),
    const QuizCategory(
      id: '6',
      name: 'Literature',
      icon: 'menu_book',
      questionCount: 110,
      colorIndex: 1,
    ),
  ];

  final recentCategories = <QuizCategory>[
    const QuizCategory(
      id: '1',
      name: 'Science',
      icon: 'biotech',
      questionCount: 120,
      colorIndex: 0,
    ),
    const QuizCategory(
      id: '3',
      name: 'Technology',
      icon: 'devices',
      questionCount: 150,
      colorIndex: 2,
    ),
  ].obs;

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
    _loadLeaderboard();
  }

  @override
  void onClose() {
    _questionTimer?.cancel();
    _matchmakingTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final entries = await _quizRepository.getLeaderboard(
        'OVERALL_XP',
        'ALL_TIME',
      );
      leaderboard.value = entries;
    } catch (e) {
      // Fallback or ignore
    }
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

    // Fetch a real quiz while matchmaking!
    _fetchRandomQuiz();

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

  Future<void> _fetchRandomQuiz() async {
    try {
      // First get all quizzes for category
      final categoryName = selectedCategory.value?.name;
      final quizzesList = await _quizRepository.getQuizzes(
        category: categoryName,
      );
      if (quizzesList.isNotEmpty) {
        final pick = quizzesList[Random().nextInt(quizzesList.length)];
        final qId = pick['quizId'] as String;
        currentQuizId.value = qId;

        // Then fetch details
        final quizDetails = await _quizRepository.getQuizDetails(qId);
        questions.value = quizDetails;
      }
    } catch (e) {
      debugPrint('Error fetching quiz: $e');
    }
  }

  /// Loads every quiz in a category so the caller can let the user pick one.
  Future<List<Map<String, dynamic>>> loadQuizOptions(String category) async {
    return _quizRepository.getQuizzes(category: category);
  }

  /// Starts a specific quiz by id (single-player pick).
  Future<void> startSelectedQuiz(String quizId) async {
    try {
      currentQuizId.value = quizId;
      final quizDetails = await _quizRepository.getQuizDetails(quizId);
      questions.value = quizDetails;
      selectedAnswers.clear();
      currentQuestionIndex.value = 0;
      isQuizSubmitted.value = false;
      _startQuestionTimer();
    } catch (e) {
      debugPrint('Error starting quiz: $e');
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
    _quizStartTime = DateTime.now();
    await _fetchRandomQuiz();
    _startQuestionTimer();
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
    if (isQuizSubmitted.value || currentQuizId.value == null) return;

    isSubmitting.value = true;
    _questionTimer?.cancel();

    final answersPayload = <Map<String, String>>[];
    for (int i = 0; i < totalQuestions; i++) {
      if (selectedAnswers.containsKey(i)) {
        answersPayload.add({
          'questionId': questions[i].id,
          'selectedOptionId': questions[i].options[selectedAnswers[i]!].id,
        });
      }
    }

    try {
      final result = await _quizRepository.submitQuizAttempt(
        currentQuizId.value!,
        answersPayload,
      );
      final elapsedSeconds = _quizStartTime == null
          ? 0
          : DateTime.now().difference(_quizStartTime!).inSeconds;
      quizResult.value = result.copyWith(
        timeTakenSeconds: elapsedSeconds,
        coinsEarned: result.correct * 10,
      );
      isQuizSubmitted.value = true;
    } catch (e) {
      debugPrint('Failed to submit quiz: $e');
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
      streak: stats.streak + 1,
      coins: stats.coins + result.coinsEarned,
      badges: stats.badges + (result.accuracyPercent >= 80 ? 1 : 0),
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
    selectedAnswers.clear();
    currentQuestionIndex.value = 0;
    selectedCategory.value = null;
    _questionTimer?.cancel();
    _matchmakingTimer?.cancel();
  }
}
