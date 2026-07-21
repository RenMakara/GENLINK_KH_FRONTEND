import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_error.dart';
import '../../domain/services/google_auth_service.dart';

/// Real [GoogleAuthService], backed by `google_sign_in` 7.x.
///
/// The 7.x API is a singleton that must be initialized once before use:
/// `GoogleSignIn.instance.initialize(...)` then `.authenticate()`. This is a
/// breaking change from 6.x, which constructed a `GoogleSignIn(...)` object
/// and called `.signIn()`.
///
/// [AppConfig.googleServerClientId] must be the **Web** OAuth client id.
/// On Android the resulting ID token's `aud` claim is that server client id,
/// and the backend's `GoogleTokenVerifier` checks exactly that value.
class GoogleAuthServiceImpl implements GoogleAuthService {
  GoogleAuthServiceImpl();

  /// `initialize` is idempotent per process but does real platform work, so
  /// it is run once, lazily, on the first sign-in rather than at startup.
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  @override
  Future<String?> signIn() async {
    if (!AppConfig.isGoogleSignInConfigured) {
      throw const AppError(
        message: 'Google Sign-In is not configured in this build yet.',
        errorCode: UnconfiguredGoogleAuthService.errorCode,
      );
    }

    try {
      await _ensureInitialized();

      // Web has no interactive `authenticate()` — it uses a rendered button
      // instead. Fail with a clear code rather than a platform exception.
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AppError(
          message: 'Google Sign-In is not supported on this platform.',
          errorCode: 'GOOGLE_SIGN_IN_UNSUPPORTED',
        );
      }

      final account = await GoogleSignIn.instance.authenticate(
        // The backend only reads sub/email/name/picture, all of which come
        // from the ID token itself, so no extra scopes are requested.
        scopeHint: const <String>['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        // Almost always a missing or wrong serverClientId: without it
        // Google returns an access token but no ID token.
        throw const AppError(
          message: 'Google did not return an ID token.',
          errorCode: 'GOOGLE_NO_ID_TOKEN',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      // Dismissing the account picker is not a failure — returning null
      // leaves the screen as it was, with no error banner.
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AppError(
        message: e.description ?? 'Google Sign-In failed.',
        errorCode: 'GOOGLE_SIGN_IN_FAILED',
      );
    }
  }

  @override
  Future<void> signOut() async {
    // Nothing to sign out of if the plugin was never initialized.
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
