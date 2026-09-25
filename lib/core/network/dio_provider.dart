import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'certificate_bypass_stub.dart'
    if (dart.library.io) 'certificate_bypass_io.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class DioProvider {
  const DioProvider._();

  static const defaultBaseUrl = AppConfig.apiBaseUrl;

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

    configureCertificateBypass(dio);

    if (errorInterceptor != null) {
      dio.interceptors.add(errorInterceptor);
    }
    if (authInterceptor != null) {
      dio.interceptors.add(authInterceptor);
    }

    if (kDebugMode) {
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
