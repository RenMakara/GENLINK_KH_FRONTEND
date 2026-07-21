import '../../../../core/errors/app_error.dart';

/// Obtains a Google ID token from the device.
///
/// Kept behind an interface so the rest of the app — controller, bindings,
/// screens — is wired for Google sign-in before the platform plugin is
/// installed. Swapping [UnconfiguredGoogleAuthService] for the real
/// implementation is the only change needed once `google_sign_in` is a
/// dependency and the OAuth clients exist.
///
/// The token is verified server-side by `GoogleTokenVerifier`, which checks
/// the signature, issuer, expiry and — critically — that the audience is one
/// of the ids in the backend's `app.google.client-id`.
abstract class GoogleAuthService {
  /// Returns a Google ID token, or `null` if the user dismissed the picker.
  ///
  /// Throws [AppError] when sign-in is unavailable or fails.
  Future<String?> signIn();

  /// Clears the cached Google account so the next sign-in shows the picker
  /// again. Safe to call when nobody is signed in.
  Future<void> signOut();
}

/// Default implementation used until the plugin and OAuth clients are set up.
///
/// It fails loudly with a specific error code rather than silently doing
/// nothing, so a misconfigured build is obvious instead of looking like a
/// dead button.
class UnconfiguredGoogleAuthService implements GoogleAuthService {
  const UnconfiguredGoogleAuthService();

  static const errorCode = 'GOOGLE_SIGN_IN_NOT_CONFIGURED';

  @override
  Future<String?> signIn() async {
    throw const AppError(
      message: 'Google Sign-In is not configured in this build yet.',
      errorCode: errorCode,
    );
  }

  @override
  Future<void> signOut() async {
    // Nothing to clear.
  }
}
