import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/app_realtime_service.dart';
import 'package:genlink_frontend/features/quiz/data/datasources/quiz_match_realtime_data_source.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_match_models.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';
import 'package:genlink_frontend/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:genlink_frontend/features/quiz/presentation/controllers/quiz_match_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockQuizRepository extends Mock implements QuizRepository {}

class _FakeQuizMatchRealtimeDataSource
    implements QuizMatchRealtimeDataSource {
  final _eventController = StreamController<QuizMatchEvent>.broadcast();
  final _connectionController =
      StreamController<RealtimeConnectionState>.broadcast();
  final _errorController = StreamController<RealtimeErrorEvent>.broadcast();

  final findMatchQuizIds = <String>[];
  final subscribedMatchIds = <String>[];
  final unsubscribedMatchIds = <String>[];
  final submittedAnswers = <({String matchId, String questionId, String? optionId})>[];
  final finishedMatchIds = <String>[];

  bool connectionAvailable = true;

  @override
  Stream<QuizMatchEvent> get events => _eventController.stream;

  @override
  Stream<RealtimeConnectionState> get connectionStates =>
      _connectionController.stream;

  @override
  Stream<RealtimeErrorEvent> get errors => _errorController.stream;

  @override
  Future<bool> connect() async => connectionAvailable;

  @override
  Future<void> findMatch(String quizId) async {
    findMatchQuizIds.add(quizId);
  }

  @override
  Future<bool> subscribeMatch(String matchId) async {
    subscribedMatchIds.add(matchId);
    return true;
  }

  @override
  Future<void> unsubscribeMatch(String matchId) async {
    unsubscribedMatchIds.add(matchId);
  }

  @override
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String? optionId,
  }) async {
    submittedAnswers.add(
      (matchId: matchId, questionId: questionId, optionId: optionId),
    );
  }

  @override
  Future<void> finishMatch(String matchId) async {
    finishedMatchIds.add(matchId);
  }

  void emitEvent(QuizMatchEvent event) => _eventController.add(event);

  void emitConnectionState(RealtimeConnectionState state) =>
      _connectionController.add(state);

  void emitError(RealtimeErrorEvent error) => _errorController.add(error);

  Future<void> close() async {
    await _eventController.close();
    await _connectionController.close();
    await _errorController.close();
  }
}

const _questions = [
  QuizQuestion(
    id: 'question-1',
    question: 'First question',
    options: [
      QuizOptionModel(id: 'option-1', text: 'First answer'),
      QuizOptionModel(id: 'option-2', text: 'Second answer'),
    ],
  ),
  QuizQuestion(
    id: 'question-2',
    question: 'Second question',
    options: [
      QuizOptionModel(id: 'option-3', text: 'Third answer'),
      QuizOptionModel(id: 'option-4', text: 'Fourth answer'),
    ],
  ),
];

const _singleQuestion = [
  QuizQuestion(
    id: 'question-1',
    question: 'First question',
    options: [
      QuizOptionModel(id: 'option-1', text: 'First answer'),
      QuizOptionModel(id: 'option-2', text: 'Second answer'),
    ],
  ),
];

QuizMatchEvent _event({
  required QuizMatchStatus status,
  int player1Score = 0,
  int player2Score = 0,
  String? winnerId,
}) {
  return QuizMatchEvent(
    matchId: 'match-1',
    quizId: 'quiz-1',
    status: status,
    player1: QuizMatchPlayer(
      id: 'user-1',
      name: 'Player One',
      score: player1Score,
    ),
    player2: QuizMatchPlayer(
      id: 'user-2',
      name: 'Player Two',
      score: player2Score,
    ),
    winnerId: winnerId,
  );
}

