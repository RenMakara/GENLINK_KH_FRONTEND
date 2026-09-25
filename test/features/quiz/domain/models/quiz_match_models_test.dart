import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_match_models.dart';

void main() {
  const payload = {
    'matchId': 'match-1',
    'quizId': 'quiz-1',
    'status': 'IN_PROGRESS',
    'player1Id': 'user-1',
    'player1Name': 'Player One',
    'player1Score': 10,
    'player2Id': 'user-2',
    'player2Name': 'Player Two',
    'player2Score': 0,
    'winnerId': null,
  };

  test('parses the backend MatchEvent contract', () {
    final event = QuizMatchEvent.fromJson(payload);

    expect(event.matchId, 'match-1');
    expect(event.quizId, 'quiz-1');
    expect(event.status, QuizMatchStatus.inProgress);
    expect(event.player1.id, 'user-1');
    expect(event.player1.score, 10);
    expect(event.player2?.id, 'user-2');
    expect(event.player2?.score, 0);
  });

  test('resolves the opponent from either participant identity', () {
    final event = QuizMatchEvent.fromJson(payload);

    expect(event.opponentFor('user-1')?.id, 'user-2');
    expect(event.opponentFor('user-2')?.id, 'user-1');
  });

  test('creates a stable deduplication key for repeated events', () {
    final first = QuizMatchEvent.fromJson(payload);
    final second = QuizMatchEvent.fromJson({...payload});

    expect(first.eventKey, second.eventKey);
    expect(quizMatchStatusFromWire('WAITING'), QuizMatchStatus.waiting);
    expect(quizMatchStatusFromWire('COMPLETED'), QuizMatchStatus.completed);
    expect(quizMatchStatusFromWire('not-a-status'), QuizMatchStatus.unknown);
  });
}
