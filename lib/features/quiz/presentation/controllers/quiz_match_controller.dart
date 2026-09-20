// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/app_realtime_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/quiz_match_realtime_data_source.dart';
import '../../domain/models/quiz_match_models.dart';
import '../../domain/models/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';

const _defaultQuestionDurationSeconds = 15;

enum QuizMatchPhase {
  idle,
  connecting,
  matchmaking,
  waiting,
  matched,
  loadingQuestions,
  playing,
  submitting,
  timeout,
  finishing,
  completed,
  disconnected,
  abandoned,
  error,
}

class QuizMatchController extends GetxController {
  QuizMatchController({
    required QuizRepository quizRepository,
    required QuizMatchRealtimeDataSource realtimeDataSource,
    AuthController? authController,
    int questionDurationSeconds = _defaultQuestionDurationSeconds,
    Duration questionTimerTick = const Duration(seconds: 1),
    Duration submissionAdvanceDelay = const Duration(milliseconds: 300),
    Duration timeoutAdvanceDelay = const Duration(milliseconds: 500),
  }) : _quizRepository = quizRepository,
       _realtimeDataSource = realtimeDataSource,
       _authController = authController,
       _questionDurationSeconds = questionDurationSeconds < 1
           ? 1
           : questionDurationSeconds,
       _questionTimerTick = questionTimerTick,
       _submissionAdvanceDelay = submissionAdvanceDelay,
       _timeoutAdvanceDelay = timeoutAdvanceDelay;

  static const defaultQuestionDurationSeconds =
      _defaultQuestionDurationSeconds;

  final QuizRepository _quizRepository;
  final QuizMatchRealtimeDataSource _realtimeDataSource;
  final AuthController? _authController;
  final int _questionDurationSeconds;
  final Duration _questionTimerTick;
  final Duration _submissionAdvanceDelay;
  final Duration _timeoutAdvanceDelay;

  final phase = QuizMatchPhase.idle.obs;
  final quizId = RxnString();
  final matchId = RxnString();
  final matchEvent = Rxn<QuizMatchEvent>();
  final questions = <QuizQuestion>[].obs;
  final currentQuestionIndex = 0.obs;
  final selectedOptionId = RxnString();
  final submittedQuestionIds = <String>{}.obs;
  late final RxInt timeRemaining = _questionDurationSeconds.obs;
  final opponentAnswered = false.obs;
  final errorMessage = RxnString();

  StreamSubscription<QuizMatchEvent>? _matchEventsSubscription;
  StreamSubscription<RealtimeConnectionState>? _connectionSubscription;
  StreamSubscription<RealtimeErrorEvent>? _errorSubscription;
  Timer? _questionTimer;
  Timer? _finishTimeoutTimer;
  Timer? _statusResetTimer;

  final _seenEventKeys = <String>{};
  String? _lastOpponentId;
  int? _lastOpponentScore;
  bool _finishSent = false;
  bool _loadingQuestionSet = false;
  bool _isLeaving = false;
  QuizMatchPhase? _phaseBeforeDisconnect;

  QuizMatchPhase get currentPhase => phase.value;
  QuizQuestion? get currentQuestion {
    final index = currentQuestionIndex.value;
    if (index < 0 || index >= questions.length) return null;
    return questions[index];
  }

  QuizMatchPlayer? get opponent => matchEvent.value?.opponentFor(
    _authController?.currentUser.value?.id,
  );

  String? get currentUserId => _authController?.currentUser.value?.id;

  int get playerScore {
    final event = matchEvent.value;
    final userId = _authController?.currentUser.value?.id;
    if (event == null || userId == null) return 0;
    return event.player1.id == userId
        ? event.player1.score
        : event.player2?.id == userId
        ? event.player2!.score
        : 0;
  }

  int get opponentScore => opponent?.score ?? 0;

  bool get isActive =>
      matchId.value != null &&
      phase.value != QuizMatchPhase.idle &&
      phase.value != QuizMatchPhase.completed &&
      phase.value != QuizMatchPhase.error &&
      phase.value != QuizMatchPhase.abandoned;

  bool get _hasLiveFlow =>
      phase.value != QuizMatchPhase.idle &&
      phase.value != QuizMatchPhase.completed &&
      phase.value != QuizMatchPhase.error &&
      phase.value != QuizMatchPhase.abandoned;

