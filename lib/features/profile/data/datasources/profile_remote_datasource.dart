import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../settings/data/models/user_settings_model.dart';
import '../../../settings/domain/entities/user_settings_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../models/profile_models.dart';

/// Remote datasource for `/api/v1/profile/*`.
///
/// [ApiClient] already unwraps the `ApiResponse` envelope and raises
/// `AppError`, so these methods only map payloads to entities.
class ProfileRemoteDatasource {
  const ProfileRemoteDatasource(this._client);

  final ApiClient _client;

  // ── Profile ───────────────────────────────────────────────────────────

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

  /// Set the avatar from a confirmed upload.
  ///
  /// Sends `avatarMediaId` rather than a URL: the server resolves it to the
  /// object's CDN url, which proves the avatar points at a real upload the
  /// caller owns. A client-supplied URL cannot make that guarantee.
  Future<ProfileEntity> updateAvatarFromMedia(String mediaId) {
    return _client.post(
      ApiEndpoints.profileAvatar,
      body: {'avatarMediaId': mediaId},
      parse: (data) => ProfileMapper.profile(ApiClient.asMap(data)),
    );
  }

  /// Set the avatar from a URL we did not upload — the picture returned by
  /// Google sign-in, for example.
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

  // ── Settings ──────────────────────────────────────────────────────────

  Future<UserSettingsEntity> getSettings() {
    return _client.get(
      ApiEndpoints.profileSettings,
      parse: (data) => UserSettingsMapper.fromJson(ApiClient.asMap(data)),
    );
  }

  Future<UserSettingsEntity> updateSettings(Map<String, dynamic> body) {
    return _client.put(
      ApiEndpoints.profileSettings,
      body: body,
      parse: (data) => UserSettingsMapper.fromJson(ApiClient.asMap(data)),
    );
  }

  // ── Interests ─────────────────────────────────────────────────────────

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

  /// Replaces the whole selection — this is a PUT, not an append.
  Future<List<InterestEntity>> replaceInterests(List<String> interestIds) {
    return _client.put(
      ApiEndpoints.profileInterests,
      body: {'interestIds': interestIds},
      parse: (data) => ApiClient.asList(data, ProfileMapper.interest),
    );
  }

  // ── Portfolio ─────────────────────────────────────────────────────────

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

  // ── Badges ────────────────────────────────────────────────────────────

  /// Full catalog with an `earned` flag per badge.
  Future<List<BadgeEntity>> getBadges() {
    return _client.get(
      ApiEndpoints.badges,
      parse: (data) => ApiClient.asList(data, ProfileMapper.badge),
    );
  }

  // ── Saved items ───────────────────────────────────────────────────────

  Future<List<SavedItemEntity>> getSavedItems() {
    return _client.get(
      ApiEndpoints.profileSaved,
      parse: (data) => ApiClient.asList(data, ProfileMapper.savedItem),
    );
  }

  // ── Social links ──────────────────────────────────────────────────────

  Future<List<SocialLinkEntity>> getSocialLinks() {
    return _client.get(
      ApiEndpoints.profileSocialLinks,
      parse: (data) => ApiClient.asList(data, ProfileMapper.socialLink),
    );
  }

  /// Upsert: posting a platform that already has a link replaces it.
  Future<SocialLinkEntity> upsertSocialLink({
    required String platform,
    required String url,
  }) {
    return _client.post(
      ApiEndpoints.profileSocialLinks,
      body: {'platform': platform, 'url': url},
      parse: (data) => ProfileMapper.socialLink(ApiClient.asMap(data)),
    );
  }

  Future<void> deleteSocialLink(String platform) {
    return _client.delete(ApiEndpoints.profileSocialLink(platform));
  }
}
