import '../../../settings/domain/entities/user_settings_entity.dart';
import '../entities/profile_entity.dart';

/// Abstract profile + settings contract.
///
/// Settings live here rather than in a separate repository because the
/// backend serves them from the same `/profile` controller family and the
/// two are always loaded together.
abstract class ProfileRepository {
  Future<ProfileEntity> getMyProfile();

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
  });

  Future<ProfileEntity> updateAvatar(String avatarUrl);

  /// Set the avatar from a confirmed media upload, resolved server-side.
  Future<ProfileEntity> updateAvatarFromMedia(String mediaId);

  Future<PublicProfileEntity> getPublicProfile(String username);

  // ── Settings ──────────────────────────────────────────────────────────

  Future<UserSettingsEntity> getSettings();

  Future<UserSettingsEntity> updateSettings({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  });

  // ── Interests ─────────────────────────────────────────────────────────

  Future<List<InterestEntity>> getInterestCatalog();

  Future<List<InterestEntity>> getMyInterests();

  /// Replaces the entire selection.
  Future<List<InterestEntity>> replaceInterests(List<String> interestIds);

  // ── Portfolio ─────────────────────────────────────────────────────────

  Future<List<PortfolioItemEntity>> getPortfolio();

  Future<PortfolioItemEntity> createPortfolioItem({
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  });

  Future<PortfolioItemEntity> updatePortfolioItem({
    required String portfolioId,
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  });

  Future<void> deletePortfolioItem(String portfolioId);

  // ── Badges & saved ────────────────────────────────────────────────────

  Future<List<BadgeEntity>> getBadges();

  Future<List<SavedItemEntity>> getSavedItems();

  // ── Social links ──────────────────────────────────────────────────────

  Future<List<SocialLinkEntity>> getSocialLinks();

  Future<SocialLinkEntity> upsertSocialLink({
    required String platform,
    required String url,
  });

  Future<void> deleteSocialLink(String platform);
}