  @override
  void onInit() {
    super.onInit();
    _matchEventsSubscription = _realtimeDataSource.events.listen(
      (event) => unawaited(_handleMatchEvent(event)),
      onError: (Object error, StackTrace stack) {
        _setError(error.toString());
      },
    );
    _connectionSubscription = _realtimeDataSource.connectionStates.listen(
      _handleConnectionState,
    );
    _errorSubscription = _realtimeDataSource.errors.listen(
      (error) => _setError(error.message),
    );
  }

  Future<void> startMatch(String selectedQuizId) async {
    final normalizedQuizId = selectedQuizId.trim();
    if (normalizedQuizId.isEmpty || phase.value == QuizMatchPhase.connecting) {
      return;
    }
    if (isActive || phase.value == QuizMatchPhase.waiting) {
      return;
    }

    _resetMatchState();
    quizId.value = normalizedQuizId;
    phase.value = QuizMatchPhase.connecting;

    try {
      final connected = await _realtimeDataSource.connect();
      if (!connected) {
        _setError('Unable to connect to the realtime quiz service.');
        return;
      }
      phase.value = QuizMatchPhase.matchmaking;
      await _realtimeDataSource.findMatch(normalizedQuizId);
    } catch (error, stack) {
      _debug('Unable to start match: $error\n$stack');
      _setError(_messageForError(error));
    }
  }

  bool canSelectAnswer(String optionId) {
    final question = currentQuestion;
    if (question == null || phase.value != QuizMatchPhase.playing) return false;
    if (submittedQuestionIds.contains(question.id)) return false;
    return question.options.any((option) => option.id == optionId);
  }

  Future<void> selectAnswer(String optionId) async {
    final question = currentQuestion;
    final activeMatchId = matchId.value;
    if (question == null || activeMatchId == null || !canSelectAnswer(optionId)) {
      return;
    }

    selectedOptionId.value = optionId;
    submittedQuestionIds.add(question.id);
    _questionTimer?.cancel();
    phase.value = QuizMatchPhase.submitting;

    try {
      await _realtimeDataSource.submitAnswer(
        matchId: activeMatchId,
        questionId: question.id,
        optionId: optionId,
      );
      phase.value = QuizMatchPhase.submitting;
      await _advanceAfterLocalSubmission();
    } catch (error, stack) {
      submittedQuestionIds.remove(question.id);
      phase.value = QuizMatchPhase.playing;
      _debug('Unable to submit match answer: $error\n$stack');
      _setError(_messageForError(error));
    }
  }

  Future<void> leaveMatch() async {
    _isLeaving = true;
    _cancelTimers();
    final activeMatchId = matchId.value;
    if (activeMatchId != null) {
      await _realtimeDataSource.unsubscribeMatch(activeMatchId);
    }
    _resetMatchState();
    _isLeaving = false;
  }

  void retry() {
    final selectedQuizId = quizId.value;
    if (selectedQuizId == null || selectedQuizId.isEmpty) {
      _resetMatchState();
      return;
    }
    unawaited(_restartMatch(selectedQuizId));
  }

  Future<void> _restartMatch(String selectedQuizId) async {
    final previousMatchId = matchId.value;
    if (previousMatchId != null) {
      try {
        await _realtimeDataSource.unsubscribeMatch(previousMatchId);
      } catch (error, stack) {
        _debug(
          'Unable to clear the previous match subscription: $error\n$stack',
        );
      }
    }
    if (_isLeaving) return;
    _resetMatchState();
    await startMatch(selectedQuizId);
  }

  @override
  void onClose() {
    _isLeaving = true;
    _cancelTimers();
    final activeMatchId = matchId.value;
    if (activeMatchId != null) {
      unawaited(_realtimeDataSource.unsubscribeMatch(activeMatchId));
    }
    final matchEventsSubscription = _matchEventsSubscription;
    if (matchEventsSubscription != null) {
      unawaited(matchEventsSubscription.cancel());
    }
    final connectionSubscription = _connectionSubscription;
    if (connectionSubscription != null) {
      unawaited(connectionSubscription.cancel());
    }
    final errorSubscription = _errorSubscription;
    if (errorSubscription != null) {
      unawaited(errorSubscription.cancel());
    }
    super.onClose();
  }

