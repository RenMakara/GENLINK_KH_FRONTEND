import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';

class QuizController extends GetxController {
  QuizController({
    QuizRepository? quizRepository,
    AuthController? authController,
  }) : _quizRepository = quizRepository ?? Get.find<QuizRepository>(),
       _authController = authController ?? Get.find<AuthController>();

  final QuizRepository _quizRepository;
  final AuthController _authController;

  final userStats = const UserStats(
    name: '',
    avatarUrl: null,
    level: 1,
    xp: 0,
    xpToNextLevel: 100,
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

  final selectedCategory = Rxn<QuizCategory>();
  final currentQuizId = RxnString();

  final questions = <QuizQuestion>[].obs;
  final selectedAnswers = <String, String>{}.obs;
  final currentQuestionIndex = 0.obs;
  int get totalQuestions => questions.length;
  final timePerQuestion = 15;
  final timeRemaining = 15.obs;

  Timer? _questionTimer;
  Worker? _authUserWorker;
  DateTime? _quizStartTime;

  final quizResult = Rxn<QuizResult>();
  final isQuizSubmitted = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    syncAuthenticatedUser(_authController.currentUser.value);
    _authUserWorker = ever<UserEntity?>(
      _authController.currentUser,
      syncAuthenticatedUser,
    );
    loadQuizzes();
    loadQuizHistory();
  }

  @override
  void onClose() {
    _questionTimer?.cancel();
    _authUserWorker?.dispose();
    super.onClose();
  }

  /// Keep Quiz profile data derived from the shared authenticated account.
  void syncAuthenticatedUser(UserEntity? user) {
    final level = user?.level ?? 1;
    final name = user == null
        ? ''
        : (user.fullName.trim().isNotEmpty ? user.fullName : user.username);

    userStats.value = UserStats(
      name: name,
      avatarUrl: user?.avatarUrl,
      level: level,
      xp: user?.totalXp ?? 0,
      xpToNextLevel: level * 100,
    );
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
      quizListError.value = _messageForError(e, 'quiz.couldNotLoadQuizzes');
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

  void selectCategory(QuizCategory cat) {
    selectedCategory.value = cat;
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
      quizError.value = _messageForError(e, 'quiz.couldNotLoadQuiz');
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
      quizError.value = _messageForError(e, 'quiz.couldNotLoadQuiz');
      questions.clear();
    } finally {
      isQuizLoading.value = false;
    }
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
      if (isQuizSubmitted.value) {
        timer.cancel();
        return;
      }
      timeRemaining.value--;
      if (timeRemaining.value <= 0) {
        nextQuestion(fromTimer: true);
      }
    });
  }

  void selectAnswer(String questionId, String selectedOptionId) {
    final question = questions.firstWhereOrNull(
      (item) => item.id == questionId,
    );
    if (question == null ||
        !question.options.any((option) => option.id == selectedOptionId)) {
      return;
    }
    selectedAnswers[questionId] = selectedOptionId;
  }

  int? selectedOptionIndexForQuestion(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= questions.length) return null;
    final selectedId = selectedAnswers[questions[questionIndex].id];
    if (selectedId == null) return null;
    final optionIndex = questions[questionIndex].options.indexWhere(
      (option) => option.id == selectedId,
    );
    return optionIndex < 0 ? null : optionIndex;
  }

  bool isQuestionAnswered(int questionIndex) =>
      selectedOptionIndexForQuestion(questionIndex) != null;

  void nextQuestion({bool fromTimer = false}) {
    _questionTimer?.cancel();
    if (isQuizSubmitted.value) return;
    if (currentQuestionIndex.value < totalQuestions - 1) {
      currentQuestionIndex.value++;
      _startQuestionTimer();
    } else if (fromTimer) {
      _openReview();
    }
  }

  void skipQuestion() {
    _questionTimer?.cancel();
    if (currentQuestionIndex.value < totalQuestions - 1) {
      currentQuestionIndex.value++;
      _startQuestionTimer();
    } else {
      _openReview();
    }
  }

  void goToQuestion(int index) {
    _questionTimer?.cancel();
    if (index >= 0 && index < totalQuestions) {
      currentQuestionIndex.value = index;
      if (!isQuizSubmitted.value) _startQuestionTimer();
    }
  }

  int get answeredCount => selectedAnswers.length;
  int get unansweredCount => totalQuestions - answeredCount;

  Future<void> submitQuiz() async {
    final quizId = currentQuizId.value;
    if (isQuizSubmitted.value ||
        isSubmitting.value ||
        quizId == null ||
        quizId.isEmpty) {
      return;
    }

    isSubmitting.value = true;
    submitError.value = null;
    _questionTimer?.cancel();

    final answersPayload = <Map<String, String>>[];
    for (final question in questions) {
      final selectedOptionId = selectedAnswers[question.id];
      if (selectedOptionId == null ||
          !question.options.any((option) => option.id == selectedOptionId)) {
        continue;
      }
      answersPayload.add({
        'questionId': question.id,
        'selectedOptionId': selectedOptionId,
      });
    }

    try {
      final result = await _quizRepository.submitQuizAttempt(
        quizId,
        answersPayload,
      );
      final elapsedSeconds = _quizStartTime == null
          ? 0
          : DateTime.now().difference(_quizStartTime!).inSeconds;
      quizResult.value = result.copyWith(timeTakenSeconds: elapsedSeconds);
      isQuizSubmitted.value = true;
      await loadQuizHistory();
      await _authController.refreshCurrentUser();
    } catch (e) {
      submitError.value = _messageForError(e, 'quiz.submissionFailed');
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetQuiz() {
    isQuizSubmitted.value = false;
    isSubmitting.value = false;
    quizResult.value = null;
    currentQuizId.value = null;
    submitError.value = null;
    quizError.value = null;
    selectedAnswers.clear();
    currentQuestionIndex.value = 0;
    selectedCategory.value = null;
    _questionTimer?.cancel();
  }

  void _openReview() {
    if (isQuizSubmitted.value) return;
    _questionTimer?.cancel();
    Get.toNamed(AppRoutes.quizReview);
  }

  String _messageForError(Object error, String fallbackKey) {
    if (error is AppError) {
      if (error.isUnauthorized) return 'quiz.sessionExpired'.tr;
      if (error.isNotFound) return 'quiz.couldNotLoadQuiz'.tr;
      if (error.errorCode == 'NO_QUESTIONS') {
        return 'quiz.noQuestionsAvailable'.tr;
      }
      if (error.isValidation) return 'quiz.invalidSubmission'.tr;
    }
    final translated = fallbackKey.tr;
    return translated == fallbackKey ? 'quiz.requestFailed'.tr : translated;
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
    if (value.toUpperCase() == 'FINANCE') return 'finance.title'.tr;
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
