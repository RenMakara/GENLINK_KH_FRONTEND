import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/notification/domain/mobile_push_registration_service.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/google_auth_service.dart';
import '../../../settings/domain/repositories/settings_repository.dart';

/// Reactive auth state controller.
///
/// Manages the full auth lifecycle: login, register, verify, refresh,
/// logout. Exposes observable state for the UI layer to bind to.
///
/// Every action returns a `bool` so screens can decide what to do next
/// without reading [errorMessage] to infer success.
class AuthController extends GetxController {
  AuthController({
    required this._authRepository,
    required SecureStorage secureStorage,
    required this._localization,
    this.settingsRepository,
    this.themeController,
    this.localStorage,
    GoogleAuthService googleAuthService = const UnconfiguredGoogleAuthService(),
    this.mobilePushRegistrationService,
    this.onSessionCleared,
    this.onSessionEstablished,
  }) : _storage = secureStorage,
       _google = googleAuthService;

  final AuthRepository _authRepository;
  final SecureStorage _storage;
  final LocalStorage? localStorage;
  final LocalizationService _localization;
  final SettingsRepository? settingsRepository;
  final ThemeController? themeController;
  final GoogleAuthService _google;
  final MobilePushRegistrationService? mobilePushRegistrationService;
  final void Function()? onSessionCleared;
  final void Function()? onSessionEstablished;

  /// Seconds a user must wait before requesting another OTP.
  static const resendCooldownSeconds = 60;
  static const _accountSettingsSyncTimeout = Duration(seconds: 2);

  // ── Observable State ──────────────────────────────────────────────────

  final isLoading = false.obs;
  final isAuthenticated = false.obs;
  final currentUser = Rxn<UserEntity>();
  final errorMessage = RxnString();

  /// Error code of the last failure, so a screen can branch on the cause
  /// (a bad OTP versus a rejected password) rather than parsing [errorMessage].
  final lastErrorCode = RxnString();

  /// Email carried from register / forgot-password into the OTP screen,
  /// so the user never has to retype it.
  final pendingEmail = ''.obs;

  /// Remaining seconds before "resend code" becomes tappable again.
  final resendCooldown = 0.obs;

