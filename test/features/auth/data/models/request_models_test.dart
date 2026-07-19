import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/auth/data/models/login_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/register_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/google_login_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/verify_email_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/forgot_password_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/reset_password_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/refresh_token_request_model.dart';
import 'package:genlink_frontend/features/auth/data/models/resend_otp_request_model.dart';

void main() {
  group('Request Models toJson', () {
    test('LoginRequestModel toJson', () {
      const model = LoginRequestModel(
        email: 'user@example.com',
        password: 'password123',
      );
      final json = model.toJson();
      expect(json['email'], 'user@example.com');
      expect(json['password'], 'password123');
    });

    test('RegisterRequestModel toJson', () {
      const model = RegisterRequestModel(
        fullName: 'John Doe',
        username: 'johndoe',
        email: 'john@example.com',
        phoneNumber: '+85512345678',
        password: 'password123',
        universityName: 'RUPP',
        workStatus: 'STUDENT',
        preferredLanguage: 'ENGLISH',
      );
      final json = model.toJson();
      expect(json['fullName'], 'John Doe');
      expect(json['username'], 'johndoe');
      expect(json['email'], 'john@example.com');
      expect(json['phoneNumber'], '+85512345678');
      expect(json['password'], 'password123');
      expect(json['universityName'], 'RUPP');
      expect(json['workStatus'], 'STUDENT');
      expect(json['preferredLanguage'], 'ENGLISH');
    });

    test('RegisterRequestModel toJson with null optional fields', () {
      const model = RegisterRequestModel(
        fullName: 'Test',
        username: 'test',
        email: 'test@example.com',
        password: 'password123',
      );
      final json = model.toJson();
      expect(json['phoneNumber'], isNull);
      expect(json['universityName'], isNull);
      expect(json['workStatus'], isNull);
      expect(json['preferredLanguage'], isNull);
    });

    test('GoogleLoginRequestModel toJson', () {
      const model = GoogleLoginRequestModel(idToken: 'firebase-id-token');
      final json = model.toJson();
      expect(json['idToken'], 'firebase-id-token');
    });

    test('VerifyEmailRequestModel toJson', () {
      const model = VerifyEmailRequestModel(
        email: 'user@example.com',
        otp: '123456',
      );
      final json = model.toJson();
      expect(json['email'], 'user@example.com');
      expect(json['otp'], '123456');
    });

    test('ForgotPasswordRequestModel toJson', () {
      const model = ForgotPasswordRequestModel(email: 'user@example.com');
      final json = model.toJson();
      expect(json['email'], 'user@example.com');
    });

    test('ResetPasswordRequestModel toJson', () {
      const model = ResetPasswordRequestModel(
        email: 'user@example.com',
        otp: '123456',
        newPassword: 'newpassword123',
      );
      final json = model.toJson();
      expect(json['email'], 'user@example.com');
      expect(json['otp'], '123456');
      expect(json['newPassword'], 'newpassword123');
    });

    test('RefreshTokenRequestModel toJson', () {
      const model = RefreshTokenRequestModel(refreshToken: 'refresh-token');
      final json = model.toJson();
      expect(json['refreshToken'], 'refresh-token');
    });

    test('ResendOtpRequestModel toJson', () {
      const model = ResendOtpRequestModel(email: 'user@example.com');
      final json = model.toJson();
      expect(json['email'], 'user@example.com');
    });
  });
}
