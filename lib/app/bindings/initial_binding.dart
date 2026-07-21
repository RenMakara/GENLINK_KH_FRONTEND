import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/auth_binding.dart';

/// Initial dependency binding for app startup.
///
/// Delegates to [AuthBinding], which owns the shared storage, localization,
/// theme and HTTP stack because auth is the first thing to need all of them.
/// Feature-level dependencies stay inside each feature module.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
  }
}
