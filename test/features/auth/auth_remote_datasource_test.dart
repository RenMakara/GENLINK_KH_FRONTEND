import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
  test('login extracts accessToken from the Postman data envelope', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _LoginResponseAdapter();

    final response = await AuthRemoteDatasource(
      dio,
    ).login(email: 'user@example.com', password: 'correct-password');

    expect(response.accessToken, 'real-access-token');
    expect(response.refreshToken, 'real-refresh-token');
    expect(response.tokenType, 'Bearer');
  });

  test('setPassword posts the setup payload and reads hasPassword', () async {
    final adapter = _PasswordResponseAdapter();
    final datasource = AuthRemoteDatasource(
      Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter,
    );

    final hasPassword = await datasource.setPassword(password: 'Password123');

    expect(hasPassword, isTrue);
    expect(adapter.requests.single.path, ApiEndpoints.setPassword);
    expect(adapter.requests.single.data, {'password': 'Password123'});
  });

  test('changePassword posts the existing security payload', () async {
    final adapter = _PasswordResponseAdapter();
    final datasource = AuthRemoteDatasource(
      Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter,
    );

    await datasource.changePassword(
      currentPassword: 'OldPassword123',
      newPassword: 'NewPassword123',
    );

    expect(adapter.requests.single.path, ApiEndpoints.changePassword);
    expect(adapter.requests.single.data, {
      'currentPassword': 'OldPassword123',
      'newPassword': 'NewPassword123',
    });
  });
}

class _LoginResponseAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'message': 'Login successful',
        'data': {
          'accessToken': 'real-access-token',
          'refreshToken': 'real-refresh-token',
          'tokenType': 'Bearer',
          'user': <String, dynamic>{},
        },
        'errorCode': null,
        'timestamp': '2026-09-01T00:00:00Z',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PasswordResponseAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final isSetup = options.path == ApiEndpoints.setPassword;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'message': isSetup ? 'Password set successfully' : 'Password changed',
        'data': isSetup ? {'hasPassword': true} : null,
        'errorCode': null,
        'timestamp': '2026-09-01T00:00:00Z',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
