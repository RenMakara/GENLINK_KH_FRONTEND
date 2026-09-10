import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';

class MockCommunityRepository implements CommunityRepository {
  List<CommunityPostModel> mockPosts = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return mockPosts;
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'mock_1',
      userId: 'user_me',
      authorName: 'Sokny Enat',
      authorTag: '@soknyenat',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
      isOwner: true,
    );
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    return mockPosts.firstWhere((p) => p.id == postId);
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    final idx = mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      mockPosts[idx] = mockPosts[idx].copyWith(content: content);
      return mockPosts[idx];
    }
    throw Exception('Not found');
  }

  @override
  Future<bool> deletePost(String postId) async {
    mockPosts.removeWhere((p) => p.id == postId);
    return true;
  }

  @override
  Future<bool> toggleLike(String postId) async => true;

  @override
  Future<bool> toggleBookmark(String postId) async => true;

  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async {
    final idx = mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      mockPosts[idx] = mockPosts[idx].copyWith(
        sharesCount: mockPosts[idx].sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: 'Sokny Enat',
        repostCaption: caption,
        reposterId: reposterId ?? 'user_me',
        originalPostId: mockPosts[idx].id,
      );
    }
    return true;
  }

  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async {
    final idx = mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      mockPosts[idx] = mockPosts[idx].copyWith(
        sharesCount: mockPosts[idx].sharesCount > 0 ? mockPosts[idx].sharesCount - 1 : 0,
        isRepostedByMe: false,
        repostedBy: null,
        repostCaption: null,
        reposterId: null,
        originalPostId: null,
      );
    }
    return true;
  }

  @override
  Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'}) async => true;

  @override
  Future<List<CommentModel>> getComments(String postId) async => [];

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    return CommentModel(
      id: 'comment_1',
      postId: postId,
      userId: 'user_me',
      userName: 'Sokny Enat',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
    );
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;

  final Set<String> followedUsers = {};

  @override
  Future<bool> followUser(String userId) async {
    followedUsers.add(userId);
    return true;
  }

  @override
  Future<bool> unfollowUser(String userId) async {
    followedUsers.remove(userId);
    return true;
  }

  @override
  Future<bool> checkIsFollowing(String userId) async {
    return followedUsers.contains(userId);
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
  late MockCommunityRepository mockRepo;
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
      id: 'user_me',
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

    mockRepo = MockCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('GenLink Community Repost UX & Duplicate Prevention Tests', () {
    testWidgets('Test 1: Current user opens own post -> No Repost option in menu', (tester) async {
      final ownPost = CommunityPostModel(
        id: 'post_own_1',
        userId: 'user_me',
        authorName: 'Sokny Enat',
        authorTag: '@soknyenat',
        authorAvatar: '',
        timeAgo: '10m ago',
        content: 'This is my own post on GenLink!',
        isOwner: true,
      );

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

      await tester.tap(find.byTooltip('Options'));
      await tester.pumpAndSettle();

      expect(find.text('Save Bookmark'), findsOneWidget);
      expect(find.text('Edit Post'), findsOneWidget);
      expect(find.text('Delete Post'), findsOneWidget);

      expect(find.text('Repost'), findsNothing);
      expect(find.text('Report Post'), findsNothing);
    });

    testWidgets("Test 2: Current user opens another user's post -> Repost option appears", (tester) async {
      final otherUserPost = CommunityPostModel(
        id: 'post_other_1',
        userId: 'user_other',
        authorName: 'Ren Makara',
        authorTag: '@renmakara',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Learning Spring Boot and Flutter microservices!',
        isOwner: false,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: otherUserPost,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Options'));
      await tester.pumpAndSettle();

      expect(find.text('Save Bookmark'), findsOneWidget);
      expect(find.text('Repost'), findsOneWidget);
      expect(find.text('Report Post'), findsOneWidget);

      expect(find.text('Edit Post'), findsNothing);
      expect(find.text('Delete Post'), findsNothing);
    });

    test('Test 3: User reposts another user\'s post -> Repost succeeds and references original post', () {
      final otherPost = CommunityPostModel(
        id: 'post_other_1',
        userId: 'user_other',
        authorName: 'Ren Makara',
        authorTag: '@renmakara',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Check out AuthGate project!',
        sharesCount: 5,
        isOwner: false,
      );

      controller.posts.assignAll([otherPost]);

      controller.repostPost('post_other_1', caption: 'Must read for developers!');

      expect(controller.posts.length, equals(1));

      final updatedPost = controller.posts.first;
      expect(updatedPost.id, equals('post_other_1'));
      expect(updatedPost.originalPostId, equals('post_other_1'));
      expect(updatedPost.sharesCount, equals(6));
      expect(updatedPost.isRepostedByMe, isTrue);
      expect(updatedPost.repostedBy, equals('Sokny Enat'));
      expect(updatedPost.repostCaption, equals('Must read for developers!'));
      expect(updatedPost.authorName, equals('Ren Makara'));
      expect(updatedPost.content, equals('Check out AuthGate project!'));
    });

    test('Test 4: User tries to repost the same original post again -> No duplicate repost', () {
      final otherPost = CommunityPostModel(
        id: 'post_other_1',
        userId: 'user_other',
        authorName: 'Ren Makara',
        authorTag: '@renmakara',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Check out AuthGate project!',
        sharesCount: 5,
        isOwner: false,
      );

      controller.posts.assignAll([otherPost]);

      controller.repostPost('post_other_1', caption: 'First quote');
      expect(controller.posts.length, equals(1));
      expect(controller.posts.first.sharesCount, equals(6));
      expect(controller.posts.first.isRepostedByMe, isTrue);

      controller.repostPost('post_other_1', caption: 'Duplicate quote attempt');

      expect(controller.posts.length, equals(1));
      expect(controller.posts.first.sharesCount, equals(6));

      controller.unrepostPost('post_other_1');
      expect(controller.posts.first.sharesCount, equals(5));
      expect(controller.posts.first.isRepostedByMe, isFalse);
      expect(controller.posts.first.repostedBy, isNull);
    });

    test('Test 5: Feed avoids creating duplicate copies of the same original content', () {
      final postA = CommunityPostModel(
        id: 'post_100',
        userId: 'user_a',
        authorName: 'User A',
        authorTag: '@usera',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Hello GenLink!',
        sharesCount: 1,
        repostedBy: 'User B',
        originalPostId: 'post_100',
      );

      controller.posts.assignAll([postA]);

      expect(controller.posts.length, equals(1));
      expect(controller.posts.first.id, equals('post_100'));
      expect(controller.posts.first.authorName, equals('User A'));
      expect(controller.posts.first.repostedBy, equals('User B'));
    });

    testWidgets('Test 6: Open the reposter\'s profile -> Repost is associated with user and shows reposter banner', (tester) async {
      final repostedPost = CommunityPostModel(
        id: 'post_100',
        userId: 'user_a',
        authorName: 'User A',
        authorTag: '@usera',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Hello GenLink!',
        sharesCount: 2,
        isRepostedByMe: true,
        repostedBy: 'Sokny Enat',
        repostCaption: 'Great post!',
        reposterId: 'user_me',
        originalPostId: 'post_100',
      );

      controller.posts.assignAll([repostedPost]);

      final userPosts = controller.getUserPosts('user_me', username: 'Sokny Enat');
      expect(userPosts.length, equals(1));
      expect(userPosts.first.repostedBy, equals('Sokny Enat'));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: userPosts.first,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sokny Enat reposted'), findsOneWidget);
      expect(find.text('Great post!'), findsOneWidget);

      expect(find.text('User A'), findsOneWidget);
      expect(find.text('Hello GenLink!'), findsOneWidget);
    });

    test('Test 7: Open original post -> Original author and original post remain unchanged', () {
      final originalPost = CommunityPostModel(
        id: 'post_original_99',
        userId: 'user_original',
        authorName: 'Original Author',
        authorTag: '@originalauthor',
        authorAvatar: 'assets/images/user_avatar.png',
        timeAgo: '3h ago',
        content: 'Original untouched content.',
        imageUrls: ['https://example.com/image.png'],
        likesCount: 10,
        commentsCount: 4,
        sharesCount: 1,
        isOwner: false,
      );

      controller.posts.assignAll([originalPost]);

      controller.repostPost('post_original_99');

      final post = controller.posts.first;
      expect(post.authorName, equals('Original Author'));
      expect(post.authorTag, equals('@originalauthor'));
      expect(post.authorAvatar, equals('assets/images/user_avatar.png'));
      expect(post.content, equals('Original untouched content.'));
      expect(post.imageUrls, equals(['https://example.com/image.png']));
      expect(post.likesCount, equals(10));
      expect(post.commentsCount, equals(4));
    });
  });
}
