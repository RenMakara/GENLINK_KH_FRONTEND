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
  static const resetPassword = '/reset-password';

  /// Routes an already-authenticated user should be redirected away from.
  static const authRoutes = <String>{
    login,
    register,
    verifyEmail,
    forgotPassword,
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
    resetPassword,
  };

  // ── Main ──────────────────────────────────────────────────────────────
  static const home = '/home';

  // ── Profile & settings ────────────────────────────────────────────────
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
}
