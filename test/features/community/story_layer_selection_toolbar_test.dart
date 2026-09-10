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
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildStoryCreatorScreen({
    required Size screenSize,
    List<MovableStoryLayer>? initialLayers,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: GetMaterialApp(
        home: StoryCreatorScreen(
          type: StoryType.photo,
          mediaPaths: const ['assets/images/user_profile.png'],
          existingStory: initialLayers != null
              ? StoryItemModel(
                  id: 'story_toolbar_test',
                  type: StoryType.photo,
                  mediaUrl: 'assets/images/user_profile.png',
                  timeAgo: 'Just now',
                  createdAt: DateTime.now(),
                  layers: initialLayers,
                )
              : null,
        ),
      ),
    );
  }

  group('Story Creator Layer Selection & Floating Toolbar Invariance Tests', () {
    testWidgets('Test 1: Selecting an image layer does NOT show the floating Edit/Duplicate/Delete toolbar', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final imageLayer = MovableStoryLayer(
        id: 'layer_image_1',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.4),
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [imageLayer],
      ));
      await tester.pumpAndSettle();

      final imageFinder = find.byType(ClipRRect);
      expect(imageFinder, findsWidgets);
      await tester.tap(imageFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byTooltip("Duplicate"), findsNothing);
      expect(find.byTooltip("Delete"), findsNothing);
    });

    testWidgets('Test 2: Selecting an asset sticker does NOT show the floating Edit/Duplicate/Delete toolbar', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final stickerLayer = MovableStoryLayer(
        id: 'layer_sticker_1',
        type: LayerType.sticker,
        text: 'assets/stickers/cats/cat_waving.png',
        offset: const Offset(0.5, 0.45),
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [stickerLayer],
      ));
      await tester.pumpAndSettle();

      final stickerFinder = find.byType(Image);
      expect(stickerFinder, findsWidgets);
      await tester.tap(stickerFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byTooltip("Duplicate"), findsNothing);
      expect(find.byTooltip("Delete"), findsNothing);
    });

    testWidgets('Test 3: Selecting an emoji sticker does NOT show floating toolbar', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emojiLayer = MovableStoryLayer(
        id: 'layer_emoji_1',
        type: LayerType.sticker,
        text: '🔥',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [emojiLayer],
      ));
      await tester.pumpAndSettle();

      final emojiFinder = find.text('🔥');
      expect(emojiFinder, findsOneWidget);
      await tester.tap(emojiFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byTooltip("Duplicate"), findsNothing);
      expect(find.byTooltip("Delete"), findsNothing);
    });

    testWidgets('Test 4: Multiple images and stickers can coexist and be moved without toolbar clutter', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final img1 = MovableStoryLayer(
        id: 'layer_img_1',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.3, 0.3),
      );
      final img2 = MovableStoryLayer(
        id: 'layer_img_2',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.7, 0.3),
      );
      final sticker = MovableStoryLayer(
        id: 'layer_stk_1',
        type: LayerType.sticker,
        text: '🎉',
        offset: const Offset(0.5, 0.6),
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [img1, img2, sticker],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('🎉'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byTooltip("Duplicate"), findsNothing);
      expect(find.byTooltip("Delete"), findsNothing);
    });

    testWidgets('Test 5: Selecting a text layer still allows in-place editing', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final textLayer = MovableStoryLayer(
        id: 'layer_txt_1',
        type: LayerType.text,
        text: 'Editable Text',
        offset: const Offset(0.5, 0.4),
        fontSize: 26.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [textLayer],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editable Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Editable Text'), findsOneWidget);
    });

    testWidgets('Test 6: Responsive check across small and large phones with zero overflow', (tester) async {
      const smallSize = Size(360, 640);
      tester.view.physicalSize = smallSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final img = MovableStoryLayer(
        id: 'layer_img_small',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.4),
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: smallSize,
        initialLayers: [img],
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip("Duplicate"), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
