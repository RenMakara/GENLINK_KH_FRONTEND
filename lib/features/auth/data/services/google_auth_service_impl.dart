import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_error.dart';
import '../../domain/services/google_auth_service.dart';

class GoogleAuthServiceImpl implements GoogleAuthService {
  GoogleAuthServiceImpl();

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

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AppError(
          message: 'Google Sign-In is not supported on this platform.',
          errorCode: 'GOOGLE_SIGN_IN_UNSUPPORTED',
        );
      }

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppError(
          message: 'Google did not return an ID token.',
          errorCode: 'GOOGLE_NO_ID_TOKEN',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AppError(
        message: e.description ?? 'Google Sign-In failed.',
        errorCode: 'GOOGLE_SIGN_IN_FAILED',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
