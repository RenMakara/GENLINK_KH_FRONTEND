import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';

void main() {
  final requestOptions = RequestOptions(path: '/api/v1/auth/login');

  group('AppError.fromDio', () {
    test('unwraps the AppError attached by ErrorInterceptor', () {
      const original = AppError(
        message: 'Invalid email or password',
        errorCode: 'AUTH_INVALID_CREDENTIALS',
        statusCode: 401,
      );

      final unwrapped = AppError.fromDio(
        DioException(requestOptions: requestOptions, error: original),
      );

      expect(unwrapped.message, 'Invalid email or password');
      expect(unwrapped.errorCode, 'AUTH_INVALID_CREDENTIALS');
      expect(unwrapped.isInvalidCredentials, isTrue);
    });

    test('falls back to a network error when nothing was attached', () {
      final unwrapped = AppError.fromDio(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      );

      expect(unwrapped.errorCode, 'NETWORK_ERROR');
      expect(unwrapped.message, 'Connection refused');
    });
  });

  group('guardDio', () {
    test('converts a thrown DioException into an AppError', () {
      const original = AppError(
        message: 'Email is already registered',
        errorCode: 'AUTH_EMAIL_TAKEN',
        statusCode: 409,
      );

      expect(
        () => guardDio<void>(
          () async => throw DioException(
            requestOptions: requestOptions,
            error: original,
          ),
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'message',
            'Email is already registered',
          ),
        ),
      );
    });

    test('passes a successful call straight through', () async {
      expect(await guardDio(() async => 42), 42);
    });
  });
}
