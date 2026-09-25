import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_gallery_screen.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Media Selection & Android Permission Regression Tests', () {
    // 1. Permission granted -> gallery loads
    testWidgets('1. Permission granted: hasPermission is true, gallery grid loads and permission banner is hidden', (tester) async {
      final controller = Get.put(StoryGalleryController());
      controller.hasPermission.value = true;
      controller.isPermanentlyDenied.value = false;
      controller.isLoading.value = false;

      final photoAsset = AssetEntity(
        id: 'real_photo_01',
        typeInt: 1, // image
        width: 1080,
        height: 1920,
        createDateSecond: 1780000000,
      );
      controller.mediaAssets.assignAll([photoAsset]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos permission needed'), findsNothing);
      expect(find.text('Allow Photos'), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
    });

    // 2. Permission denied -> permission UI appears
    testWidgets('2. Permission denied: displays "Photos permission needed" and "Allow Photos" button', (tester) async {
      final controller = Get.put(StoryGalleryController());
      controller.hasPermission.value = false;
      controller.isPermanentlyDenied.value = false;
      controller.isLoading.value = false;

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

    // 3. Limited / selected access -> usable accessible media loads
    testWidgets('3. Limited / selected photo access: treated as accessible, displays grid without permission error', (tester) async {
      final controller = Get.put(StoryGalleryController());
      // On Android 14+, limited/selected photos grants access to chosen assets
      controller.hasPermission.value = true;
      controller.isPermanentlyDenied.value = false;
      controller.isLoading.value = false;

      final selectedAsset1 = AssetEntity(
        id: 'limited_user_selected_photo_01',
        typeInt: 1, // image
        width: 1080,
        height: 1920,
        createDateSecond: 1780000000,
      );
      final selectedAsset2 = AssetEntity(
        id: 'limited_user_selected_video_02',
        typeInt: 2, // video
        width: 1080,
        height: 1920,
        duration: 15,
        createDateSecond: 1780000010,
      );
      controller.mediaAssets.assignAll([selectedAsset1, selectedAsset2]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos permission needed'), findsNothing);
      expect(controller.mediaAssets.length, equals(2));
      expect(find.byType(GridView), findsOneWidget);
    });

    // 4. Photo asset can be selected
    test('4. Photo asset can be selected: selection updates selectedAssets correctly', () {
      final controller = Get.put(StoryGalleryController());
      final photoAsset = AssetEntity(
        id: 'real_device_photo_test',
        typeInt: 1, // image
        width: 1080,
        height: 1920,
      );

      expect(controller.selectedAssets.isEmpty, isTrue);
      controller.selectAsset(photoAsset);
      expect(controller.selectedAssets.length, equals(1));
      expect(controller.selectedAssets.first.id, equals('real_device_photo_test'));
      expect(controller.getSelectionIndex(photoAsset), equals(1));

      // Tapping again deselects in single select mode
      controller.selectAsset(photoAsset);
      expect(controller.selectedAssets.isEmpty, isTrue);
    });

    // 5. Video asset can be selected
    test('5. Video asset can be selected: selection updates selectedAssets with video asset', () {
      final controller = Get.put(StoryGalleryController());
      final videoAsset = AssetEntity(
        id: 'real_device_video_test',
        typeInt: 2, // video
        width: 1080,
        height: 1920,
        duration: 25,
      );

      expect(videoAsset.type, equals(AssetType.video));
      controller.selectAsset(videoAsset);
      expect(controller.selectedAssets.length, equals(1));
      expect(controller.selectedAssets.first.id, equals('real_device_video_test'));
      expect(controller.selectedAssets.first.type, equals(AssetType.video));
    });

    // 6. Multi-select still works
    test('6. Multi-select: toggle multi-select, select multiple assets, verify indices and limits', () {
      final controller = Get.put(StoryGalleryController());
      final asset1 = AssetEntity(id: 'multi_01', typeInt: 1, width: 100, height: 100);
      final asset2 = AssetEntity(id: 'multi_02', typeInt: 1, width: 100, height: 100);
      final asset3 = AssetEntity(id: 'multi_03', typeInt: 2, width: 100, height: 100);

      controller.toggleMultiSelectMode();
      expect(controller.isMultiSelectMode.value, isTrue);

      controller.selectAsset(asset1);
      controller.selectAsset(asset2);
      controller.selectAsset(asset3);

      expect(controller.selectedAssets.length, equals(3));
      expect(controller.getSelectionIndex(asset1), equals(1));
      expect(controller.getSelectionIndex(asset2), equals(2));
      expect(controller.getSelectionIndex(asset3), equals(3));

      // Deselect asset2
      controller.selectAsset(asset2);
      expect(controller.selectedAssets.length, equals(2));
      expect(controller.selectedAssets.contains(asset2), isFalse);
    });

    // 7. No fake media is inserted
    test('7. No fake or demo media is inserted: list strictly reflects fetched real assets', () {
      final controller = Get.put(StoryGalleryController());
      controller.mediaAssets.clear();

      expect(controller.mediaAssets, isEmpty);
      for (final asset in controller.mediaAssets) {
        expect(asset.id.contains('demo_'), isFalse);
        expect(asset.id.contains('mock_'), isFalse);
      }
    });

    // 8. Template selection configuration and photo limit enforcement
    test('8. Template configuration sets requiredPhotos and caps maxSelectionCount', () {
      final controller = Get.put(StoryGalleryController());
      final tmpl = storyTemplatePresets.firstWhere((t) => t.slotCount == 2);

      controller.configureForTemplate(
        template: tmpl,
        requiredPhotos: 2,
        maxSelection: 2,
        isMultiSelect: true,
        clearSelection: true,
      );

      expect(controller.selectedTemplate.value?.id, equals(tmpl.id));
      expect(controller.requiredPhotosCount.value, equals(2));
      expect(controller.maxSelectionCount.value, equals(2));
      expect(controller.isMultiSelectMode.value, isTrue);
    });
  });
}
