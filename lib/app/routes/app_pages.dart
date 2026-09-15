import 'package:get/get.dart';

import '../../features/auth/presentation/middleware/auth_middleware.dart';
import '../../features/auth/presentation/screens/auth_choice_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_otp_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/onboarding/presentation/screens/language_select_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/completion_screen.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/achievements_screen.dart';
import '../../features/profile/presentation/screens/interests_screen.dart';
import '../../features/profile/presentation/screens/portfolio_screen.dart';
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/profile/presentation/screens/saved_items_screen.dart';
import '../../features/settings/presentation/screens/account_settings_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/bindings/settings_binding.dart';
import '../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../features/settings/presentation/screens/language_settings_screen.dart';
import '../../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/chat/chat_feature.dart';
import '../../features/community/presentation/screens/friend_requests_screen.dart';
import '../../features/notification/notification_feature.dart';
import '../../features/quiz/presentation/bindings/quiz_binding.dart';
import '../../features/quiz/presentation/screens/quiz_dashboard_screen.dart';
import '../../features/quiz/presentation/screens/category_selection_screen.dart';
import '../../features/quiz/presentation/screens/find_opponent_screen.dart';
import '../../features/quiz/presentation/screens/opponent_found_screen.dart';
import '../../features/quiz/presentation/screens/quiz_in_progress_screen.dart';
import '../../features/quiz/presentation/screens/review_submit_screen.dart';
import '../../features/quiz/presentation/screens/result_screen.dart';
import '../../features/quiz/presentation/screens/claim_reward_screen.dart';
import '../../features/quiz/presentation/screens/reward_animation_screen.dart';
import '../../features/quiz/presentation/screens/reward_claimed_screen.dart';
import '../../features/quiz/presentation/screens/leaderboard_screen.dart';
import '../../features/quiz/presentation/screens/top_rank_detail_screen.dart';
import '../../features/leaderboard/presentation/bindings/leaderboard_binding.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_home_screen.dart';
import '../../features/leaderboard/presentation/screens/full_ranking_screen.dart';
import '../../features/leaderboard/presentation/screens/top_rank_detail_screen.dart'
    as lb_detail;
import '../../features/leaderboard/presentation/screens/achievements_screen.dart'
    as lb_achievements;
import '../../features/leaderboard/presentation/screens/invite_friends_screen.dart';
import '../../features/splash/presentation/bindings/splash_binding.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/splash/presentation/screens/welcome_screen.dart';
import '../../main_screen.dart';
import '../bindings/main_binding.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.welcome,
      page: () => const WelcomeScreen(),
      binding: WelcomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.languageSelect,
      page: () => const LanguageSelectScreen(),
      binding: LanguageSelectBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.completion,
      page: () => const CompletionScreen(),
      binding: CompletionBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.authChoice,
      page: () => const AuthChoiceScreen(),
    ),
    GetPage<dynamic>(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.verifyEmail,
      page: () => const VerifyOtpScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.resetOtp,
      page: () => const ResetOtpScreen(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordScreen(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const MainScreen(),
      binding: MainBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const NotificationScreen(),
      binding: NotificationBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.friendRequests,
      page: () => const FriendRequestsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.chat,
      page: () => const ChatListScreen(),
      binding: ChatBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.chatDetail,
      page: () => const ChatDetailScreen(),
      binding: ChatBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage<dynamic>(
      name: AppRoutes.quizDashboard,
      page: () => const QuizDashboardScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizCategories,
      page: () => const CategorySelectionScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizMatchmaking,
      page: () => const FindOpponentScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizOpponentFound,
      page: () => const OpponentFoundScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizInProgress,
      page: () => const QuizInProgressScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizReview,
      page: () => const ReviewSubmitScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizResult,
      page: () => const ResultScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizClaimReward,
      page: () => const ClaimRewardScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizRewardAnimation,
      page: () => const RewardAnimationScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizRewardClaimed,
      page: () => const RewardClaimedScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizLeaderboard,
      page: () => const LeaderboardScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.quizTopRank,
      page: () => const TopRankDetailScreen(),
      binding: QuizBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage<dynamic>(
      name: AppRoutes.leaderboard,
      page: () => const LeaderboardHomeScreen(),
      binding: LeaderboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.leaderboardRanking,
      page: () => const FullRankingScreen(),
      binding: LeaderboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.leaderboardProfile,
      page: () => const lb_detail.TopRankDetailScreen(),
      binding: LeaderboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.leaderboardAchievements,
      page: () => const lb_achievements.AchievementsScreen(),
      binding: LeaderboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.leaderboardInvite,
      page: () => const InviteFriendsScreen(),
      binding: LeaderboardBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage<dynamic>(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.profile,
      page: () => ProfileScreen(viewingUsername: Get.parameters['username']),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.profileAchievements,
      page: () => const AchievementsScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.profileSaved,
      page: () => const SavedItemsScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.profilePortfolio,
      page: () => const PortfolioScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.profileInterests,
      page: () => const InterestsScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.settingsLanguage,
      page: () => const LanguageSettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.settingsAppearance,
      page: () => const AppearanceSettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.settingsPrivacy,
      page: () => const PrivacySettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.settingsAccount,
      page: () => const AccountSettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.settingsAbout,
      page: () => const AboutScreen(),
      middlewares: [AuthMiddleware()],
    ),
  ];

  static final unknownRoute = GetPage<dynamic>(
    name: '/not-found',
    page: () => const SplashScreen(),
    binding: SplashBinding(),
  );
}
