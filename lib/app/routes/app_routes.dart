abstract final class AppRoutes {
  static const initial = splash;
  static const splash = '/';

  static const welcome = '/welcome';
  static const languageSelect = '/language';
  static const onboarding = '/onboarding';
  static const completion = '/onboarding/complete';

  static const authChoice = '/auth';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';

  static const resetOtp = '/reset-otp';
  static const resetPassword = '/reset-password';

  static const home = '/home';

  static const notifications = '/notifications';
  static const friendRequests = '/friend-requests';
  static const chat = '/chat';
  static const chatDetail = '/chat/detail';

  static const quizDashboard = '/quiz/dashboard';
  static const quizCategories = '/quiz/categories';
  static const quizMultiplayer = '/quiz/multiplayer';
  static const quizInProgress = '/quiz/in-progress';
  static const quizReview = '/quiz/review';
  static const quizResult = '/quiz/result';

  static const shortContent = '/short-content';
  static const shortContentDetail = '/short-content/detail';
  static const shortContentCreate = '/short-content/create';

  static const challengeList = '/challenges';
  static const challengeDetail = '/challenges/detail';

  static const leaderboard = '/leaderboard';
  static const leaderboardRanking = '/leaderboard/ranking';
  static const leaderboardProfile = '/leaderboard/profile';
  static const leaderboardAchievements = '/leaderboard/achievements';

  static const profileSetup = '/profile/setup';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const profileAchievements = '/profile/achievements';
  static const profileSaved = '/profile/saved';
  static const profilePortfolio = '/profile/portfolio';
  static const profileInterests = '/profile/interests';
  static const settings = '/settings';
  static const settingsNotifications = '/settings/notifications';
  static const settingsLanguage = '/settings/language';
  static const settingsAppearance = '/settings/appearance';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsAccount = '/settings/account';
  static const settingsAbout = '/settings/about';
}
