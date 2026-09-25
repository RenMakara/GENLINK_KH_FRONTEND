import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';

class MockLocalStorage extends LocalStorage {
  final Map<String, dynamic> _memory = {};

  @override
  Future<void> saveStoryDraft(String draftJson) async {
    _memory['story_draft'] = draftJson;
  }

  @override
  Future<String?> readStoryDraft() async {
    return _memory['story_draft'] as String?;
  }

  @override
  Future<void> deleteStoryDraft() async {
    _memory.remove('story_draft');
  }
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(MockLocalStorage());
    Get.put<StoryRepository>(StoryRepositoryImpl());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story UX Final Fix Tests (A to M)', () {
    test('A & D & E: Successful Story post updates reactive state immediately to "Your Story"', () async {
      final controller = Get.put(StoryController());
      await controller.fetchStories();

      final success = await controller.publishStory(
        type: StoryType.text,
        textContent: 'Hello CampusLink KH!',
        visibility: 'Friends',
      );

      expect(success, isTrue);
      expect(controller.storyGroups.isNotEmpty, isTrue);
      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.isOwner, isTrue);
      expect(ownerGroup.userName, contains('Sokny Enat'));
      expect(ownerGroup.stories.isNotEmpty, isTrue);
      expect(ownerGroup.stories.first.textContent, 'Hello CampusLink KH!');
    });

    test('C: Double-tap Post prevention - concurrent publish requests are rejected', () async {
      final controller = Get.put(StoryController());
      controller.isUploading.value = true;

      final result = await controller.publishStory(
        type: StoryType.text,
        textContent: 'Double tap attempt',
      );

      expect(result, isFalse);
    });

    testWidgets('G & H: Manage Your Story bottom sheet removes Edit Story and Story Insights', (tester) async {
      final controller = Get.put(StoryController());
      final ownerStory = StoryItemModel(
        id: 'owner_story_1',
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(),
      );
      final ownerGroup = StoryGroupModel(
        userId: 'user_me',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        hasUnseen: false,
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
      await tester.pump(const Duration(milliseconds: 100));

      final moreButtonFinder = find.byIcon(Icons.more_vert);
      expect(moreButtonFinder, findsOneWidget);
      await tester.tap(moreButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Manage Your Story'), findsOneWidget);

      expect(find.text('Edit Story'), findsNothing);

      expect(find.text('Story Insights'), findsNothing);

      expect(find.text('Story Privacy'), findsOneWidget);
      expect(find.text('Who can see your story'), findsOneWidget);

      expect(find.text('Save to Device'), findsOneWidget);
      expect(find.text('Save story photo/video to your phone gallery'), findsOneWidget);

      expect(find.text('Delete Story'), findsOneWidget);
      expect(find.text('Permanently remove this story'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('K: Delete Story shows confirmation dialog with required title and content', (tester) async {
      final controller = Get.put(StoryController());
      final ownerStory = StoryItemModel(
        id: 'owner_story_1',
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(),
      );
      final ownerGroup = StoryGroupModel(
        userId: 'user_me',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        hasUnseen: false,
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
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      final deleteTile = find.widgetWithText(ListTile, 'Delete Story');
      expect(deleteTile, findsOneWidget);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Story?'), findsOneWidget);
      expect(find.text('Are you sure you want to permanently delete this story?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.storyGroups.first.stories.length, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    test('L: Successful deletion removes story from reactive state', () async {
      final controller = Get.put(StoryController());
      final ownerStory = StoryItemModel(
        id: 'owner_story_delete_1',
        type: StoryType.text,
        textContent: 'Delete me',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(),
      );
      final ownerGroup = StoryGroupModel(
        userId: 'user_me',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        hasUnseen: false,
        stories: [ownerStory],
      );
      controller.storyGroups.assignAll([ownerGroup]);

      final success = await controller.deleteStory('owner_story_delete_1');
      expect(success, isTrue);
      expect(controller.storyGroups.first.stories.isEmpty, isTrue);
    });

    test('I: Story Privacy retains settings correctly', () async {
      final controller = Get.put(StoryController());
      final ownerStory = StoryItemModel(
        id: 'owner_story_privacy_1',
        type: StoryType.text,
        textContent: 'Privacy story',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        settings: const StorySettings(visibility: StoryPrivacy.friends),
      );
      final ownerGroup = StoryGroupModel(
        userId: 'user_me',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        hasUnseen: false,
        stories: [ownerStory],
      );
      controller.storyGroups.assignAll([ownerGroup]);

      controller.updateStoryPrivacy('owner_story_privacy_1', 'Public');
      expect(controller.storyGroups.first.stories.first.settings.visibility, StoryPrivacy.public);

      controller.updateStoryPrivacy('owner_story_privacy_1', 'Only Me');
      expect(controller.storyGroups.first.stories.first.settings.visibility, StoryPrivacy.onlyMe);
    });
  });
}
