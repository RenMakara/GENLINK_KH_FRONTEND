import 'package:dio/dio.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Creates and configures the shared [Dio] instance.
///
/// All HTTP communication goes through this provider so interceptors are
/// applied consistently.
class DioProvider {
  const DioProvider._();

  /// Base URL for the GenLink KH API.
  ///
  /// Override via environment config in production. This default works for
  /// local development against the Spring Boot server.
  static const defaultBaseUrl = 'http://10.0.2.2:8080';

  /// Create a fully-configured [Dio] instance.
  ///
  /// [authInterceptor] handles Bearer token injection and refresh-token retry.
  /// [errorInterceptor] maps Dio errors to [AppError].
  static Dio create({
    String? baseUrl,
    AuthInterceptor? authInterceptor,
    ErrorInterceptor? errorInterceptor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (errorInterceptor != null) {
      dio.interceptors.add(errorInterceptor);
    }
    if (authInterceptor != null) {
      dio.interceptors.add(authInterceptor);
    }

    return dio;
  }
}
