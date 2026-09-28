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

  group('Story Ownership & Self-Like Prevention Tests', () {
    testWidgets(
      'Test 1: Viewing another user\'s story allows double-tap liking and shows bottom like button',
      (tester) async {
        final otherUserStory = StoryItemModel(
          id: 'story_other_1',
          type: StoryType.text,
          textContent: 'Other user text story',
          timeAgo: '10m',
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
            stories: [otherUserStory],
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(StoryInteractiveLikeButton), findsOneWidget);
        expect(otherUserStory.isLiked, false);
        expect(otherUserStory.likesCount, 5);

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(otherUserStory.isLiked, true);
        expect(otherUserStory.likesCount, 6);
      },
    );

    testWidgets(
      'Test 2: Viewing MY OWN story PREVENTS double-tap liking and HIDES bottom like button',
      (tester) async {
        final myStory = StoryItemModel(
          id: 'story_mine_1',
          type: StoryType.text,
          textContent: 'My own text story',
          timeAgo: '5m',
          createdAt: DateTime.now(),
          likesCount: 10,
          isLiked: false,
          allowReactions: true,
        );

        final groups = [
          StoryGroupModel(
            userId: 'current_user_123',
            userName: 'Current User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: true,
            stories: [myStory],
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: StoryViewerScreen(initialGroupIndex: 0, groups: groups),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(StoryInteractiveLikeButton), findsNothing);
        expect(myStory.isLiked, false);
        expect(myStory.likesCount, 10);

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(myStory.isLiked, false);
        expect(myStory.likesCount, 10);
      },
    );

    test(
      'Test 3: StoryController prevents like API calls and state changes for own stories',
      () async {
        final storyController = Get.put(StoryController());

        final ownStory = StoryItemModel(
          id: 'own_story_99',
          type: StoryType.text,
          timeAgo: '1m',
          createdAt: DateTime.now(),
          likesCount: 3,
          isLiked: false,
        );

        final otherStory = StoryItemModel(
          id: 'other_story_88',
          type: StoryType.text,
          timeAgo: '1m',
          createdAt: DateTime.now(),
          likesCount: 7,
          isLiked: false,
        );

        storyController.storyGroups.assignAll([
          StoryGroupModel(
            userId: 'current_user_123',
            userName: 'Current User',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: true,
            stories: [ownStory],
          ),
          StoryGroupModel(
            userId: 'other_user_777',
            userName: 'Friend',
            userAvatar: 'assets/images/user_profile.png',
            isOwner: false,
            stories: [otherStory],
          ),
        ]);

        storyController.toggleLike('own_story_99');
        expect(ownStory.isLiked, false);
        expect(ownStory.likesCount, 3);

        storyController.syncLikeToBackend('own_story_99', isLiked: true);
        expect(ownStory.isLiked, false);
        expect(ownStory.likesCount, 3);

        storyController.toggleLike('other_story_88');
        expect(otherStory.isLiked, true);
        expect(otherStory.likesCount, 8);
      },
    );
  });
}
