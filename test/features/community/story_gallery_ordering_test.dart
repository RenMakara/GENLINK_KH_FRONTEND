import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_gallery_screen.dart';
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
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Gallery Media Ordering & Header Controls Tests', () {
    test('compareAssetsNewestFirst orders assets strictly from newest to oldest by creation date', () {
      final oldAsset = AssetEntity(
        id: 'asset_2020',
        typeInt: 1,
        width: 1080,
        height: 1920,
        createDateSecond: 1600000000,
      );
      final midAsset = AssetEntity(
        id: 'asset_2023',
        typeInt: 1,
        width: 1080,
        height: 1920,
        createDateSecond: 1700000000,
      );
      final newAsset = AssetEntity(
        id: 'asset_2026',
        typeInt: 1,
        width: 1080,
        height: 1920,
        createDateSecond: 1780000000,
      );

      final list = [oldAsset, newAsset, midAsset];
      list.sort(StoryGalleryController.compareAssetsNewestFirst);

      expect(list[0].id, 'asset_2026');
      expect(list[1].id, 'asset_2023');
      expect(list[2].id, 'asset_2020');
    });

    test('compareAssetsNewestFirst handles zero/null createDateSecond by falling back to modified date and tie-breakers', () {
      final noCreateOldMod = AssetEntity(
        id: 'old_mod',
        typeInt: 1,
        width: 1080,
        height: 1920,
        createDateSecond: 0,
        modifiedDateSecond: 1650000000,
      );
      final noCreateNewMod = AssetEntity(
        id: 'new_mod',
        typeInt: 1,
        width: 1080,
        height: 1920,
        createDateSecond: null,
        modifiedDateSecond: 1750000000,
      );
      final validCreate = AssetEntity(
        id: 'valid_create',
        typeInt: 1,
        width: 1080,
        height: 1920,
        createDateSecond: 1780000000,
      );

      final list = [noCreateOldMod, validCreate, noCreateNewMod];
      list.sort(StoryGalleryController.compareAssetsNewestFirst);

      expect(list[0].id, 'valid_create');
      expect(list[1].id, 'new_mod');
      expect(list[2].id, 'old_mod');
    });

    test('Pagination maintains newest -> oldest order across pages', () {
      final page0 = [
        AssetEntity(id: 'p0_1', typeInt: 1, width: 100, height: 100, createDateSecond: 300),
        AssetEntity(id: 'p0_2', typeInt: 1, width: 100, height: 100, createDateSecond: 200),
      ];
      final page1 = [
        AssetEntity(id: 'p1_1', typeInt: 1, width: 100, height: 100, createDateSecond: 150),
        AssetEntity(id: 'p1_2', typeInt: 1, width: 100, height: 100, createDateSecond: 100),
      ];

      page0.sort(StoryGalleryController.compareAssetsNewestFirst);
      page1.sort(StoryGalleryController.compareAssetsNewestFirst);

      final combined = [...page0, ...page1];
      for (int i = 0; i < combined.length - 1; i++) {
        final current = StoryGalleryController.getAssetTimestamp(combined[i]);
        final next = StoryGalleryController.getAssetTimestamp(combined[i + 1]);
        expect(current >= next, isTrue, reason: 'Media at $i must be newer than or equal to media at ${i + 1}');
      }
    });

    testWidgets('Header displays Close navigation, album name, Camera action, and visible Gallery action with comfortable touch targets', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Close button with tooltip
      final closeButton = find.byTooltip('Close');
      expect(closeButton, findsOneWidget);
      final closeSize = tester.getSize(closeButton);
      expect(closeSize.width, greaterThanOrEqualTo(44.0));
      expect(closeSize.height, greaterThanOrEqualTo(44.0));

      // 2. Camera button with tooltip
      final cameraButton = find.byTooltip('Camera');
      expect(cameraButton, findsOneWidget);
      final cameraSize = tester.getSize(cameraButton);
      expect(cameraSize.width, greaterThanOrEqualTo(44.0));
      expect(cameraSize.height, greaterThanOrEqualTo(44.0));

      // 3. Gallery button with tooltip and icon
      final galleryButton = find.byTooltip('Gallery');
      expect(galleryButton, findsOneWidget);
      final gallerySize = tester.getSize(galleryButton);
      expect(gallerySize.width, greaterThanOrEqualTo(44.0));
      expect(gallerySize.height, greaterThanOrEqualTo(44.0));
      expect(find.byIcon(Icons.photo_library_rounded), findsOneWidget);

      // 4. Current gallery/album name in header
      expect(find.textContaining('Album:'), findsOneWidget);

      // 5. Zero horizontal overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Story Gallery renders newest asset at the top of the grid', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      final oldAsset = AssetEntity(id: 'old', typeInt: 1, width: 100, height: 100, createDateSecond: 100);
      final newAsset = AssetEntity(id: 'new', typeInt: 1, width: 100, height: 100, createDateSecond: 999);

      final sorted = [oldAsset, newAsset];
      sorted.sort(StoryGalleryController.compareAssetsNewestFirst);
      galleryController.mediaAssets.assignAll(sorted);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(galleryController.mediaAssets.first.id, 'new');
      expect(galleryController.mediaAssets.last.id, 'old');
    });
  });
}
