import 'package:get/get.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../../../../core/network/interceptors/error_interceptor.dart';
import '../../../../core/network/interceptors/language_interceptor.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

/// GetX binding for the auth feature.
///
/// Registers the full dependency chain:
/// storage -> device preferences -> Dio + interceptors -> ApiClient ->
/// AuthRemoteDatasource -> AuthRepository -> AuthController
///
/// Everything here is `permanent`: there is exactly one of each for the
/// process lifetime, and later feature bindings resolve them with
/// `Get.find`.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // ── Storage ─────────────────────────────────────────────────────────
    final storage = SecureStorage();
    final localStorage = LocalStorage();
    Get.put<SecureStorage>(storage, permanent: true);
    Get.put<LocalStorage>(localStorage, permanent: true);

    // ── Device preferences ──────────────────────────────────────────────
    final localization = LocalizationService(localStorage: localStorage);
    Get.put<LocalizationService>(localization, permanent: true);
    Get.put<ThemeController>(
      ThemeController(localStorage: localStorage),
      permanent: true,
    );

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

    Get.put<ApiClient>(ApiClient(dio), permanent: true);
    Get.put<AuthRepository>(authRepository, permanent: true);

    // ── Controller ──────────────────────────────────────────────────────
    Get.put<AuthController>(
      AuthController(
        authRepository: authRepository,
        secureStorage: storage,
        localization: localization,
      ),
      permanent: true,
    );
  }
}
