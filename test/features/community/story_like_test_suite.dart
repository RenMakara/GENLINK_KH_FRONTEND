import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_interactive_like_button.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
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
  int likeCallCount = 0;
  bool shouldThrowOnLike = false;
  final requestedLikedStates = <bool>[];

  @override
  Future<List<StoryGroupModel>> getStories() async => [];

  @override
  Future<void> likeStory(String storyId) async {
    likeCallCount++;
    requestedLikedStates.add(true);
    if (shouldThrowOnLike) {
      throw Exception('Network connection timed out');
    }
  }

  @override
  Future<void> unlikeStory(String storyId) async {
    likeCallCount++;
    requestedLikedStates.add(false);
    if (shouldThrowOnLike) {
      throw Exception('Network connection timed out');
    }
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
  late _TrackingStoryRepository trackingRepo;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);

    final authController = _FakeAuthController();
    authController.currentUser.value = _testCurrentUser;
    Get.put<AuthController>(authController, permanent: true);

    trackingRepo = _TrackingStoryRepository();
    final storyController = StoryController(repository: trackingRepo);
    Get.put<StoryController>(storyController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Like 8-Point Verification Test Suite', () {
    test(
      'repeated toggles send explicit desired states to the repository',
      () async {
        final story = StoryItemModel(
          id: 'story_desired_state',
          type: StoryType.text,
          textContent: 'Retry-safe reaction',
          timeAgo: 'now',
          createdAt: DateTime.now(),
          likesCount: 0,
          isLiked: false,
          allowReactions: true,
        );
        final controller = Get.find<StoryController>();
        controller.storyGroups.assignAll([
          StoryGroupModel(
            userId: 'other_user_456',
            userName: 'Other User',
            userAvatar: '',
            isOwner: false,
            stories: [story],
          ),
        ]);

        await controller.toggleLike(story.id);
        await controller.toggleLike(story.id);

        expect(trackingRepo.requestedLikedStates, [true, false]);
        expect(story.isLiked, isFalse);
        expect(story.likesCount, 0);
      },
    );

    testWidgets(
      'TEST 1: Open another user\'s Story -> Tap Like -> Story becomes liked',
      (tester) async {
        final story = StoryItemModel(
          id: 'story_t1',
          type: StoryType.text,
          textContent: 'Story T1',
          timeAgo: '5m',
          createdAt: DateTime.now(),
          likesCount: 10,
          isLiked: false,
          allowReactions: true,
        );

        final groups = [
          StoryGroupModel(
            userId: 'other_user_456',
            userName: 'Other User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: false,
            stories: [story],
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(story.isLiked, false);
        expect(story.likesCount, 10);

        await tester.tap(find.byType(StoryInteractiveLikeButton));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(story.isLiked, true);
        expect(story.likesCount, 11);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      },
    );

    testWidgets('TEST 2: Tap Like again -> Story becomes unliked', (
      tester,
    ) async {
      final story = StoryItemModel(
        id: 'story_t2',
        type: StoryType.text,
        textContent: 'Story T2',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 15,
        isLiked: true,
        allowReactions: true,
      );

      final groups = [
        StoryGroupModel(
          userId: 'other_user_456',
          userName: 'Other User',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: false,
          stories: [story],
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(story.isLiked, true);

      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(story.isLiked, false);
      expect(story.likesCount, 14);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets(
      'TEST 3: Double tap another user\'s Story -> Story becomes liked',
      (tester) async {
        final story = StoryItemModel(
          id: 'story_t3',
          type: StoryType.text,
          textContent: 'Story T3',
          timeAgo: '5m',
          createdAt: DateTime.now(),
          likesCount: 20,
          isLiked: false,
          allowReactions: true,
        );

        final groups = [
          StoryGroupModel(
            userId: 'other_user_456',
            userName: 'Other User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: false,
            stories: [story],
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );
        await tester.pumpAndSettle();

        final centerFinder = find.byType(StoryViewerScreen);
        await tester.tap(centerFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(centerFinder);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(story.isLiked, true);
        expect(story.likesCount, 21);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 4: Open own Story -> Tap Like -> Nothing happens (button hidden/blocked)',
      (tester) async {
        final ownStory = StoryItemModel(
          id: 'story_own_1',
          type: StoryType.text,
          textContent: 'My Own Story',
          timeAgo: '1m',
          createdAt: DateTime.now(),
          likesCount: 0,
          isLiked: false,
          allowReactions: true,
        );

        final groups = [
          StoryGroupModel(
            userId: 'current_user_123',
            userName: 'Current User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: true,
            stories: [ownStory],
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StoryInteractiveLikeButton), findsNothing);
        expect(ownStory.isLiked, false);
        expect(ownStory.likesCount, 0);
      },
    );

    testWidgets('TEST 5: Open own Story -> Double tap -> Nothing happens', (
      tester,
    ) async {
      final ownStory = StoryItemModel(
        id: 'story_own_2',
        type: StoryType.text,
        textContent: 'My Own Story Double Tap Test',
        timeAgo: '1m',
        createdAt: DateTime.now(),
        likesCount: 0,
        isLiked: false,
        allowReactions: true,
      );

      final groups = [
        StoryGroupModel(
          userId: 'current_user_123',
          userName: 'Current User',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: true,
          stories: [ownStory],
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
        ),
      );
      await tester.pumpAndSettle();

      final centerFinder = find.byType(StoryViewerScreen);
      await tester.tap(centerFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(centerFinder);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(ownStory.isLiked, false);
      expect(ownStory.likesCount, 0);
    });

    testWidgets(
      'TEST 6: Move from Story A to Story B -> Each Story displays its own correct reaction state',
      (tester) async {
        final storyA = StoryItemModel(
          id: 'story_A',
          type: StoryType.text,
          textContent: 'Story A (Liked)',
          timeAgo: '5m',
          createdAt: DateTime.now(),
          likesCount: 10,
          isLiked: true,
          allowReactions: true,
        );

        final storyB = StoryItemModel(
          id: 'story_B',
          type: StoryType.text,
          textContent: 'Story B (Unliked)',
          timeAgo: '2m',
          createdAt: DateTime.now(),
          likesCount: 5,
          isLiked: false,
          allowReactions: true,
        );

        final groups = [
          StoryGroupModel(
            userId: 'other_user_456',
            userName: 'Other User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: false,
            stories: [storyA, storyB],
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

        final nextZone = find
            .byWidgetPredicate(
              (w) =>
                  w is GestureDetector &&
                  w.behavior == HitTestBehavior.translucent,
            )
            .last;
        await tester.tap(nextZone);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      },
    );

    testWidgets(
      'TEST 7: Simulate API failure -> Previous state remains unchanged',
      (tester) async {
        final story = StoryItemModel(
          id: 'story_fail_test',
          type: StoryType.text,
          textContent: 'Story Fail Test',
          timeAgo: '5m',
          createdAt: DateTime.now(),
          likesCount: 7,
          isLiked: false,
          allowReactions: true,
        );

        final groups = [
          StoryGroupModel(
            userId: 'other_user_456',
            userName: 'Other User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: false,
            stories: [story],
          ),
        ];

        trackingRepo.shouldThrowOnLike = true;

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );
        await tester.pumpAndSettle();

        expect(story.isLiked, false);
        expect(story.likesCount, 7);

        await tester.tap(find.byType(StoryInteractiveLikeButton));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(story.isLiked, false);
        expect(story.likesCount, 7);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      },
    );

    testWidgets('TEST 8: Rapid taps -> No duplicate reaction requests', (
      tester,
    ) async {
      final story = StoryItemModel(
        id: 'story_rapid_test',
        type: StoryType.text,
        textContent: 'Story Rapid Tap Test',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 5,
        isLiked: false,
        allowReactions: true,
      );

      final groups = [
        StoryGroupModel(
          userId: 'other_user_456',
          userName: 'Other User',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: false,
          stories: [story],
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(story.isLiked, true);
      expect(story.likesCount, 6);
    });
  });
}
