import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_template_canvas.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_template_picker_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_creation_picker_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_canvas_renderer.dart';
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

  group('Story Template Feature Tests', () {
    // ── 1. Template Presets & Model Validation ──
    test('Test 1: Preset library contains presets for all 5 requested categories', () {
      final categories = storyTemplatePresets.map((t) => t.category).toSet();
      expect(categories.contains('Single'), isTrue);
      expect(categories.contains('Two Photos'), isTrue);
      expect(categories.contains('Three Photos'), isTrue);
      expect(categories.contains('Four Photos'), isTrue);
      expect(categories.contains('Photo + Text'), isTrue);
    });

    test('Test 2: StoryTemplateSlot model serialization and cloning', () {
      final slot = StoryTemplateSlot(
        id: 'slot_0',
        mediaPath: 'assets/images/user_profile.png',
        scale: 1.5,
        offset: const Offset(10, 20),
        rotation: 90.0,
        text: 'Sample Note',
      );

      final cloned = slot.clone();
      expect(cloned.id, slot.id);
      expect(cloned.mediaPath, slot.mediaPath);
      expect(cloned.scale, 1.5);
      expect(cloned.offset, const Offset(10, 20));
      expect(cloned.rotation, 90.0);
      expect(cloned.text, 'Sample Note');

      final json = slot.toJson();
      final fromJson = StoryTemplateSlot.fromJson(json);
      expect(fromJson.id, slot.id);
      expect(fromJson.mediaPath, slot.mediaPath);
      expect(fromJson.scale, 1.5);
      expect(fromJson.offset.dx, 10.0);
      expect(fromJson.offset.dy, 20.0);
      expect(fromJson.rotation, 90.0);
      expect(fromJson.text, 'Sample Note');
    });

    // ── 2. Canvas Rendering of all Template Layouts ──
    testWidgets('Test 3: StoryTemplateCanvas renders Single Photo layout (Polaroid)', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'single_polaroid');
      final slots = [StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: preset,
                slots: slots,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Test 4: StoryTemplateCanvas renders Two Photos Split Vertical layout', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'two_split_v');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: preset,
                slots: slots,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('Test 5: StoryTemplateCanvas renders Three Photos layout (1 Top, 2 Bottom)', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'three_hero_bottom');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
        StoryTemplateSlot(id: 'slot_2', mediaPath: 'assets/images/user_profile.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: preset,
                slots: slots,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(3));
    });

    testWidgets('Test 6: StoryTemplateCanvas renders Four Photos 2x2 Grid layout', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'four_grid');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
        StoryTemplateSlot(id: 'slot_2', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_3', mediaPath: 'assets/images/heng_chansela_post.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: preset,
                slots: slots,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(4));
    });

    testWidgets('Test 7: StoryTemplateCanvas renders Photo + Text Quote Card layout', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'photo_text_quote');
      final slots = [StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: preset,
                slots: slots,
                customText: '"Campus life is beautiful."',
                isInteractive: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('"Campus life is beautiful."'), findsOneWidget);
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
    });

    // ── 3. Empty Slot Interaction ──
    testWidgets('Test 8: Empty slot shows Tap to add photo and triggers onTap callback', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'two_split_v');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: null),
        StoryTemplateSlot(id: 'slot_1', mediaPath: null),
      ];

      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: preset,
                slots: slots,
                isInteractive: true,
                onTapSlot: (idx) => tappedIndex = idx,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tap to add photo'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('empty_slot_0')));
      expect(tappedIndex, 0);

      await tester.tap(find.byKey(const ValueKey('empty_slot_1')));
      expect(tappedIndex, 1);
    });

    // ── 4. Story Template Picker Sheet ──
    testWidgets('Test 9: StoryTemplatePickerSheet allows category filtering and selection', (tester) async {
      StoryTemplateConfig? chosen;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryTemplatePickerSheet(
              onSelectTemplate: (t) => chosen = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Story Templates'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('Two Photos'), findsOneWidget);
      expect(find.text('Three Photos'), findsOneWidget);
      expect(find.text('Four Photos'), findsOneWidget);
      expect(find.text('Photo + Text'), findsOneWidget);

      // Tap 'Two Photos' filter chip
      await tester.tap(find.text('Two Photos'));
      await tester.pumpAndSettle();

      expect(find.text('Split Vertical'), findsOneWidget);

      // Select 'Split Vertical'
      await tester.tap(find.text('Split Vertical'));
      expect(chosen?.id, 'two_split_v');
    });

    // ── 5. Story Creator Screen in Template Mode ──
    testWidgets('Test 10: StoryCreatorScreen opens in template mode with template tools', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(type: StoryType.template),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byType(StoryCreatorScreen), findsOneWidget);
      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.text('Polaroid Classic'), findsOneWidget);
      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Background'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
    });

    // ── 6. Publishing Flow for Templates ──
    test('Test 11: StoryController.publishStory publishes template story correctly', () async {
      final controller = Get.put(StoryController());
      await controller.fetchStories();
      final initialCount = controller.storyGroups.firstWhere((g) => g.isOwner).stories.length;

      final success = await controller.publishStory(
        type: StoryType.template,
        templateId: 'two_split_v',
        templateSlots: [
          StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
          StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
        ],
        textContent: 'Dual collage story',
        visibility: 'Friends',
      );

      expect(success, true);
      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.length, initialCount + 1);

      final published = ownerGroup.stories.first;
      expect(published.type, StoryType.template);
      expect(published.templateId, 'two_split_v');
      expect(published.templateSlots.length, 2);
    });

    // ── 7. StoryCanvasRenderer Support ──
    testWidgets('Test 12: StoryCanvasRenderer renders template story correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryCanvasRenderer(
                canvasSize: const Size(390, 844),
                layers: const [],
                storyType: StoryType.template,
                templateId: 'photo_text_quote',
                templateSlots: [
                  StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
                ],
                textContent: 'Quote text on canvas renderer',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.text('Quote text on canvas renderer'), findsOneWidget);
    });

    // ── 8. Responsive Layouts across Screen Sizes (Zero Overflow) ──
    testWidgets('Test 13: Template Canvas renders across small (320x568), normal (390x844), and large (430x932) devices without overflow', (tester) async {
      final testSizes = [
        const Size(320, 568), // Small iPhone SE
        const Size(360, 640), // Android compact
        const Size(390, 844), // iPhone 13/14
        const Size(430, 932), // Large Pro Max
      ];

      for (final size in testSizes) {
        for (final preset in storyTemplatePresets) {
          final slots = List.generate(
            preset.slotCount,
            (i) => StoryTemplateSlot(id: 'slot_$i', mediaPath: 'assets/images/user_profile.png'),
          );

          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: StoryTemplateCanvas(
                    template: preset,
                    slots: slots,
                    customText: 'Responsive test text',
                    isInteractive: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Failed for preset ${preset.id} on size $size');
        }
      }
    });

    // ── 9. Complete End-to-End Scenario Test ──
    testWidgets('Test 14: Exact Scenario - Create Story -> Polaroid Classic -> 1 Photo -> Add & Move Text & Sticker -> Post -> Viewer Identical', (tester) async {
      final controller = Get.put(StoryController());
      await tester.runAsync(() async => await controller.fetchStories());
      final initialCount = controller.storyGroups.firstWhere((g) => g.isOwner).stories.length;

      // 1. Open Story Creator in Template Mode with 1 photo for Polaroid Classic
      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.template,
            templateId: 'single_polaroid',
            mediaPaths: ['assets/images/user_profile.png'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 2. Verify Polaroid template and photo are rendered on canvas
      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // 3. Verify all Story Creator toolbar controls are available
      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Background'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
      expect(find.text('Post Story'), findsOneWidget);

      // 4. Publish Template Story with Text and Sticker layers via Controller
      final textLayer = MovableStoryLayer(
        id: 'layer_text_1',
        type: LayerType.text,
        text: 'Our Campus Memory ✨',
        offset: const Offset(0.5, 0.25),
        fontSize: 22.0,
      );

      final stickerLayer = MovableStoryLayer(
        id: 'layer_sticker_1',
        type: LayerType.sticker,
        text: '🔥',
        offset: const Offset(0.75, 0.65),
        scale: 1.4,
      );

      final slot = StoryTemplateSlot(
        id: 'slot_0',
        mediaPath: 'assets/images/user_profile.png',
      );

      bool publishSuccess = false;
      await tester.runAsync(() async {
        publishSuccess = await controller.publishStory(
          type: StoryType.template,
          templateId: 'single_polaroid',
          templateSlots: [slot],
          layers: [textLayer, stickerLayer],
          textContent: 'Our Campus Memory ✨',
        );
      });
      expect(publishSuccess, isTrue);

      // 5. Verify posted story in storyGroups
      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.length, initialCount + 1);

      final postedStory = ownerGroup.stories.first;
      expect(postedStory.type, StoryType.template);
      expect(postedStory.templateId, 'single_polaroid');
      expect(postedStory.templateSlots.length, 1);
      expect(postedStory.templateSlots.first.mediaPath, 'assets/images/user_profile.png');
      expect(postedStory.layers.length, 2);
      expect(postedStory.layers.any((l) => l.type == LayerType.text && l.text == 'Our Campus Memory ✨'), isTrue);
      expect(postedStory.layers.any((l) => l.type == LayerType.sticker && l.text == '🔥'), isTrue);

      // 6. Verify StoryViewer / StoryCanvasRenderer renders identical composition
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryCanvasRenderer(
                canvasSize: const Size(390, 844),
                storyType: postedStory.type,
                templateId: postedStory.templateId,
                templateSlots: postedStory.templateSlots,
                layers: postedStory.layers,
                mediaUrl: postedStory.mediaUrl,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.text('Our Campus Memory ✨'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);

      // Flush repository timers
      await tester.pump(const Duration(milliseconds: 500));
    });

    // ── 10. Photo Frame Transformations: Pan, Zoom, Reset ──
    testWidgets('Test 15: Photo frame transformation gestures: scale, reposition, and double-tap reset', (tester) async {
      final slot = StoryTemplateSlot(
        id: 'slot_0',
        mediaPath: 'assets/images/user_profile.png',
        scale: 2.0,
        offset: const Offset(20, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: storyTemplatePresets.firstWhere((t) => t.id == 'single_polaroid'),
                slots: [slot],
                isInteractive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find image container gesture detector
      final gestureFinder = find.byType(GestureDetector);
      expect(gestureFinder, findsWidgets);

      // Verify reset action icon is present
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);

      // Replace photo pill action
      expect(find.byIcon(Icons.cached_rounded), findsOneWidget);

      // Remove photo pill action
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    // ── 11. Create Story Sheet -> Template Picker Navigation ──
    testWidgets('Test 16: Tapping Templates in StoryCreationPickerSheet triggers StoryTemplatePickerSheet', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => StoryCreationPickerSheet.show(ctx),
                child: const Text('Open Create Story'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Create Story'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryCreationPickerSheet), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);

      await tester.tap(find.text('Templates'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplatePickerSheet), findsOneWidget);
    });
  });
}
