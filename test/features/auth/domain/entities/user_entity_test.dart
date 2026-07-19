import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('isAdmin returns true when role is ADMIN', () {
      const user = UserEntity(
        id: '1',
        fullName: 'Admin',
        username: 'admin',
        email: 'admin@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 0,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'ADMIN',
        active: true,
      );
      expect(user.isAdmin, isTrue);
    });

    test('isAdmin returns false when role is USER', () {
      const user = UserEntity(
        id: '1',
        fullName: 'User',
        username: 'user',
        email: 'user@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 0,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
      );
      expect(user.isAdmin, isFalse);
    });

    test('isPending returns true when accountStatus is PENDING', () {
      const user = UserEntity(
        id: '1',
        fullName: 'User',
        username: 'user',
        email: 'user@example.com',
        emailVerified: false,
        accountStatus: 'PENDING',
        totalXp: 0,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: false,
      );
      expect(user.isPending, isTrue);
    });

    test('isActive returns true when accountStatus is ACTIVE and active', () {
      const user = UserEntity(
        id: '1',
        fullName: 'User',
        username: 'user',
        email: 'user@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 2,
        preferredLanguage: 'KHMER',
        role: 'USER',
        active: true,
      );
      expect(user.isActive, isTrue);
    });

    test('isActive returns false when active is false', () {
      const user = UserEntity(
        id: '1',
        fullName: 'User',
        username: 'user',
        email: 'user@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 0,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: false,
      );
      expect(user.isActive, isFalse);
    });

    test('isActive returns false when accountStatus is BANNED', () {
      const user = UserEntity(
        id: '1',
        fullName: 'User',
        username: 'user',
        email: 'user@example.com',
        emailVerified: true,
        accountStatus: 'BANNED',
        totalXp: 0,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
      );
      expect(user.isActive, isFalse);
    });
  });
}
