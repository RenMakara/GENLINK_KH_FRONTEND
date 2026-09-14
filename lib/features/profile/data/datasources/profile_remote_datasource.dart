import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/profile_entity.dart';
import '../models/profile_models.dart';

class ProfileRemoteDatasource {
  const ProfileRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ProfileEntity> getMyProfile() {
    return _client.get(
      ApiEndpoints.profileMe,
      parse: (data) => ProfileMapper.profile(ApiClient.asMap(data)),
    );
  }

  Future<ProfileEntity> updateProfile(Map<String, dynamic> body) {
    return _client.put(
      ApiEndpoints.profileMe,
      body: body,
      parse: (data) => ProfileMapper.profile(ApiClient.asMap(data)),
    );
  }

  Future<ProfileEntity> updateAvatarFromMedia(String mediaId) {
    return _client.post(
      ApiEndpoints.profileAvatar,
      body: {'avatarMediaId': mediaId},
      parse: (data) => ProfileMapper.profile(ApiClient.asMap(data)),
    );
  }

  Future<ProfileEntity> updateAvatar(String avatarUrl) {
    return _client.post(
      ApiEndpoints.profileAvatar,
      body: {'avatarUrl': avatarUrl},
      parse: (data) => ProfileMapper.profile(ApiClient.asMap(data)),
    );
  }

  Future<PublicProfileEntity> getPublicProfile(String username) {
    return _client.get(
      ApiEndpoints.publicProfile(username),
      parse: (data) => ProfileMapper.publicProfile(ApiClient.asMap(data)),
    );
  }

  Future<FollowStatsEntity> getFollowStats(String userId) {
    return _client.get(
      ApiEndpoints.communityFollowStats(userId),
      parse: (data) => ProfileMapper.followStats(ApiClient.asMap(data)),
    );
  }

  Future<String?> followUser(String userId) {
    return _client.post<String?>(
      ApiEndpoints.communityFollowUser(userId),
      parse: (data) => ApiClient.asMap(data)['status'] as String?,
    );
  }

  Future<void> unfollowUser(String userId) {
    return _client.delete(ApiEndpoints.communityFollowUser(userId));
  }

  Future<List<InterestEntity>> getInterestCatalog() {
    return _client.get(
      ApiEndpoints.interestCatalog,
      parse: (data) => ApiClient.asList(data, ProfileMapper.interest),
    );
  }

  Future<List<InterestEntity>> getMyInterests() {
    return _client.get(
      ApiEndpoints.profileInterests,
      parse: (data) => ApiClient.asList(data, ProfileMapper.interest),
    );
  }

  Future<List<InterestEntity>> replaceInterests(List<String> interestIds) {
    return _client.put(
      ApiEndpoints.profileInterests,
      body: {'interestIds': interestIds},
      parse: (data) => ApiClient.asList(data, ProfileMapper.interest),
    );
  }

  Future<List<PortfolioItemEntity>> getPortfolio() {
    return _client.get(
      ApiEndpoints.profilePortfolio,
      parse: (data) => ApiClient.asList(data, ProfileMapper.portfolioItem),
    );
  }

  Future<PortfolioItemEntity> createPortfolioItem(Map<String, dynamic> body) {
    return _client.post(
      ApiEndpoints.profilePortfolio,
      body: body,
      parse: (data) => ProfileMapper.portfolioItem(ApiClient.asMap(data)),
    );
  }

  Future<PortfolioItemEntity> updatePortfolioItem(
    String portfolioId,
    Map<String, dynamic> body,
  ) {
    return _client.put(
      ApiEndpoints.profilePortfolioItem(portfolioId),
      body: body,
      parse: (data) => ProfileMapper.portfolioItem(ApiClient.asMap(data)),
    );
  }

  Future<void> deletePortfolioItem(String portfolioId) {
    return _client.delete(ApiEndpoints.profilePortfolioItem(portfolioId));
  }

  Future<List<BadgeEntity>> getBadges() {
    return _client.get(
      ApiEndpoints.badges,
      parse: (data) => ApiClient.asList(data, ProfileMapper.badge),
    );
  }

  Future<List<SavedItemEntity>> getSavedItems() {
    return _client.get(
      ApiEndpoints.profileSaved,
      parse: (data) => ApiClient.asList(data, ProfileMapper.savedItem),
    );
  }

  Future<List<SocialLinkEntity>> getSocialLinks() {
    return _client.get(
      ApiEndpoints.profileSocialLinks,
      parse: (data) => ApiClient.asList(data, ProfileMapper.socialLink),
    );
  }

  Future<SocialLinkEntity> upsertSocialLink({
    required String platform,
    required String url,
  }) {
    return _client.put(
      ApiEndpoints.profileSocialLinks,
      body: {'platform': platform, 'url': url},
      parse: (data) => ProfileMapper.socialLink(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteSocialLink(String platform) {
    return _client.delete(ApiEndpoints.profileSocialLink(platform));
  }
}
