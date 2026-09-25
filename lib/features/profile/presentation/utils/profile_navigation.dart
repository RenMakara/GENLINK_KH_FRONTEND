import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../shared/utils/current_user.dart';

/// Opens the correct profile surface for a tapped user.
///
/// A profile link can contain the signed-in user's username (for example, a
/// user's own post). In that case the app must use the owner route so editing
/// and private profile data remain available. Every other username is opened
/// through the public-profile route.
abstract final class ProfileNavigation {
  const ProfileNavigation._();

  static String? ownerAwareUsername({String? username, String? userId}) {
    final normalizedUsername = _normalize(username);
    final normalizedUserId = _normalize(userId);
    final currentUser = CurrentUser.get();

    if (currentUser != null) {
      final currentUserId = currentUser.id.trim();
      if (normalizedUserId != null &&
          currentUserId.isNotEmpty &&
          normalizedUserId == currentUserId) {
        return null;
      }

      final currentUsername = currentUser.username.trim();
      if (normalizedUsername != null &&
          currentUsername.isNotEmpty &&
          normalizedUsername.toLowerCase() == currentUsername.toLowerCase()) {
        return null;
      }
    }

    return normalizedUsername ?? normalizedUserId;
  }

  static Future<void> open({String? username, String? userId}) async {
    final publicUsername = ownerAwareUsername(
      username: username,
      userId: userId,
    );

    if (publicUsername == null) {
      await Get.toNamed<void>(AppRoutes.profile);
      return;
    }

    await Get.toNamed<void>(
      AppRoutes.profile,
      parameters: {'username': publicUsername},
    );
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
