import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';

class MockAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMediaRepo implements MediaRepository {
  int uploadCount = 0;
  List<MediaPurpose> uploadPurposes = [];
  bool shouldFail = false;

  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    uploadPurposes.add(purpose);
    if (shouldFail) {
      throw const AppError(
        message: 'Presign failed',
        errorCode: 'PRESIGN_FAILED',
      );
    }
    return PresignedUpload(
      mediaId: 'id_${uploadCount + 1}',
      uploadUrl: 'https://storage.genlink.kh/presign',
      storageKey: 'posts/test_${uploadCount + 1}',
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
    uploadCount++;
    if (shouldFail) {
      throw const AppError(
        message: 'Upload failed',
        errorCode: 'UPLOAD_FAILED',
      );
    }
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    if (shouldFail) {
      throw const AppError(
        message: 'Confirm failed',
        errorCode: 'CONFIRM_FAILED',
      );
    }
    return MediaEntity(
      mediaId: mediaId,
      url: 'https://storage.genlink.kh/uploads/$mediaId',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    );
  }

  @override
  Future<void> delete(String mediaId) async {}
}

class MockCommunityRepo implements CommunityRepository {
  CommunityPostModel? lastCreatedPost;
  List<String> lastCreatedImages = [];
  String? lastCreatedVideo;