  Timer? _cooldownTimer;
  bool _logoutInProgress = false;
  bool _sessionPersistenceInProgress = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    super.onClose();
  }

  /// Try to restore a session from secure storage.
  ///
  /// Returns `true` when a valid session was restored. Called by splash
  /// before deciding where to route.
  Future<bool> restoreSession() async {
    try {
      // Inside the try: a failing keystore read must not propagate, or the
      // splash screen never reaches its navigation call.
      final token = await _storage.readAccessToken();
      if (token == null || token.isEmpty) return false;
      if (_isDemoToken(token)) {
        await _clearSession();
        return false;
      }

      final user = await _authRepository.getCurrentUser();
      if (!user.isActive) {
        // PENDING / BANNED / DELETED cannot use the app.
        await _clearSession();
        return false;
      }
      currentUser.value = user;
      isAuthenticated.value = true;
      // Sync, not setLanguage: adopting the account value must not lock
      // the language against device-following.
      _localization.syncFromAccount(user.preferredLanguage);
      await _syncAccountSettings();
      onSessionEstablished?.call();
      unawaited(_registerMobilePushDevice());
      return true;
    } on AppError catch (e) {
      // Only confirmed authentication/account failures invalidate the
      // stored session. A timeout, offline launch, or 5xx response must not
      // destroy a valid refresh token and force the user to sign in again.
      if (e.shouldLogout || e.isAccountBanned || e.isNotFound) {
        await _clearSession();
      }
      return false;
    } catch (_) {
      // Preserve the stored session for transient or unexpected failures.
      // Splash can fall back for this launch and retry restoration later.
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────

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

  // ── Register ──────────────────────────────────────────────────────────

  /// Registers the account and sends an OTP. No session is returned —
  /// the caller should route to the verify screen.
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

  // ── Google Login ──────────────────────────────────────────────────────

  /// Full Google flow: obtain an ID token on device, then exchange it for a
  /// session. The backend creates the account when the email is new, so this
  /// is both "sign in" and "sign up".
  ///
  /// Returns `false` without setting an error when the user simply dismissed
  /// the Google account picker — a cancel is not a failure.
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

  /// Exchanges an existing Google ID token for a GenLink session.
  Future<bool> googleLogin({required String idToken}) {
    return _run(() async {
      final session = await _authRepository.googleLogin(idToken: idToken);
      await _persistSession(session);
      return true;
    });
  }

  // ── Verify Email ──────────────────────────────────────────────────────

  /// Verifies the OTP. The backend returns a full token pair here, so a
  /// successful verification signs the user straight in.
  Future<bool> verifyEmail({required String email, required String otp}) {
    return _run(() async {
      final session = await _authRepository.verifyEmail(email: email, otp: otp);
      await _persistSession(session);
      return true;
    });
  }

  // ── Resend OTP ────────────────────────────────────────────────────────

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

  // ── Password Reset ────────────────────────────────────────────────────

  Future<bool> forgotPassword({required String email}) {
    return _run(() async {
      await _authRepository.forgotPassword(email: email);
      pendingEmail.value = email;
      startResendCooldown();
      return true;
    });
  }

  Future<bool> verifyResetOtp({required String email, required String otp}) {
    return _run(() async {
      await _authRepository.verifyResetOtp(email: email, otp: otp);
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

  /// Adds a password to an account that currently authenticates through
  /// Google. The current Google session remains valid.
  Future<bool> setPassword({required String password}) {
    return _run(() async {
      final hasPassword = await _authRepository.setPassword(password: password);
      final user = currentUser.value;
      if (user != null && hasPassword) {
        currentUser.value = user.copyWith(hasPassword: true);
      }
      return hasPassword;
    });
  }

  /// Uses the existing backend change-password flow. That flow revokes all
  /// sessions, so a successful change intentionally returns the user to login.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _run(() async {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _clearSession();
      return true;
    });
  }

  /// Whether the optional post-Google-login prompt should be shown. This is
  /// only a UX decision; [UserEntity.hasPassword] remains server-authoritative.
  Future<bool> shouldPromptForGooglePasswordSetup() async {
    final user = currentUser.value;
    if (user == null || user.hasPassword) return false;

    final storage = localStorage;
    if (storage == null) return true;

    try {
      return !(await storage.wasGooglePasswordPromptDismissed(user.id));
    } catch (_) {
      // A local-storage failure must not block the authenticated user.
      return true;
    }
  }

  Future<void> dismissGooglePasswordPrompt() async {
    final userId = currentUser.value?.id;
    final storage = localStorage;
    if (userId == null || storage == null) return;

    try {
      await storage.markGooglePasswordPromptDismissed(userId);
    } catch (_) {
      // Dismissal is best-effort UX state, never an authentication failure.
    }
  }

  /// Completes any Google entry point consistently across login, register, and
  /// the initial auth-choice screen.
  Future<void> continueAfterGoogleLogin() async {
    if (await shouldPromptForGooglePasswordSetup()) {
      Get.offAllNamed<void>(
        AppRoutes.passwordSetup,
        arguments: const {'optionalPrompt': true},
      );
    } else {
      Get.offAllNamed<void>(AppRoutes.home);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;

    try {
      try {
        // Clear the cached Google account too, otherwise the next sign-in
        // silently reuses it and the account picker never appears.
        await _google.signOut();
      } catch (_) {
        // A local provider failure must not prevent the session from ending.
      }

      // The backend invalidates the current access token as part of logout.
      // Deactivate the push device while that token is still valid; doing it
      // afterwards makes the device DELETE enter the refresh-token flow.
      await _deactivateMobilePushDeviceBeforeLogout();

      try {
        await _authRepository.logout();
      } catch (_) {
        // Logout is best effort on the server. Local state must still clear.
      }

      try {
        // Push cleanup already ran above, so do not issue another authenticated
        // device request after the server has invalidated the token.
        await _clearSession();
      } catch (error, stackTrace) {
        // Navigation must not be blocked by a controller cleanup callback.
        debugPrint('[AUTH] Local session cleanup failed: $error\n$stackTrace');
        try {
          await _storage.clearAll();
        } catch (_) {}
        currentUser.value = null;
        isAuthenticated.value = false;
      }
    } finally {
      _logoutInProgress = false;
      Get.offAllNamed<void>(AppRoutes.login);
    }
  }

  /// Called by the network layer when a token refresh fails and the
  /// session is unrecoverable.
  Future<void> onSessionExpired() async {
    // A late response from the previous session must not clear credentials
    // while a new login is persisting its token pair.
    if (_logoutInProgress || _sessionPersistenceInProgress) return;
    isAuthenticated.value = false;
    currentUser.value = null;
    await _clearSession();
    Get.offAllNamed<void>(AppRoutes.login);
  }

  // ── Profile sync ─────────────────────────────────────────────────────

  /// Keep the cached user in step after a profile or settings update.
  void updateCachedUser(UserEntity user) => currentUser.value = user;

  /// Refresh server-backed account fields after another feature grants XP.
  Future<bool> refreshCurrentUser() async {
    if (!isAuthenticated.value) return false;

    try {
      final user = await _authRepository.getCurrentUser();
      if (!user.isActive) {
        await _clearSession();
        return false;
      }
      currentUser.value = user;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Cooldown ─────────────────────────────────────────────────────────

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

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Load account-owned preferences before the app enters the authenticated
  /// area. Local storage remains the immediate fallback, but the server is
  /// authoritative once a session exists.
  ///
  /// This is deliberately best effort: an unavailable settings endpoint must
  /// never turn a successful login into a failed login or clear credentials.
  Future<void> _syncAccountSettings() async {
    final repository = settingsRepository;
    if (repository == null) return;

    try {
      final accountSettings = await repository.getSettings().timeout(
        _accountSettingsSyncTimeout,
      );

      final theme = themeController;
      if (theme != null) {
        try {
          await theme.applyBackendTheme(accountSettings.theme);
        } catch (error, stackTrace) {
          debugPrint(
            '[AUTH] Theme preference sync failed: $error\n$stackTrace',
          );
        }
      }

      _localization.syncFromAccount(accountSettings.language);
    } catch (error, stackTrace) {
      debugPrint('[AUTH] Account settings sync skipped: $error\n$stackTrace');
    }
  }

  /// Runs [action] with loading + error handling, returning `false` on
  /// any failure.
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
    _sessionPersistenceInProgress = true;
    try {
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

      // Read back the value so a successful HTTP response cannot be mistaken
      // for an authenticated session when persistence silently fails.
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
      // Adopt the account's language so system content comes back localized —
      // as a sync, so device-following keeps working for users who never
      // explicitly chose.
      _localization.syncFromAccount(session.user.preferredLanguage);
      await _syncAccountSettings();
      onSessionEstablished?.call();
      unawaited(_registerMobilePushDevice());
    } finally {
      _sessionPersistenceInProgress = false;
    }
  }

  Future<void> _registerMobilePushDevice() async {
    final service = mobilePushRegistrationService;
    if (service == null) return;

    try {
      await service.registerCurrentDevice();
    } catch (error, stackTrace) {
      // Push registration is supplemental. A Firebase or network failure must
      // never turn a successful authentication into a failed login.
      debugPrint('[FCM] Device registration failed: $error\n$stackTrace');
    }
  }

  Future<void> _deactivateMobilePushDeviceBeforeLogout() async {
    final service = mobilePushRegistrationService;
    if (service == null) return;

    try {
      await service.deactivateCurrentDevice(
        remote: true,
        waitForRegistration: true,
      );
    } catch (error, stackTrace) {
      // Device cleanup is supplemental. A network or plugin failure must not
      // prevent the user from reaching the login screen.
      debugPrint('[FCM] Device cleanup failed: $error\n$stackTrace');
    }
  }

  Future<void> _clearSession({bool deactivateMobilePushDevice = false}) async {
    final pushService = mobilePushRegistrationService;
    if (pushService != null) {
      try {
        await pushService.deactivateCurrentDevice(
          remote: deactivateMobilePushDevice,
          // Session-expiry callbacks can be triggered by the very request
          // being registered. Waiting here would deadlock that request.
          waitForRegistration: false,
        );
      } catch (error, stackTrace) {
        debugPrint('[FCM] Device cleanup failed: $error\n$stackTrace');
      }
    }

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
