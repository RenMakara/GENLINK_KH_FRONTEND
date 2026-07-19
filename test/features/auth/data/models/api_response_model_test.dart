import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/auth/data/models/api_response_model.dart';

void main() {
  group('ApiResponseModel', () {
    test('fromJson parses success response with data', () {
      final json = {
        'success': true,
        'message': 'Login successful',
        'data': {
          'accessToken': 'token-123',
          'refreshToken': 'refresh-456',
        },
        'errorCode': null,
        'timestamp': '2024-01-01T00:00:00Z',
      };

      final response = ApiResponseModel<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.message, 'Login successful');
      expect(response.data, isNotNull);
      expect(response.data!['accessToken'], 'token-123');
      expect(response.errorCode, isNull);
      expect(response.timestamp, '2024-01-01T00:00:00Z');
    });

    test('fromJson parses error response', () {
      final json = {
        'success': false,
        'message': 'Invalid email or password',
        'data': null,
        'errorCode': 'AUTH_INVALID_CREDENTIALS',
        'timestamp': '2024-01-01T00:00:00Z',
      };

      final response = ApiResponseModel<dynamic>.fromJson(json, null);

      expect(response.success, isFalse);
      expect(response.message, 'Invalid email or password');
      expect(response.data, isNull);
      expect(response.errorCode, 'AUTH_INVALID_CREDENTIALS');
    });

    test('fromJson parses message-only response', () {
      final json = {
        'success': true,
        'message': 'Registration successful. Please check your email.',
        'data': null,
      };

      final response = ApiResponseModel<dynamic>.fromJson(json, null);

      expect(response.success, isTrue);
      expect(response.message, 'Registration successful. Please check your email.');
      expect(response.data, isNull);
      expect(response.errorCode, isNull);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'success': true,
      };

      final response = ApiResponseModel<dynamic>.fromJson(json, null);

      expect(response.success, isTrue);
      expect(response.message, isNull);
      expect(response.data, isNull);
      expect(response.errorCode, isNull);
      expect(response.timestamp, isNull);
    });

    test('fromJson with dataFromJson parser', () {
      final json = {
        'success': true,
        'data': 'some-string-data',
      };

      final response = ApiResponseModel<String>.fromJson(
        json,
        (data) => data as String,
      );

      expect(response.data, 'some-string-data');
    });
  });
}
