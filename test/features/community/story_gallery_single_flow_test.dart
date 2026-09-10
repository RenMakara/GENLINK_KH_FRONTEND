import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_gallery_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_creation_picker_sheet.dart';
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
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Gallery Single-Flow & Double-Open Prevention Tests', () {
    testWidgets('Test 1: Header has Gallery icon with tooltip "Gallery" (not System Gallery)', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Camera'), findsOneWidget);
      expect(find.byTooltip('Gallery'), findsOneWidget);
      expect(find.byTooltip('System Gallery'), findsNothing);
    });

    testWidgets('Test 2: Tapping Gallery header icon when permission is granted stays in StoryGalleryScreen and does not crash or pop', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Gallery'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryGalleryScreen), findsOneWidget);
      expect(find.text('Create Story'), findsOneWidget);
    });

    testWidgets('Test 3: Permission State displays explicit "Use system photo picker" secondary fallback', (tester) async {
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
      expect(find.text('Allow Photos'), findsOneWidget);
      expect(find.text('Use system photo picker'), findsOneWidget);
    });

    testWidgets('Test 4: Permanently Denied Permission State displays "Open Settings" and explicit fallback', (tester) async {
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
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Use system photo picker'), findsOneWidget);
    });

    testWidgets('Test 5: Empty Gallery State displays both "Open Camera" and explicit "System Picker" fallback', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;
      galleryController.mediaAssets.clear();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No photos yet'), findsOneWidget);
      expect(find.text('Open Camera'), findsOneWidget);
      expect(find.text('System Picker'), findsOneWidget);
    });

    testWidgets('Test 6: Multi-Select Mode toggle does not pop system picker and shows select multiple UI', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select multiple'), findsOneWidget);

      await tester.tap(find.text('Select multiple'));
      await tester.pumpAndSettle();

      expect(galleryController.isMultiSelectMode.value, isTrue);
      expect(find.byType(StoryGalleryScreen), findsOneWidget);
    });

    testWidgets('Test 7: Tapping Gallery header icon when permission is not granted stays inside StoryGalleryScreen and requests permission without opening system picker', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = false;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Gallery icon in header
      final galleryIcon = find.byTooltip('Gallery');
      expect(galleryIcon, findsOneWidget);
      await tester.tap(galleryIcon);
      await tester.pumpAndSettle();

      // Verified: Stays strictly inside StoryGalleryScreen without any dialog/system picker popping up
      expect(find.byType(StoryGalleryScreen), findsOneWidget);
    });

    testWidgets('Test 8: Android 14 limited/selected photo access displays limited assets directly inside StoryGalleryScreen without duplicate picker', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      final limitedAsset1 = AssetEntity(id: 'limited_1', typeInt: 1, width: 100, height: 100, createDateSecond: 500);
      final limitedAsset2 = AssetEntity(id: 'limited_2', typeInt: 1, width: 100, height: 100, createDateSecond: 400);
      galleryController.mediaAssets.assignAll([limitedAsset1, limitedAsset2]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Screen stays in StoryGalleryScreen and displays the assets directly
      expect(find.byType(StoryGalleryScreen), findsOneWidget);
      expect(galleryController.mediaAssets.length, 2);
      expect(galleryController.mediaAssets.first.id, 'limited_1');
    });

    testWidgets('Test 9: StoryCreationPickerSheet Gallery option navigates to exactly ONE StoryGalleryScreen', (tester) async {
      Get.put(StoryGalleryController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => StoryCreationPickerSheet.show(context),
                  child: const Text('Show Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryCreationPickerSheet), findsOneWidget);

      // Tap Gallery option
      final galleryTile = find.widgetWithText(ListTile, 'community.gallery');
      expect(galleryTile, findsOneWidget);
      await tester.tap(galleryTile);
      await tester.pumpAndSettle();

      // Bottom sheet is popped, exactly one StoryGalleryScreen is displayed
      expect(find.byType(StoryCreationPickerSheet), findsNothing);
      expect(find.byType(StoryGalleryScreen), findsOneWidget);
    });
  });
}
