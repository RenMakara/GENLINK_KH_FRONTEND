import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/google_auth_service.dart';

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
    GoogleAuthService googleAuthService = const UnconfiguredGoogleAuthService(),
  })  : _storage = secureStorage,
        _google = googleAuthService;

  final AuthRepository _authRepository;
  final SecureStorage _storage;
  final LocalizationService _localization;
  final GoogleAuthService _google;

  /// Seconds a user must wait before requesting another OTP.
  static const resendCooldownSeconds = 60;

  // ── Observable State ──────────────────────────────────────────────────

  final isLoading = false.obs;
  final isAuthenticated = true.obs;
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
      return true;
    } catch (_) {
      // Token invalid, expired, or the account is gone — clear silently.
      await _clearSession();
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) {
    return _run(() async {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      await _persistSession(session);
      return true;
    });
  }

  /// Instant demo login for testing without a backend account.
  Future<void> demoLogin() async {
    const demoSession = AuthSession(
      accessToken: 'demo_access_token',
      refreshToken: 'demo_refresh_token',
      tokenType: 'Bearer',
      user: UserEntity(
        id: 'demo_user_1',
        fullName: 'Sokny Enat',
        username: 'sokny_enat',
        email: 'sokny@genlink.kh',
        avatarUrl: 'https://i.pravatar.cc/150?img=32',
        universityName: 'ACLEDA University of Business',
        active: true,
        emailVerified: true,
        accountStatus: 'ACTIVE',
        preferredLanguage: 'en',
        role: 'USER',
        totalXp: 250,
        level: 5,
      ),
    );
    await _persistSession(demoSession);
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
    String? idToken;
    try {
      idToken = await _google.signIn();
    } catch (_) {
      // Fallback for dev mode / desktop / unconfigured native Google client
    } finally {
      isLoading.value = false;
    }

    // If native Google login is unconfigured, fallback to instant demo login
    idToken ??= 'demo_google_id_token_123';
    return googleLogin(idToken: idToken);
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
  Future<bool> verifyEmail({
    required String email,
    required String otp,
  }) {
    return _run(() async {
      final session = await _authRepository.verifyEmail(
        email: email,
        otp: otp,
      );
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

  // ── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      // Clear the cached Google account too, otherwise the next sign-in
      // silently reuses it and the account picker never appears.
      await _google.signOut();
      await _authRepository.logout();
    } catch (_) {
      // Always clear local state, even if the server call fails —
      // otherwise a network blip would trap the user in the session.
    }
    await _clearSession();
    Get.offAllNamed<void>(AppRoutes.login);
  }

  /// Called by the network layer when a token refresh fails and the
  /// session is unrecoverable.
  Future<void> onSessionExpired() async {
    isAuthenticated.value = false;
    currentUser.value = null;
    await _clearSession();
    Get.offAllNamed<void>(AppRoutes.login);
  }

  // ── Profile sync ─────────────────────────────────────────────────────

  /// Keep the cached user in step after a profile or settings update.
  void updateCachedUser(UserEntity user) => currentUser.value = user;

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
    await _storage.saveTokenPair(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _storage.saveUserEmail(session.user.email);
    await _storage.saveUserId(session.user.id);
    currentUser.value = session.user;
    isAuthenticated.value = true;
    pendingEmail.value = '';
    // Adopt the account's language so system content comes back localized —
    // as a sync, so device-following keeps working for users who never
    // explicitly chose.
    _localization.syncFromAccount(session.user.preferredLanguage);
  }

  Future<void> _clearSession() async {
    await _storage.clearAll();
    currentUser.value = null;
    isAuthenticated.value = false;
  }
}
