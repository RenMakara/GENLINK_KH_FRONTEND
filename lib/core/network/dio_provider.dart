import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
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
  /// Comes from `AppConfig`, which reads the `API_BASE_URL` dart-define so
  /// a physical device can point at the host's LAN IP without a code edit.
  static const defaultBaseUrl = AppConfig.apiBaseUrl;

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

    if (kDebugMode) {
      // One readable line per request/failure. Without this a failed call
      // is invisible in the console and the UI can only say "something
      // went wrong". Debug builds only — never log tokens in release.
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('→ ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '← ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              '✖ ${error.type.name} ${error.requestOptions.uri}\n'
              '  status: ${error.response?.statusCode}\n'
              '  message: ${error.message}\n'
              '  body: ${error.response?.data}',
            );
            handler.next(error);
          },
        ),
      );
    }

    return dio;
  }
}
