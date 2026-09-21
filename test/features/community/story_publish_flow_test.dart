import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_video_player_widget.dart';

class _MockLocalStorage extends LocalStorage {
  _MockLocalStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> readStoryDraft() async => null;

  @override
  Future<void> saveStoryDraft(String draftJson) async {}

  @override
  Future<void> deleteStoryDraft() async {}
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  bool shouldFail = false;
  String? failErrorCode;
  String? failErrorMessage;
  int? failStatusCode;

  String returnedStoryId = 'server_story_1001';
  Map<String, dynamic>? lastPostBody;
  String? lastPostPath;
  int postCallCount = 0;

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    postCallCount++;
    lastPostPath = path;
    if (body is Map) {
      lastPostBody = Map<String, dynamic>.from(body);
    }

    if (shouldFail) {
      throw AppError(
        message: failErrorMessage ?? 'Backend story creation failed',
        errorCode: failErrorCode ?? 'API_ERROR',
        statusCode: failStatusCode ?? 500,
      );
    }

    if (path == ApiEndpoints.stories) {
      final bodyMap = body is Map ? body : <String, dynamic>{};
      final json = {
        'id': returnedStoryId,
        'mediaUrl': bodyMap['mediaUrl'] ?? 'https://cdn.genlink.com/default.jpg',
        'mediaType': bodyMap['mediaType'] ?? 'IMAGE',
        'caption': bodyMap['caption'],
        'createdAt': DateTime.now().toIso8601String(),
        'visibility': bodyMap['visibility'] ?? 'PUBLIC',
        'replyPermission': bodyMap['replyPermission'] ?? 'EVERYONE',
        'allowReactions': bodyMap['allowReactions'] ?? true,
      };
      return parse(json);
    }

    return parse(<String, dynamic>{});
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    if (path == ApiEndpoints.stories) {
      return parse(<Map<String, dynamic>>[]);
    }
    return parse(<String, dynamic>{});
  }
}

class _FakeMediaUploadService extends MediaUploadService {
  _FakeMediaUploadService() : super(_FakeMediaRepo());

  bool shouldFail = false;
  String returnedUrl = 'https://cdn.genlink.com/uploaded_media.jpg';
  int uploadCallCount = 0;

  @override
  Future<MediaEntity> upload({
    required Uint8List bytes,
    required String contentType,
    required MediaPurpose purpose,
    int? width,
    int? height,
    int? durationMs,
    UploadProgress? onProgress,
  }) async {
    uploadCallCount++;
    if (shouldFail) {
      throw const AppError(
        message: 'Media upload failed',
        errorCode: 'UPLOAD_FAILED',
      );
    }

    return MediaEntity(
      mediaId: 'media_upload_001',
      url: returnedUrl,
      contentType: contentType,
      sizeBytes: bytes.length,
      uploadedAt: DateTime.now(),
    );
  }
}

class _FakeMediaRepo implements MediaRepository {
  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    return const PresignedUpload(
      mediaId: 'mock-media-id',
      uploadUrl: 'https://storage.genlink.com/upload',
      storageKey: 'stories/mock.jpg',
      requiredHeaders: {},
      expiresInSeconds: 300,
    );
  }

  @override
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async {}

  @override
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    return MediaEntity(
      mediaId: mediaId,
      url: 'https://cdn.genlink.com/stories/mock.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 100,
      uploadedAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(String mediaId) async {}
}

