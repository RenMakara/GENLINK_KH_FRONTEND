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
  Future<ProfileEntity> getMyProfile() async {
    try {
      return await _remote.getMyProfile();
    } catch (_) {
      return const ProfileEntity(
        userId: 'user_1',
        fullName: 'Enat',
        username: 'enat_kh',
        email: 'enat@genlink.kh',
        avatarUrl: 'https://i.pravatar.cc/150?img=32',
        bio: 'Flutter Developer & Student at RUPP',
        universityName: 'RUPP University',
        workStatus: 'Student',
        location: 'Phnom Penh, Cambodia',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 150,
        level: 3,
        preferredLanguage: 'en',
      );
    }
  }

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
  Future<List<InterestEntity>> getInterestCatalog() async {
    try {
      return await _remote.getInterestCatalog();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<InterestEntity>> getMyInterests() async {
    try {
      return await _remote.getMyInterests();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<InterestEntity>> replaceInterests(List<String> interestIds) async {
    try {
      return await _remote.replaceInterests(interestIds);
    } catch (_) {
      return const [];
    }
  }

  // ── Portfolio ─────────────────────────────────────────────────────────

  @override
  Future<List<PortfolioItemEntity>> getPortfolio() async {
    try {
      return await _remote.getPortfolio();
    } catch (_) {
      return const [];
    }
  }

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
  Future<List<BadgeEntity>> getBadges() async {
    try {
      return await _remote.getBadges();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<SavedItemEntity>> getSavedItems() async {
    try {
      return await _remote.getSavedItems();
    } catch (_) {
      return const [];
    }
  }

  // ── Social links ──────────────────────────────────────────────────────

  @override
  Future<List<SocialLinkEntity>> getSocialLinks() async {
    try {
      return await _remote.getSocialLinks();
    } catch (_) {
      return const [];
    }
  }

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
