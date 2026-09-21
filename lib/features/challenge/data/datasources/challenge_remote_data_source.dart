import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/challenge_models.dart';

abstract class ChallengeRemoteDataSource {
  Future<List<ChallengeModel>> getActiveChallenges();

  Future<List<ChallengeModel>> getMyChallenges();

  Future<ChallengeModel> joinChallenge(String challengeId);

  Future<ChallengeModel> completeChallenge(String challengeId);

  Future<ChallengeModel> claimReward(String challengeId);
}

class ChallengeRemoteDataSourceImpl implements ChallengeRemoteDataSource {
  const ChallengeRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ChallengeModel>> getActiveChallenges() {
    return _apiClient.get(
      ApiEndpoints.challenges,
      parse: (data) => ApiClient.asList(data, ChallengeModel.fromJson),
    );
  }

  @override
  Future<List<ChallengeModel>> getMyChallenges() {
    return _apiClient.get(
      ApiEndpoints.myChallenges,
      parse: (data) => ApiClient.asList(data, ChallengeModel.fromJson),
    );
  }

  @override
  Future<ChallengeModel> joinChallenge(String challengeId) {
    return _apiClient.post(
      ApiEndpoints.challengeJoin(challengeId),
      parse: (data) => ChallengeModel.fromJson(ApiClient.asMap(data)),
    );
  }

  @override
  Future<ChallengeModel> completeChallenge(String challengeId) {
    return _apiClient.post(
      ApiEndpoints.challengeComplete(challengeId),
      parse: (data) => ChallengeModel.fromJson(ApiClient.asMap(data)),
    );
  }

  @override
  Future<ChallengeModel> claimReward(String challengeId) {
    return _apiClient.post(
      ApiEndpoints.challengeClaim(challengeId),
      parse: (data) => ChallengeModel.fromJson(ApiClient.asMap(data)),
    );
  }
}
