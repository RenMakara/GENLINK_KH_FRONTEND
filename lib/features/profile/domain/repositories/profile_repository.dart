import '../entities/profile_entity.dart';

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
    int? coverPreset,
  });

  Future<ProfileEntity> updateAvatar(String avatarUrl);

  Future<ProfileEntity> updateAvatarFromMedia(String mediaId);

  Future<PublicProfileEntity> getPublicProfile(String username);

  Future<FollowStatsEntity> getFollowStats(String userId);

  Future<String?> followUser(String userId);

  Future<void> unfollowUser(String userId);

  Future<List<InterestEntity>> getInterestCatalog();

  Future<List<InterestEntity>> getMyInterests();

  Future<List<InterestEntity>> replaceInterests(List<String> interestIds);

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

  Future<List<BadgeEntity>> getBadges();

  Future<List<SavedItemEntity>> getSavedItems();

  Future<List<SocialLinkEntity>> getSocialLinks();

  Future<SocialLinkEntity> upsertSocialLink({
    required String platform,
    required String url,
  });

  Future<void> deleteSocialLink(String platform);
}
