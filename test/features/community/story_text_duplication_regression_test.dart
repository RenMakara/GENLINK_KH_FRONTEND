import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_canvas_renderer.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/repositories/media_repository.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentPng = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLocalStorage extends LocalStorage {
  _MockLocalStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> readStoryDraft() async => null;

  @override
  Future<void> saveStoryDraft(String draftJson) async {}

  @override
  Future<void> deleteStoryDraft() async {}
}

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(Dio());

  Map<String, dynamic>? lastPostBody;

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    if (path == ApiEndpoints.stories) {
      lastPostBody = body as Map<String, dynamic>?;
      final responseData = {
        'storyId': 'server_story_123',
        'mediaUrl': body?['mediaUrl'] ?? 'https://cdn.example.com/mock_bg.png',
        'mediaType': body?['mediaType'] ?? 'IMAGE',
        'caption': body?['caption'],
        'seen': false,
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      };
      return parse(responseData);
    }
    throw UnimplementedError('Path not mocked: $path');
  }
}

class _TestMockMediaRepository implements MediaRepository {
  int uploadCallCount = 0;
  String returnedUrl = 'https://cdn.example.com/mock_bg.png';

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
      storageKey: 'uploads/stories/test_bg.png',
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
      contentType: 'image/png',
      sizeBytes: 1024,
    );
  }

  @override
  Future<void> delete(String mediaId) async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Text Story Duplication Bug & Backend Restoration Regression Tests', () {
    test('1. Publishing Text Story uploads clean canvas background and stores single caption in backend payload', () async {
      final mockClient = _MockApiClient();
      final mockMediaRepo = _TestMockMediaRepository();
      final uploadService = MediaUploadService(mockMediaRepo);
      final repo = StoryRepositoryImpl(
        apiClient: mockClient,
        mediaUploadService: uploadService,
      );

      final createdStory = await repo.createStory(
        type: StoryType.text,
        textContent: 'Test',
        bgGradientStart: '0xFF0F172A',
        bgGradientEnd: '0xFF1E293B',
        layers: [
          MovableStoryLayer(
            id: 'text_1',
            type: LayerType.text,
            text: 'Test',
            offset: const Offset(0.5, 0.5),
          ),
        ],
      );

      expect(mockMediaRepo.uploadCallCount, 1);
      expect(mockClient.lastPostBody, isNotNull);
      expect(mockClient.lastPostBody!['caption'], 'Test');
      expect(mockClient.lastPostBody!['mediaType'], 'IMAGE');
      expect(mockClient.lastPostBody!['mediaUrl'], mockMediaRepo.returnedUrl);

      expect(createdStory.textContent, 'Test');
      expect(createdStory.layers.length, 1);
      expect(createdStory.layers.first.text, 'Test');
    });

    testWidgets('2. Immediate Story Viewer rendering after posting displays "Test" exactly once', (tester) async {
      final story = StoryItemModel(
        id: 'story_immediate_1',
        type: StoryType.text,
        mediaUrl: 'https://cdn.example.com/mock_bg.png',
        textContent: 'Test',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        layers: [
          MovableStoryLayer(
            id: 'layer_1',
            type: LayerType.text,
            text: 'Test',
            offset: const Offset(0.5, 0.5),
          ),
        ],
      );

      final group = StoryGroupModel(
        userId: 'user_1',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [story],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final testFinder = find.text('Test');
      expect(testFinder, findsOneWidget, reason: 'Only ONE "Test" text widget must render immediately after posting');
    });

    testWidgets('3. Backend restoration (layers empty, textContent set from caption) renders "Test" exactly once', (tester) async {
      // Simulates story restored from backend (e.g. reload or refresh)
      final restoredStory = StoryItemModel(
        id: 'story_backend_restored_1',
        type: StoryType.text,
        mediaUrl: 'https://cdn.example.com/mock_bg.png',
        textContent: 'Test',
        timeAgo: '5m ago',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        layers: const [], // Backend does not store layers, layers are empty
      );

      final group = StoryGroupModel(
        userId: 'user_1',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [restoredStory],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final testFinder = find.text('Test');
      expect(testFinder, findsOneWidget, reason: 'Only ONE "Test" text widget must render after backend restoration');
    });

    testWidgets('4. Legitimate multiple text layers both render without duplication', (tester) async {
      final storyWithTwoTexts = StoryItemModel(
        id: 'story_multi_text_1',
        type: StoryType.text,
        mediaUrl: 'https://cdn.example.com/mock_bg.png',
        textContent: 'Heading Text',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        layers: [
          MovableStoryLayer(
            id: 'layer_header',
            type: LayerType.text,
            text: 'Heading Text',
            offset: const Offset(0.5, 0.3),
          ),
          MovableStoryLayer(
            id: 'layer_sub',
            type: LayerType.text,
            text: 'Subtitle Information',
            offset: const Offset(0.5, 0.6),
          ),
        ],
      );

      final group = StoryGroupModel(
        userId: 'user_1',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [storyWithTwoTexts],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Heading Text'), findsOneWidget);
      expect(find.text('Subtitle Information'), findsOneWidget);
    });

    testWidgets('5. StoryCanvasRenderer renders restored backend Text Story text exactly once', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoryCanvasRenderer(
              canvasSize: Size(390, 844),
              layers: [],
              storyType: StoryType.text,
              textContent: 'Test',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test'), findsOneWidget, reason: 'StoryCanvasRenderer must render "Test" exactly once when layers are empty');
    });

    testWidgets('6. StoryCanvasRenderer with active text layer does not render duplicate textContent', (tester) async {
      final layer = MovableStoryLayer(
        id: 'layer_active',
        type: LayerType.text,
        text: 'Test',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCanvasRenderer(
              canvasSize: const Size(390, 844),
              layers: [layer],
              storyType: StoryType.text,
              textContent: 'Test',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test'), findsOneWidget, reason: 'StoryCanvasRenderer must not duplicate text when layers contains text and textContent is set');
    });
  });
}
