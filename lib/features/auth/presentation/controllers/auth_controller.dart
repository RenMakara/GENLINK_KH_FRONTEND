import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Reactive auth state controller.
///
/// Manages the full auth lifecycle: login, register, verify, refresh,
/// logout. Exposes observable state for the UI layer to bind to.
class AuthController extends GetxController {
  AuthController({
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
  })  : _authRepository = authRepository,
        _storage = secureStorage;

  final AuthRepository _authRepository;
  final SecureStorage _storage;

  // ── Observable State ──────────────────────────────────────────────────

  final isLoading = false.obs;
  final isAuthenticated = false.obs;
  final currentUser = Rxn<UserEntity>();
  final errorMessage = RxnString();

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  /// Try to restore session from secure storage on app start.
  Future<void> _restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final user = await _authRepository.getCurrentUser();
      currentUser.value = user;
      isAuthenticated.value = true;
    } catch (_) {
      // Token invalid or expired — clear silently.
      await _storage.clearAll();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await _persistSession(session);
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────

  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber,
    required String password,
    String? universityName,
    String? workStatus,
    String? preferredLanguage,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.register(
        fullName: fullName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        universityName: universityName,
        workStatus: workStatus,
        preferredLanguage: preferredLanguage,
      );
      // Registration returns a message, not a session. The user must
      // verify their email before logging in.
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Login ──────────────────────────────────────────────────────

  Future<void> googleLogin({required String idToken}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final session = await _authRepository.googleLogin(idToken: idToken);
      await _persistSession(session);
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Verify Email ──────────────────────────────────────────────────────

  Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final session = await _authRepository.verifyEmail(
        email: email,
        otp: otp,
      );
      await _persistSession(session);
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────

  Future<void> resendOtp({required String email}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.resendOtp(email: email);
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Resend Verification OTP ──────────────────────────────────────────

  Future<void> resendVerificationOtp({required String email}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.resendVerificationOtp(email: email);
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Forgot Password ──────────────────────────────────────────────────

  Future<void> forgotPassword({required String email}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.forgotPassword(email: email);
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Reset Password ──────────────────────────────────────────────────

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (_) {
      // Logout should always clear local state even if the server call fails.
    }
    await _storage.clearAll();
    currentUser.value = null;
    isAuthenticated.value = false;
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Future<void> _persistSession(AuthSession session) async {
    await _storage.saveTokenPair(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _storage.saveUserEmail(session.user.email);
    await _storage.saveUserId(session.user.id);
    currentUser.value = session.user;
    isAuthenticated.value = true;
  }
}
