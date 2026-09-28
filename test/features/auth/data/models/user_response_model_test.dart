import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/auth/data/models/user_response_model.dart';

void main() {
  group('UserResponseModel', () {
    test('fromJson parses complete user response', () {
      final json = {
        'userId': '550e8400-e29b-41d4-a716-446655440000',
        'fullName': 'Sokha Chan',
        'username': 'sokha',
        'email': 'sokha@example.com',
        'phoneNumber': '+85598765432',
        'avatarUrl': 'https://example.com/sokha.jpg',
        'bio': 'Student at RUPP',
        'universityName': 'Royal University of Phnom Penh',
        'workStatus': 'STUDENT',
        'location': 'Siem Reap',
        'emailVerified': true,
        'accountStatus': 'ACTIVE',
        'totalXp': 1200,
        'level': 12,
        'preferredLanguage': 'KHMER',
        'role': 'ADMIN',
        'active': true,
        'hasPassword': true,
      };

      final model = UserResponseModel.fromJson(json);

      expect(model.userId, '550e8400-e29b-41d4-a716-446655440000');
      expect(model.fullName, 'Sokha Chan');
      expect(model.username, 'sokha');
      expect(model.email, 'sokha@example.com');
      expect(model.phoneNumber, '+85598765432');
      expect(model.avatarUrl, 'https://example.com/sokha.jpg');
      expect(model.bio, 'Student at RUPP');
      expect(model.universityName, 'Royal University of Phnom Penh');
      expect(model.workStatus, 'STUDENT');
      expect(model.location, 'Siem Reap');
      expect(model.emailVerified, isTrue);
      expect(model.accountStatus, 'ACTIVE');
      expect(model.totalXp, 1200);
      expect(model.level, 12);
      expect(model.preferredLanguage, 'KHMER');
      expect(model.role, 'ADMIN');
      expect(model.active, isTrue);
      expect(model.hasPassword, isTrue);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'userId': 'id',
        'fullName': 'Test',
        'username': 'test',
        'email': 'test@example.com',
        'emailVerified': false,
        'accountStatus': 'PENDING',
        'totalXp': 0,
        'level': 1,
        'preferredLanguage': 'ENGLISH',
        'role': 'USER',
        'active': false,
      };

      final model = UserResponseModel.fromJson(json);

      expect(model.phoneNumber, isNull);
      expect(model.avatarUrl, isNull);
      expect(model.bio, isNull);
      expect(model.universityName, isNull);
      expect(model.workStatus, isNull);
      expect(model.location, isNull);
      expect(model.hasPassword, isFalse);
    });

    test('fromJson handles snake_case keys and string booleans', () {
      final json = {
        'id': 'uuid-snake',
        'full_name': 'Snake User',
        'username': 'snakeuser',
        'email': 'snake@example.com',
        'email_verified': 'true',
        'account_status': 'ACTIVE',
        'total_xp': 50,
        'level': 2,
        'preferred_language': 'ENGLISH',
        'role': 'USER',
        'is_active': 'true',
        'has_password': 'true',
      };

      final model = UserResponseModel.fromJson(json);

      expect(model.userId, 'uuid-snake');
      expect(model.fullName, 'Snake User');
      expect(model.emailVerified, isTrue);
      expect(model.active, isTrue);
      expect(model.hasPassword, isTrue);
    });

    test('toEntity maps correctly', () {
      final json = {
        'userId': 'uuid-1',
        'fullName': 'Test User',
        'username': 'testuser',
        'email': 'test@example.com',
        'emailVerified': true,
        'accountStatus': 'ACTIVE',
        'totalXp': 100,
        'level': 3,
        'preferredLanguage': 'ENGLISH',
        'role': 'USER',
        'active': true,
        'hasPassword': true,
      };

      final model = UserResponseModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.id, 'uuid-1');
      expect(entity.fullName, 'Test User');
      expect(entity.username, 'testuser');
      expect(entity.email, 'test@example.com');
      expect(entity.emailVerified, isTrue);
      expect(entity.accountStatus, 'ACTIVE');
      expect(entity.totalXp, 100);
      expect(entity.level, 3);
      expect(entity.preferredLanguage, 'ENGLISH');
      expect(entity.role, 'USER');
      expect(entity.active, isTrue);
      expect(entity.hasPassword, isTrue);
    });
  });
}
