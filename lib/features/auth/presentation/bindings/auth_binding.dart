import 'package:get/get.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../../../../core/network/interceptors/error_interceptor.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

/// GetX binding for the auth feature.
///
/// Registers the full dependency chain:
/// SecureStorage -> Dio -> AuthInterceptor -> AuthRemoteDatasource ->
/// AuthRepository -> AuthController
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Core
    final storage = SecureStorage();
    Get.put<SecureStorage>(storage, permanent: true);

    // Dio with interceptors
    final errorInterceptor = ErrorInterceptor();
    final dio = DioProvider.create(
      errorInterceptor: errorInterceptor,
    );

    // Auth interceptor depends on both storage and repository.
    // We use a lazy registration to break the circular dependency:
    // the interceptor needs the repository, but the repository needs Dio.
    final remoteDatasource = AuthRemoteDatasource(dio);
    final authRepository = AuthRepositoryImpl(remoteDatasource);

    // Now wire the auth interceptor and re-add it to Dio.
    final authInterceptor = AuthInterceptor(
      secureStorage: storage,
      authRepository: authRepository,
    );
    dio.interceptors.add(authInterceptor);

    // Register repositories
    Get.put<AuthRepository>(authRepository, permanent: true);

    // Controller
    Get.put<AuthController>(
      AuthController(
        authRepository: authRepository,
        secureStorage: storage,
      ),
      permanent: true,
    );
  }
}
