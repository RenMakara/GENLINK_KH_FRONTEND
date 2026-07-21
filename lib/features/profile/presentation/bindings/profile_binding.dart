import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_setup_controller.dart';

/// Binding for the profile screens.
///
/// The repository is permanent (settings needs it too); the controller is
/// lazy so it is rebuilt — and refetched — each time the user opens the tab.
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    _registerRepository();
    // Sub-screens (portfolio, saved, achievements, interests) share the
    // tab's controller; fenix recreates it if GetX disposed it.
    Get.lazyPut<ProfileController>(
      () => ProfileController(repository: Get.find<ProfileRepository>()),
      fenix: true,
    );
  }

  /// Shared with [SettingsBinding]; registered once.
  static void _registerRepository() {
    if (Get.isRegistered<ProfileRepository>()) return;
    Get.put<ProfileRepository>(
      ProfileRepositoryImpl(
        ProfileRemoteDatasource(Get.find<ApiClient>()),
      ),
      permanent: true,
    );
  }
}

/// Binding for the post-registration profile setup flow.
class ProfileSetupBinding extends Bindings {
  @override
  void dependencies() {
    ProfileBinding._registerRepository();
    Get.lazyPut<ProfileSetupController>(
      () => ProfileSetupController(repository: Get.find<ProfileRepository>()),
    );
  }
}

/// Binding for the settings screen.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    ProfileBinding._registerRepository();
    // The hub and its four sub-pages all bind this; fenix keeps one
    // instance alive across them and revives it after disposal.
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        repository: Get.find<ProfileRepository>(),
        themeController: Get.find<ThemeController>(),
        localization: Get.find<LocalizationService>(),
      ),
      fenix: true,
    );
  }
}
