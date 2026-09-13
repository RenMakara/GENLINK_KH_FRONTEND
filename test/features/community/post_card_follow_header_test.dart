import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class MockCommunityFollowRepository implements CommunityRepository {
  List<CommunityPostModel> mockPosts = [];
  final Set<String> followedUserIds = {};
  int followCallCount = 0;
  int unfollowCallCount = 0;
  int checkFollowCallCount = 0;
  bool shouldFailFollow = false;
  Duration? simulatedDelay;

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return mockPosts;
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'mock_created',
      userId: 'user_me',
      authorName: 'Sokny Enat',
      authorTag: '@soknyenat',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      isOwner: true,
    );
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    return mockPosts.firstWhere((p) => p.id == postId);
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    return mockPosts.firstWhere((p) => p.id == postId);
  }

  @override
  Future<bool> deletePost(String postId) async => true;

  @override
  Future<bool> toggleLike(String postId) async => true;

  @override
  Future<bool> toggleBookmark(String postId) async => true;

  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async => true;

  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;

  @override
  Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'}) async => true;

  @override
  Future<List<CommentModel>> getComments(String postId) async => [];

  @override
  Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async {
    return CommentModel(
      id: 'c1',
      postId: postId,
      userId: 'user_me',
      userName: 'Sokny',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
    );
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;

  @override
  Future<bool> followUser(String userId) async {
    followCallCount++;
    if (simulatedDelay != null) {
      await Future.delayed(simulatedDelay!);
    }
    if (shouldFailFollow) {
      throw Exception('API error: unable to follow user');
    }
    followedUserIds.add(userId);
    return true;
  }

  @override
  Future<bool> unfollowUser(String userId) async {
    unfollowCallCount++;
    if (simulatedDelay != null) {
      await Future.delayed(simulatedDelay!);
    }
    followedUserIds.remove(userId);
    return true;
  }

  @override
  Future<bool> checkIsFollowing(String userId) async {
    checkFollowCallCount++;
    return followedUserIds.contains(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSecureStorage implements SecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalizationService extends GetxService implements LocalizationService {
  @override
  final language = 'en'.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockCommunityFollowRepository mockRepo;
  late CommunityController controller;
  late AuthController authController;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    authController = AuthController(
      authRepository: FakeAuthRepository(),
      secureStorage: FakeSecureStorage(),
      localization: FakeLocalizationService(),
    );
    authController.currentUser.value = const UserEntity(
      id: 'user_current_123',
      fullName: 'Sokny Enat',
      username: 'soknyenat',
      email: 'sokny@genlink.kh',
      active: true,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      preferredLanguage: 'en',
      role: 'USER',
      totalXp: 100,
      level: 1,
    );
    Get.put<AuthController>(authController);

    mockRepo = MockCommunityFollowRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('GenLink Post Card Follow Button & Header Polish Tests (A-H)', () {
    testWidgets('Test A: Open another user\'s post -> Not following -> "+ Follow" appears', (tester) async {
      final otherPost = CommunityPostModel(
        id: 'post_other_1',
        userId: 'user_chansela',
        authorName: 'Heng Chansela',
        authorTag: '@hengchansela',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Campus life at AUB! ☕📸',
        community: 'ACLEDA University of Business',
        isFollowing: false,
        isOwner: false,
      );
      controller.posts.assignAll([otherPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: otherPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Follow'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('Following'), findsNothing);
    });

    testWidgets('Test B: Tap Follow -> Existing API is called -> Success -> "Following" appears', (tester) async {
      final otherPost = CommunityPostModel(
        id: 'post_other_1',
        userId: 'user_chansela',
        authorName: 'Heng Chansela',
        authorTag: '@hengchansela',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Campus life at AUB! ☕📸',
        community: 'ACLEDA University of Business',
        isFollowing: false,
        isOwner: false,
      );
      controller.posts.assignAll([otherPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: otherPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Follow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(mockRepo.followCallCount, equals(1));
      expect(mockRepo.followedUserIds.contains('user_chansela'), isTrue);

      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Follow'), findsNothing);
    });

    testWidgets('Test C: Tap Following -> Existing unfollow API is called -> Success -> "+ Follow" appears', (tester) async {
      final otherPost = CommunityPostModel(
        id: 'post_other_1',
        userId: 'user_chansela',
        authorName: 'Heng Chansela',
        authorTag: '@hengchansela',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Campus life at AUB! ☕📸',
        community: 'ACLEDA University of Business',
        isFollowing: true,
        isOwner: false,
      );
      mockRepo.followedUserIds.add('user_chansela');
      controller.posts.assignAll([otherPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: otherPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Following'), findsOneWidget);

      await tester.tap(find.text('Following'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(mockRepo.unfollowCallCount, equals(1));
      expect(mockRepo.followedUserIds.contains('user_chansela'), isFalse);

      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('Following'), findsNothing);
    });

    testWidgets('Test D: Open the same author\'s post again -> Correct relationship state is loaded', (tester) async {
      mockRepo.followedUserIds.add('user_chansela');

      final postA = CommunityPostModel(
        id: 'post_1',
        userId: 'user_chansela',
        authorName: 'Heng Chansela',
        authorTag: '@hengchansela',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'First post by Chansela',
        community: 'ACLEDA University of Business',
        isFollowing: true,
        isOwner: false,
      );
      mockRepo.mockPosts = [postA];

      await controller.fetchPosts();

      expect(controller.posts.first.isFollowing, isTrue);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: controller.posts.first,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Follow'), findsNothing);
    });

    testWidgets('Test E: Open own post -> Follow button is hidden & ⋯ menu remains in normal position', (tester) async {
      final ownPost = CommunityPostModel(
        id: 'post_own_1',
        userId: 'user_current_123',
        authorName: 'Sokny Enat',
        authorTag: '@soknyenat',
        authorAvatar: '',
        timeAgo: '10m ago',
        content: 'This is my own post on GenLink!',
        community: 'ACLEDA University of Business',
        isOwner: true,
      );
      controller.posts.assignAll([ownPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: ownPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Follow'), findsNothing);
      expect(find.text('Following'), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsNothing);

      expect(find.byTooltip('Options'), findsOneWidget);
    });

    testWidgets('Test F: API failure -> Previous state remains ("+ Follow")', (tester) async {
      mockRepo.shouldFailFollow = true;

      final otherPost = CommunityPostModel(
        id: 'post_fail_1',
        userId: 'user_makara',
        authorName: 'Ren Makara',
        authorTag: '@renmakara',
        authorAvatar: '',
        timeAgo: '3h ago',
        content: 'Post testing failure state',
        community: 'ACLEDA University of Business',
        isFollowing: false,
        isOwner: false,
      );
      controller.posts.assignAll([otherPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: otherPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('follow')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('follow')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(controller.posts.first.isFollowing, isFalse);
      expect(find.byKey(const ValueKey('follow')), findsOneWidget);
      expect(find.byKey(const ValueKey('following')), findsNothing);
    });

    testWidgets('Test G: Rapid tapping -> No duplicate API requests while in-flight', (tester) async {
      mockRepo.simulatedDelay = const Duration(milliseconds: 300);

      final otherPost = CommunityPostModel(
        id: 'post_rapid_1',
        userId: 'user_makara',
        authorName: 'Ren Makara',
        authorTag: '@renmakara',
        authorAvatar: '',
        timeAgo: '3h ago',
        content: 'Testing rapid tapping prevention',
        community: 'ACLEDA University of Business',
        isFollowing: false,
        isOwner: false,
      );
      controller.posts.assignAll([otherPost]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: otherPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Follow'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byType(InkWell).first);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byType(InkWell).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(mockRepo.followCallCount, equals(1));
    });

    testWidgets('Test H: Small screen responsive test -> Header does not overflow and university truncates gracefully', (tester) async {
      final narrowPost = CommunityPostModel(
        id: 'post_narrow_1',
        userId: 'user_chansela',
        authorName: 'Heng Chansela Very Long Name That Might Exceed Bounds',
        authorTag: '@hengchansela',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Small screen responsiveness test.',
        community: 'ACLEDA University of Business (AUB) Cambodia Institute of Technology',
        isFollowing: false,
        isOwner: false,
      );
      controller.posts.assignAll([narrowPost]);

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: narrowPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Heng Chansela Very Long Name That Might Exceed Bounds'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
      expect(find.byTooltip('Options'), findsOneWidget);
    });
  });
}
