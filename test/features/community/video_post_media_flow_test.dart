import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';

class TestAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestMediaRepository implements MediaRepository {
  int uploadCallCount = 0;
  MediaPurpose? lastPurpose;
  String returnedUrl = 'https://storage.genlink.kh/uploads/posts/video_123.mp4';
  bool shouldFail = false;

  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    lastPurpose = purpose;
    if (shouldFail) {
      throw const AppError(
        message: 'Storage connection timeout',
        errorCode: 'STORAGE_ERROR',
      );
    }
    return const PresignedUpload(
      mediaId: 'mock_vid_123',
      uploadUrl: 'https://storage.genlink.kh/presign_put',
      storageKey: 'uploads/posts/video_123.mp4',
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
    if (shouldFail) {
      throw const AppError(
        message: 'Upload stream failed',
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
        message: 'Confirmation failed',
        errorCode: 'CONFIRM_FAILED',
      );
    }
    return MediaEntity(
      mediaId: mediaId,
      url: returnedUrl,
      contentType: 'video/mp4',
      sizeBytes: 1024,
    );
  }

  @override
  Future<void> delete(String mediaId) async {}
}

class TestCommunityRepository implements CommunityRepository {
  CommunityPostModel? lastCreatedPost;
  String? lastCreatedVideoUrl;
  List<String> lastCreatedImageUrls = [];

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
    lastCreatedImageUrls = List.from(imageUrls);
    lastCreatedPost = CommunityPostModel(
      id: 'test_post_regular',
      userId: 'user_1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
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
  Future<CommunityPostModel> createPostWithVideo({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    lastCreatedImageUrls = List.from(imageUrls);
    lastCreatedVideoUrl = videoUrl;
    lastCreatedPost = CommunityPostModel(
      id: 'test_post_video',
      userId: 'user_1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      visibility: visibility,
      community: community,
      isOwner: true,
      postType: 'VIDEO',
    );
    return lastCreatedPost!;
  }

  @override
  Future<CommunityPostModel> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
  }) async {
    lastCreatedPost = CommunityPostModel(
      id: 'test_poll_post',
      userId: 'user_1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: caption ?? question,
      visibility: visibility,
      postType: 'POLL',
      pollQuestion: question,
      pollOptions: options
          .map((opt) => PollOptionModel(id: opt, text: opt, votes: 0))
          .toList(),
      isOwner: true,
    );
    return lastCreatedPost!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestMediaRepository mockMediaRepo;
  late MediaUploadService uploadService;
  late TestCommunityRepository mockCommunityRepo;
  late CommunityController communityController;
  late TestAuthController authController;
  late Directory tempDir;
  late File tempVideoFile;

  setUp(() {
    Get.reset();

    mockMediaRepo = TestMediaRepository();
    uploadService = MediaUploadService(mockMediaRepo);
    Get.put<MediaUploadService>(uploadService);

    mockCommunityRepo = TestCommunityRepository();
    communityController = CommunityController(repository: mockCommunityRepo);
    Get.put<CommunityController>(communityController);

    authController = TestAuthController();
    authController.currentUser.value = UserEntity(
      id: 'test_user_id',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
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

    tempDir = Directory.systemTemp.createTempSync('video_flow_test_');
    tempVideoFile = File('${tempDir.path}/1000005369.mp4');
    tempVideoFile.writeAsBytesSync([
      0x00,
      0x00,
      0x00,
      0x20,
      0x66,
      0x74,
      0x79,
      0x70,
    ]);
  });

  tearDown(() {
    Get.reset();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('MediaPurpose.post Video Support', () {
    test('MediaPurpose.post allows video uploads', () {
      expect(MediaPurpose.post.allowsVideo, isTrue);
      expect(MediaPurpose.story.allowsVideo, isTrue);
      expect(MediaPurpose.short.allowsVideo, isTrue);
      expect(MediaPurpose.avatar.allowsVideo, isFalse);
    });
  });

  group('Video Upload & URL Resolution in CommunityController', () {
    test(
      'addNewPost uploads local video and sends its opaque media reference',
      () async {
        final success = await communityController.addNewPost(
          content: 'Check out this video post',
          videoUrl: tempVideoFile.path,
        );

        expect(success, isTrue);
        expect(mockMediaRepo.uploadCallCount, 1);
        expect(mockMediaRepo.lastPurpose, MediaPurpose.post);
        expect(
          mockCommunityRepo.lastCreatedVideoUrl,
          'genlink-media://mock_vid_123',
        );
        expect(
          mockCommunityRepo.lastCreatedVideoUrl,
          isNot(contains(tempDir.path)),
        );
      },
    );

    test(
      'addNewPost does not re-upload existing remote HTTPS video URLs',
      () async {
        const remoteUrl =
            'https://genlink-media.cdn.digitaloceanspaces.com/posts/2026/video.mp4';
        final success = await communityController.addNewPost(
          content: 'Video with remote link',
          videoUrl: remoteUrl,
        );

        expect(success, isTrue);
        expect(mockMediaRepo.uploadCallCount, 0);
        expect(mockCommunityRepo.lastCreatedVideoUrl, remoteUrl);
      },
    );

    test(
      'addNewPost fails cleanly and NEVER sends temporary local path if video upload fails',
      () async {
        mockMediaRepo.shouldFail = true;

        final success = await communityController.addNewPost(
          content: 'Post with failing video',
          videoUrl: tempVideoFile.path,
        );

        expect(success, isFalse);
        expect(mockCommunityRepo.lastCreatedVideoUrl, isNull);
        expect(mockCommunityRepo.lastCreatedPost, isNull);
      },
    );
  });

  group('Backward Compatibility for Non-Video Post Types', () {
    test('creates TEXT post without affecting video flow', () async {
      final success = await communityController.addNewPost(
        content: 'Just a text post',
      );

      expect(success, isTrue);
      expect(mockCommunityRepo.lastCreatedVideoUrl, isNull);
      expect(mockCommunityRepo.lastCreatedPost?.content, 'Just a text post');
    });

    test('creates IMAGE post without affecting video flow', () async {
      final success = await communityController.addNewPost(
        content: 'Post with photo',
        imageUrls: ['https://example.com/photo.jpg'],
      );

      expect(success, isTrue);
      expect(mockCommunityRepo.lastCreatedVideoUrl, isNull);
      expect(mockCommunityRepo.lastCreatedImageUrls, [
        'https://example.com/photo.jpg',
      ]);
    });

    test('creates POLL post without affecting video flow', () async {
      final success = await communityController.createPollPost(
        question: 'Which framework do you prefer?',
        options: ['Flutter', 'React Native'],
      );

      expect(success, isTrue);
      expect(mockCommunityRepo.lastCreatedVideoUrl, isNull);
      expect(mockCommunityRepo.lastCreatedPost?.postType, 'POLL');
    });
  });

  group('VideoPostMedia Widget Architecture', () {
    testWidgets('VideoPostMedia builds and exposes stable identity key', (
      tester,
    ) async {
      const testUrl = 'https://example.com/sample.mp4';
      const key = ValueKey('video_test_123_$testUrl');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoPostMedia(key: key, videoUrl: testUrl),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);
    });

    testWidgets('VideoPostMedia handles local filesystem path safely', (
      tester,
    ) async {
      final localPath = tempVideoFile.path;
      final key = ValueKey('video_local_$localPath');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPostMedia(key: key, videoUrl: localPath),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);
    });

    testWidgets(
      'VideoPostMedia handles URL update via didUpdateWidget safely',
      (tester) async {
        const initialUrl = 'https://example.com/initial.mp4';
        const updatedUrl = 'https://example.com/updated.mp4';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VideoPostMedia(videoUrl: initialUrl)),
          ),
        );

        expect(find.byType(VideoPostMedia), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VideoPostMedia(videoUrl: updatedUrl)),
          ),
        );

        expect(find.byType(VideoPostMedia), findsOneWidget);
      },
    );
  });
}