  Future<void> _handleMatchEvent(QuizMatchEvent event) async {
    if (_isLeaving || event.matchId.isEmpty || event.quizId.isEmpty) return;
    final activeMatchId = matchId.value;
    if (activeMatchId != null && activeMatchId != event.matchId) return;

    final isDuplicate = !_seenEventKeys.add(event.eventKey);
    if (_seenEventKeys.length > 100) {
      _seenEventKeys.remove(_seenEventKeys.first);
    }

    final previousOpponentId = _lastOpponentId;
    final previousOpponentScore = _lastOpponentScore;
    final nextOpponent = event.opponentFor(
      _authController?.currentUser.value?.id,
    );
    _lastOpponentId = nextOpponent?.id;
    _lastOpponentScore = nextOpponent?.score;
    matchEvent.value = event;
    matchId.value = event.matchId;
    quizId.value = event.quizId;

    final opponentScoreChanged = previousOpponentId == nextOpponent?.id &&
        previousOpponentScore != null &&
        previousOpponentScore != nextOpponent?.score;
    if (opponentScoreChanged) {
      opponentAnswered.value = true;
      _statusResetTimer?.cancel();
      _statusResetTimer = Timer(const Duration(milliseconds: 900), () {
        opponentAnswered.value = false;
      });
    }

    if (isDuplicate) return;

    switch (event.status) {
      case QuizMatchStatus.waiting:
        phase.value = QuizMatchPhase.waiting;
      case QuizMatchStatus.inProgress:
        await _handleMatchStarted(event);
      case QuizMatchStatus.completed:
        await _handleMatchCompleted(event);
      case QuizMatchStatus.abandoned:
        _cancelTimers();
        phase.value = QuizMatchPhase.abandoned;
      case QuizMatchStatus.unknown:
        _setError('The server returned an unknown match status.');
    }
  }

  Future<void> _handleMatchStarted(QuizMatchEvent event) async {
    final subscribed = await _realtimeDataSource.subscribeMatch(event.matchId);
    if (!subscribed) {
      _setError('Unable to subscribe to the quiz match.');
      return;
    }
    if (_loadingQuestionSet ||
        (questions.isNotEmpty && quizId.value == event.quizId)) {
      if (phase.value == QuizMatchPhase.disconnected) {
        phase.value = QuizMatchPhase.playing;
        _startQuestionTimer();
      }
      return;
    }

    _loadingQuestionSet = true;
    phase.value = QuizMatchPhase.matched;
    phase.value = QuizMatchPhase.loadingQuestions;
    try {
      final loadedQuestions = await _quizRepository.getQuizDetails(event.quizId);
      if (_isLeaving || matchId.value != event.matchId) return;
      if (loadedQuestions.isEmpty) {
        _setError('No questions are available for this match.');
        return;
      }
      questions.assignAll(loadedQuestions);
      currentQuestionIndex.value = 0;
      selectedOptionId.value = null;
      submittedQuestionIds.clear();
      _finishSent = false;
      phase.value = QuizMatchPhase.playing;
      _startQuestionTimer();
    } catch (error, stack) {
      _debug('Unable to load multiplayer questions: $error\n$stack');
      _setError(_messageForError(error));
    } finally {
      _loadingQuestionSet = false;
    }
  }

  Future<void> _handleMatchCompleted(QuizMatchEvent event) async {
    _cancelTimers();
    matchEvent.value = event;
    phase.value = QuizMatchPhase.completed;
    final activeMatchId = matchId.value;
    if (activeMatchId != null) {
      await _realtimeDataSource.unsubscribeMatch(activeMatchId);
    }
    await _authController?.refreshCurrentUser();
  }

  Future<void> _advanceAfterLocalSubmission() async {
    await Future<void>.delayed(_submissionAdvanceDelay);
    if (_isLeaving || phase.value != QuizMatchPhase.submitting) return;
    _advanceQuestion();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    timeRemaining.value = _questionDurationSeconds;
    _questionTimer = Timer.periodic(_questionTimerTick, (timer) {
      if (_isLeaving || phase.value != QuizMatchPhase.playing) {
        timer.cancel();
        return;
      }
      timeRemaining.value--;
      if (timeRemaining.value <= 0) {
        timer.cancel();
        unawaited(_handleTimeout());
      }
    });
  }

