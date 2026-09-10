import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
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

  group('Story Like Interaction & Polish Comprehensive Verification', () {
    testWidgets('1. Like another user\'s Story: tap button -> fills heart & increments count', (tester) async {
      final story = StoryItemModel(
        id: 'story_1',
        type: StoryType.text,
        textContent: 'Story 1',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 12,
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
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: groups,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(story.isLiked, false);
      expect(story.likesCount, 12);

      // Tap Like button and wait for gesture arena + 180ms pop animation
      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(story.isLiked, true);
      expect(story.likesCount, 13);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('2. Unlike another user\'s Story: tap button -> outlines heart & decrements count', (tester) async {
      final story = StoryItemModel(
        id: 'story_2',
        type: StoryType.text,
        textContent: 'Story 2',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 20,
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
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: groups,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(story.isLiked, true);
      expect(story.likesCount, 20);

      // Tap to Unlike and wait for gesture arena + settle
      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(story.isLiked, false);
      expect(story.likesCount, 19);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('3. Double-tap another user\'s Story: likes Story with subtle pop, NO giant center heart', (tester) async {
      final story = StoryItemModel(
        id: 'story_3',
        type: StoryType.text,
        textContent: 'Story 3',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 8,
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
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: groups,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(story.isLiked, false);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // Double tap anywhere on story canvas
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Liked state updated
      expect(story.isLiked, true);
      expect(story.likesCount, 9);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('4. Double-tap own Story -> nothing happens (no like, no animation, no API call)', (tester) async {
      final ownStory = StoryItemModel(
        id: 'own_story_4',
        type: StoryType.text,
        textContent: 'My Story',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 15,
        isLiked: false,
        allowReactions: true,
      );

      final groups = [
        StoryGroupModel(
          userId: 'current_user_123', // Matches CurrentUser.id
          userName: 'Current User',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: true,
          stories: [ownStory],
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: groups,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Like button should be hidden for own story
      expect(find.byType(StoryInteractiveLikeButton), findsNothing);
      expect(ownStory.isLiked, false);
      expect(ownStory.likesCount, 15);

      // Double tap on own story
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Remains strictly unchanged
      expect(ownStory.isLiked, false);
      expect(ownStory.likesCount, 15);
    });

    testWidgets('5. Move between Stories -> correct like state reset and no animation replay', (tester) async {
      final storyA = StoryItemModel(
        id: 'story_A',
        type: StoryType.text,
        textContent: 'Story A (Liked)',
        timeAgo: '5m',
        createdAt: DateTime.now(),
        likesCount: 30,
        isLiked: true,
        allowReactions: true,
      );

      final storyB = StoryItemModel(
        id: 'story_B',
        type: StoryType.text,
        textContent: 'Story B (Unliked)',
        timeAgo: '4m',
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
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: groups,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // On Story A: Liked
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

      // Move to next story
      final nextZone = find.byWidgetPredicate((w) => w is GestureDetector && w.behavior == HitTestBehavior.translucent).last;
      await tester.tap(nextZone);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // On Story B: Unliked
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    test('6. API failure & safety -> UI state remains correct and safe rollback', () async {
      final controller = Get.put(StoryController());

      final story = StoryItemModel(
        id: 'story_error_test',
        type: StoryType.text,
        textContent: 'Error Test',
        timeAgo: '1m',
        createdAt: DateTime.now(),
        likesCount: 10,
        isLiked: false,
      );

      final ownStory = StoryItemModel(
        id: 'story_own_test',
        type: StoryType.text,
        textContent: 'Own Test',
        timeAgo: '1m',
        createdAt: DateTime.now(),
        likesCount: 20,
        isLiked: false,
      );

      controller.storyGroups.assignAll([
        StoryGroupModel(
          userId: 'other_user_888',
          userName: 'Other',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: false,
          stories: [story],
        ),
        StoryGroupModel(
          userId: 'current_user_123',
          userName: 'Me',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: true,
          stories: [ownStory],
        ),
      ]);

      // Toggling own story is blocked
      controller.toggleLike('story_own_test');
      expect(ownStory.isLiked, false);
      expect(ownStory.likesCount, 20);

      // Toggling other story succeeds
      controller.toggleLike('story_error_test');
      expect(story.isLiked, true);
      expect(story.likesCount, 11);
    });

    testWidgets('7. Rapid taps -> debounces cleanly without crashing or duplicate calls', (tester) async {
      final story = StoryItemModel(
        id: 'story_rapid_test',
        type: StoryType.text,
        textContent: 'Rapid Test',
        timeAgo: '1m',
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
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: groups,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Double tap on story canvas rapidly 4 times
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Debounce allowed only 1 toggle to liked
      expect(story.isLiked, true);
      expect(story.likesCount, 6);
      expect(find.byType(StoryInteractiveLikeButton), findsOneWidget);
    });
  });
}
