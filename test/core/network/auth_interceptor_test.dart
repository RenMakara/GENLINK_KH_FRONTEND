import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/interceptors/auth_interceptor.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/auth_session.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AuthInterceptor', () {
    test('blocks protected requests without a token before network', () async {
      final storage = _FakeSecureStorage();
      final auth = _FakeAuthRepository();
      var expiredCalls = 0;
      final adapter = _RecordingAdapter();
      final dio = _dioWith(
        storage: storage,
        authRepository: auth,
        adapter: adapter,
        onSessionExpired: () => expiredCalls++,
      );

      final error = await _captureDioError(
        () => dio.get<dynamic>('/api/v1/entertainment/quizzes'),
      );

      expect(adapter.calls, 0);
      expect(error.response?.statusCode, 401);
      expect(error.response?.data['errorCode'], 'AUTH_REQUIRED');
      expect(expiredCalls, 1);
    });

    test('clears legacy demo tokens and blocks before network', () async {
      final storage = _FakeSecureStorage(accessToken: 'demo_access_token');
      final auth = _FakeAuthRepository();
      final adapter = _RecordingAdapter();
      final dio = _dioWith(
        storage: storage,
        authRepository: auth,
        adapter: adapter,
      );

      final error = await _captureDioError(
        () => dio.get<dynamic>('/api/v1/entertainment/quizzes'),
      );

      expect(adapter.calls, 0);
      expect(error.response?.statusCode, 401);
      expect(storage.cleared, isTrue);
      expect(await storage.readAccessToken(), isNull);
    });

    test('attaches real bearer token to protected requests', () async {
      final storage = _FakeSecureStorage(accessToken: 'real-access-token');
      final auth = _FakeAuthRepository();
      final adapter = _RecordingAdapter();
      final dio = _dioWith(
        storage: storage,
        authRepository: auth,
        adapter: adapter,
      );

      await dio.get<dynamic>('/api/v1/entertainment/quizzes');

      expect(adapter.calls, 1);
      expect(
        adapter.lastOptions?.headers['Authorization'],
        'Bearer real-access-token',
      );
    });
  });
}

Dio _dioWith({
  required _FakeSecureStorage storage,
  required AuthRepository authRepository,
  required _RecordingAdapter adapter,
  void Function()? onSessionExpired,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
  final interceptor = AuthInterceptor(
    secureStorage: storage,
    authRepository: authRepository,
    onSessionExpired: onSessionExpired,
  )..client = dio;
  dio.interceptors.add(interceptor);
  dio.httpClientAdapter = adapter;
  return dio;
}

Future<DioException> _captureDioError(Future<void> Function() action) async {
  try {
    await action();
  } on DioException catch (error) {
    return error;
  }
  fail('Expected DioException');
}

class _RecordingAdapter implements HttpClientAdapter {
  int calls = 0;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastOptions = options;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': []}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorage {
  _FakeSecureStorage({this.accessToken});

  String? accessToken;
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> clearAll() async {
    cleared = true;
    accessToken = null;
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber,
    required String password,
    String? universityName,
    String? workStatus,
    String? preferredLanguage,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> googleLogin({required String idToken}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String otp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> verifyOtp({required String email, required String otp}) {
    throw UnimplementedError();
  }

  @override
  Future<void> resendOtp({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> resendVerificationOtp({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }
}