  @override
  Future<List<CommunityPostModel>> getPosts({
    int page = 1,
    int limit = 10,
  }) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    lastCreatedImages = List.from(imageUrls);
    lastCreatedVideo = null;
    lastCreatedPost = CommunityPostModel(
      id: 'post_img_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'u1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      isOwner: true,
      postType: 'IMAGE',
    );
    return lastCreatedPost!;
  }

  @override
  Future<CommunityPostModel> createPostWithVideo({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    lastCreatedImages = List.from(imageUrls);
    lastCreatedVideo = videoUrl;
    lastCreatedPost = CommunityPostModel(
      id: 'post_mixed_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'u1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      visibility: visibility,
      isOwner: true,
      postType: 'VIDEO',
    );
    return lastCreatedPost!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMediaRepo mockMediaRepo;
  late MediaUploadService uploadService;
  late MockCommunityRepo mockCommunityRepo;
  late CommunityController communityController;
  late MockAuthController authController;
  late Directory tempDir;
  late File tempImage1;
  late File tempImage2;
  late File tempVideo;
  late File tempVideo2;

  setUp(() {
    Get.reset();

    mockMediaRepo = MockMediaRepo();
    uploadService = MediaUploadService(mockMediaRepo);
    Get.put<MediaUploadService>(uploadService);

    mockCommunityRepo = MockCommunityRepo();
    communityController = CommunityController(repository: mockCommunityRepo);
    Get.put<CommunityController>(communityController);

    authController = MockAuthController();
    authController.currentUser.value = UserEntity(
      id: 'u1',
      fullName: 'Test User',
      username: 'tester',
      email: 'tester@example.com',
      avatarUrl: null,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 1,
      preferredLanguage: 'en',
      role: 'USER',
      active: true,
    );
    Get.put<AuthController>(authController);

    tempDir = Directory.systemTemp.createTempSync('composer_mixed_test_');
    tempImage1 = File('${tempDir.path}/img1.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    tempImage2 = File('${tempDir.path}/img2.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    tempVideo = File('${tempDir.path}/vid.mp4')
      ..writeAsBytesSync([0x00, 0x00, 0x00, 0x20]);
    tempVideo2 = File('${tempDir.path}/vid2.mp4')
      ..writeAsBytesSync([0x00, 0x00, 0x00, 0x20]);
  });

  tearDown(() {
    Get.reset();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildComposerApp() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const CreatePostScreen(),
    );
  }

  group('Post Composer Mixed Media Tests (11 Required Cases)', () {
    // 1. Image only
    testWidgets(
      '1. Image only attaches cleanly and renders in horizontal strip',
      (tester) async {
        await tester.pumpWidget(buildComposerApp());
        await tester.pumpAndSettle();

        final state = tester.state<CreatePostScreenState>(
          find.byType(CreatePostScreen),
        );
        state.setAttachedImagesForTesting([tempImage1.path]);
        await tester.pumpAndSettle();

        expect(state.attachedImages.length, 1);
        expect(state.attachedVideo, isNull);
        // Verify "+ Add" button is visible
        expect(find.text('+ Add'), findsOneWidget);
      },
    );

    // 2. Video only
    testWidgets('2. Video only attaches cleanly and displays VIDEO badge', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerApp());
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(
        find.byType(CreatePostScreen),
      );
      state.setAttachedVideoForTesting(tempVideo.path);
      state.setVideoInitializedForTesting(true);
      await tester.pump();

      expect(state.attachedImages.isEmpty, isTrue);
      expect(state.attachedVideo, tempVideo.path);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.byKey(const Key('remove_video_btn')), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);
    });

    // 3. Multiple images
    testWidgets('3. Multiple images attach without video', (tester) async {
      await tester.pumpWidget(buildComposerApp());
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(
        find.byType(CreatePostScreen),
      );
      state.setAttachedImagesForTesting([tempImage1.path, tempImage2.path]);
      await tester.pump();

      expect(state.attachedImages.length, 2);
      expect(state.attachedVideo, isNull);
      expect(find.text('+ Add'), findsOneWidget);
    });

    // 4. Image + video
    testWidgets('4. Single image + video both remain attached simultaneously', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerApp());
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(
        find.byType(CreatePostScreen),
      );
      // First attach image
      state.setAttachedImagesForTesting([tempImage1.path]);
      await tester.pump();
      // Then attach video
      state.setAttachedVideoForTesting(tempVideo.path);
      state.setVideoInitializedForTesting(true);
      await tester.pump();

      expect(state.attachedImages.length, 1);
      expect(state.attachedVideo, tempVideo.path);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.byKey(const Key('remove_video_btn')), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);
    });

    // 5. Multiple images + video
    testWidgets(
      '5. Multiple images + video all remain attached in [Img1][Img2][Vid][+Add] order',
      (tester) async {
        await tester.pumpWidget(buildComposerApp());
        await tester.pumpAndSettle();

        final state = tester.state<CreatePostScreenState>(
          find.byType(CreatePostScreen),
        );
        state.setAttachedImagesForTesting([tempImage1.path, tempImage2.path]);
        state.setAttachedVideoForTesting(tempVideo.path);
        state.setVideoInitializedForTesting(true);
        await tester.pump();

        expect(state.attachedImages.length, 2);
        expect(state.attachedVideo, tempVideo.path);
        expect(find.text('VIDEO'), findsOneWidget);
        expect(find.byKey(const Key('remove_video_btn')), findsOneWidget);
        expect(find.text('+ Add'), findsOneWidget);
      },
    );

    // 6. Removing one image
    testWidgets('6. Removing one image leaves other image and video intact', (
      tester,
    ) async {
      await tester.pumpWidget(buildComposerApp());
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(
        find.byType(CreatePostScreen),
      );
      state.setAttachedImagesForTesting([tempImage1.path, tempImage2.path]);
      state.setAttachedVideoForTesting(tempVideo.path);
      state.setVideoInitializedForTesting(true);
      await tester.pump();

      // Find remove button for the first image
      final removeButtons = find.byIcon(Icons.close);
      // 2 images + 1 video = 3 close icons
      expect(removeButtons, findsNWidgets(3));

      // Tap remove on image 1
      await tester.tap(removeButtons.first);
      await tester.pump();

      expect(state.attachedImages.length, 1);
      expect(state.attachedImages.first, tempImage2.path);
      expect(state.attachedVideo, tempVideo.path);
      expect(find.text('VIDEO'), findsOneWidget);
    });

    // 7. Removing video
    testWidgets('7. Removing video leaves all images intact', (tester) async {
      await tester.pumpWidget(buildComposerApp());
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(
        find.byType(CreatePostScreen),
      );
      state.setAttachedImagesForTesting([tempImage1.path, tempImage2.path]);
      state.setAttachedVideoForTesting(tempVideo.path);
      state.setVideoInitializedForTesting(true);
      await tester.pump();

      // Tap remove on video
      await tester.tap(find.byKey(const Key('remove_video_btn')));
      await tester.pump();

      expect(state.attachedVideo, isNull);
      expect(state.attachedImages.length, 2);
      expect(find.text('VIDEO'), findsNothing);
    });

    // 8. Attempting to add second video shows compact validation message and keeps existing video
    testWidgets(
      '8. Attempting to add second video shows compact validation message and keeps existing video',
      (tester) async {
        await tester.pumpWidget(buildComposerApp());
        await tester.pumpAndSettle();

        final state = tester.state<CreatePostScreenState>(
          find.byType(CreatePostScreen),
        );
        state.setAttachedImagesForTesting([tempImage1.path]);
        state.setAttachedVideoForTesting(tempVideo.path);
        state.setVideoInitializedForTesting(true);
        await tester.pump();

        // Attempt to attach second video via handler
        await state.handleSelectedMediaPathsForTesting([tempVideo2.path]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // No confirmation dialog with Cancel/Replace buttons
        expect(find.text('Replace existing video?'), findsNothing);
        expect(find.byKey(const Key('dialog_cancel_btn')), findsNothing);

        // Compact validation message shown
        expect(
          find.text('Only one video can be added to a post.'),
          findsOneWidget,
        );

        // Existing video strictly kept
        expect(state.attachedVideo, tempVideo.path);
        expect(state.attachedImages.length, 1);
      },
    );

    // 9. Successful mixed-media upload
    test(
      '9. Successful mixed-media upload sends image and video references',
      () async {
        final success = await communityController.addNewPost(
          content: 'Check out our project demo',
          imageUrls: [tempImage1.path, tempImage2.path],
          videoUrl: tempVideo.path,
        );

        expect(success, isTrue);
        // 2 images + 1 video = 3 uploads
        expect(mockMediaRepo.uploadCount, 3);
        expect(
          mockMediaRepo.uploadPurposes.every((p) => p == MediaPurpose.post),
          isTrue,
        );

        expect(mockCommunityRepo.lastCreatedImages.length, 2);
        expect(mockCommunityRepo.lastCreatedImages, [
          'genlink-media://id_1',
          'genlink-media://id_2',
        ]);
        expect(mockCommunityRepo.lastCreatedVideo, 'genlink-media://id_3');
      },
    );

    // 9B. Failed upload preserves state and returns false
    test('9B. Failed upload does not create post and fails safely', () async {
      mockMediaRepo.shouldFail = true;

      final success = await communityController.addNewPost(
        content: 'Failing mixed post',
        imageUrls: [tempImage1.path],
        videoUrl: tempVideo.path,
      );

      expect(success, isFalse);
      expect(mockCommunityRepo.lastCreatedPost, isNull);
    });

    // 10. Mixed-media publish payload
    test(
      '10. Mixed-media publish payload contains both imageUrls and videoUrl together',
      () async {
        await communityController.addNewPost(
          content: 'Payload verification post',
          imageUrls: [tempImage1.path, tempImage2.path],
          videoUrl: tempVideo.path,
        );

        final created = mockCommunityRepo.lastCreatedPost;
        expect(created, isNotNull);
        expect(created!.content, 'Payload verification post');
        expect(created.imageUrls.length, 2);
        expect(created.videoUrl, isNotNull);
        expect(created.postType, 'VIDEO');

        // Verify toJson payload format
        final json = created.toJson();
        expect(json['imageUrls'], isNotEmpty);
        expect(json['imageUrl'], contains(','));
        expect(json['videoUrl'], isNotNull);
      },
    );

    // 11. Published post parsing and rendering
    test(
      '11A. CommunityPostModel parses both comma-separated imageUrl and videoUrl from backend JSON',
      () {
        final rawBackendResponse = {
          'postId': 'post_server_999',
          'author': {
            'userId': 'u1',
            'fullName': 'Sokny Enat',
            'username': 'enat',
            'avatarUrl': 'https://example.com/avatar.jpg',
          },
          'contentText': 'Published post with both media types',
          'imageUrl':
              'https://cdn.example.com/img1.jpg,https://cdn.example.com/img2.jpg',
          'videoUrl': 'https://cdn.example.com/video.mp4',
          'postType': 'VIDEO',
          'visibility': 'PUBLIC',
          'likeCount': 5,
          'commentCount': 2,
          'createdAt': '2026-09-20T10:00:00Z',
        };

        final post = CommunityPostModel.fromJson(rawBackendResponse);

        expect(post.id, 'post_server_999');
        expect(post.imageUrls.length, 2);
        expect(post.imageUrls[0], 'https://cdn.example.com/img1.jpg');
        expect(post.imageUrls[1], 'https://cdn.example.com/img2.jpg');
        expect(post.videoUrl, 'https://cdn.example.com/video.mp4');
        expect(post.isVideoPost, isTrue);
      },
    );

    testWidgets(
      '11B. PostCardWidget renders unified carousel with Video and Images in ONE PageView (1/3)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mixedPost = CommunityPostModel(
          id: 'post_render_test',
          userId: 'u1',
          authorName: 'Sokny Enat',
          authorTag: '@enat',
          authorAvatar: '',
          timeAgo: '2m ago',
          content: 'Post with both video and images',
          imageUrls: const [
            'https://example.com/photo1.jpg',
            'https://example.com/photo2.jpg',
          ],
          videoUrl: 'https://example.com/clip.mp4',
          visibility: 'Public',
          isOwner: true,
        );

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostCardWidget(
                  post: mixedPost,
                  controller: communityController,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Verify VideoPostMedia is rendered within the carousel
        expect(find.byType(VideoPostMedia), findsOneWidget);
        // Verify exactly ONE PageView is rendered with unified count (1/3)
        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('1/3'), findsOneWidget);

        // Swiping to page 2 updates counter to 2/3
        await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text('2/3'), findsOneWidget);

        // Swiping to page 3 updates counter to 3/3
        await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text('3/3'), findsOneWidget);
      },
    );
  });
}
