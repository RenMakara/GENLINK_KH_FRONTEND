/// Central route name registry.
///
/// Use this folder for typed route constants only. Feature pages should
/// register their routes through modular route files as the app grows.
abstract final class AppRoutes {
  static const initial = '/';

  // ── Auth ──────────────────────────────────────────────────────────────
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // ── Main ──────────────────────────────────────────────────────────────
  static const home = '/home';
}
