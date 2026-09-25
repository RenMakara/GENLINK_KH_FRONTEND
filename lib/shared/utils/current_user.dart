import 'package:get/get.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class CurrentUser {
  const CurrentUser._();

  static UserEntity? get() {
    if (!Get.isRegistered<AuthController>()) return null;
    return Get.find<AuthController>().currentUser.value;
  }

  static String get name => get()?.fullName ?? 'Guest';

  static String? get avatarUrl => get()?.avatarUrl;

  static String get id => get()?.id ?? '';

  static String get username => get()?.username ?? name;
}