  Future<void> _handleTimeout() async {
    final question = currentQuestion;
    if (question == null || submittedQuestionIds.contains(question.id)) return;
    phase.value = QuizMatchPhase.timeout;
    await Future<void>.delayed(_timeoutAdvanceDelay);
    if (_isLeaving || phase.value != QuizMatchPhase.timeout) return;
    _advanceQuestion();
  }

  void _advanceQuestion() {
    _questionTimer?.cancel();
    selectedOptionId.value = null;
    opponentAnswered.value = false;
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      phase.value = QuizMatchPhase.playing;
      _startQuestionTimer();
      return;
    }
    unawaited(_finishMatch());
  }

  Future<void> _finishMatch() async {
    final activeMatchId = matchId.value;
    if (activeMatchId == null || _finishSent) return;
    _finishSent = true;
    phase.value = QuizMatchPhase.finishing;
    _finishTimeoutTimer?.cancel();
    _finishTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (phase.value == QuizMatchPhase.finishing) {
        _setError('The match result did not arrive in time.');
      }
    });
    try {
      await _realtimeDataSource.finishMatch(activeMatchId);
    } catch (error, stack) {
      _debug('Unable to finish match: $error\n$stack');
      _setError(_messageForError(error));
    }
  }

  void _handleConnectionState(RealtimeConnectionState state) {
    if (_isLeaving || !_hasLiveFlow) return;
    switch (state) {
      case RealtimeConnectionState.connected:
        if (phase.value == QuizMatchPhase.disconnected) {
          final previousPhase = _phaseBeforeDisconnect;
          phase.value = switch (previousPhase) {
            QuizMatchPhase.finishing => QuizMatchPhase.finishing,
            QuizMatchPhase.matchmaking || QuizMatchPhase.connecting =>
              QuizMatchPhase.matchmaking,
            _ => questions.isEmpty
                ? QuizMatchPhase.waiting
                : QuizMatchPhase.playing,
          };
          if (phase.value == QuizMatchPhase.playing) _startQuestionTimer();
          _phaseBeforeDisconnect = null;
        }
      case RealtimeConnectionState.connecting:
      case RealtimeConnectionState.reconnecting:
        if (phase.value != QuizMatchPhase.disconnected) {
          _phaseBeforeDisconnect = phase.value;
        }
        phase.value = QuizMatchPhase.disconnected;
        _questionTimer?.cancel();
      case RealtimeConnectionState.disconnected:
      case RealtimeConnectionState.error:
        if (phase.value != QuizMatchPhase.disconnected) {
          _phaseBeforeDisconnect = phase.value;
        }
        phase.value = QuizMatchPhase.disconnected;
        _questionTimer?.cancel();
    }
  }

  void _setError(String message) {
    if (_isLeaving) return;
    _cancelTimers();
    errorMessage.value = message.trim().isEmpty
        ? 'The multiplayer quiz is unavailable right now.'
        : message;
    phase.value = QuizMatchPhase.error;
  }

  String _messageForError(Object error) {
    final value = error.toString().trim();
    return value.isEmpty
        ? 'The multiplayer quiz is unavailable right now.'
        : value;
  }

  void _resetMatchState() {
    _cancelTimers();
    _seenEventKeys.clear();
    _lastOpponentId = null;
    _lastOpponentScore = null;
    _finishSent = false;
    _loadingQuestionSet = false;
    _phaseBeforeDisconnect = null;
    phase.value = QuizMatchPhase.idle;
    quizId.value = null;
    matchId.value = null;
    matchEvent.value = null;
    questions.clear();
    currentQuestionIndex.value = 0;
    selectedOptionId.value = null;
    submittedQuestionIds.clear();
    opponentAnswered.value = false;
    errorMessage.value = null;
    timeRemaining.value = _questionDurationSeconds;
  }

  void _cancelTimers() {
    _questionTimer?.cancel();
    _questionTimer = null;
    _finishTimeoutTimer?.cancel();
    _finishTimeoutTimer = null;
    _statusResetTimer?.cancel();
    _statusResetTimer = null;
  }

  void _debug(String message) {
    if (kDebugMode) debugPrint('[QuizMatch] $message');
  }
}
