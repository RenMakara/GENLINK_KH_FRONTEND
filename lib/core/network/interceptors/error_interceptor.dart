import 'package:dio/dio.dart';

import '../../../core/errors/app_error.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final body = err.response?.data;

    if (body is Map<String, dynamic>) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: AppError.fromResponse(body, statusCode ?? 0),
          type: err.type,
          message: body['message'] as String?,
        ),
      );
      return;
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: AppError(
          message: _mapDioErrorType(err.type),
          errorCode: 'NETWORK_ERROR',
          statusCode: statusCode,
        ),
        type: err.type,
      ),
    );
  }

  String _mapDioErrorType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your network.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      case DioExceptionType.badCertificate:
        return 'Certificate verification failed.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'An unexpected network error occurred.';
    }
  }
}
