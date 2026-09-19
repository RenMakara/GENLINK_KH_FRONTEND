import '../../domain/models/leaderboard_models.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  const LeaderboardRepositoryImpl(this._remoteDataSource);

  final LeaderboardRemoteDataSource _remoteDataSource;

  @override
  Future<LeaderboardResponse> getLeaderboard({
    required LeaderboardCategory category,
    required LeaderboardPeriod period,
  }) {
    return _remoteDataSource.getLeaderboard(category: category, period: period);
  }
}
