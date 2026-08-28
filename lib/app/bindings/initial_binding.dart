import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/interceptors/auth_interceptor.dart';
import '../../core/network/interceptors/error_interceptor.dart';
import '../../core/network/interceptors/language_interceptor.dart';
import '../../core/network/interceptors/mock_interceptor.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/media/data/datasources/media_remote_datasource.dart';
import '../../features/media/data/repositories/media_repository_impl.dart';
import '../../features/media/domain/media_upload_service.dart';
import '../../features/media/presentation/media_picker.dart';
import '../../main_controller.dart';

/// Application composition root.
///
/// Owns process-wide infrastructure and composes feature bindings. Individual
/// features remain responsible for their own data sources, repositories, and
/// controllers.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ── Storage and device preferences ──────────────────────────────────
    final secureStorage = SecureStorage();
    final localStorage = LocalStorage();
    final localization = LocalizationService(localStorage: localStorage);
    final mainController = MainController();

    Get
      ..put<SecureStorage>(secureStorage, permanent: true)
      ..put<LocalStorage>(localStorage, permanent: true)
      ..put<LocalizationService>(localization, permanent: true)
      ..put<ThemeController>(
        ThemeController(localStorage: localStorage),
        permanent: true,
      )
      ..put<MainController>(mainController, permanent: true);

    // ── Shared HTTP stack ───────────────────────────────────────────────
    final dio = DioProvider.create();
    dio.interceptors.addAll([
      LanguageInterceptor(localization),
      MockInterceptor(secureStorage),
    ]);
    final apiClient = ApiClient(dio);
    Get
      ..put<Dio>(dio, permanent: true)
      ..put<ApiClient>(apiClient, permanent: true);

    // Auth owns its feature dependencies. The composition root supplies the
    // app-shell reset callback without making Auth depend on MainController.
    AuthBinding(onSessionCleared: mainController.reset).dependencies();

    final authInterceptor = AuthInterceptor(
      secureStorage: secureStorage,
      authRepository: Get.find<AuthRepository>(),
      onSessionExpired: () async {
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().onSessionExpired();
        } else {
          await secureStorage.clearAll();
          mainController.reset();
        }
      },
    )..client = dio;

    // Auth must refresh/replay the raw 401 before ErrorInterceptor converts
    // the final Dio failure into an AppError.
    dio.interceptors.addAll([authInterceptor, ErrorInterceptor()]);

    // ── Cross-feature media services ────────────────────────────────────
    Get
      ..put<MediaUploadService>(
        MediaUploadService(
          MediaRepositoryImpl(MediaRemoteDatasource(apiClient)),
        ),
        permanent: true,
      )
      ..put<MediaPicker>(MediaPicker(), permanent: true);
  }
}
