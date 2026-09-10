import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettingsRepository>()) {
      Get.put<SettingsRepository>(
        SettingsRepositoryImpl(SettingsRemoteDatasource(Get.find<ApiClient>())),
        permanent: true,
      );
    }

    Get.lazyPut<SettingsController>(
      () => SettingsController(
        repository: Get.find<SettingsRepository>(),
        themeController: Get.find<ThemeController>(),
        localization: Get.find<LocalizationService>(),
      ),
      fenix: true,
    );
  }
}
