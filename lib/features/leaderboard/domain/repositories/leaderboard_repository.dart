import '../models/leaderboard_models.dart';

abstract class LeaderboardRepository {
  Future<LeaderboardResponse> getLeaderboard({
    required LeaderboardCategory category,
    required LeaderboardPeriod period,
  });
}
