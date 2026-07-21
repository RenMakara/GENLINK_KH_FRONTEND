import 'package:get/get.dart';

import '../../features/auth/presentation/middleware/auth_middleware.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/onboarding/presentation/screens/language_select_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
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
      middlewares: [AuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      middlewares: [AuthMiddleware()],
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
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordScreen(),
    ),

    // ── Main ────────────────────────────────────────────────────────────
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const MainScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // ── Profile & settings ──────────────────────────────────────────────
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
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
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
