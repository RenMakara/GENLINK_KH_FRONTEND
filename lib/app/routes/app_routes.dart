/// Central route name registry.
///
/// Typed route constants only. Pages are registered in `app_pages.dart`.
abstract final class AppRoutes {
  // ── Entry ─────────────────────────────────────────────────────────────
  static const initial = splash;
  static const splash = '/';

  /// First-run flow: language select (step 1) then the onboarding slides.
  static const languageSelect = '/language';
  static const onboarding = '/onboarding';

  // ── Auth ──────────────────────────────────────────────────────────────
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';

  /// Code entry for the password reset, between forgot and reset.
  static const resetOtp = '/reset-otp';
  static const resetPassword = '/reset-password';

  // ── Main ──────────────────────────────────────────────────────────────
  static const home = '/home';

  static const notifications = '/notifications';
  static const chat = '/chat';
  static const chatDetail = '/chat/detail';

  // ── Quiz ────────────────────────────────────────────────────────────────
  static const quizDashboard = '/quiz/dashboard';
  static const quizCategories = '/quiz/categories';
  static const quizMatchmaking = '/quiz/matchmaking';
  static const quizOpponentFound = '/quiz/opponent-found';
  static const quizInProgress = '/quiz/in-progress';
  static const quizReview = '/quiz/review';
  static const quizResult = '/quiz/result';
  static const quizClaimReward = '/quiz/claim-reward';
  static const quizRewardAnimation = '/quiz/reward-animation';
  static const quizRewardClaimed = '/quiz/reward-claimed';
  static const quizLeaderboard = '/quiz/leaderboard';
  static const quizTopRank = '/quiz/top-rank';

  // ── Leaderboard ──────────────────────────────────────────────────────────
  static const leaderboard = '/leaderboard';
  static const leaderboardRanking = '/leaderboard/ranking';
  static const leaderboardProfile = '/leaderboard/profile';
  static const leaderboardAchievements = '/leaderboard/achievements';
  static const leaderboardInvite = '/leaderboard/invite';

  // ── Profile & settings ────────────────────────────────────────────────
  /// Three-step setup shown once, right after registration.
  static const profileSetup = '/profile/setup';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const profileAchievements = '/profile/achievements';
  static const profileSaved = '/profile/saved';
  static const profilePortfolio = '/profile/portfolio';
  static const profileInterests = '/profile/interests';
  static const settings = '/settings';
  static const settingsLanguage = '/settings/language';
  static const settingsAppearance = '/settings/appearance';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsAccount = '/settings/account';
}
