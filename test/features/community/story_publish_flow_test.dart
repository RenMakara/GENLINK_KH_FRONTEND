import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
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

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Publishing Flow & Navigation Lifecycle Tests', () {
    test('Test 1: Publish Story success updates story controller and refreshes groups', () async {
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

      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.length, initialCount + 1);
      expect(ownerGroup.stories.first.textContent, 'New test image story');
      expect(ownerGroup.stories.first.type, StoryType.photo);
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

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.type, StoryType.photo);
      expect(createdStory.textContent, 'Fresh photo story from camera');
      expect(createdStory.mediaUrl, 'assets/images/user_profile.png');

      final storyIds = ownerStories.map((s) => s.id).toList();
      expect(storyIds.toSet().length, storyIds.length);
    });

    test('Test 8: Text Story without media publishes with background gradient and text', () async {
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

      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.type, StoryType.text);
      expect(createdStory.textContent, 'Study session at ACLEDA Library!');
      expect(createdStory.bgGradientStart, '0xFF0F172A');
      expect(createdStory.bgGradientEnd, '0xFF3B82F6');
    });

    test('Test 9: Story containing a link publishes with link preserved in caption', () async {
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
      final ownerStories = controller.storyGroups.firstWhere((g) => g.isOwner).stories;
      final createdStory = ownerStories.first;
      expect(createdStory.textContent, contains('https://genlink.kh/event/hackathon-2026'));
    });
  });
}
