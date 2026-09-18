import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/app_realtime_service.dart';
import 'package:genlink_frontend/features/quiz/data/datasources/quiz_match_realtime_data_source.dart';

class _SpyRealtimeService extends AppRealtimeService {
  final sentMessages = <({String destination, Map<String, dynamic>? body})>[];
  final subscribedMatchIds = <String>[];
  final unsubscribedMatchIds = <String>[];

  @override
  Stream<Map<String, dynamic>> get matchStream => const Stream.empty();

  @override
  Stream<RealtimeConnectionState> get connectionStateStream =>
      const Stream.empty();

  @override
  Stream<RealtimeErrorEvent> get errorStream => const Stream.empty();

  @override
  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 12),
  }) async => true;

  @override
  Future<void> sendStompMessage(
    String destination, {
    Map<String, dynamic>? body,
  }) async {
    sentMessages.add((destination: destination, body: body));
  }

  @override
  Future<bool> subscribeQuizMatch(String matchId) async {
    subscribedMatchIds.add(matchId);
    return true;
  }

  @override
  Future<void> unsubscribeQuizMatch(String matchId) async {
    unsubscribedMatchIds.add(matchId);
  }
}

void main() {
  test('uses the backend quiz STOMP destinations and payload fields', () async {
    final realtime = _SpyRealtimeService();
    final dataSource = QuizMatchRealtimeDataSourceImpl(realtime);

    await dataSource.findMatch('quiz-1');
    expect(await dataSource.subscribeMatch('match-1'), isTrue);
    await dataSource.submitAnswer(
      matchId: 'match-1',
      questionId: 'question-1',
      optionId: 'option-1',
    );
    await dataSource.finishMatch('match-1');
    await dataSource.unsubscribeMatch('match-1');

    expect(realtime.sentMessages, [
      (destination: '/app/quiz/matchmake/quiz-1', body: null),
      (
        destination: '/app/quiz/match/match-1/submit',
        body: {'questionId': 'question-1', 'optionId': 'option-1'},
      ),
      (destination: '/app/quiz/match/match-1/finish', body: null),
    ]);
    expect(realtime.subscribedMatchIds, ['match-1']);
    expect(realtime.unsubscribedMatchIds, ['match-1']);
  });
}
