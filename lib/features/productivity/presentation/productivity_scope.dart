import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import 'bindings/productivity_binding.dart';
import 'controllers/productivity_controller.dart';

/// Returns the shared productivity controller when the app has its API
/// bindings. Lightweight screen tests and the create sheet can still render
/// without bootstrapping the whole app.
ProductivityController? ensureProductivityController() {
  if (Get.isRegistered<ProductivityController>()) {
    return Get.find<ProductivityController>();
  }
  if (!Get.isRegistered<ApiClient>()) return null;

  ProductivityBinding().dependencies();
  return Get.isRegistered<ProductivityController>()
      ? Get.find<ProductivityController>()
      : null;
}
