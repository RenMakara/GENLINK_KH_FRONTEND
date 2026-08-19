import 'package:get/get.dart';

import '../../features/auth/presentation/middleware/auth_middleware.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_otp_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/onboarding/presentation/screens/language_select_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/achievements_screen.dart';
import '../../features/profile/presentation/screens/interests_screen.dart';
import '../../features/profile/presentation/screens/portfolio_screen.dart';
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/profile/presentation/screens/saved_items_screen.dart';
import '../../features/settings/presentation/screens/account_settings_screen.dart';
import '../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../features/settings/presentation/screens/language_settings_screen.dart';
import '../../features/settings/presentation/screens/privacy_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/community/presentation/bindings/community_binding.dart';
import '../../features/chat/chat_feature.dart';
import '../../features/notification/notification_feature.dart';
import '../../features/splash/presentation/bindings/splash_binding.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../main_screen.dart';
import 'app_routes.dart';

/// Central GetX page registry.
///
/// Splash and onboarding are deliberately unguarded: splash is what
/// restores the session in the first place, so guarding it would bounce
/// the user to login before the stored token has been read.
abstract final class AppPages {
  static const initial = AppRoutes.splash;

  static final pages = <GetPage<dynamic>>[
    // ── Entry ───────────────────────────────────────────────────────────
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
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

    // ── Auth ────────────────────────────────────────────────────────────
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
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

    // ── Main ────────────────────────────────────────────────────────────
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const MainScreen(),
      binding: CommunityBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const NotificationScreen(),
      binding: NotificationBinding(),
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


    // ── Profile & settings ──────────────────────────────────────────────
    GetPage<dynamic>(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
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
  ];

  /// Unknown routes fall back to splash, which re-resolves the session and
  /// sends the user somewhere valid.
  static final unknownRoute = GetPage<dynamic>(
    name: '/not-found',
    page: () => const SplashScreen(),
    binding: SplashBinding(),
  );
}
