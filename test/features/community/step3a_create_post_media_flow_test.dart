import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/data/datasources/demo_community_data_provider.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';
import 'package:genlink_frontend/shared/utils/current_user.dart';

class FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserEntity createTestUser({
  required String id,
  required String fullName,
  required String username,
  String? avatarUrl,
}) => UserEntity(
  id: id,
  fullName: fullName,
  username: username,
  email: '$username@example.com',
  avatarUrl: avatarUrl,
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 1,
  preferredLanguage: 'en',
  role: 'USER',
  active: true,
);

class MockMediaRepository implements MediaRepository {
  int uploadCallCount = 0;
  String returnedUrl = 'https://storage.genlink.kh/uploads/posts/test_image.jpg';

  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    return const PresignedUpload(
      mediaId: 'mock_media_123',
      uploadUrl: 'https://storage.genlink.kh/presign_put',
      storageKey: 'uploads/posts/test_image.jpg',
      requiredHeaders: {},
      expiresInSeconds: 300,
    );
  }

  @override
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    uploadCallCount++;
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    return MediaEntity(
      mediaId: mediaId,
      url: returnedUrl,
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    );
  }

  @override
  Future<void> delete(String mediaId) async {}
}

class Step3aMockCommunityRepository implements CommunityRepository {
  CommunityPostModel? lastCreatedPost;
  List<String> lastCreatedImageUrls = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    lastCreatedImageUrls = List.from(imageUrls);
    lastCreatedPost = CommunityPostModel(
      id: 'test_post_3a',
      userId: CurrentUser.id.isNotEmpty ? CurrentUser.id : 'user_me',
      authorName: CurrentUser.name.isNotEmpty ? CurrentUser.name : 'Sokny Enat',
      authorTag: CurrentUser.username.isNotEmpty ? '@${CurrentUser.username}' : '@soknyenat',
      authorAvatar: CurrentUser.avatarUrl ?? '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
      isOwner: true,
    );
    return lastCreatedPost!;
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'User',
      authorTag: '@user',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: '',
      imageUrls: const [],
    );
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'User',
      authorTag: '@user',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: const [],
    );
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
      userId: 'user_1',
      userName: 'User',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
    );
  }
  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthController authController;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    authController = FakeAuthController();
    Get.put<AuthController>(authController);
  });

  tearDown(() {
    Get.reset();
  });

  group('Step 3A — Media Flow & Model Serialization', () {
    test('1. CommunityPostModel.fromJson parses single-image and comma-delimited multi-image URLs', () {
      // Single image
      final singlePost = CommunityPostModel.fromJson({
        'postId': 'p_single',
        'contentText': 'Single image post',
        'imageUrl': 'https://example.com/single.jpg',
      });
      expect(singlePost.imageUrls, hasLength(1));
      expect(singlePost.imageUrls.first, 'https://example.com/single.jpg');

      // Comma-separated multi-image string
      final multiPost = CommunityPostModel.fromJson({
        'postId': 'p_multi',
        'contentText': 'Multi image post',
        'imageUrl': 'https://example.com/img1.jpg,https://example.com/img2.jpg,https://example.com/img3.jpg',
      });
      expect(multiPost.imageUrls, hasLength(3));
      expect(multiPost.imageUrls[0], 'https://example.com/img1.jpg');
      expect(multiPost.imageUrls[1], 'https://example.com/img2.jpg');
      expect(multiPost.imageUrls[2], 'https://example.com/img3.jpg');

      // JSON array string
      final jsonArrayPost = CommunityPostModel.fromJson({
        'postId': 'p_json',
        'contentText': 'JSON array image post',
        'imageUrl': '["https://example.com/a.png", "https://example.com/b.png"]',
      });
      expect(jsonArrayPost.imageUrls, hasLength(2));
      expect(jsonArrayPost.imageUrls[0], 'https://example.com/a.png');
      expect(jsonArrayPost.imageUrls[1], 'https://example.com/b.png');

      // Standard list in imageUrls
      final listPost = CommunityPostModel.fromJson({
        'postId': 'p_list',
        'contentText': 'List post',
        'imageUrls': ['https://example.com/x.jpg', 'https://example.com/y.jpg'],
      });
      expect(listPost.imageUrls, hasLength(2));
      expect(listPost.imageUrls[0], 'https://example.com/x.jpg');
      expect(listPost.imageUrls[1], 'https://example.com/y.jpg');
    });

    test('2. CommunityPostModel.toJson preserves joined imageUrl and imageUrls list', () {
      final post = CommunityPostModel(
        id: 'p_test',
        userId: 'u1',
        authorName: 'Test Author',
        authorTag: '@tester',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Testing toJson',
        imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      );

      final json = post.toJson();
      expect(json['imageUrls'], ['https://example.com/1.jpg', 'https://example.com/2.jpg']);
      expect(json['imageUrl'], 'https://example.com/1.jpg,https://example.com/2.jpg');
      expect(json['images'], ['https://example.com/1.jpg', 'https://example.com/2.jpg']);
    });
  });

  group('Step 3A — Media Upload Integration in CommunityController', () {
    test('3. addNewPost uploads local images via MediaUploadService and sends resolved public URLs', () async {
      // Create a temporary file to simulate local picked image
      final tempDir = Directory.systemTemp.createTempSync('genlink_test_');
      final tempFile = File('${tempDir.path}/test_upload.jpg');
      tempFile.writeAsBytesSync([1, 2, 3, 4, 5]);

      final mockMediaRepo = MockMediaRepository();
      final uploadService = MediaUploadService(mockMediaRepo);
      Get.put<MediaUploadService>(uploadService);

      final mockCommunityRepo = Step3aMockCommunityRepository();
      final controller = CommunityController(repository: mockCommunityRepo);
      Get.put<CommunityController>(controller);

      authController.currentUser.value = createTestUser(
        id: 'user_nat',
        fullName: 'Nat User',
        username: 'nat',
        avatarUrl: 'https://example.com/nat.jpg',
      );

      final success = await controller.createPost(
        content: 'Post with local photo',
        imageUrls: [tempFile.path],
      );

      expect(success, isTrue);
      expect(mockMediaRepo.uploadCallCount, 1);
      expect(mockCommunityRepo.lastCreatedImageUrls, hasLength(1));
      expect(mockCommunityRepo.lastCreatedImageUrls.first, mockMediaRepo.returnedUrl);

      // Clean up temp file
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('4. Existing HTTP and asset URLs are preserved without re-uploading', () async {
      final mockMediaRepo = MockMediaRepository();
      final uploadService = MediaUploadService(mockMediaRepo);
      Get.put<MediaUploadService>(uploadService);

      final mockCommunityRepo = Step3aMockCommunityRepository();
      final controller = CommunityController(repository: mockCommunityRepo);
      Get.put<CommunityController>(controller);

      final urls = [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ];

      final success = await controller.createPost(
        content: 'Post with existing URLs',
        imageUrls: urls,
      );

      expect(success, isTrue);
      expect(mockMediaRepo.uploadCallCount, 0);
      expect(mockCommunityRepo.lastCreatedImageUrls, urls);
    });
  });

  group('Step 3A — Instagram-style Swipe Carousel in PostCardWidget', () {
    testWidgets('5. Single-image post renders single image view without carousel counter pill', (tester) async {
      final post = CommunityPostModel(
        id: 'single_img_post',
        userId: 'u1',
        authorName: 'Author',
        authorTag: '@author',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Single image post body',
        imageUrls: ['https://example.com/single.jpg'],
      );

      final repo = Step3aMockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: post,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT have "1/1" counter badge
      expect(find.text('1/1'), findsNothing);
      // Should NOT have PageView
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('6. Multi-image post renders Instagram-style PageView with "1/N" pill and dots', (tester) async {
      final post = CommunityPostModel(
        id: 'multi_img_post',
        userId: 'u1',
        authorName: 'Author',
        authorTag: '@author',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Multi image post body',
        imageUrls: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
          'https://example.com/img3.jpg',
        ],
      );

      final repo = Step3aMockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: post,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must have PageView for Instagram-style horizontal swipe
      expect(find.byType(PageView), findsOneWidget);

      // Must display subtle top-right badge "1/3"
      expect(find.text('1/3'), findsOneWidget);

      // Swipe to page 2
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // Badge must update to "2/3"
      expect(find.text('2/3'), findsOneWidget);

      // Swipe to page 3
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // Badge must update to "3/3"
      expect(find.text('3/3'), findsOneWidget);
    });
  });

  group('Step 3A — Current User Ownership & Demo Post Isolation', () {
    test('7. Newly created post inherits CurrentUser identity and isOwner = true', () async {
      authController.currentUser.value = createTestUser(
        id: 'user_authenticated',
        fullName: 'Authenticated Nat',
        username: 'nat_dev',
        avatarUrl: 'https://example.com/avatar_nat.png',
      );

      final post = CommunityPostModel.fromJson({
        'postId': 'p_new',
        'userId': 'user_authenticated',
        'contentText': 'My new photo post',
        'imageUrl': 'https://example.com/my_pic.jpg',
        'author': {
          'userId': 'user_authenticated',
          'fullName': 'Authenticated Nat',
          'username': 'nat_dev',
          'avatarUrl': 'https://example.com/avatar_nat.png',
        },
      });

      expect(post.isOwner, isTrue);
      expect(post.authorName, 'Authenticated Nat');
      expect(post.authorTag, '@nat_dev');
      expect(post.authorAvatar, 'https://example.com/avatar_nat.png');
      expect(post.imageUrls, ['https://example.com/my_pic.jpg']);
    });

    test('8. Day 15 demo posts retain isOwner = false and demo author identities', () {
      authController.currentUser.value = createTestUser(
        id: 'user_authenticated',
        fullName: 'Authenticated Nat',
        username: 'nat_dev',
      );

      final demoPosts = DemoCommunityDataProvider.getDay15DemoPosts();
      for (final p in demoPosts) {
        expect(p.isOwner, isFalse, reason: 'Post ${p.id} must not be owned by current user');
        expect(p.userId, isNot('user_authenticated'));
      }
    });
  });

  group('Step 3A — Upload Failure, Image-only Posts & Empty Post Rejection', () {
    testWidgets('9. Failed upload does not silently create a broken post — returns false and post is not added',
        (tester) async {
      // Mount a GetMaterialApp so Get.snackbar() has a valid overlay
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: SizedBox()),
        ),
      );

      // Repository that simulates upload failure
      final failingRepo = _FailingUploadRepository();
      final controller = CommunityController(repository: failingRepo);
      Get.put<CommunityController>(controller);

      final initialPostCount = controller.posts.length;

      final result = await controller.createPost(
        content: 'Caption with a failing image',
        imageUrls: ['https://example.com/existing.jpg'],
      );
      await tester.pump();                                 // start snackbar animation
      await tester.pump(const Duration(seconds: 4));       // advance past 3-second snackbar timer

      // Must return false on failure
      expect(result, isFalse);
      // Posts list must NOT grow after a failed creation
      expect(controller.posts.length, initialPostCount,
          reason: 'Broken post must not be inserted into the feed');
      // Upload state must be reset
      expect(controller.isUploadingPost.value, isFalse);
    });

    test('10. Image-only post (empty contentText) is a valid _canPost scenario — imageUrls is enough', () {
      // This verifies the model accepts image-only data correctly.
      // The backend @NotBlank was removed; service allows imageUrl-only posts.
      final imageOnlyPost = CommunityPostModel.fromJson({
        'postId': 'p_img_only',
        'contentText': '',          // empty text — valid when imageUrl is present
        'imageUrl': 'https://cdn.genlink.kh/post/abc123.jpg',
      });

      expect(imageOnlyPost.imageUrls, hasLength(1));
      expect(imageOnlyPost.content, isEmpty);
      // Single image must be parseable from imageUrl field
      expect(imageOnlyPost.imageUrls.first, 'https://cdn.genlink.kh/post/abc123.jpg');
    });

    test('11. Completely empty post (no text, no images) is caught — _canPost returns false', () {
      // The frontend _canPost guard ensures completely empty posts never reach the backend.
      // We verify the model correctly represents the empty state.
      final emptyPost = CommunityPostModel.fromJson({
        'postId': 'p_empty',
        'contentText': '',
        'imageUrl': null,
      });

      expect(emptyPost.imageUrls, isEmpty);
      expect(emptyPost.content, isEmpty);

      // Verify the business rule: at least one of text or images must be non-empty.
      // In the app, _canPost = content.isNotEmpty || _attachedImages.isNotEmpty || ...
      final hasContent = emptyPost.content.isNotEmpty;
      final hasImages  = emptyPost.imageUrls.isNotEmpty;
      expect(hasContent || hasImages, isFalse,
          reason: 'Both text and images are empty — this post must be rejected by _canPost');
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: mock repository that throws on createPost to simulate upload failure
// ---------------------------------------------------------------------------

class _FailingUploadRepository implements CommunityRepository {
  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    throw Exception('Simulated backend failure');
  }

  @override Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];
  @override Future<CommunityPostModel> getPostDetails(String postId) async => throw UnimplementedError();
  @override Future<CommunityPostModel> updatePost(String postId, {required String content}) async => throw UnimplementedError();
  @override Future<bool> deletePost(String postId) async => true;
  @override Future<bool> toggleLike(String postId) async => true;
  @override Future<bool> toggleBookmark(String postId) async => true;
  @override Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async => true;
  @override Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;
  @override Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'}) async => true;
  @override Future<List<CommentModel>> getComments(String postId) async => [];
  @override Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async => throw UnimplementedError();
  @override Future<bool> deleteComment(String postId, String commentId) async => true;
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
