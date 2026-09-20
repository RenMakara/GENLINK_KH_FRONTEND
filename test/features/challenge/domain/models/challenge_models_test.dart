import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/challenge/domain/models/challenge_models.dart';

void main() {
  test('parses the backend ChallengeResponse contract', () {
    final challenge = ChallengeModel.fromJson({
      'challengeId': 'challenge-1',
      'title': 'Complete a quiz',
      'description': 'Answer today\'s questions',
      'challengeType': 'QUIZ',
      'xpReward': 40,
      'deadline': '2026-09-20T12:30:00',
      'status': 'IN_PROGRESS',
      'progress': 60,
    });

    expect(challenge.challengeId, 'challenge-1');
    expect(challenge.title, 'Complete a quiz');
    expect(challenge.challengeType, ChallengeType.quiz);
    expect(challenge.xpReward, 40);
    expect(challenge.deadline, DateTime.parse('2026-09-20T12:30:00'));
    expect(challenge.status, ChallengeStatus.inProgress);
    expect(challenge.progress, 60);
    expect(challenge.isJoined, isTrue);
    expect(challenge.isCompleted, isFalse);
  });

  test('maps all backend statuses and unknown values safely', () {
    expect(challengeStatusFromWire('NOT_STARTED'), ChallengeStatus.notStarted);
    expect(challengeStatusFromWire('IN_PROGRESS'), ChallengeStatus.inProgress);
    expect(challengeStatusFromWire('COMPLETED'), ChallengeStatus.completed);
    expect(challengeStatusFromWire('CLAIMED'), ChallengeStatus.claimed);
    expect(challengeStatusFromWire('unexpected'), ChallengeStatus.unknown);
  });
}
