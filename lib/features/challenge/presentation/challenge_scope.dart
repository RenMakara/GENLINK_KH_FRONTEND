import 'package:get/get.dart';

import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../core/network/api_client.dart';
import 'bindings/challenge_binding.dart';
import 'controllers/challenge_controller.dart';

/// Returns the shared challenge controller when the app has its API and auth
/// bindings. Lightweight screen tests can render without bootstrapping them.
ChallengeController? ensureChallengeController() {
  if (Get.isRegistered<ChallengeController>()) {
    return Get.find<ChallengeController>();
  }
  if (!Get.isRegistered<ApiClient>() || !Get.isRegistered<AuthController>()) {
    return null;
  }

  ChallengeBinding().dependencies();
  return Get.isRegistered<ChallengeController>()
      ? Get.find<ChallengeController>()
      : null;
}
