import '../../../../core/network/app_realtime_service.dart';
import '../../domain/models/quiz_match_models.dart';

abstract class QuizMatchRealtimeDataSource {
  Stream<QuizMatchEvent> get events;
  Stream<RealtimeConnectionState> get connectionStates;
  Stream<RealtimeErrorEvent> get errors;

  Future<bool> connect();
  Future<void> findMatch(String quizId);
  Future<bool> subscribeMatch(String matchId);
  Future<void> unsubscribeMatch(String matchId);
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  });
  Future<void> finishMatch(String matchId);
}

class QuizMatchRealtimeDataSourceImpl implements QuizMatchRealtimeDataSource {
  const QuizMatchRealtimeDataSourceImpl(this._realtimeService);

  final AppRealtimeService _realtimeService;

  @override
  Stream<QuizMatchEvent> get events =>
      _realtimeService.matchStream.map(QuizMatchEvent.fromJson);

  @override
  Stream<RealtimeConnectionState> get connectionStates =>
      _realtimeService.connectionStateStream;

  @override
  Stream<RealtimeErrorEvent> get errors => _realtimeService.errorStream;

  @override
  Future<bool> connect() => _realtimeService.ensureConnected();

  @override
  Future<void> findMatch(String quizId) {
    return _realtimeService.sendStompMessage(
      '/app/quiz/matchmake/$quizId',
    );
  }

  @override
  Future<bool> subscribeMatch(String matchId) {
    return _realtimeService.subscribeQuizMatch(matchId);
  }

  @override
  Future<void> unsubscribeMatch(String matchId) {
    return _realtimeService.unsubscribeQuizMatch(matchId);
  }

  @override
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  }) {
    return _realtimeService.sendStompMessage(
      '/app/quiz/match/$matchId/submit',
      body: {
        'questionId': questionId,
        'optionId': optionId,
      },
    );
  }

  @override
  Future<void> finishMatch(String matchId) {
    return _realtimeService.sendStompMessage(
      '/app/quiz/match/$matchId/finish',
    );
  }
}
