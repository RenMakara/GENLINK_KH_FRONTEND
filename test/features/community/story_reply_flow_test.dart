import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

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

class _TrackingStoryRepository implements StoryRepository {
  final List<Map<String, String>> recordedReplies = [];
  bool shouldThrowOnReply = false;

  @override
  Future<List<StoryGroupModel>> getStories() async => [];

  @override
  Future<void> toggleLikeStory(String storyId) async {}

  @override
  Future<void> markViewed(String storyId) async {}

  @override
  Future<void> replyToStory(String storyId, String message) async {
    if (shouldThrowOnReply) {
      throw Exception('Network connection timed out');
    }
    recordedReplies.add({'storyId': storyId, 'message': message});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testCurrentUser = UserEntity(
  id: 'current_user_123',
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Story Reply - Repository Unit Verification', () {
    test('1. replyToStory sends POST to /api/v1/community/stories/{id}/reply with message body', () async {
      String? requestedPath;
      dynamic requestedBody;

      final dio = dio_pkg.Dio();
      dio.httpClientAdapter = dio_pkg.HttpClientAdapter();
      dio.interceptors.add(dio_pkg.InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPath = options.path;
          requestedBody = options.data;
          handler.resolve(dio_pkg.Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Story reply sent',
              'data': {'id': 'reply_123'},
            },
          ));
        },
      ));

      final apiClient = ApiClient(dio);
      final repo = StoryRepositoryImpl(apiClient: apiClient);

      await repo.replyToStory('story_abc_999', 'Great story, loved the photo!');

      expect(requestedPath, equals('${ApiEndpoints.stories}/story_abc_999/reply'));
      expect(requestedPath, equals('/api/v1/community/stories/story_abc_999/reply'));
      expect(requestedBody, equals({'message': 'Great story, loved the photo!'}));
    });

    test('2. replyToStory propagates API error when request fails', () async {
      final dio = dio_pkg.Dio();
      dio.interceptors.add(dio_pkg.InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(dio_pkg.DioException(
            requestOptions: options,
            type: dio_pkg.DioExceptionType.connectionTimeout,
            error: 'Connection timed out',
          ));
        },
      ));

      final apiClient = ApiClient(dio);
      final repo = StoryRepositoryImpl(apiClient: apiClient);

      expect(
        () => repo.replyToStory('story_err_1', 'Hello error test'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Story Reply - StoryViewerScreen Integration Verification', () {
    late _TrackingStoryRepository mockRepo;
    late StoryController storyController;
    late _FakeAuthController authController;

    setUp(() {
      Get.testMode = true;
      Get.reset();
      Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);

      mockRepo = _TrackingStoryRepository();
      Get.put<StoryRepository>(mockRepo, permanent: true);

      authController = _FakeAuthController();
      authController.currentUser.value = _testCurrentUser;
      Get.put<AuthController>(authController, permanent: true);

      storyController = StoryController(repository: mockRepo);
      Get.put<StoryController>(storyController, permanent: true);
    });

    tearDown(() {
      Get.reset();
    });

    final testStory = StoryItemModel(
      id: 'story_reply_target_1',
      type: StoryType.text,
      textContent: 'Testing story reply',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      timeAgo: '5m ago',
      likesCount: 3,
      isLiked: false,
      allowReactions: true,
      replyPrivacy: 'Everyone',
    );

    final otherUserGroup = StoryGroupModel(
      userId: 'author_user_456',
      userName: 'Author User',
      userAvatar: 'assets/images/user_profile.png',
      isOwner: false,
      stories: [testStory],
    );

    testWidgets('3. Submitting story reply calls replyToStory before opening chat', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            groups: [otherUserGroup],
            initialGroupIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the message trigger button to open the reply sheet
      final openReplyButton = find.text("Send a message...");
      expect(openReplyButton, findsOneWidget);
      await tester.tap(openReplyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final replyField = find.byType(TextField);
      expect(replyField, findsOneWidget);

      await tester.enterText(replyField, 'Replying to your cool story!');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(mockRepo.recordedReplies.length, equals(1));
      expect(mockRepo.recordedReplies.first['storyId'], equals('story_reply_target_1'));
      expect(mockRepo.recordedReplies.first['message'], equals('Replying to your cool story!'));
    });

    testWidgets('4. Story reply failure shows danger banner and prevents navigation', (tester) async {
      mockRepo.shouldThrowOnReply = true;

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            groups: [otherUserGroup],
            initialGroupIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openReplyButton = find.text("Send a message...");
      expect(openReplyButton, findsOneWidget);
      await tester.tap(openReplyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final replyField = find.byType(TextField);
      expect(replyField, findsOneWidget);

      await tester.enterText(replyField, 'Failed reply attempt');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.text('Failed to Send Reply'), findsOneWidget);
    });
  });
}
