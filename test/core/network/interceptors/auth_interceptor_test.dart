import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/network/interceptors/auth_interceptor.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/fallback')),
    );
  });

  late _MockAuthRepository repository;
  late _MockSecureStorage storage;
  late _MockErrorInterceptorHandler handler;

  setUp(() {
    repository = _MockAuthRepository();
    storage = _MockSecureStorage();
    handler = _MockErrorInterceptorHandler();
    when(() => handler.next(any())).thenReturn(null);
    when(
      () => storage.readAccessToken(),
    ).thenAnswer((_) async => 'access-token');
  });

  DioException responseError(int statusCode) {
    final options = RequestOptions(path: '/api/v1/profile/me');
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: statusCode,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test(
    'passes 403 through without refreshing or clearing the session',
    () async {
      var sessionExpiredCalls = 0;
      final interceptor = AuthInterceptor(
        secureStorage: storage,
        authRepository: repository,
        onSessionExpired: () => sessionExpiredCalls++,
      );
      final error = responseError(403);

      interceptor.onError(error, handler);
      await untilCalled(() => handler.next(any()));

      verify(() => handler.next(error)).called(1);
      verifyNever(() => storage.readRefreshToken());
      verifyNever(
        () => repository.refreshToken(refreshToken: any(named: 'refreshToken')),
      );
      verifyNever(() => storage.clearAll());
      expect(sessionExpiredCalls, 0);
    },
  );

  test('awaits session cleanup when refresh after a 401 fails', () async {
    when(
      () => storage.readRefreshToken(),
    ).thenAnswer((_) async => 'expired-refresh-token');
    when(
      () => repository.refreshToken(refreshToken: 'expired-refresh-token'),
    ).thenThrow(
      const AppError(
        message: 'Refresh token expired',
        errorCode: 'TOKEN_EXPIRED',
        statusCode: 401,
      ),
    );

    var cleanupFinished = false;
    final interceptor = AuthInterceptor(
      secureStorage: storage,
      authRepository: repository,
      onSessionExpired: () async {
        await Future<void>.delayed(Duration.zero);
        cleanupFinished = true;
      },
    );
    final error = responseError(401);

    interceptor.onError(error, handler);
    await untilCalled(() => handler.next(any()));

    expect(cleanupFinished, isTrue);
    verify(() => handler.next(error)).called(1);
  });

  test(
    'clears secure storage on failed 401 refresh without a callback',
    () async {
      when(() => storage.readRefreshToken()).thenAnswer((_) async => null);
      when(() => storage.clearAll()).thenAnswer((_) async {});
      final interceptor = AuthInterceptor(
        secureStorage: storage,
        authRepository: repository,
      );
      final error = responseError(401);

      interceptor.onError(error, handler);
      await untilCalled(() => handler.next(any()));

      verify(() => storage.clearAll()).called(1);
      verify(() => handler.next(error)).called(1);
    },
  );
}
