import '../entities/auth_session.dart';
import '../entities/user_entity.dart';

/// Abstract auth repository contract.
///
/// All auth operations go through this interface. The data layer provides
/// the implementation; the presentation layer depends only on this.
abstract class AuthRepository {
  /// Email + password login.
  Future<AuthSession> login({required String email, required String password});

  /// Register a new account. Sends OTP to email; no session returned.
  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber,
    required String password,
    String? universityName,
    String? workStatus,
    String? preferredLanguage,
  });

  /// Firebase Google sign-in.
  Future<AuthSession> googleLogin({required String idToken});

  /// Verify email with 6-digit OTP. Returns session on success.
  Future<AuthSession> verifyEmail({required String email, required String otp});

  /// Alias for verifyEmail (backend has both /verify-email and /verify-otp).
  Future<AuthSession> verifyOtp({required String email, required String otp});

  /// Resend registration OTP.
  Future<void> resendOtp({required String email});

  /// Resend verification OTP (idempotent, safe for already-verified).
  Future<void> resendVerificationOtp({required String email});

  /// Start password reset flow (sends OTP to email).
  Future<void> forgotPassword({required String email});

  /// Complete password reset with OTP + new password.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  /// Refresh the access token using a refresh token.
  Future<AuthSession> refreshToken({required String refreshToken});

  /// Get the current authenticated user profile.
  Future<UserEntity> getCurrentUser();

  /// Logout: revoke all refresh tokens server-side, clear local storage.
  Future<void> logout();
}
