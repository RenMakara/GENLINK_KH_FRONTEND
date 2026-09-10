import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/google_auth_service.dart';

class AuthController extends GetxController {
  AuthController({
    required this._authRepository,
    required SecureStorage secureStorage,
    required this._localization,
    GoogleAuthService googleAuthService = const UnconfiguredGoogleAuthService(),
    this.onSessionCleared,
  }) : _storage = secureStorage,
       _google = googleAuthService;

  final AuthRepository _authRepository;
  final SecureStorage _storage;
  final LocalizationService _localization;
  final GoogleAuthService _google;
  final void Function()? onSessionCleared;

  static const resendCooldownSeconds = 60;


  final isLoading = false.obs;
  final isAuthenticated = false.obs;
  final currentUser = Rxn<UserEntity>();
  final errorMessage = RxnString();

  final lastErrorCode = RxnString();

  final pendingEmail = ''.obs;

  final resendCooldown = 0.obs;

  Timer? _cooldownTimer;


  @override
  void onClose() {
    _cooldownTimer?.cancel();
    super.onClose();
  }

  Future<bool> restoreSession() async {
    try {
      final token = await _storage.readAccessToken();
      if (token == null || token.isEmpty) return false;
      if (_isDemoToken(token)) {
        await _clearSession();
        return false;
      }

      final user = await _authRepository.getCurrentUser();
      if (!user.isActive) {
        await _clearSession();
        return false;
      }
      currentUser.value = user;
      isAuthenticated.value = true;
      _localization.syncFromAccount(user.preferredLanguage);
      return true;
    } on AppError catch (e) {
      if (e.shouldLogout || e.isAccountBanned || e.isNotFound) {
        await _clearSession();
      }
      return false;
    } catch (_) {
      return false;
    }
  }


  Future<bool> login({required String email, required String password}) {
    return _run(() async {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await _persistSession(session);
      return true;
    });
  }


  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber,
    required String password,
    String? universityName,
    String? workStatus,
    String? preferredLanguage,
  }) {
    return _run(() async {
      await _authRepository.register(
        fullName: fullName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        universityName: universityName,
        workStatus: workStatus,
        preferredLanguage: preferredLanguage ?? _localization.language.value,
      );
      pendingEmail.value = email;
      startResendCooldown();
      return true;
    });
  }


  Future<bool> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = null;
    lastErrorCode.value = null;
    try {
      final idToken = await _google.signIn();
      if (idToken == null) return false;

      final session = await _authRepository.googleLogin(idToken: idToken);
      await _persistSession(session);
      return true;
    } on AppError catch (e) {
      errorMessage.value = e.message;
      lastErrorCode.value = e.errorCode;
      return false;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
      lastErrorCode.value = 'UNKNOWN';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> googleLogin({required String idToken}) {
    return _run(() async {
      final session = await _authRepository.googleLogin(idToken: idToken);
      await _persistSession(session);
      return true;
    });
  }


  Future<bool> verifyEmail({required String email, required String otp}) {
    return _run(() async {
      final session = await _authRepository.verifyEmail(email: email, otp: otp);
      await _persistSession(session);
      return true;
    });
  }


  Future<bool> resendOtp({required String email}) {
    return _run(() async {
      await _authRepository.resendOtp(email: email);
      startResendCooldown();
      return true;
    });
  }

  Future<bool> resendVerificationOtp({required String email}) {
    return _run(() async {
      await _authRepository.resendVerificationOtp(email: email);
      startResendCooldown();
      return true;
    });
  }


  Future<bool> forgotPassword({required String email}) {
    return _run(() async {
      await _authRepository.forgotPassword(email: email);
      pendingEmail.value = email;
      startResendCooldown();
      return true;
    });
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _run(() async {
      await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return true;
    });
  }


  Future<void> logout() async {
    try {
      await _google.signOut();
      await _authRepository.logout();
    } catch (_) {
    }
    await _clearSession();
    Get.offAllNamed<void>(AppRoutes.login);
  }

  Future<void> onSessionExpired() async {
    isAuthenticated.value = false;
    currentUser.value = null;
    await _clearSession();
    Get.offAllNamed<void>(AppRoutes.login);
  }


  void updateCachedUser(UserEntity user) => currentUser.value = user;


  void startResendCooldown() {
    _cooldownTimer?.cancel();
    resendCooldown.value = resendCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value <= 1) {
        resendCooldown.value = 0;
        timer.cancel();
      } else {
        resendCooldown.value--;
      }
    });
  }


  Future<bool> _run(Future<bool> Function() action) async {
    isLoading.value = true;
    errorMessage.value = null;
    lastErrorCode.value = null;
    try {
      return await action();
    } on AppError catch (e) {
      errorMessage.value = e.message;
      lastErrorCode.value = e.errorCode;
      return false;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
      lastErrorCode.value = 'UNKNOWN';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    final accessToken = session.accessToken.trim();
    if (accessToken.isEmpty) {
      throw const AppError(
        message: 'Login response did not include an access token.',
        errorCode: 'AUTH_TOKEN_MISSING',
      );
    }

    await _storage.saveTokenPair(
      accessToken: accessToken,
      refreshToken: session.refreshToken.trim(),
    );

    final savedAccessToken = await _storage.readAccessToken();
    final tokenSaved = savedAccessToken == accessToken;
    if (kDebugMode) {
      debugPrint(
        '[AUTH]\n'
        'Login successful: true\n'
        'Access token received: true\n'
        'Access token saved: $tokenSaved',
      );
    }
    if (!tokenSaved) {
      throw const AppError(
        message: 'Unable to save the login session.',
        errorCode: 'AUTH_TOKEN_NOT_SAVED',
      );
    }

    await _storage.saveUserEmail(session.user.email);
    await _storage.saveUserId(session.user.id);
    currentUser.value = session.user;
    isAuthenticated.value = true;
    pendingEmail.value = '';
    _localization.syncFromAccount(session.user.preferredLanguage);
  }

  Future<void> _clearSession() async {
    await _storage.clearAll();
    currentUser.value = null;
    isAuthenticated.value = false;
    onSessionCleared?.call();
  }

  bool _isDemoToken(String token) =>
      token == 'demo_access_token' ||
      token == 'mock_access_token_123' ||
      token == 'mock_google_token';
}
