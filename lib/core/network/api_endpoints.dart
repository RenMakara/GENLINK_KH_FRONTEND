/// API endpoint registry.
///
/// All backend contract paths live here. Feature modules reference these
/// constants instead of hardcoding URL strings.
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
}
