import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
