import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
<<<<<<< Updated upstream
=======
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../../../../core/network/interceptors/error_interceptor.dart';
import '../../../../core/network/interceptors/language_interceptor.dart';
import '../../../../core/storage/local_storage.dart';
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
    Get.put<MainController>(MainController(), permanent: true);

    // ── HTTP stack ──────────────────────────────────────────────────────
    final dio = DioProvider.create();

    // The interceptor needs the repository and the repository needs Dio,
    // so the repository is built against `dio` first and the interceptor
    // is attached afterwards.
    final authRepository = AuthRepositoryImpl(AuthRemoteDatasource(dio));

    final authInterceptor = AuthInterceptor(
      secureStorage: storage,
      authRepository: authRepository,
      onSessionExpired: () {
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().onSessionExpired();
        }
      },
    )..client = dio;

    // Order matters: AuthInterceptor must see the raw DioException so it
    // can refresh and replay, before ErrorInterceptor rewrites the error
    // into an AppError.
    dio.interceptors.addAll([
      LanguageInterceptor(localization),
      authInterceptor,
      ErrorInterceptor(),
    ]);

    final apiClient = ApiClient(dio);
    Get.put<ApiClient>(apiClient, permanent: true);
>>>>>>> Stashed changes
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
