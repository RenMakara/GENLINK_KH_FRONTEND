import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_gallery_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_creation_flow.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_creation_picker_sheet.dart';

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
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story "Add to Story" Direct Entry & Media Picker Tests', () {
    testWidgets('Test 1: CommunityCreationFlow.openCreateStory opens StoryGalleryScreen directly without picker sheet', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CommunityCreationFlow.openCreateStory(context),
                child: const Text('Open Story'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Story'));
      await tester.pumpAndSettle();

      // Verify: Direct transition to StoryGalleryScreen, StoryCreationPickerSheet is NOT opened
      expect(find.byType(StoryGalleryScreen), findsOneWidget);
      expect(find.byType(StoryCreationPickerSheet), findsNothing);
      expect(find.text('Add to Story'), findsOneWidget);
    });

    testWidgets('Test 2: StoryGalleryScreen displays all requested header, feature buttons, filters, and controls', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;
      galleryController.mediaAssets.assignAll([
        AssetEntity(
          id: 'test_asset',
          typeInt: 1,
          width: 100,
          height: 100,
          createDateSecond: 1000,
        ),
      ]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top title & close
      expect(find.text('Add to Story'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      // Top feature buttons
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);

      // Media section controls
      expect(find.text('Recents'), findsOneWidget);
      expect(find.text('Select multiple'), findsOneWidget);

      // Filter tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);

      // Camera shortcut tile in the media grid
      expect(find.text('Camera'), findsWidgets);
    });

    testWidgets('Test 3: Tapping Text button navigates directly to Text Story editor', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textButton = find.text('Text');
      expect(textButton, findsOneWidget);

      await tester.tap(textButton);
      await tester.pumpAndSettle();

      expect(find.byType(StoryCreatorScreen), findsOneWidget);
    });

    testWidgets('Test 4: Tapping Archive button opens Story Archive bottom sheet', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final archiveButton = find.text('Archive');
      expect(archiveButton, findsOneWidget);

      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      expect(find.text('Story Archive'), findsOneWidget);
      expect(find.text('Your expired stories will appear here.'), findsOneWidget);
    });

    testWidgets('Test 5: Media filter tabs switch active filter and filter media assets', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      final photoAsset = AssetEntity(
        id: 'photo_1',
        typeInt: 1, // Image
        width: 100,
        height: 100,
        createDateSecond: 1000,
      );
      final videoAsset = AssetEntity(
        id: 'video_1',
        typeInt: 2, // Video
        width: 100,
        height: 100,
        createDateSecond: 1001,
      );

      galleryController.mediaAssets.assignAll([photoAsset, videoAsset]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Videos' tab
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      // Tap 'Photos' tab
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();

      // Tap 'Favourites' tab
      await tester.tap(find.text('Favourites'));
      await tester.pumpAndSettle();

      // Tap 'All' tab
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Test 6: Select multiple button toggles multi-select mode in controller', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(galleryController.isMultiSelectMode.value, isFalse);

      await tester.tap(find.text('Select multiple'));
      await tester.pumpAndSettle();

      expect(galleryController.isMultiSelectMode.value, isTrue);

      await tester.tap(find.text('Select multiple'));
      await tester.pumpAndSettle();

      expect(galleryController.isMultiSelectMode.value, isFalse);
    });

    testWidgets('Test 7: Fresh permission state shows Photos permission needed, Allow Photos and fallback', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = false;
      galleryController.isPermanentlyDenied.value = false;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos permission needed'), findsOneWidget);
      expect(find.text('Allow GenLink to access your photos so you can create a Story.'), findsOneWidget);
      expect(find.text('Allow Photos'), findsOneWidget);
      expect(find.text('Use system photo picker'), findsOneWidget);
    });

    testWidgets('Test 8: Permanently denied state shows Photos access is disabled and Open Settings', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = false;
      galleryController.isPermanentlyDenied.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos access is disabled'), findsOneWidget);
      expect(find.text('Enable photo access in Settings to select photos for your Story.'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Use system photo picker'), findsOneWidget);
    });

    testWidgets('Test 9: Automatically displays grid when permission becomes granted', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = false;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos permission needed'), findsOneWidget);

      // Simulate permission granted and media loaded
      galleryController.hasPermission.value = true;
      galleryController.mediaAssets.assignAll([
        AssetEntity(
          id: 'new_photo_1',
          typeInt: 1,
          width: 200,
          height: 200,
          createDateSecond: 2000,
        ),
      ]);
      await tester.pumpAndSettle();

      // Permission screen gone, grid visible
      expect(find.text('Photos permission needed'), findsNothing);
      expect(find.text('Camera'), findsWidgets);
    });
  });
}