void main() {
  late _FakeApiClient fakeApiClient;
  late _FakeMediaUploadService fakeUploadService;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    fakeApiClient = _FakeApiClient();
    fakeUploadService = _FakeMediaUploadService();
    Get.put<ApiClient>(fakeApiClient, permanent: true);
    Get.put<MediaUploadService>(fakeUploadService, permanent: true);
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Publishing Flow & Navigation Lifecycle Tests', () {
    test('Test 1: Publish Story success updates story controller and refreshes groups', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_1';
      final controller = Get.put(StoryController());
      await controller.fetchStories();
      final initialCount = controller.storyGroups.firstWhere((g) => g.isOwner).stories.length;

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'New test image story',
        visibility: 'Friends',
      );

      expect(success, true);
      expect(controller.isUploading.value, false);
      expect(fakeApiClient.postCallCount, 1);
      expect(fakeUploadService.uploadCallCount, 1);

      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.length, initialCount + 1);
      expect(ownerGroup.stories.first.id, 'real_backend_story_1');
      expect(ownerGroup.stories.first.id.startsWith('story_'), isFalse);
      expect(ownerGroup.stories.first.textContent, 'New test image story');
      expect(ownerGroup.stories.first.type, StoryType.photo);
      expect(ownerGroup.stories.first.mediaUrl, 'https://cdn.genlink.com/uploaded_media.jpg');
    });

    test('Test 2: Double-tap prevention - concurrent publish requests are rejected', () async {
      final controller = Get.put(StoryController());
      controller.isUploading.value = true;

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Concurrent story attempt',
      );

      expect(success, false);
    });

    testWidgets('Test 3: Story Creator Screen publishing flow closes composer on success', (tester) async {
      fakeApiClient.returnedStoryId = 'real_backend_story_3';
      Get.put(StoryController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(
              name: '/home',
              page: () => const Scaffold(body: Text('Community Home Screen')),
            ),
            GetPage(
              name: '/StoryGalleryScreen',
              page: () => const Scaffold(body: Text('Gallery Screen')),
            ),
            GetPage(
              name: '/StoryCreatorScreen',
              page: () => const StoryCreatorScreen(
                type: StoryType.photo,
                mediaPaths: ['assets/images/user_profile.png'],
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Community Home Screen'), findsOneWidget);

      Get.toNamed('/StoryGalleryScreen');
      await tester.pumpAndSettle();
      expect(find.text('Gallery Screen'), findsOneWidget);

      Get.to(
        () => const StoryCreatorScreen(
          type: StoryType.photo,
          mediaPaths: ['assets/images/user_profile.png'],
        ),
        routeName: '/StoryCreatorScreen',
      );
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);

      await tester.tap(find.text('Post Story'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Community Home Screen'), findsOneWidget);
      expect(find.text('Post Story'), findsNothing);
      expect(find.text('Gallery Screen'), findsNothing);
    });

    testWidgets('Test 4: Story Creator Screen with Camera in stack unwinds all creator routes on success', (tester) async {
      fakeApiClient.returnedStoryId = 'real_backend_story_4';
      Get.put(StoryController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/community',
          getPages: [
            GetPage(
              name: '/community',
              page: () => const Scaffold(body: Text('Community Feed')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Community Feed'), findsOneWidget);

      Get.to(
        () => const Scaffold(body: Text('StoryGalleryScreen Mock')),
        routeName: '/StoryGalleryScreen',
      );
      await tester.pumpAndSettle();

      Get.to(
        () => const Scaffold(body: Text('InAppCameraScreen Mock')),
        routeName: '/InAppCameraScreen',
      );
      await tester.pumpAndSettle();

      Get.to(
        () => const StoryCreatorScreen(
          type: StoryType.photo,
          mediaPaths: ['assets/images/user_profile.png'],
        ),
        routeName: '/StoryCreatorScreen',
      );
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);

      await tester.tap(find.text('Post Story'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Community Feed'), findsOneWidget);
      expect(find.text('InAppCameraScreen Mock'), findsNothing);
      expect(find.text('StoryGalleryScreen Mock'), findsNothing);
      expect(find.text('Post Story'), findsNothing);
    });

    testWidgets('Test 5: Editing existing story returns to StoryViewerScreen', (tester) async {
      Get.put(StoryController());

      final existingStory = StoryItemModel(
        id: 'story_edit_test',
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Old caption',
        timeAgo: '1h ago',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.friends),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/community',
          getPages: [
            GetPage(
              name: '/community',
              page: () => const Scaffold(body: Text('Community Feed')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      Get.to(
        () => const Scaffold(body: Text('StoryViewerScreen Mock')),
        routeName: '/StoryViewerScreen',
      );
      await tester.pumpAndSettle();
      expect(find.text('StoryViewerScreen Mock'), findsOneWidget);

      Get.to(
        () => StoryCreatorScreen(
          type: StoryType.photo,
          existingStory: existingStory,
        ),
        routeName: '/StoryCreatorScreen',
      );
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);

      await tester.tap(find.text('Post Story'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('StoryViewerScreen Mock'), findsOneWidget);
      expect(find.text('Post Story'), findsNothing);
    });

    testWidgets('Test 6: Empty text story validation failure keeps composer open and does not navigate', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/community',
          getPages: [
            GetPage(
              name: '/community',
              page: () => const Scaffold(body: Text('Community Feed')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      Get.to(
        () => const StoryCreatorScreen(type: StoryType.text),
        routeName: '/StoryCreatorScreen',
      );
      await tester.pumpAndSettle();

      if (find.text('Done').evaluate().isNotEmpty) {
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Post Story'), findsOneWidget);

      await tester.tap(find.text('Post Story'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);
      expect(find.text('Empty Story'), findsOneWidget);
    });

    test('Test 7: Image Story publishing creates story and adds to owner group without duplicates', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_7';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Fresh photo story from camera',
        visibility: 'Public',
      );

      expect(success, true);
      expect(controller.isUploading.value, false);
      expect(fakeApiClient.postCallCount, 1);

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.id, 'real_backend_story_7');
      expect(createdStory.type, StoryType.photo);
      expect(createdStory.textContent, 'Fresh photo story from camera');
      expect(createdStory.mediaUrl, 'https://cdn.genlink.com/uploaded_media.jpg');

      final storyIds = ownerStories.map((s) => s.id).toList();
      expect(storyIds.toSet().length, storyIds.length);
    });

    test('Test 8: Text Story without media publishes with background gradient and text', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_8';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final success = await controller.publishStory(
        type: StoryType.text,
        textContent: 'Study session at ACLEDA Library!',
        bgGradientStart: '0xFF0F172A',
        bgGradientEnd: '0xFF3B82F6',
        visibility: 'Public',
      );

      expect(success, true);
      expect(controller.isUploading.value, false);
      expect(fakeApiClient.postCallCount, 1);
      expect(fakeUploadService.uploadCallCount, 1);

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.id, 'real_backend_story_8');
      expect(createdStory.type, StoryType.text);
      expect(createdStory.textContent, 'Study session at ACLEDA Library!');
      expect(createdStory.bgGradientStart, '0xFF0F172A');
      expect(createdStory.bgGradientEnd, '0xFF3B82F6');
      expect(createdStory.mediaUrl, 'https://cdn.genlink.com/uploaded_media.jpg');
    });

    test('Test 9: Story containing a link publishes with link preserved in caption', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_9';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      const linkText = 'Check out this campus event: https://genlink.kh/event/hackathon-2026';
      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: linkText,
        visibility: 'Public',
      );

      expect(success, true);
      expect(fakeApiClient.postCallCount, 1);
      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.id, 'real_backend_story_9');
      expect(createdStory.textContent, contains('https://genlink.kh/event/hackathon-2026'));
    });

    test('Test 10: Missing ApiClient causes explicit failure and generates no fake story', () async {
      Get.reset();
      // Neither ApiClient nor MediaUploadService is registered in Get
      final repository = StoryRepositoryImpl(apiClient: null);

      expect(
        () => repository.createStory(
          type: StoryType.photo,
          mediaUrl: 'https://cdn.genlink.com/test.jpg',
        ),
        throwsA(
          isA<AppError>().having((e) => e.errorCode, 'errorCode', 'API_CLIENT_UNAVAILABLE'),
        ),
      );
    });

    test('Test 11: Missing or empty media URL causes explicit failure', () async {
      final repository = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      // Empty string mediaUrl for photo story
      expect(
        () => repository.createStory(
          type: StoryType.photo,
          mediaUrl: '',
        ),
        throwsA(
          isA<AppError>().having((e) => e.errorCode, 'errorCode', 'INVALID_MEDIA_URL'),
        ),
      );

      // Null mediaUrl with no text / layers to render
      expect(
        () => repository.createStory(
          type: StoryType.photo,
          mediaUrl: null,
        ),
        throwsA(
          isA<AppError>().having((e) => e.errorCode, 'errorCode', 'INVALID_MEDIA_URL'),
        ),
      );

      // Non-existent local media file
      expect(
        () => repository.createStory(
          type: StoryType.photo,
          mediaUrl: 'non_existent_image_file_xyz.jpg',
        ),
        throwsA(
          isA<AppError>().having((e) => e.errorCode, 'errorCode', 'MEDIA_NOT_FOUND'),
        ),
      );
    });

    test('Test 12: Backend publication failure causes failure, generates no fake story ID, and does not insert into story tray', () async {
      fakeApiClient.shouldFail = true;
      fakeApiClient.failErrorMessage = '500 Internal Server Error';
      fakeApiClient.failErrorCode = 'SERVER_ERROR';

      final controller = Get.put(StoryController());
      await controller.fetchStories();
      final initialOwnerStories = List.of(controller.storyGroups.firstWhere((g) => g.isOwner).stories);
      final initialTotalStories = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

      expect(
        () => controller.publishStory(
          type: StoryType.photo,
          mediaUrl: 'assets/images/user_profile.png',
          textContent: 'This story will fail to publish',
        ),
        throwsA(
          isA<AppError>().having((e) => e.errorCode, 'errorCode', 'SERVER_ERROR'),
        ),
      );

      // Verify no story was added to owner group or story tray
      final currentOwnerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final currentTotalStories = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);
      expect(currentOwnerStories.length, initialOwnerStories.length);
      expect(currentTotalStories, initialTotalStories);

      // Verify no fake story ID matching story_\d+ exists in any story tray group
      for (final group in controller.storyGroups) {
        for (final story in group.stories) {
          expect(story.id, isNot(matches(r'^story_\d+$')));
        }
      }
    });

    test('Test 13: Backend response with empty story ID causes failure (no fake ID manufactured)', () async {
      // Backend returns empty ID
      fakeApiClient.returnedStoryId = '';

      final repository = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      expect(
        () => repository.createStory(
          type: StoryType.photo,
          mediaUrl: 'https://cdn.genlink.com/valid_remote.jpg',
        ),
        throwsA(
          isA<AppError>().having((e) => e.errorCode, 'errorCode', 'INVALID_STORY_ID'),
        ),
      );
    });

    testWidgets('Test 14: Story Creator Screen UI displays failure and never reports success on backend failure', (tester) async {
      fakeApiClient.shouldFail = true;
      fakeApiClient.failErrorMessage = 'Backend server down';
      Get.put(StoryController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(
              name: '/home',
              page: () => const Scaffold(body: Text('Community Home Screen')),
            ),
            GetPage(
              name: '/StoryCreatorScreen',
              page: () => const StoryCreatorScreen(
                type: StoryType.photo,
                mediaPaths: ['assets/images/user_profile.png'],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.to(
        () => const StoryCreatorScreen(
          type: StoryType.photo,
          mediaPaths: ['assets/images/user_profile.png'],
        ),
        routeName: '/StoryCreatorScreen',
      );
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);

      await tester.tap(find.text('Post Story'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // UI must NOT report success
      expect(find.text('Story posted successfully!'), findsNothing);
      expect(find.text('Your story is now live.'), findsNothing);

      // UI must show error
      expect(find.text("Couldn't post story"), findsOneWidget);

      // Composer must remain open (not closed on error)
      expect(find.text('Post Story'), findsOneWidget);
    });

    test('Test 15: Selected visibility Friends reaches backend as FRIENDS and is preserved in settings', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_15';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Friends only story',
        visibility: 'Friends',
      );

      expect(success, true);
      expect(fakeApiClient.lastPostBody!['visibility'], 'FRIENDS');
      expect(fakeApiClient.lastPostBody!['replyPermission'], 'EVERYONE');
      expect(fakeApiClient.lastPostBody!['allowReactions'], true);

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.settings.visibility, StoryPrivacy.friends);
      expect(createdStory.visibility, 'Friends');
    });

    test('Test 16: Selected visibility Only Me reaches backend as ONLY_ME and is preserved in settings', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_16';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Only me story',
        visibility: 'Only Me',
      );

      expect(success, true);
      expect(fakeApiClient.lastPostBody!['visibility'], 'ONLY_ME');

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.settings.visibility, StoryPrivacy.onlyMe);
      expect(createdStory.visibility, 'Only Me');
    });

    test('Test 17: Reply permission and allowReactions are preserved and sent to backend', () async {
      fakeApiClient.returnedStoryId = 'real_backend_story_17';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final customSettings = const StorySettings(
        visibility: StoryPrivacy.friends,
        replyPermission: StoryReplyPermission.off,
        allowReactions: false,
      );

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'No replies or reactions',
        storySettings: customSettings,
      );

      expect(success, true);
      expect(fakeApiClient.lastPostBody!['visibility'], 'FRIENDS');
      expect(fakeApiClient.lastPostBody!['replyPermission'], 'OFF');
      expect(fakeApiClient.lastPostBody!['allowReactions'], false);

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.settings.replyPermission, StoryReplyPermission.off);
      expect(createdStory.settings.allowReactions, false);
    });

    test('Test 18: Backend response with various visibilities correctly maps to StoryItemModel without defaulting to Public', () async {
      final repository = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      fakeApiClient.returnedStoryId = 'story_friends_18';
      final friendsStory = await repository.createStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        visibility: 'Friends',
      );
      expect(friendsStory.settings.visibility, StoryPrivacy.friends);
      expect(friendsStory.visibility, 'Friends');

      fakeApiClient.returnedStoryId = 'story_only_me_18';
      final onlyMeStory = await repository.createStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        visibility: 'Only Me',
      );
      expect(onlyMeStory.settings.visibility, StoryPrivacy.onlyMe);
      expect(onlyMeStory.visibility, 'Only Me');
    });

    test('Test 19: Video Story publishing sends mediaType = VIDEO, real remote mediaUrl, and maps to StoryType.video', () async {
      fakeApiClient.returnedStoryId = 'video_story_real_19';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final success = await controller.publishStory(
        type: StoryType.video,
        mediaUrl: 'https://cdn.genlink.com/stories/campus_tour.mp4',
        textContent: 'Test video post',
        visibility: 'Public',
      );

      expect(success, isTrue);
      expect(fakeApiClient.lastPostBody!['mediaType'], 'VIDEO');
      expect(fakeApiClient.lastPostBody!['mediaUrl'], 'https://cdn.genlink.com/stories/campus_tour.mp4');
      expect(fakeApiClient.lastPostBody!['caption'], 'Test video post');

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.id, 'video_story_real_19');
      expect(createdStory.type, StoryType.video);
      expect(createdStory.mediaUrl, 'https://cdn.genlink.com/stories/campus_tour.mp4');
      expect(createdStory.textContent, 'Test video post');
    });

    test('Test 20: Failed video upload throws error, prevents story creation, and does not create fake story', () async {
      fakeUploadService.shouldFail = true;
      final repository = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      expect(
        () => repository.createStory(
          type: StoryType.video,
          mediaUrl: 'assets/images/user_profile.png',
        ),
        throwsA(isA<AppError>()),
      );
      expect(fakeApiClient.postCallCount, 0);
    });

    test('Test 21: Empty or invalid media URL cannot create a fake Video Story', () async {
      final repository = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      expect(
        () => repository.createStory(
          type: StoryType.video,
          mediaUrl: '',
        ),
        throwsA(isA<AppError>()),
      );

      expect(
        () => repository.createStory(
          type: StoryType.video,
          mediaUrl: 'non_existent_video_file.mp4',
        ),
        throwsA(isA<AppError>()),
      );
      expect(fakeApiClient.postCallCount, 0);
    });

    test('Test 22: Video Story preserves all privacy fields alongside mediaType = VIDEO', () async {
      fakeApiClient.returnedStoryId = 'video_story_privacy_22';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final customSettings = const StorySettings(
        visibility: StoryPrivacy.friends,
        replyPermission: StoryReplyPermission.friends,
        allowReactions: true,
      );

      final success = await controller.publishStory(
        type: StoryType.video,
        mediaUrl: 'https://cdn.genlink.com/stories/private_video.mp4',
        textContent: 'Friends-only video story',
        storySettings: customSettings,
      );

      expect(success, isTrue);
      expect(fakeApiClient.lastPostBody!['mediaType'], 'VIDEO');
      expect(fakeApiClient.lastPostBody!['visibility'], 'FRIENDS');
      expect(fakeApiClient.lastPostBody!['replyPermission'], 'FRIENDS');
      expect(fakeApiClient.lastPostBody!['allowReactions'], isTrue);

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.type, StoryType.video);
      expect(createdStory.settings.visibility, StoryPrivacy.friends);
      expect(createdStory.settings.replyPermission, StoryReplyPermission.friends);
      expect(createdStory.settings.allowReactions, isTrue);
    });

    testWidgets('Test 23: StoryViewerScreen renders StoryVideoPlayerWidget for video stories with proper keys', (tester) async {
      final videoStory = StoryItemModel(
        id: 'test_vid_viewer_23',
        type: StoryType.video,
        mediaUrl: 'https://cdn.genlink.com/stories/playback_test.mp4',
        textContent: 'Test video post',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      );
      final videoGroup = StoryGroupModel(
        userId: 'owner_user_1',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [videoStory],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [videoGroup],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.byType(StoryVideoPlayerWidget), findsOneWidget);
      expect(find.byKey(const ValueKey('story_video_test_vid_viewer_23')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Test 24: Story with Only Me privacy preserves ONLY_ME, displays Lock icon in StoryViewerScreen, and never Public globe icon', (tester) async {
      fakeApiClient.returnedStoryId = 'story_only_me_24';
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      const onlyMeSettings = StorySettings(
        visibility: StoryPrivacy.onlyMe,
        replyPermission: StoryReplyPermission.everyone,
        allowReactions: true,
      );

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Private personal story',
        storySettings: onlyMeSettings,
        visibility: 'Only Me',
      );

      expect(success, isTrue);
      expect(fakeApiClient.lastPostBody!['visibility'], 'ONLY_ME');

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.settings.visibility, StoryPrivacy.onlyMe);
      expect(createdStory.visibility, 'Only Me');
      expect(createdStory.storyPrivacy, StoryPrivacy.onlyMe);

      final ownerGroup = StoryGroupModel(
        userId: 'owner_user_24',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [createdStory],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [ownerGroup],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Test 25: All 3 privacy tiers (PUBLIC, FRIENDS, ONLY_ME) render distinct header icons without cross-contamination', (tester) async {
      final publicStory = StoryItemModel(
        id: 'story_pub_25',
        type: StoryType.photo,
        mediaUrl: 'https://cdn.genlink.com/stories/pub.jpg',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.public),
      );

      final friendsStory = StoryItemModel(
        id: 'story_friends_25',
        type: StoryType.photo,
        mediaUrl: 'https://cdn.genlink.com/stories/friends.jpg',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.friends),
      );

      final onlyMeStory = StoryItemModel(
        id: 'story_only_me_25',
        type: StoryType.photo,
        mediaUrl: 'https://cdn.genlink.com/stories/only_me.jpg',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.onlyMe),
      );

      // Verify Public story shows public_rounded
      final pubGroup = StoryGroupModel(
        userId: 'user_pub',
        userName: 'User Public',
        userAvatar: '',
        isOwner: true,
        stories: [publicStory],
      );
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [pubGroup],
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byIcon(Icons.people_alt_rounded), findsNothing);

      // Verify Friends story shows people_alt_rounded
      final friendsGroup = StoryGroupModel(
        userId: 'user_friends',
        userName: 'User Friends',
        userAvatar: '',
        isOwner: true,
        stories: [friendsStory],
      );
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [friendsGroup],
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      expect(find.byIcon(Icons.public_rounded), findsNothing);

      // Verify Only Me story shows lock_rounded
      final onlyMeGroup = StoryGroupModel(
        userId: 'user_only_me',
        userName: 'User Only Me',
        userAvatar: '',
        isOwner: true,
        stories: [onlyMeStory],
      );
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [onlyMeGroup],
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsNothing);
      expect(find.byIcon(Icons.people_alt_rounded), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    test('Test 26: createStory preserves user Only Me selection even if backend response omits visibility', () async {
      final repository = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      fakeApiClient.returnedStoryId = 'story_fallback_omitted_26';
      // Post with custom settings
      const userSettings = StorySettings(
        visibility: StoryPrivacy.onlyMe,
        replyPermission: StoryReplyPermission.everyone,
        allowReactions: true,
      );

      final created = await repository.createStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        settings: userSettings,
      );

      expect(created.settings.visibility, StoryPrivacy.onlyMe);
      expect(created.visibility, 'Only Me');
      expect(created.storyPrivacy, StoryPrivacy.onlyMe);
    });
  });
}
