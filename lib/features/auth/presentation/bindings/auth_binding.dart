import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/notification/domain/mobile_push_registration_service.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/google_auth_service_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  AuthBinding({this.onSessionCleared, this.mobilePushRegistrationService});

  final void Function()? onSessionCleared;
  final MobilePushRegistrationService? mobilePushRegistrationService;

  @override
  void dependencies() {
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDatasource(Get.find<Dio>()),
    );
    Get.put<AuthRepository>(authRepository, permanent: true);
    Get.put<AuthController>(
      AuthController(
        authRepository: authRepository,
        secureStorage: Get.find<SecureStorage>(),
        localization: Get.find<LocalizationService>(),
        googleAuthService: GoogleAuthServiceImpl(),
        mobilePushRegistrationService: mobilePushRegistrationService,
        onSessionCleared: onSessionCleared,
      ),
      permanent: true,
    );
  }
}
