import '../../../../core/errors/app_error.dart';

abstract class GoogleAuthService {
  Future<String?> signIn();

  Future<void> signOut();
}

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
  }
}
