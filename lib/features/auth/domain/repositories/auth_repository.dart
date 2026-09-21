import '../entities/auth_session.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

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

  Future<AuthSession> googleLogin({required String idToken});

  Future<AuthSession> verifyEmail({required String email, required String otp});

  Future<AuthSession> verifyOtp({required String email, required String otp});

  Future<void> resendOtp({required String email});

  Future<void> resendVerificationOtp({required String email});

  Future<void> forgotPassword({required String email});

  Future<void> verifyResetOtp({required String email, required String otp});

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  Future<bool> setPassword({required String password});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AuthSession> refreshToken({required String refreshToken});

  Future<UserEntity> getCurrentUser();

  Future<void> logout();
}
