import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/leaderboard/domain/models/leaderboard_models.dart';

void main() {
  test('parses and preserves the backend leaderboard contract', () {
    final response = LeaderboardResponse.fromJson({
      'category': 'QUIZ_PERFORMANCE',
      'period': 'MONTHLY',
      'entries': [
        {
          'rank': 1,
          'userId': 'user-1',
          'name': 'Learner',
          'avatarUrl': 'https://example.test/avatar.png',
          'level': 4,
          'points': 320,
        },
      ],
      'me': {'rank': 1, 'points': 320},
    });

    final normalized = response.markCurrentUserByRank();
    final entry = normalized.entries.single;

    expect(normalized.category, LeaderboardCategory.quizPerformance);
    expect(normalized.period, LeaderboardPeriod.monthly);
    expect(entry.userId, 'user-1');
    expect(entry.name, 'Learner');
    expect(entry.avatarUrl, 'https://example.test/avatar.png');
    expect(entry.rank, 1);
    expect(entry.level, 4);
    expect(entry.points, 320);
    expect(entry.isCurrentUser, isTrue);
    expect(normalized.me?.rank, 1);
    expect(normalized.me?.points, 320);
  });
}
