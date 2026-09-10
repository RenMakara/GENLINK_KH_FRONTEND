import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/auth/data/models/auth_response_model.dart';

void main() {
  group('AuthResponseModel', () {
    test('fromJson parses complete auth response', () {
      final json = {
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9...',
        'refreshToken': 'eyJhbGciOiJIUzI1NiJ9...',
        'tokenType': 'Bearer',
        'user': {
          'userId': '550e8400-e29b-41d4-a716-446655440000',
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'phoneNumber': '+85512345678',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'bio': 'Software developer',
          'universityName': 'Royal University of Phnom Penh',
          'workStatus': 'STUDENT',
          'location': 'Phnom Penh',
          'emailVerified': true,
          'accountStatus': 'ACTIVE',
          'totalXp': 500,
          'level': 5,
          'preferredLanguage': 'ENGLISH',
          'role': 'USER',
          'active': true,
        },
      };

      final model = AuthResponseModel.fromJson(json);

      expect(model.accessToken, 'eyJhbGciOiJIUzI1NiJ9...');
      expect(model.refreshToken, 'eyJhbGciOiJIUzI1NiJ9...');
      expect(model.tokenType, 'Bearer');
      expect(model.user.userId, '550e8400-e29b-41d4-a716-446655440000');
      expect(model.user.fullName, 'John Doe');
      expect(model.user.username, 'johndoe');
      expect(model.user.email, 'john@example.com');
      expect(model.user.phoneNumber, '+85512345678');
      expect(model.user.emailVerified, isTrue);
      expect(model.user.accountStatus, 'ACTIVE');
      expect(model.user.totalXp, 500);
      expect(model.user.level, 5);
      expect(model.user.role, 'USER');
      expect(model.user.active, isTrue);
    });

    test('fromJson handles null user gracefully', () {
      final json = {
        'accessToken': 'token',
        'refreshToken': 'refresh',
        'tokenType': 'Bearer',
        'user': null,
      };

      final model = AuthResponseModel.fromJson(json);
      expect(model.accessToken, 'token');
      expect(model.user.userId, '');
      expect(model.user.fullName, '');
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'accessToken': 'token',
        'refreshToken': 'refresh',
        'tokenType': 'Bearer',
        'user': <String, dynamic>{},
      };

      final model = AuthResponseModel.fromJson(json);

      expect(model.user.userId, '');
      expect(model.user.fullName, '');
      expect(model.user.email, '');
      expect(model.user.emailVerified, isFalse);
      expect(model.user.accountStatus, 'PENDING');
      expect(model.user.totalXp, 0);
      expect(model.user.level, 1);
      expect(model.user.role, 'USER');
      expect(model.user.active, isFalse);
    });
  });
}
