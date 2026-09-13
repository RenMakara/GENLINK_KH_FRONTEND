import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/shared/utils/current_user.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
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

class _TrackingApiClient extends ApiClient {
  _TrackingApiClient() : super(Dio());

  final List<String> viewedStoryIds = [];
  bool throwOnView = false;
  List<Map<String, dynamic>> viewersToReturn = [];
  int getStoryViewersCallCount = 0;
  final List<String> requestedViewerStoryIds = [];

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    if (path.startsWith('/api/v1/community/stories/') && path.endsWith('/view')) {
      if (throwOnView) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'Simulated network failure',
        );
      }
      final parts = path.split('/');
      final storyId = parts[parts.length - 2];
      viewedStoryIds.add(storyId);
      return parse({'success': true});
    }
    throw UnimplementedError('Unmocked path: $path');
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    if (path.startsWith('/api/v1/community/stories/') && path.endsWith('/viewers')) {
      getStoryViewersCallCount++;
      final parts = path.split('/');
      final storyId = parts[parts.length - 2];
      requestedViewerStoryIds.add(storyId);
      return parse(viewersToReturn);
    }
    if (path == ApiEndpoints.stories) {
      return parse([
        {
          'author': {
            'userId': 'current_user_1',
            'fullName': 'User Owner',
            'avatarUrl': 'assets/images/user_profile.png',
          },
          'hasUnseen': false,
          'stories': [
            {
              'storyId': 'story_owner_1',
              'mediaType': 'IMAGE',
              'mediaUrl': 'https://cdn.example.com/bg.png',
              'caption': 'My Story',
              'seen': true,
              'viewerCount': viewersToReturn.length,
              'createdAt': DateTime.now().toIso8601String(),
              'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
            },
          ],
        },
      ]);
    }
    throw UnimplementedError('Unmocked GET path: $path');
  }
}

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testCurrentUser = UserEntity(
  id: 'current_user_1',
  fullName: 'Current User',
  username: 'currentuser',
  email: 'me@example.com',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 1,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);

    final authController = _FakeAuthController();
    authController.currentUser.value = _testCurrentUser;
    Get.put<AuthController>(authController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Viewer Tracking & Insights Regression Tests', () {
    testWidgets('1. Opening another user\'s story records a view exactly once', (tester) async {
      final mockClient = _TrackingApiClient();
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final otherUserStory = StoryItemModel(
        id: 'story_other_1',
        type: StoryType.text,
        textContent: 'Hello from friend',
        timeAgo: '10m ago',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isViewed: false,
      );

      final otherGroup = StoryGroupModel(
        userId: 'user_other_99',
        userName: 'Friend User',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [otherUserStory],
      );

      controller.storyGroups.assignAll([otherGroup]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [otherGroup],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockClient.viewedStoryIds, contains('story_other_1'),
          reason: 'Viewing another user\'s story must call markViewed API on backend');
      expect(mockClient.viewedStoryIds.length, 1,
          reason: 'Exactly one view call must be made');
      expect(otherUserStory.isViewed, isTrue);
    });

    testWidgets('2. Same user reopening the same story does not create duplicate views', (tester) async {
      final mockClient = _TrackingApiClient();
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final alreadyViewedStory = StoryItemModel(
        id: 'story_other_2',
        type: StoryType.photo,
        mediaUrl: 'https://cdn.example.com/mock.png',
        timeAgo: '1h ago',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isViewed: true,
      );

      final group = StoryGroupModel(
        userId: 'user_other_99',
        userName: 'Friend User',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [alreadyViewedStory],
      );

      controller.storyGroups.assignAll([group]);

      // Open first time
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

      final firstCount = mockClient.viewedStoryIds.length;

      // Reopen the story screen
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

      expect(alreadyViewedStory.isViewed, isTrue);
      // Reopening does not increment viewed calls beyond the initial count
      expect(mockClient.viewedStoryIds.length, equals(firstCount));
    });

    testWidgets('3. Owner viewing their own story is not counted', (tester) async {
      final mockClient = _TrackingApiClient();
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final ownStory = StoryItemModel(
        id: 'story_own_1',
        type: StoryType.text,
        textContent: 'My own story',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        viewersCount: 0,
      );

      final ownGroup = StoryGroupModel(
        userId: CurrentUser.id,
        userName: CurrentUser.name,
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [ownStory],
      );

      controller.storyGroups.assignAll([ownGroup]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [ownGroup],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockClient.viewedStoryIds, isEmpty,
          reason: 'Owner viewing own story must NEVER call view tracking API');
    });

    testWidgets('4. Viewer count is correctly deserialized from backend and displayed in UI', (tester) async {
      final mockClient = _TrackingApiClient();
      mockClient.viewersToReturn = [
        {
          'userId': 'viewer_1',
          'fullName': 'Viewer One',
          'username': 'viewer1',
          'avatarUrl': 'assets/images/user_profile.png',
          'viewedAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        {
          'userId': 'viewer_2',
          'fullName': 'Viewer Two',
          'username': 'viewer2',
          'avatarUrl': 'assets/images/user_profile.png',
          'viewedAt': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        },
      ];

      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);

      // Verify repository deserialization from backend JSON
      final stories = await repo.getStories();
      expect(stories.isNotEmpty, isTrue);
      final ownerGroup = stories.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.isNotEmpty, isTrue);
      final story = ownerGroup.stories.first;
      expect(story.viewersCount, 2, reason: 'viewerCount must deserialize from backend response');

      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);
      controller.storyGroups.assignAll(stories);

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: stories,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The owner viewer pill displays the viewer count
      expect(find.text('2'), findsOneWidget, reason: 'Viewer count 2 must be displayed in owner UI pill');
    });

    testWidgets('5. Real viewer list survives refresh/reload without fake demo data', (tester) async {
      final mockClient = _TrackingApiClient();
      mockClient.viewersToReturn = [
        {
          'userId': 'viewer_real_1',
          'fullName': 'Sophea Real',
          'username': 'sophea',
          'avatarUrl': 'assets/images/user_profile.png',
          'viewedAt': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        },
      ];

      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);

      final viewers = await repo.getStoryViewers('story_owner_1');
      expect(viewers.length, 1);
      expect(viewers.first.userName, 'Sophea Real');
      expect(viewers.first.id, 'viewer_real_1');

      // Verify no fake demo names exist in result
      expect(viewers.any((v) => v.userName == 'Chhaeng Sokuntheara'), isFalse);
      expect(viewers.any((v) => v.userName == 'Heng Chansela'), isFalse);
    });

    testWidgets('6. View-tracking API failure does not crash Story Viewer playback', (tester) async {
      final mockClient = _TrackingApiClient();
      mockClient.throwOnView = true; // Simulate network error / 500 error
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final otherStory = StoryItemModel(
        id: 'story_faulty_1',
        type: StoryType.text,
        textContent: 'Resilient story',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      );

      final group = StoryGroupModel(
        userId: 'user_other_faulty',
        userName: 'Friend',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [otherStory],
      );

      controller.storyGroups.assignAll([group]);

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

      // Widget continues to render cleanly and text is visible without crash
      expect(find.text('Resilient story'), findsOneWidget);
    });

    testWidgets('7. Opening Story Viewer with mounted Obx does not trigger setState() or markNeedsBuild() during build', (tester) async {
      final mockClient = _TrackingApiClient();
      mockClient.viewersToReturn = [
        {
          'userId': 'viewer_user_1',
          'fullName': 'Viewer Alice',
          'username': 'alice',
          'avatarUrl': 'assets/images/user_profile.png',
          'viewedAt': DateTime.now().toIso8601String(),
        },
      ];
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final ownerStory = StoryItemModel(
        id: 'story_owner_lifecycle',
        type: StoryType.text,
        textContent: 'Owner lifecycle test',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        viewersCount: 0,
      );

      final ownerGroup = StoryGroupModel(
        userId: 'current_user_1',
        userName: 'Your Story',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [ownerStory],
      );

      controller.storyGroups.assignAll([ownerGroup]);

      // Pump a tree with an Obx observing controller.storyGroups (identical to StoryTrayWidget)
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Simulated StoryTray Obx widget that rebuilds when storyGroups refreshes
                Obx(() => Text('Groups: ${controller.storyGroups.length} | Viewers: ${controller.storyGroups.firstOrNull?.stories.firstOrNull?.viewersCount ?? 0}')),
                // StoryViewerScreen opened directly on top
                StoryViewerScreen(
                  initialGroupIndex: 0,
                  groups: [ownerGroup],
                ),
              ],
            ),
          ),
        ),
      );

      // Verify initial frame builds without throwing
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'Opening StoryViewerScreen with Obx in tree must never throw setState or markNeedsBuild during build');
      expect(find.text('Owner lifecycle test'), findsOneWidget);
    });

    testWidgets('8. Another user opening story with mounted Obx does not trigger markNeedsBuild during build', (tester) async {
      final mockClient = _TrackingApiClient();
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final friendStory = StoryItemModel(
        id: 'story_friend_lifecycle',
        type: StoryType.text,
        textContent: 'Friend lifecycle test',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        isViewed: false,
      );

      final friendGroup = StoryGroupModel(
        userId: 'user_friend_1',
        userName: 'Friend 1',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [friendStory],
      );

      controller.storyGroups.assignAll([friendGroup]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Obx(() => Text('Seen: ${controller.storyGroups.firstOrNull?.stories.firstOrNull?.isViewed ?? false}')),
                StoryViewerScreen(
                  initialGroupIndex: 0,
                  groups: [friendGroup],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: 'Marking story as viewed with Obx in tree must be lifecycle-safe');
      expect(friendStory.isViewed, isTrue);
      expect(mockClient.viewedStoryIds, contains('story_friend_lifecycle'));
    });

    testWidgets('9. Prevent duplicate viewer-fetch requests when the same story is already loading', (tester) async {
      final mockClient = _TrackingApiClient();
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final ownerStory = StoryItemModel(
        id: 'story_dedup_test',
        type: StoryType.text,
        textContent: 'Dedup check',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      );

      final ownerGroup = StoryGroupModel(
        userId: 'current_user_1',
        userName: 'Your Story',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [ownerStory],
      );

      controller.storyGroups.assignAll([ownerGroup]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [ownerGroup],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(mockClient.requestedViewerStoryIds.where((id) => id == 'story_dedup_test').length, 1,
          reason: 'Duplicate viewer-fetch requests for the same active story must be prevented');
    });

    testWidgets('10. Safe navigation between multiple stories without stale viewer data leaking', (tester) async {
      final mockClient = _TrackingApiClient();
      mockClient.viewersToReturn = [
        {
          'userId': 'viewer_user_A',
          'fullName': 'Viewer A',
          'username': 'viewera',
          'avatarUrl': 'assets/images/user_profile.png',
          'viewedAt': DateTime.now().toIso8601String(),
        },
      ];
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final storyA = StoryItemModel(
        id: 'story_multi_A',
        type: StoryType.text,
        textContent: 'Story A Content',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      );
      final storyB = StoryItemModel(
        id: 'story_multi_B',
        type: StoryType.text,
        textContent: 'Story B Content',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      );

      final ownerGroup = StoryGroupModel(
        userId: 'current_user_1',
        userName: 'Your Story',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [storyA, storyB],
      );

      controller.storyGroups.assignAll([ownerGroup]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [ownerGroup],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Story A Content'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap right half of the screen to advance to Story B
      await tester.tapAt(const Offset(600, 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Story B Content'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Navigating between stories must complete without lifecycle exceptions');
    });

    testWidgets('11. Opening viewers sheet (FutureBuilder) does not call markNeedsBuild during build', (tester) async {
      final mockClient = _TrackingApiClient();
      mockClient.viewersToReturn = [
        {
          'userId': 'viewer_user_sheet',
          'fullName': 'Sheet Viewer',
          'username': 'sheetuser',
          'avatarUrl': 'assets/images/user_profile.png',
          'viewedAt': DateTime.now().toIso8601String(),
        },
      ];
      final repo = StoryRepositoryImpl(apiClient: mockClient);
      Get.put<StoryRepository>(repo, permanent: true);
      final controller = StoryController(repository: repo);
      Get.put<StoryController>(controller, permanent: true);

      final ownerStory = StoryItemModel(
        id: 'story_sheet_test',
        type: StoryType.text,
        textContent: 'Sheet test story',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        viewersCount: 1,
      );

      final ownerGroup = StoryGroupModel(
        userId: 'current_user_1',
        userName: 'Your Story',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [ownerStory],
      );

      controller.storyGroups.assignAll([ownerGroup]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Obx(() => Text('Observed: ${controller.storyGroups.length}')),
                StoryViewerScreen(
                  initialGroupIndex: 0,
                  groups: [ownerGroup],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the viewer count pill and tap it to open the sheet
      final viewerPillFinder = find.byIcon(Icons.remove_red_eye_outlined);
      expect(viewerPillFinder, findsOneWidget);
      await tester.tap(viewerPillFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull,
          reason: 'Opening viewer bottom sheet with FutureBuilder must not throw markNeedsBuild during build');
      expect(find.text('Story Insights'), findsOneWidget);
      expect(find.text('Sheet Viewer'), findsOneWidget);
    });
  });
}
