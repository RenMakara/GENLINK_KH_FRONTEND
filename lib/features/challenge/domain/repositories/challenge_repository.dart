import '../models/challenge_models.dart';

abstract class ChallengeRepository {
  Future<List<ChallengeModel>> getActiveChallenges();

  Future<List<ChallengeModel>> getMyChallenges();

  Future<ChallengeModel> joinChallenge(String challengeId);

  Future<ChallengeModel> completeChallenge(String challengeId);

  Future<ChallengeModel> claimReward(String challengeId);
}
