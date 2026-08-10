import 'package:get/get.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Convenience helper for retrieving the currently authenticated [UserEntity].
///
/// Usage:
/// ```dart
/// final user = CurrentUser.get();   // nullable
/// final name = CurrentUser.name;    // 'Guest' if not logged in
/// ```
class CurrentUser {
  const CurrentUser._();

  /// Returns the logged-in [UserEntity], or null when not authenticated.
  static UserEntity? get() {
    if (!Get.isRegistered<AuthController>()) return null;
    return Get.find<AuthController>().currentUser.value;
  }

  /// Full display name, falls back to 'Guest'.
  static String get name => get()?.fullName ?? 'Guest';

  /// Avatar URL. Null if not set.
  static String? get avatarUrl => get()?.avatarUrl;

  /// Unique user ID. Empty string if not logged in.
  static String get id => get()?.id ?? '';

  /// User @handle. Falls back to name.
  static String get username => get()?.username ?? name;
}
