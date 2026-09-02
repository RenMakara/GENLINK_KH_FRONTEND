/// API endpoint registry.
///
/// All backend contract paths live here. Feature modules reference these
/// constants instead of hardcoding URL strings.
///
/// Paths are verified against the Spring Boot controllers, not the draft
/// API docs — profile lives under `/profile/*`, not `/users/me/*`.
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  static const _base = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────
  static const login = '$_base/auth/login';
  static const register = '$_base/auth/register';
  static const googleLogin = '$_base/auth/google';
  static const verifyEmail = '$_base/auth/verify-email';
  static const verifyOtp = '$_base/auth/verify-otp';
  static const resendOtp = '$_base/auth/resend-otp';
  static const resendVerificationOtp = '$_base/auth/resend-verification-otp';
  static const forgotPassword = '$_base/auth/forgot-password';
  static const resetPassword = '$_base/auth/reset-password';
  static const refreshToken = '$_base/auth/refresh-token';
  static const me = '$_base/auth/me';
  static const logout = '$_base/auth/logout';

  // ── Media ─────────────────────────────────────────────────────────────
  //
  // Only presign/confirm/url/delete are ours. The upload itself PUTs to the
  // absolute `uploadUrl` returned by presign, which points at the storage
  // provider — never at this API.
  static const mediaPresign = '$_base/media/presign';
  static const mediaConfirm = '$_base/media/confirm';
  static String mediaUrl(String mediaId) => '$_base/media/$mediaId/url';
  static String mediaItem(String mediaId) => '$_base/media/$mediaId';

  // ── Profile ───────────────────────────────────────────────────────────
  static const profileMe = '$_base/profile/me';
  static const profileAvatar = '$_base/profile/avatar';

  /// Public profile is keyed by username, nested under `/public/` so it can
  /// never collide with the sibling literal routes.
  static String publicProfile(String username) =>
      '$_base/profile/public/$username';

  // ── Settings ──────────────────────────────────────────────────────────
  static const profileSettings = '$_base/profile/settings';

  // ── Interests ─────────────────────────────────────────────────────────
  /// Full catalog, names already resolved to the caller's language.
  static const interestCatalog = '$_base/interests';
  static const profileInterests = '$_base/profile/interests';

  // ── Portfolio ─────────────────────────────────────────────────────────
  static const profilePortfolio = '$_base/profile/portfolio';

  static String profilePortfolioItem(String portfolioId) =>
      '$_base/profile/portfolio/$portfolioId';

  // ── Social links ──────────────────────────────────────────────────────
  /// Upsert by platform: POST replaces the existing link for that platform.
  static const profileSocialLinks = '$_base/profile/social-links';

  static String profileSocialLink(String platform) =>
      '$_base/profile/social-links/$platform';

  // ── Saved items ───────────────────────────────────────────────────────
  static const profileSaved = '$_base/profile/saved';
  static const profileSavedCheck = '$_base/profile/saved/check';

  static String profileSavedItem(String itemType, String itemId) =>
      '$_base/profile/saved/$itemType/$itemId';

  // ── Badges / achievements ─────────────────────────────────────────────
  /// Full catalog with an `earned` flag per badge — this is what the
  /// profile's achievements row renders (earned ones plus locked ones).
  static const badges = '$_base/entertainment/badges';
  static const myBadges = '$_base/entertainment/badges/mine';

  // ── Mobile BFF ────────────────────────────────────────────────────────
  static const mobileHome = '$_base/mobile/home';
  static const mobileProfileSummary = '$_base/mobile/profile-summary';
  static const mobileFinanceDashboard = '$_base/mobile/finance-dashboard';
  static const mobileProductivityDashboard =
      '$_base/mobile/productivity-dashboard';

  // ── Productivity ──────────────────────────────────────────────────────
  static const habits = '$_base/productivity/habits';
  static String habitCheckIn(String habitId) =>
      '$_base/productivity/habits/$habitId/check-in';

  // ── Community ─────────────────────────────────────────────────────────
  static const communityFeed = '$_base/community/posts/feed';
  static const communityPosts = '$_base/community/posts';

  static String communityPostDetail(String postId) =>
      '$_base/community/posts/$postId';

  static String communityPostLike(String postId) =>
      '$_base/community/posts/$postId/like';

  static String communityPostBookmark(String postId) =>
      '$_base/community/posts/$postId/bookmark';

  static String communityPostRepost(String postId) =>
      '$_base/community/posts/$postId/repost';

  static String communityPostReport(String postId) =>
      '$_base/community/posts/$postId/report';

  static String communityPostComments(String postId) =>
      '$_base/community/posts/$postId/comments';

  static String communityFollowUser(String userId) =>
      '$_base/community/users/$userId/follow';

  static String communityFollowStats(String userId) =>
      '$_base/community/users/$userId/follow-stats';

  // ── Discussions ───────────────────────────────────────────────────────
  static const communityDiscussions = '$_base/community/discussions';
  static String communityDiscussionDetail(String discussionId) =>
      '$_base/community/discussions/$discussionId';
  static String communityDiscussionComments(String discussionId) =>
      '$_base/community/discussions/$discussionId/comments';
  static String communityDiscussionReact(String discussionId) =>
      '$_base/community/discussions/$discussionId/react';

  // ── Stories ────────────────────────────────────────────────────────────
  static const stories = '$_base/community/stories';

  static String storyItem(String storyId) =>
      '$_base/community/stories/$storyId';

  static String storyView(String storyId) =>
      '$_base/community/stories/$storyId/view';

  static String storyLike(String storyId) =>
      '$_base/community/stories/$storyId/like';

  static String storyViewers(String storyId) =>
      '$_base/community/stories/$storyId/viewers';

  // ── Notifications ─────────────────────────────────────────────────────
  static const notifications = '$_base/notifications';

  // ── Chats ─────────────────────────────────────────────────────────────
  static const chats = '$_base/community/chats';

  // ── Entertainment / Gamification ──────────────────────────────────────
  static const quizzes = '$_base/entertainment/quizzes';
  static String quizDetail(String quizId) =>
      '$_base/entertainment/quizzes/$quizId';
  static String quizAttempt(String quizId) =>
      '$_base/entertainment/quizzes/$quizId/attempts';
  static const quizHistory = '$_base/entertainment/quizzes/history';
  static const leaderboards = '$_base/entertainment/leaderboards';
}
