import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/google_auth_service_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

/// GetX binding for the auth feature.
///
/// App-wide storage, networking, preferences, navigation, and shared media
/// services are owned by `InitialBinding`. This binding owns only the Auth
/// data source, repository, platform service, and controller.
class AuthBinding extends Bindings {
  AuthBinding({this.onSessionCleared});

  final void Function()? onSessionCleared;

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
        onSessionCleared: onSessionCleared,
      ),
      permanent: true,
    );
  }
}
