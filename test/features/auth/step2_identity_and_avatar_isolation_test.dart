import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/auth_session.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/data/datasources/demo_community_data_provider.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/presentation/bindings/profile_binding.dart';
import 'package:genlink_frontend/shared/utils/current_user.dart';

class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
  }) async {
    _data['accessToken'] = accessToken;
    _data['refreshToken'] = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => _data['accessToken'];

  @override
  Future<String?> readRefreshToken() async => _data['refreshToken'];

  @override
  Future<void> saveUserId(String userId) async => _data['userId'] = userId;

  @override
  Future<String?> readUserId() async => _data['userId'];

  @override
  Future<void> saveUserEmail(String email) async => _data['userEmail'] = email;

  @override
  Future<String?> readUserEmail() async => _data['userEmail'];

  @override
  Future<void> clearAll() async => _data.clear();
}

class FakeLocalStorage extends LocalStorage {
  final Map<String, dynamic> _storage = {};

  String? getString(String key) => _storage[key] as String?;

  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }
}

class FakeAuthRepository implements AuthRepository {
  UserEntity? userToReturn;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'test_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'test_refresh_token',
      tokenType: 'Bearer',
      user: userToReturn!,
    );
  }

  @override
  Future<UserEntity> getCurrentUser() async => userToReturn!;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> googleLogin({required String idToken}) {
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
  Future<AuthSession> verifyEmail({required String email, required String otp}) {
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
  Future<void> verifyResetOtp({required String email, required String otp}) {
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStorage secureStorage;
  late FakeLocalStorage localStorage;
  late LocalizationService localization;
  late FakeAuthRepository authRepo;
  late AuthController authController;

  const userA = UserEntity(
    id: 'user-nat-uuid-1234',
    fullName: 'Nat Sok',
    username: 'natsok',
    email: 'nat@example.com',
    avatarUrl: 'https://cdn.example.com/avatar_nat.jpg',
    emailVerified: true,
    accountStatus: 'ACTIVE',
    totalXp: 120,
    level: 2,
    preferredLanguage: 'ENGLISH',
    role: 'USER',
    active: true,
  );

  const userB = UserEntity(
    id: 'user-sothea-uuid-5678',
    fullName: 'Sothea Vuth',
    username: 'sotheav',
    email: 'sothea@example.com',
    avatarUrl: 'https://cdn.example.com/avatar_sothea.png',
    emailVerified: true,
    accountStatus: 'ACTIVE',
    totalXp: 350,
    level: 4,
    preferredLanguage: 'KHMER',
    role: 'USER',
    active: true,
  );

  setUp(() {
    Get.reset();
    Get.testMode = true;
    secureStorage = FakeSecureStorage();
    localStorage = FakeLocalStorage();
    localization = LocalizationService(localStorage: localStorage);
    authRepo = FakeAuthRepository();

    authController = AuthController(
      authRepository: authRepo,
      secureStorage: secureStorage,
      localization: localization,
    );
    Get.put<AuthController>(authController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Step 2: Current User Identity & Consistency', () {
    test('User A login establishes consistent identity in CurrentUser helper', () async {
      authRepo.userToReturn = userA;
      final success = await authController.login(
        email: userA.email,
        password: 'password123',
      );

      expect(success, isTrue);
      expect(CurrentUser.id, equals(userA.id));
      expect(CurrentUser.name, equals(userA.fullName));
      expect(CurrentUser.username, equals(userA.username));
      expect(CurrentUser.avatarUrl, equals(userA.avatarUrl));
    });

    test('Profile sync updates AuthController and CurrentUser avatar', () {
      authController.updateCachedUser(userA);
      expect(CurrentUser.avatarUrl, equals(userA.avatarUrl));

      const updatedProfile = ProfileEntity(
        userId: 'user-nat-uuid-1234',
        fullName: 'Nat Sok Updated',
        username: 'natsok',
        email: 'nat@example.com',
        avatarUrl: 'https://cdn.example.com/avatar_nat_new.jpg',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 150,
        level: 3,
        preferredLanguage: 'ENGLISH',
      );

      ProfileBinding.syncCachedAuthUser(updatedProfile);

      expect(CurrentUser.name, equals('Nat Sok Updated'));
      expect(CurrentUser.avatarUrl, equals('https://cdn.example.com/avatar_nat_new.jpg'));
    });
  });

  group('Step 2: CommunityPostModel and Post Ownership Isolation', () {
    test('Post parsed for CurrentUser receives correct isOwner and author details', () {
      authController.updateCachedUser(userA);

      final backendPostJson = {
        'postId': 'post_backend_101',
        'author': {
          'userId': userA.id,
          'fullName': userA.fullName,
          'username': userA.username,
          'avatarUrl': null,
        },
        'contentText': 'Testing post author resolution',
        'imageUrls': <String>[],
        'likeCount': 0,
        'commentCount': 0,
        'sharesCount': 0,
      };

      final parsed = CommunityPostModel.fromJson(backendPostJson);

      expect(parsed.id, equals('post_backend_101'));
      expect(parsed.userId, equals(userA.id));
      expect(parsed.authorName, equals(userA.fullName));
      expect(parsed.authorTag, equals('@${userA.username}'));
      expect(parsed.authorAvatar, equals(userA.avatarUrl));
      expect(parsed.isOwner, isTrue);
    });

    test('Demo posts have isOwner = false and belong to demo users, not CurrentUser', () {
      authController.updateCachedUser(userA);

      final demoPosts = DemoCommunityDataProvider.getDay15DemoPosts();
      for (final post in demoPosts) {
        expect(post.isOwner, isFalse);
        expect(post.userId, isNot(equals(userA.id)));
      }
    });

    test('getUserPosts returns ONLY posts belonging to the target userId', () {
      authController.updateCachedUser(userA);

      final controller = CommunityController();

      final postA1 = CommunityPostModel(
        id: 'post_user_a_1',
        userId: userA.id,
        authorName: userA.fullName,
        authorTag: '@${userA.username}',
        authorAvatar: userA.avatarUrl ?? '',
        timeAgo: 'Just now',
        content: 'Post by Nat',
        isOwner: true,
      );

      final postB1 = CommunityPostModel(
        id: 'post_user_b_1',
        userId: userB.id,
        authorName: userB.fullName,
        authorTag: '@${userB.username}',
        authorAvatar: userB.avatarUrl ?? '',
        timeAgo: 'Just now',
        content: 'Post by Sothea',
        isOwner: false,
      );

      final demoPosts = DemoCommunityDataProvider.getDay15DemoPosts();

      controller.posts.assignAll([postA1, postB1, ...demoPosts]);

      // When User A views User A profile posts
      final userAPosts = controller.getUserPosts(userA.id, username: userA.fullName);
      expect(userAPosts.length, equals(1));
      expect(userAPosts.first.id, equals('post_user_a_1'));
      expect(userAPosts.first.authorName, equals(userA.fullName));

      // Verify Sokny Enat demo posts are NEVER returned for User A
      final containsDemo = userAPosts.any((p) => p.authorName == 'Sokny Enat' || p.id == 'post_day15_1');
      expect(containsDemo, isFalse);

      // When User B views User B profile posts
      final userBPosts = controller.getUserPosts(userB.id, username: userB.fullName);
      expect(userBPosts.length, equals(1));
      expect(userBPosts.first.id, equals('post_user_b_1'));
      expect(userBPosts.first.authorName, equals(userB.fullName));
    });
  });

  group('Step 2: Multi-User Session Isolation & Logout Clearing', () {
    test('Switching from User A to User B completely isolates state', () async {
      // 1. User A logs in
      authRepo.userToReturn = userA;
      await authController.login(email: userA.email, password: 'pw');
      expect(CurrentUser.id, equals(userA.id));
      expect(CurrentUser.name, equals(userA.fullName));
      expect(CurrentUser.avatarUrl, equals(userA.avatarUrl));

      // 2. Logout clears session
      await authController.logout();
      expect(CurrentUser.get(), isNull);
      expect(CurrentUser.id, isEmpty);
      expect(CurrentUser.avatarUrl, isNull);
      expect(authController.isAuthenticated.value, isFalse);

      // 3. User B logs in
      authRepo.userToReturn = userB;
      await authController.login(email: userB.email, password: 'pw');
      expect(CurrentUser.id, equals(userB.id));
      expect(CurrentUser.name, equals(userB.fullName));
      expect(CurrentUser.avatarUrl, equals(userB.avatarUrl));

      // Verify no traces of User A remain in User B session
      expect(CurrentUser.id, isNot(equals(userA.id)));
      expect(CurrentUser.name, isNot(equals(userA.fullName)));
      expect(CurrentUser.avatarUrl, isNot(equals(userA.avatarUrl)));
    });
  });
}
