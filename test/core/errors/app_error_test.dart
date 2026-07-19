import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';

void main() {
  group('AppError', () {
    test('fromResponse parses backend error JSON', () {
      final json = {
        'success': false,
        'message': 'Invalid email or password',
        'errorCode': 'AUTH_INVALID_CREDENTIALS',
        'timestamp': '2024-01-01T00:00:00Z',
      };

      final error = AppError.fromResponse(json, 401);

      expect(error.message, 'Invalid email or password');
      expect(error.errorCode, 'AUTH_INVALID_CREDENTIALS');
      expect(error.statusCode, 401);
    });

    test('fromResponse handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final error = AppError.fromResponse(json, 500);

      expect(error.message, 'Unknown error');
      expect(error.errorCode, 'API_ERROR');
      expect(error.statusCode, 500);
    });

    test('isUnauthorized returns true for 401', () {
      const error = AppError(
        message: 'Unauthorized',
        errorCode: 'UNAUTHORIZED',
        statusCode: 401,
      );
      expect(error.isUnauthorized, isTrue);
    });

    test('isTokenExpired returns true for TOKEN_EXPIRED', () {
      const error = AppError(
        message: 'Token expired',
        errorCode: 'TOKEN_EXPIRED',
        statusCode: 401,
      );
      expect(error.isTokenExpired, isTrue);
    });

    test('isRateLimited returns true for RATE_LIMITED', () {
      const error = AppError(
        message: 'Too many requests',
        errorCode: 'RATE_LIMITED',
        statusCode: 429,
      );
      expect(error.isRateLimited, isTrue);
    });

    test('shouldLogout returns true for TOKEN_EXPIRED', () {
      const error = AppError(
        message: 'Token expired',
        errorCode: 'TOKEN_EXPIRED',
        statusCode: 401,
      );
      expect(error.shouldLogout, isTrue);
    });

    test('shouldLogout returns true for TOKEN_REVOKED', () {
      const error = AppError(
        message: 'Token revoked',
        errorCode: 'TOKEN_REVOKED',
        statusCode: 401,
      );
      expect(error.shouldLogout, isTrue);
    });

    test('shouldLogout returns true for TOKEN_REUSE_DETECTED', () {
      const error = AppError(
        message: 'Token reuse detected',
        errorCode: 'TOKEN_REUSE_DETECTED',
        statusCode: 401,
      );
      expect(error.shouldLogout, isTrue);
    });

    test('shouldLogout returns false for AUTH_INVALID_CREDENTIALS', () {
      const error = AppError(
        message: 'Invalid credentials',
        errorCode: 'AUTH_INVALID_CREDENTIALS',
        statusCode: 401,
      );
      expect(error.shouldLogout, isFalse);
    });

    test('isInvalidCredentials returns true', () {
      const error = AppError(
        message: 'Invalid email or password',
        errorCode: 'AUTH_INVALID_CREDENTIALS',
        statusCode: 401,
      );
      expect(error.isInvalidCredentials, isTrue);
    });

    test('isWeakPassword returns true', () {
      const error = AppError(
        message: 'Password must be 8-72 chars',
        errorCode: 'AUTH_WEAK_PASSWORD',
        statusCode: 400,
      );
      expect(error.isWeakPassword, isTrue);
    });

    test('isAccountBanned returns true', () {
      const error = AppError(
        message: 'Account banned',
        errorCode: 'AUTH_ACCOUNT_BANNED',
        statusCode: 403,
      );
      expect(error.isAccountBanned, isTrue);
    });

    test('isOtpInvalid returns true', () {
      const error = AppError(
        message: 'Invalid OTP',
        errorCode: 'OTP_INVALID',
        statusCode: 400,
      );
      expect(error.isOtpInvalid, isTrue);
    });

    test('toString formats correctly', () {
      const error = AppError(
        message: 'Test error',
        errorCode: 'TEST_ERROR',
        statusCode: 400,
      );
      expect(error.toString(), 'AppError(TEST_ERROR): Test error');
    });
  });
}
