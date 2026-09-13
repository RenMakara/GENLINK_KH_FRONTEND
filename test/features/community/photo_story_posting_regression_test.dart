import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_canvas_renderer.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _MockLocalStorage extends LocalStorage {
  _MockLocalStorage() : super(storage: const FlutterSecureStorage());
  @override
  Future<String?> readStoryDraft() async => null;
  @override
  Future<void> saveStoryDraft(String draftJson) async {}
  @override
  Future<void> deleteStoryDraft() async {}
}

class _FakeMediaUploadService extends MediaUploadService {
  _FakeMediaUploadService() : super(_DummyMediaRepository());

  int uploadCallCount = 0;
  Uint8List? lastUploadedBytes;
  String? lastContentType;
  MediaPurpose? lastPurpose;
  String returnUrl = 'https://cdn.genlink.kh/stories/2026/09/real_uploaded_photo.jpg';

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
    lastUploadedBytes = bytes;
    lastContentType = contentType;
    lastPurpose = purpose;
    return MediaEntity(
      mediaId: 'media_uuid_123',
      url: returnUrl,
      contentType: contentType,
      sizeBytes: bytes.length,
      uploadedAt: DateTime.now(),
    );
  }
}

class _DummyMediaRepository implements MediaRepository {
  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async => const PresignedUpload(
        mediaId: 'm1',
        uploadUrl: 'https://upload.url',
        storageKey: 'key',
        requiredHeaders: {},
        expiresInSeconds: 300,
      );

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
  }) async => MediaEntity(
        mediaId: mediaId,
        url: 'https://cdn.genlink.kh/test.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 100,
        uploadedAt: DateTime.now(),
      );

  @override
  Future<void> delete(String mediaId) async {}
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  int postCallCount = 0;
  String? lastPostEndpoint;
  Map<String, dynamic>? lastPostBody;
  Map<String, dynamic> mockPostResponse = {
    'storyId': 'server-story-uuid-9999',
    'mediaType': 'IMAGE',
    'mediaUrl': 'https://cdn.genlink.kh/stories/2026/09/real_uploaded_photo.jpg',
    'caption': 'My photo story caption',
    'seen': false,
    'viewerCount': 0,
    'createdAt': DateTime.now().toIso8601String(),
    'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
  };

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    postCallCount++;
    lastPostEndpoint = path;
    if (body is Map<String, dynamic>) {
      lastPostBody = body;
    }
    return parse(mockPostResponse);
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    if (path == ApiEndpoints.stories) {
      final data = [
        {
          'author': {
            'userId': 'current_user',
            'fullName': 'Author Name',
            'username': 'author',
            'avatarUrl': 'https://cdn/avatar.jpg',
          },
          'hasUnseen': false,
          'stories': [mockPostResponse],
        }
      ];
      return parse(data);
    }
    return parse([]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeApiClient fakeApiClient;
  late _FakeMediaUploadService fakeUploadService;
  late File tempPhotoFile;

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);

    fakeApiClient = _FakeApiClient();
    fakeUploadService = _FakeMediaUploadService();

    // Create a real temp photo file to test local file resolution
    final tempDir = Directory.systemTemp;
    tempPhotoFile = File('${tempDir.path}/camera_photo_test_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempPhotoFile.writeAsBytes(Uint8List.fromList(List.generate(1024, (i) => i % 256)));
  });

  tearDown(() async {
    Get.reset();
    if (tempPhotoFile.existsSync()) {
      try {
        await tempPhotoFile.delete();
      } catch (_) {}
    }
  });

  group('Photo Story Posting Complete Flow Verification', () {
    test('1. Local camera photo upload & backend publish creates valid API request with CDN URL and server UUID', () async {
      final repo = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      final controller = Get.put(StoryController(repository: repo));

      // Simulate posting a photo taken by device camera with file:// scheme
      final localPhotoUri = Uri.file(tempPhotoFile.path).toString();
      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: localPhotoUri,
        textContent: 'My photo story caption',
        visibility: 'Public',
      );

      expect(success, true);
      // Verify local file was uploaded via MediaUploadService
      expect(fakeUploadService.uploadCallCount, 1);
      expect(fakeUploadService.lastPurpose, MediaPurpose.story);
      expect(fakeUploadService.lastContentType, 'image/jpeg');

      // Verify backend API request was created with CDN mediaUrl (NOT the local file:// path)
      expect(fakeApiClient.postCallCount, 1);
      expect(fakeApiClient.lastPostEndpoint, ApiEndpoints.stories);
      expect(fakeApiClient.lastPostBody!['mediaUrl'], 'https://cdn.genlink.kh/stories/2026/09/real_uploaded_photo.jpg');
      expect(fakeApiClient.lastPostBody!['mediaType'], 'IMAGE');
      expect(fakeApiClient.lastPostBody!['caption'], 'My photo story caption');

      // Verify created story has server UUID and CDN mediaUrl
      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.isNotEmpty, true);
      final postedStory = ownerGroup.stories.first;
      expect(postedStory.id, 'server-story-uuid-9999');
      expect(postedStory.mediaUrl, 'https://cdn.genlink.kh/stories/2026/09/real_uploaded_photo.jpg');
      expect(postedStory.type, StoryType.photo);
      expect(postedStory.textContent, 'My photo story caption');
    });

    test('2. Backend stories feed deserialization correctly parses storyId and resolves photo type', () async {
      final repo = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      final groups = await repo.getStories();
      expect(groups.isNotEmpty, true);
      final groupWithStories = groups.firstWhere((g) => g.stories.isNotEmpty);
      final story = groupWithStories.stories.first;

      // Ensure storyId from backend response is preserved (not empty string)
      expect(story.id, 'server-story-uuid-9999');
      expect(story.mediaUrl, 'https://cdn.genlink.kh/stories/2026/09/real_uploaded_photo.jpg');
      expect(story.type, StoryType.photo);
    });

    test('3. Photo Story with asset image loads bytes and uploads to CDN', () async {
      final repo = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );

      final controller = Get.put(StoryController(repository: repo));

      final success = await controller.publishStory(
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        textContent: 'Asset photo story',
        visibility: 'Public',
      );

      expect(success, true);
      expect(fakeApiClient.lastPostBody!['mediaUrl'], 'https://cdn.genlink.kh/stories/2026/09/real_uploaded_photo.jpg');
      expect(fakeApiClient.lastPostBody!['mediaType'], 'IMAGE');
    });

    testWidgets('4. StoryCreatorScreen with single photo loads image canvas and publishes successfully', (tester) async {
      final repo = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );
      Get.put(StoryController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(name: '/home', page: () => const Scaffold(body: Text('Home Feed'))),
            GetPage(
              name: '/StoryCreatorScreen',
              page: () => StoryCreatorScreen(
                type: StoryType.photo,
                mediaPaths: [tempPhotoFile.path],
              ),
            ),
          ],
        ),
      );

      await tester.pump();
      Get.toNamed('/StoryCreatorScreen');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Post Story'), findsOneWidget);
      // Verify image error placeholder is NOT displayed
      expect(find.text('Unable to load image.'), findsNothing);

      // Tap Post Story and execute real file I/O inside runAsync
      await tester.runAsync(() async {
        await tester.tap(find.text('Post Story'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verify composer completed and returned to Home Feed
      expect(find.text('Home Feed'), findsOneWidget);
      expect(fakeApiClient.postCallCount, 1);
    });

    testWidgets('5. StoryCreatorScreen with multiple photos initializes active media and publishes', (tester) async {
      final repo = StoryRepositoryImpl(
        apiClient: fakeApiClient,
        mediaUploadService: fakeUploadService,
      );
      Get.put(StoryController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(name: '/home', page: () => const Scaffold(body: Text('Home Feed'))),
            GetPage(
              name: '/StoryCreatorScreen',
              page: () => StoryCreatorScreen(
                type: StoryType.photo,
                mediaPaths: [tempPhotoFile.path, 'assets/images/user_profile.png'],
              ),
            ),
          ],
        ),
      );

      await tester.pump();
      Get.toNamed('/StoryCreatorScreen');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Post Story'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Post Story'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.text('Home Feed'), findsOneWidget);
      expect(fakeApiClient.postCallCount, 1);
      expect(fakeApiClient.lastPostBody!['mediaUrl'], isNotEmpty);
    });

    testWidgets('6. StoryCanvasRenderer correctly displays network image for photo stories', (tester) async {
      final photoStory = StoryItemModel(
        id: 'photo_test_1',
        type: StoryType.photo,
        mediaUrl: 'https://cdn.genlink.kh/stories/2026/09/sample.jpg',
        textContent: 'Caption for viewer',
        timeAgo: '1m ago',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.public),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: StoryCanvasRenderer(
                canvasSize: const Size(360, 640),
                storyType: photoStory.type,
                mediaUrl: photoStory.mediaUrl,
                textContent: photoStory.textContent,
                bgGradientStart: '0xFF0F172A',
                bgGradientEnd: '0xFF1E293B',
                layers: photoStory.layers,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // Should find Image widget rendering the network mediaUrl
      expect(find.byType(Image), findsOneWidget);
      // Should find the caption
      expect(find.text('Caption for viewer'), findsOneWidget);
    });

    testWidgets('7. Text Story duplication fix remains intact (only one caption drawn)', (tester) async {
      final textStory = StoryItemModel(
        id: 'text_test_1',
        type: StoryType.text,
        mediaUrl: null,
        textContent: 'Test',
        timeAgo: '1m ago',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.public),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: StoryCanvasRenderer(
                canvasSize: const Size(360, 640),
                storyType: textStory.type,
                mediaUrl: textStory.mediaUrl,
                textContent: textStory.textContent,
                bgGradientStart: '0xFF0F172A',
                bgGradientEnd: '0xFF1E293B',
                layers: textStory.layers,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // "Test" must appear exactly once in the tree
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