Future<void> _settleStreamWork() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockQuizRepository quizRepository;
  late _FakeQuizMatchRealtimeDataSource realtime;
  late QuizMatchController controller;

  setUp(() {
    quizRepository = _MockQuizRepository();
    realtime = _FakeQuizMatchRealtimeDataSource();
    when(
      () => quizRepository.getQuizDetails('quiz-1'),
    ).thenAnswer((_) async => _questions);
    controller = QuizMatchController(
      quizRepository: quizRepository,
      realtimeDataSource: realtime,
      questionDurationSeconds: 15,
      submissionAdvanceDelay: Duration.zero,
      timeoutAdvanceDelay: Duration.zero,
    )..onInit();
  });

  tearDown(() async {
    controller.onClose();
    await realtime.close();
  });

  Future<void> startPlaying() async {
    await controller.startMatch('quiz-1');
    realtime.emitEvent(_event(status: QuizMatchStatus.waiting));
    await _settleStreamWork();
    realtime.emitEvent(_event(status: QuizMatchStatus.inProgress));
    await _settleStreamWork();
  }

  test('moves from connection to matchmaking and waiting states', () async {
    await controller.startMatch('quiz-1');

    expect(controller.phase.value, QuizMatchPhase.matchmaking);
    expect(realtime.findMatchQuizIds, ['quiz-1']);

    realtime.emitEvent(_event(status: QuizMatchStatus.waiting));
    await _settleStreamWork();

    expect(controller.phase.value, QuizMatchPhase.waiting);
    expect(controller.matchId.value, 'match-1');
  });

  test('loads questions once when a match becomes in progress', () async {
    await startPlaying();

    expect(controller.phase.value, QuizMatchPhase.playing);
    expect(controller.questions.toList(), _questions);
    expect(controller.currentQuestionIndex.value, 0);
    expect(realtime.subscribedMatchIds, ['match-1']);

    realtime.emitEvent(_event(status: QuizMatchStatus.inProgress));
    await _settleStreamWork();

    verify(() => quizRepository.getQuizDetails('quiz-1')).called(1);
  });

  test('submits one answer and advances without allowing duplicates', () async {
    await startPlaying();

    final first = controller.selectAnswer('option-1');
    final duplicate = controller.selectAnswer('option-2');
    await Future.wait([first, duplicate]);

    expect(realtime.submittedAnswers, [
      (matchId: 'match-1', questionId: 'question-1', optionId: 'option-1'),
    ]);
    expect(controller.currentQuestionIndex.value, 1);
    expect(controller.phase.value, QuizMatchPhase.playing);
  });

  test('updates and expires the local question timer', () async {
    final previousRealtime = realtime;
    realtime = _FakeQuizMatchRealtimeDataSource();
    when(
      () => quizRepository.getQuizDetails('quiz-1'),
    ).thenAnswer((_) async => _questions);
    controller.onClose();
    await previousRealtime.close();
    controller = QuizMatchController(
      quizRepository: quizRepository,
      realtimeDataSource: realtime,
      questionDurationSeconds: 2,
      questionTimerTick: const Duration(milliseconds: 10),
      timeoutAdvanceDelay: const Duration(milliseconds: 50),
    )..onInit();

    await startPlaying();
    expect(controller.timeRemaining.value, 2);

    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(controller.timeRemaining.value, lessThan(2));
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(controller.currentQuestionIndex.value, 1);
  });

  test('finishes the match and handles the completed result event', () async {
    when(
      () => quizRepository.getQuizDetails('quiz-1'),
    ).thenAnswer((_) async => _singleQuestion);
    await startPlaying();

    await controller.selectAnswer('option-1');
    await _settleStreamWork();

    expect(controller.phase.value, QuizMatchPhase.finishing);
    expect(realtime.finishedMatchIds, ['match-1']);

    realtime.emitEvent(
      _event(
        status: QuizMatchStatus.completed,
        player1Score: 10,
        winnerId: 'user-1',
      ),
    );
    await _settleStreamWork();

    expect(controller.phase.value, QuizMatchPhase.completed);
    expect(realtime.unsubscribedMatchIds, ['match-1']);
  });

  test('moves to disconnected and error states from realtime events', () async {
    await startPlaying();

    realtime.emitConnectionState(RealtimeConnectionState.reconnecting);
    await _settleStreamWork();
    expect(controller.phase.value, QuizMatchPhase.disconnected);

    realtime.emitConnectionState(RealtimeConnectionState.connected);
    await _settleStreamWork();
    expect(controller.phase.value, QuizMatchPhase.playing);

    realtime.emitConnectionState(RealtimeConnectionState.reconnecting);
    await _settleStreamWork();
    expect(controller.phase.value, QuizMatchPhase.disconnected);

    realtime.emitError(
      const RealtimeErrorEvent(message: 'broker rejected the frame'),
    );
    await _settleStreamWork();
    expect(controller.phase.value, QuizMatchPhase.error);
    expect(controller.errorMessage.value, 'broker rejected the frame');
  });
}
