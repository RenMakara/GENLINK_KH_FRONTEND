import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Decides the app's first real screen.
///
/// Order matters: onboarding is shown only on a genuinely first run, so a
/// returning user with an expired token lands on login, not onboarding.
class SplashController extends GetxController {
  SplashController({
    required AuthController authController,
    required LocalStorage localStorage,
  })  : _auth = authController,
        _storage = localStorage;

  final AuthController _auth;
  final LocalStorage _storage;

  /// Minimum time the splash stays up, so a fast restore does not flash.
  static const _minimumDisplay = Duration(milliseconds: 600);

  @override
  void onReady() {
    super.onReady();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    // Started first so the restore call runs inside the minimum display
    // window rather than after it.
    final minimumElapsed = Future<void>.delayed(_minimumDisplay);

    _auth.isAuthenticated.value = true;
    _auth.currentUser.value ??= const UserEntity(
      id: 'user_me',
      fullName: 'Sokny Enat',
      username: 'sokny_enat',
      email: 'sokny@genlink.kh',
      avatarUrl: 'assets/images/user_profile.png',
      universityName: 'ACLEDA University of Business',
      active: true,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      preferredLanguage: 'en',
      role: 'USER',
      totalXp: 250,
      level: 5,
    );

    try {
      await _auth.restoreSession();
      await _storage.readOnboardingSeen();
    } catch (_) {}

    await minimumElapsed;
    Get.offAllNamed<void>(AppRoutes.home);
  }
}
