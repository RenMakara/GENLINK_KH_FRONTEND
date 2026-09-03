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

      // Should immediately return false because upload is already in progress
      expect(success, false);
    });

    testWidgets('Test 3: Story Creator Screen publishing flow closes composer on success', (tester) async {
      Get.put(StoryController());

      // Simulate navigation stack: Home -> StoryGallery -> StoryCreator
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

      // Push Gallery then Creator
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

      // Tap Post Story
      await tester.tap(find.text('Post Story'));
      await tester.pump();

      // Wait for publish async completion and animations
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Should automatically exit composer and return to Community Home Screen
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

      // Push Gallery -> Camera -> Creator
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

      // Tap Post Story
      await tester.tap(find.text('Post Story'));
      await tester.pump();

      // Settle publish async and popUntil
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Completely returned to Community Feed
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

      // Open StoryViewer
      Get.to(
        () => const Scaffold(body: Text('StoryViewerScreen Mock')),
        routeName: '/StoryViewerScreen',
      );
      await tester.pumpAndSettle();
      expect(find.text('StoryViewerScreen Mock'), findsOneWidget);

      // Open StoryCreator in edit mode
      Get.to(
        () => StoryCreatorScreen(
          type: StoryType.photo,
          existingStory: existingStory,
        ),
        routeName: '/StoryCreatorScreen',
      );
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);

      // Tap Post/Save Story
      await tester.tap(find.text('Post Story'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Should return to StoryViewerScreen
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

      // If full screen text editor is open, tap 'Done' first to close editor
      if (find.text('Done').evaluate().isNotEmpty) {
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Post Story'), findsOneWidget);

      // Tap Post Story with empty text
      await tester.tap(find.text('Post Story'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Composer should remain OPEN
      expect(find.text('Post Story'), findsOneWidget);
      expect(find.text('Empty Story'), findsOneWidget);
    });
  });
}
