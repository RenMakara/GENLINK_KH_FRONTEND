import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/notification/domain/mobile_push_registration_service.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/google_auth_service_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../settings/data/datasources/settings_remote_datasource.dart';
import '../../../settings/data/repositories/settings_repository_impl.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  AuthBinding({
    this.onSessionCleared,
    this.onSessionEstablished,
    this.mobilePushRegistrationService,
  });

  final void Function()? onSessionCleared;
  final void Function()? onSessionEstablished;
  final MobilePushRegistrationService? mobilePushRegistrationService;

  @override
  void dependencies() {
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDatasource(Get.find<Dio>()),
    );
    final settingsRepository = SettingsRepositoryImpl(
      SettingsRemoteDatasource(Get.find<ApiClient>()),
    );
    Get.put<AuthRepository>(authRepository, permanent: true);
    Get.put<AuthController>(
      AuthController(
        authRepository: authRepository,
        settingsRepository: settingsRepository,
        secureStorage: Get.find<SecureStorage>(),
        localization: Get.find<LocalizationService>(),
        themeController: Get.find<ThemeController>(),
        localStorage: Get.find<LocalStorage>(),
        googleAuthService: GoogleAuthServiceImpl(),
        mobilePushRegistrationService: mobilePushRegistrationService,
        onSessionCleared: onSessionCleared,
        onSessionEstablished: onSessionEstablished,
      ),
      permanent: true,
    );
  }
}
