import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/network/interceptors/auth_interceptor.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/auth_session.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository repository;
  late _RecordingSecureStorage storage;
  late AuthController controller;

  setUp(() {
    repository = _MockAuthRepository();
    storage = _RecordingSecureStorage();
    controller = AuthController(
      authRepository: repository,
      secureStorage: storage,
      localization: LocalizationService(localStorage: LocalStorage()),
    );
  });

  test(
    'login persists the real token and the Quiz interceptor uses it',
    () async {
      final session = _session(
        accessToken: 'real-access-token',
        refreshToken: 'real-refresh-token',
      );
      when(
        () => repository.login(
          email: 'user@example.com',
          password: 'correct-password',
        ),
      ).thenAnswer((_) async => session);

      final success = await controller.login(
        email: 'user@example.com',
        password: 'correct-password',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated.value, isTrue);
      expect(storage.savedAccessToken, 'real-access-token');
      expect(await storage.readAccessToken(), 'real-access-token');

      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.interceptors.add(
        AuthInterceptor(secureStorage: storage, authRepository: repository)
          ..client = dio,
      );
      dio.httpClientAdapter = adapter;

      await dio.get<dynamic>('/api/v1/entertainment/quizzes');

      expect(
        adapter.lastOptions?.headers['Authorization'],
        'Bearer real-access-token',
      );
    },
  );

  test('login rejects a response without an access token', () async {
    when(
      () => repository.login(
        email: 'user@example.com',
        password: 'correct-password',
      ),
    ).thenAnswer(
      (_) async => _session(accessToken: '', refreshToken: 'refresh-token'),
    );

    final success = await controller.login(
      email: 'user@example.com',
      password: 'correct-password',
    );

    expect(success, isFalse);
    expect(controller.isAuthenticated.value, isFalse);
    expect(controller.lastErrorCode.value, 'AUTH_TOKEN_MISSING');
    expect(storage.savedAccessToken, isNull);
  });
}

AuthSession _session({
  required String accessToken,
  required String refreshToken,
}) {
  return AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    tokenType: 'Bearer',
    user: const UserEntity(
      id: 'user-1',
      fullName: 'Test User',
      username: 'test-user',
      email: 'user@example.com',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 0,
      level: 1,
      preferredLanguage: 'ENGLISH',
      role: 'USER',
      active: true,
    ),
  );
}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _RecordingSecureStorage extends SecureStorage {
  String? savedAccessToken;
  String? savedRefreshToken;

  @override
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
  }) async {
    savedAccessToken = accessToken;
    savedRefreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => savedAccessToken;

  @override
  Future<void> saveUserEmail(String email) async {}

  @override
  Future<void> saveUserId(String id) async {}
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
