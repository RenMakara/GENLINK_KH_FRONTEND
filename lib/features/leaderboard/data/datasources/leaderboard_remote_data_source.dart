import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/leaderboard_models.dart';

abstract class LeaderboardRemoteDataSource {
  Future<LeaderboardResponse> getLeaderboard({
    required LeaderboardCategory category,
    required LeaderboardPeriod period,
  });
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  const LeaderboardRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<LeaderboardResponse> getLeaderboard({
    required LeaderboardCategory category,
    required LeaderboardPeriod period,
  }) {
    return _apiClient.get(
      ApiEndpoints.leaderboards,
      query: {'category': category.apiValue, 'period': period.apiValue},
      parse: (data) => LeaderboardResponse.fromJson(ApiClient.asMap(data)),
    );
  }
}
