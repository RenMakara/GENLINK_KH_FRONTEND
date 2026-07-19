import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/auth_binding.dart';

/// Initial dependency binding for app startup.
///
/// Registers global GetX services here. Feature-level dependencies should
/// stay inside each feature module.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
  }
}
