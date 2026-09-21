import '../../domain/models/challenge_models.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_remote_data_source.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  const ChallengeRepositoryImpl(this._remoteDataSource);

  final ChallengeRemoteDataSource _remoteDataSource;

  @override
  Future<List<ChallengeModel>> getActiveChallenges() {
    return _remoteDataSource.getActiveChallenges();
  }

  @override
  Future<List<ChallengeModel>> getMyChallenges() {
    return _remoteDataSource.getMyChallenges();
  }

  @override
  Future<ChallengeModel> joinChallenge(String challengeId) {
    return _remoteDataSource.joinChallenge(challengeId);
  }

  @override
  Future<ChallengeModel> completeChallenge(String challengeId) {
    return _remoteDataSource.completeChallenge(challengeId);
  }

  @override
  Future<ChallengeModel> claimReward(String challengeId) {
    return _remoteDataSource.claimReward(challengeId);
  }
}
