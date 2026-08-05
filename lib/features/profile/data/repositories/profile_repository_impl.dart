import '../../../settings/data/models/user_settings_model.dart';
import '../../../settings/domain/entities/user_settings_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_models.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDatasource _remote;

  @override
  Future<ProfileEntity> getMyProfile() => _remote.getMyProfile();

  @override
  Future<ProfileEntity> updateProfile({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? universityName,
    String? workStatus,
    String? location,
    String? preferredLanguage,
  }) {
    return _remote.updateProfile(
      ProfileMapper.profileUpdateBody(
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
        dateOfBirth: dateOfBirth,
        gender: gender,
        universityName: universityName,
        workStatus: workStatus,
        location: location,
        preferredLanguage: preferredLanguage,
      ),
    );
  }

  @override
  Future<ProfileEntity> updateAvatar(String avatarUrl) =>
      _remote.updateAvatar(avatarUrl);

  @override
  Future<ProfileEntity> updateAvatarFromMedia(String mediaId) =>
      _remote.updateAvatarFromMedia(mediaId);

  @override
  Future<PublicProfileEntity> getPublicProfile(String username) =>
      _remote.getPublicProfile(username);

  // ── Settings ──────────────────────────────────────────────────────────

  @override
  Future<UserSettingsEntity> getSettings() => _remote.getSettings();

  @override
  Future<UserSettingsEntity> updateSettings({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  }) {
    return _remote.updateSettings(
      UserSettingsMapper.updateBody(
        language: language,
        theme: theme,
        notificationEnabled: notificationEnabled,
        privacyProfile: privacyProfile,
        allowMessages: allowMessages,
        allowFollowRequest: allowFollowRequest,
        biometricEnabled: biometricEnabled,
      ),
    );
  }

  // ── Interests ─────────────────────────────────────────────────────────

  @override
  Future<List<InterestEntity>> getInterestCatalog() => _remote.getInterestCatalog();

  @override
  Future<List<InterestEntity>> getMyInterests() => _remote.getMyInterests();

  @override
  Future<List<InterestEntity>> replaceInterests(List<String> interestIds) => _remote.replaceInterests(interestIds);

  // ── Portfolio ─────────────────────────────────────────────────────────

  @override
  Future<List<PortfolioItemEntity>> getPortfolio() => _remote.getPortfolio();

  @override
  Future<PortfolioItemEntity> createPortfolioItem({
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  }) {
    return _remote.createPortfolioItem(
      _portfolioBody(
        title: title,
        description: description,
        link: link,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  Future<PortfolioItemEntity> updatePortfolioItem({
    required String portfolioId,
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  }) {
    return _remote.updatePortfolioItem(
      portfolioId,
      _portfolioBody(
        title: title,
        description: description,
        link: link,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  Future<void> deletePortfolioItem(String portfolioId) =>
      _remote.deletePortfolioItem(portfolioId);

  // ── Badges & saved ────────────────────────────────────────────────────

  @override
  Future<List<BadgeEntity>> getBadges() => _remote.getBadges();

  @override
  Future<List<SavedItemEntity>> getSavedItems() => _remote.getSavedItems();

  // ── Social links ──────────────────────────────────────────────────────

  @override
  Future<List<SocialLinkEntity>> getSocialLinks() => _remote.getSocialLinks();

  @override
  Future<SocialLinkEntity> upsertSocialLink({
    required String platform,
    required String url,
  }) {
    return _remote.upsertSocialLink(platform: platform, url: url);
  }

  @override
  Future<void> deleteSocialLink(String platform) =>
      _remote.deleteSocialLink(platform);

  /// `title` is required by the backend; the rest are dropped when blank so
  /// an empty text field clears rather than storing "".
  static Map<String, dynamic> _portfolioBody({
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  }) {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'link': link,
      'imageUrl': imageUrl,
    }..removeWhere((key, value) =>
        key != 'title' && (value == null || (value as String).isEmpty));
  }
}
