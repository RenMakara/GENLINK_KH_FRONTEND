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

  /// Routes an already-authenticated user should be redirected away from.
  static const authRoutes = <String>{
    login,
    register,
    verifyEmail,
    forgotPassword,
    resetOtp,
    resetPassword,
  };

  /// Routes reachable without a session.
  static const publicRoutes = <String>{
    splash,
    languageSelect,
    onboarding,
    login,
    register,
    verifyEmail,
    forgotPassword,
    resetOtp,
    resetPassword,
  };

  // ── Main ──────────────────────────────────────────────────────────────
  static const home = '/home';

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
