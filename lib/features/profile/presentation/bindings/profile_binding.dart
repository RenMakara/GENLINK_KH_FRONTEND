import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_controller.dart';

/// Binding for the profile screens.
///
/// The repository is permanent (settings needs it too); the controller is
/// lazy so it is rebuilt — and refetched — each time the user opens the tab.
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    _registerRepository();
    Get.lazyPut<ProfileController>(
      () => ProfileController(repository: Get.find<ProfileRepository>()),
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

/// Binding for the settings screen.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    ProfileBinding._registerRepository();
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        repository: Get.find<ProfileRepository>(),
        themeController: Get.find<ThemeController>(),
        localization: Get.find<LocalizationService>(),
      ),
    );
  }
}
