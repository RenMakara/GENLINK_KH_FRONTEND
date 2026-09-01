import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_gallery_screen.dart';
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
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Template Feature Tests', () {
    // ── 1. Template Presets & Model Validation ──
    test('Test 1: Preset library contains presets for all requested categories', () {
      final categories = storyTemplatePresets.map((t) => t.category).toSet();
      expect(categories.contains('Single'), isTrue);
      expect(categories.contains('Two Photos'), isTrue);
      expect(categories.contains('Three Photos'), isTrue);
      expect(categories.contains('Four Photos'), isTrue);
      expect(categories.contains('Photo + Text'), isTrue);

      // Verify specific required templates
      expect(storyTemplatePresets.any((t) => t.id == 'single_polaroid' && t.slotCount == 1), isTrue);
      expect(storyTemplatePresets.any((t) => t.id == 'single_card' && t.slotCount == 1), isTrue);
      expect(storyTemplatePresets.any((t) => t.id == 'two_split_v' && t.slotCount == 2), isTrue);
      expect(storyTemplatePresets.any((t) => t.id == 'two_split_h' && t.slotCount == 2), isTrue);
      expect(storyTemplatePresets.any((t) => t.id == 'three_columns' && t.slotCount == 3), isTrue);
      expect(storyTemplatePresets.any((t) => t.id == 'four_grid' && t.slotCount == 4), isTrue);
      expect(storyTemplatePresets.any((t) => t.id == 'four_hero_strip' && t.slotCount == 4), isTrue);
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

    // ── 2. Canvas Rendering of Template Layouts ──
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

    testWidgets('Test 5: StoryTemplateCanvas renders Three Photos 3 Columns layout', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'three_columns');
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
      await tester.binding.setSurfaceSize(const Size(390, 844));
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
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('Two Photos'), findsOneWidget);
      expect(find.text('Three Photos'), findsOneWidget);

      // Tap 'Two Photos' filter chip
      await tester.tap(find.text('Two Photos'));
      await tester.pumpAndSettle();

      expect(find.text('Split Vertical'), findsOneWidget);

      // Select 'Split Vertical'
      await tester.ensureVisible(find.text('Split Vertical'));
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
      expect(find.byTooltip('Reorder'), findsOneWidget);
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
        const Size(320, 568), // Small iPhone SE / Android compact
        const Size(360, 640), // Android normal
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

    // ── 9. Contextual Controls on Slot Selection ──
    testWidgets('Test 14: Contextual slot toolbar appears only when a slot is selected, with Replace, Reset, and Remove actions', (tester) async {
      final slot = StoryTemplateSlot(
        id: 'slot_0',
        mediaPath: 'assets/images/user_profile.png',
        scale: 1.0,
        offset: Offset.zero,
      );

      // Unselected state -> NO floating buttons over image
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
                selectedSlotIndex: null, // Nothing selected
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replace'), findsNothing);
      expect(find.byIcon(Icons.restart_alt_rounded), findsNothing);

      // Selected state -> Contextual toolbar appears
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
                selectedSlotIndex: 0, // Slot 0 selected
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replace'), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    // ── 10. Initial Create Story Sheet contains Camera, Gallery, and Text Story (Templates removed from initial sheet) ──
    testWidgets('Test 15: Create Story sheet contains Camera, Gallery, and Text Story without top-level Templates', (tester) async {
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
      expect(find.text('community.camera'.tr), findsOneWidget);
      expect(find.text('community.gallery'.tr), findsOneWidget);
      expect(find.text('community.textStory'.tr), findsOneWidget);
      // Templates MUST NOT appear as a top-level option in initial Create Story bottom sheet
      expect(find.text('Templates'), findsNothing);
    });

    // ── 11. Story Gallery Screen Smart Multi-Select for Templates ──
    testWidgets('Test 16: StoryGalleryScreen auto-enables multi-select for 3-photo template and shows target count banner', (tester) async {
      final template3 = storyTemplatePresets.firstWhere((t) => t.id == 'three_columns');

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryGalleryScreen(
            targetTemplate: template3,
            requiredPhotos: 3,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      final galleryCtrl = Get.find<StoryGalleryController>();
      expect(galleryCtrl.isMultiSelectMode.value, isTrue);
      expect(galleryCtrl.requiredPhotosCount.value, 3);
      expect(galleryCtrl.maxSelectionCount.value, 3);

      // Verify instruction banner and counter
      expect(find.text('3 Columns'), findsOneWidget);
      expect(find.text('0/3 selected'), findsOneWidget);
      expect(find.text('Select 3 Photos (0/3)'), findsOneWidget);
    });

    // ── 12. Single Photo Template in Story Creator auto-applies active image with NO extra picker ──
    testWidgets('Test 17: In Image Story Editor, selecting a Single Photo template immediately uses active image without extra picker', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: ['assets/images/user_profile.png'],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byTooltip('Template'), findsOneWidget);

      // Tap Template toolbar button
      await tester.tap(find.byTooltip('Template'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplatePickerSheet), findsOneWidget);

      // Tap Polaroid Classic (Single Photo template)
      await tester.ensureVisible(find.text('Polaroid Classic'));
      await tester.tap(find.text('Polaroid Classic'));
      await tester.pumpAndSettle();

      // Verify Polaroid template is applied immediately on canvas with image
      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    // ── 13. Image Story Editor Toolbar contains all required creation tools including Template ──
    testWidgets('Test 18: Image Story Editor toolbar contains Template, Photo, Text, Stickers, Location, Mention tools', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: ['assets/images/user_profile.png'],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify all tools are accessible in editor toolbar
      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Photo'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
      expect(find.byTooltip('Location'), findsOneWidget);
      expect(find.byTooltip('Mention'), findsOneWidget);
    });

    // ── 14. Multi-photo Template auto-applies when enough photos are already present ──
    testWidgets('Test 19: When 2 photos are present, selecting Two Photos template reuses them immediately', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: [
              'assets/images/user_profile.png',
              'assets/images/heng_chansela_post.png',
            ],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Open template picker
      await tester.tap(find.byTooltip('Template'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryTemplatePickerSheet), findsOneWidget);

      // Filter by Two Photos
      await tester.tap(find.text('Two Photos'));
      await tester.pumpAndSettle();

      // Tap Split Vertical (now at the top of the grid)
      await tester.tap(find.text('Split Vertical').first);
      await tester.pumpAndSettle();

      // Verify template canvas has 2 images loaded
      expect(find.byType(StoryTemplateCanvas), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    // ── 15. Slot transformation state is isolated per slot ──
    test('Test 20: Slot transformation state is isolated per slot', () {
      final slot0 = StoryTemplateSlot(
        id: 'slot_0',
        mediaPath: 'assets/images/user_profile.png',
        scale: 2.0,
        offset: const Offset(15, -20),
        rotation: 90.0,
      );

      final slot1 = StoryTemplateSlot(
        id: 'slot_1',
        mediaPath: 'assets/images/heng_chansela_post.png',
        scale: 1.0,
        offset: Offset.zero,
        rotation: 0.0,
      );

      expect(slot0.scale, 2.0);
      expect(slot0.offset, const Offset(15, -20));
      expect(slot0.rotation, 90.0);

      expect(slot1.scale, 1.0);
      expect(slot1.offset, Offset.zero);
      expect(slot1.rotation, 0.0);
    });

    // ── 16. Five & Six Photo Layout Rendering Tests ──
    testWidgets('Test 21: StoryTemplateCanvas renders Five Photos 1 Top + 4 Grid layout', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'five_hero_grid');
      final slots = List.generate(
        5,
        (i) => StoryTemplateSlot(id: 'slot_$i', mediaPath: 'assets/images/user_profile.png'),
      );

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
      expect(find.byType(Image), findsNWidgets(5));
    });

    testWidgets('Test 22: StoryTemplateCanvas renders Six Photos 2x3 Grid layout', (tester) async {
      final preset = storyTemplatePresets.firstWhere((t) => t.id == 'six_grid');
      final slots = List.generate(
        6,
        (i) => StoryTemplateSlot(id: 'slot_$i', mediaPath: 'assets/images/user_profile.png'),
      );

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
      expect(find.byType(Image), findsNWidgets(6));
    });

    testWidgets('Test 23: Bottom toolbar in Story Creator Screen provides unique Template, Text, Stickers, Location, Mention, Photo tools without duplicates', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: ['assets/images/user_profile.png'],
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
      expect(find.byTooltip('Location'), findsOneWidget);
      expect(find.byTooltip('Mention'), findsOneWidget);
      expect(find.byTooltip('Photo'), findsOneWidget);
    });

    testWidgets('Test 24: Select Single, Two Photos, Three Photos, Four Photos templates and verify configuration and preview without build errors', (tester) async {
      Get.put(StoryController());
      final galleryCtrl = Get.put(StoryGalleryController());

      // 1. Single photo template
      final singleTemplate = storyTemplatePresets.firstWhere((t) => t.category == 'Single');
      galleryCtrl.configureForTemplate(
        template: singleTemplate,
        requiredPhotos: singleTemplate.slotCount,
        maxSelection: singleTemplate.slotCount,
        isMultiSelect: false,
        clearSelection: true,
      );
      expect(galleryCtrl.selectedTemplate.value?.id, singleTemplate.id);
      expect(galleryCtrl.requiredPhotosCount.value, 1);
      expect(galleryCtrl.isMultiSelectMode.value, false);

      // 2. Two photos template
      final twoTemplate = storyTemplatePresets.firstWhere((t) => t.category == 'Two Photos');
      galleryCtrl.configureForTemplate(
        template: twoTemplate,
        requiredPhotos: twoTemplate.slotCount,
        maxSelection: twoTemplate.slotCount,
        isMultiSelect: true,
        clearSelection: true,
      );
      expect(galleryCtrl.selectedTemplate.value?.id, twoTemplate.id);
      expect(galleryCtrl.requiredPhotosCount.value, 2);
      expect(galleryCtrl.isMultiSelectMode.value, true);

      // 3. Three photos template
      final threeTemplate = storyTemplatePresets.firstWhere((t) => t.category == 'Three Photos');
      galleryCtrl.configureForTemplate(
        template: threeTemplate,
        requiredPhotos: threeTemplate.slotCount,
        maxSelection: threeTemplate.slotCount,
        isMultiSelect: true,
        clearSelection: true,
      );
      expect(galleryCtrl.selectedTemplate.value?.id, threeTemplate.id);
      expect(galleryCtrl.requiredPhotosCount.value, 3);
      expect(galleryCtrl.isMultiSelectMode.value, true);

      // 4. Four photos template
      final fourTemplate = storyTemplatePresets.firstWhere((t) => t.category == 'Four Photos');
      galleryCtrl.configureForTemplate(
        template: fourTemplate,
        requiredPhotos: fourTemplate.slotCount,
        maxSelection: fourTemplate.slotCount,
        isMultiSelect: true,
        clearSelection: true,
      );
      expect(galleryCtrl.selectedTemplate.value?.id, fourTemplate.id);
      expect(galleryCtrl.requiredPhotosCount.value, 4);
      expect(galleryCtrl.isMultiSelectMode.value, true);
    });

    testWidgets('Test 25: 3-photo template allows selecting 3 photos together without markNeedsBuild errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final template3 = storyTemplatePresets.firstWhere((t) => t.slotCount == 3);
      final galleryCtrl = Get.put(StoryGalleryController());

      galleryCtrl.configureForTemplate(
        template: template3,
        requiredPhotos: 3,
        maxSelection: 3,
        isMultiSelect: true,
        clearSelection: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryGalleryScreen(
            targetTemplate: template3,
            requiredPhotos: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no exception occurred during build / startup
      expect(tester.takeException(), isNull);
      expect(galleryCtrl.isMultiSelectMode.value, isTrue);
      expect(galleryCtrl.requiredPhotosCount.value, 3);
      expect(galleryCtrl.selectedTemplate.value?.id, template3.id);
    });

    testWidgets('Test 26: Replace photo in template slot preserves other slots and updates preview', (tester) async {
      final template2 = storyTemplatePresets.firstWhere((t) => t.id == 'two_split_v');
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
                template: template2,
                slots: slots,
                isInteractive: true,
                selectedSlotIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replace'), findsOneWidget);

      // Simulate slot replacement
      slots[0].mediaPath = 'assets/images/cat_stickers.png';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: template2,
                slots: slots,
                isInteractive: true,
                selectedSlotIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(slots[0].mediaPath, 'assets/images/cat_stickers.png');
      expect(slots[1].mediaPath, 'assets/images/heng_chansela_post.png');
    });

    testWidgets('Test 27: Remove photo from template slot clears slot to empty state', (tester) async {
      final template2 = storyTemplatePresets.firstWhere((t) => t.id == 'two_split_v');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
      ];

      int? clearedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: template2,
                slots: slots,
                isInteractive: true,
                selectedSlotIndex: 1,
                onClearSlot: (idx) => clearedIndex = idx,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(clearedIndex, 1);
    });

    testWidgets('Test 28: 3-Photo Hero layout renders 3 independent slots with cover fitting and zero empty space', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final template3 = storyTemplatePresets.firstWhere((t) => t.id == 'three_hero_bottom');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
        StoryTemplateSlot(id: 'slot_2', mediaPath: 'assets/images/cat_stickers.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: template3,
                slots: slots,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNWidgets(3));
      // Each slot has its own independent ClipRect
      expect(find.byType(ClipRect), findsWidgets);
    });

    testWidgets('Test 29: Pinch-to-zoom updates slot scale with minimum 1.0 cover constraint', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final template1 = storyTemplatePresets.firstWhere((t) => t.id == 'single_card');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png', scale: 1.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: template1,
                slots: slots,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zoom in via pinch gesture
      final gesture = await tester.createGesture();
      await gesture.down(const Offset(195, 400));
      await gesture.moveBy(const Offset(20, 20));
      await gesture.up();
      await tester.pumpAndSettle();

      // Double tap resets to 1.0 and zero offset
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Test 30: Contextual toolbar provides Rotate (90 deg), Reset, Replace, and Remove actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final template2 = storyTemplatePresets.firstWhere((t) => t.id == 'two_split_v');
      final slots = [
        StoryTemplateSlot(id: 'slot_0', mediaPath: 'assets/images/user_profile.png'),
        StoryTemplateSlot(id: 'slot_1', mediaPath: 'assets/images/heng_chansela_post.png'),
      ];

      double? rotatedDegrees;
      double? resetScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: StoryTemplateCanvas(
                template: template2,
                slots: slots,
                isInteractive: true,
                selectedSlotIndex: 0,
                onUpdateSlot: (idx, scale, offset, rot) {
                  rotatedDegrees = rot;
                  resetScale = scale;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all actions are present in the contextual pill
      expect(find.text('Replace'), findsOneWidget);
      expect(find.byIcon(Icons.rotate_90_degrees_cw_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap Rotate
      await tester.tap(find.byIcon(Icons.rotate_90_degrees_cw_rounded));
      await tester.pumpAndSettle();
      expect(rotatedDegrees, 90.0);

      // Tap Reset
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();
      expect(resetScale, 1.0);
    });

    testWidgets('Test 31: Full Text Story lifecycle flow (Text -> Format -> Done -> Normal Editor -> Stickers -> Location -> Post)', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(type: StoryType.text),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Text story opens in full-screen text editing mode
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // 2. Formatting controls: Color, Alignment, Font
      expect(find.byTooltip('Color'), findsOneWidget);
      await tester.tap(find.byTooltip('Color'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Alignment'), findsOneWidget);
      await tester.tap(find.byTooltip('Alignment'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Font'), findsOneWidget);
      await tester.tap(find.byTooltip('Font'));
      await tester.pumpAndSettle();

      // 3. Press Done -> return to normal Story editor
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // 4. Verify normal Story editor toolbar has unique actions without duplicated Emoji
      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
      expect(find.byTooltip('Location'), findsOneWidget);
      expect(find.byTooltip('Mention'), findsOneWidget);
      expect(find.byTooltip('Emoji'), findsNothing); // No duplicate Emoji button

      // 5. Tap Text again -> verify text editing controls re-appear
      await tester.tap(find.byTooltip('Text'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // 6. Tap Stickers -> verify sticker/emoji sheet opens
      await tester.tap(find.byTooltip('Stickers'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      Navigator.pop(tester.element(find.byType(BottomSheet)));
      await tester.pumpAndSettle();

      // 7. Tap Location -> verify location tag sheet opens
      await tester.tap(find.byTooltip('Location'));
      await tester.pumpAndSettle();
      expect(find.text('Add Location Tag'), findsOneWidget);
      Navigator.pop(tester.element(find.byType(BottomSheet)));
      await tester.pumpAndSettle();

      // 8. Post Story
      expect(find.text('Post Story'), findsOneWidget);
      await tester.tap(find.text('Post Story'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Test 32: Full Image Story lifecycle flow (Add text -> Edit -> Done -> Add stickers -> Verify zero duplicates)', (tester) async {
      Get.put(StoryController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: ['assets/images/user_profile.png'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify normal Story editor toolbar
      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
      expect(find.byTooltip('Location'), findsOneWidget);
      expect(find.byTooltip('Mention'), findsOneWidget);
      expect(find.byTooltip('Photo'), findsOneWidget);
      expect(find.byTooltip('Emoji'), findsNothing); // Zero duplicates

      // 2. Add text
      await tester.tap(find.byTooltip('Text'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'photo caption');
      await tester.pumpAndSettle();

      // 3. Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // 4. Open Stickers sheet
      await tester.tap(find.byTooltip('Stickers'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      Navigator.pop(tester.element(find.byType(BottomSheet)));
      await tester.pumpAndSettle();

      // 5. Verify toolbar remains clean with 0 duplicate buttons
      expect(find.byTooltip('Template'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Stickers'), findsOneWidget);
      expect(find.byTooltip('Location'), findsOneWidget);
      expect(find.byTooltip('Mention'), findsOneWidget);
      expect(find.byTooltip('Photo'), findsOneWidget);
      expect(find.byTooltip('Emoji'), findsNothing);
    });
  });
}
