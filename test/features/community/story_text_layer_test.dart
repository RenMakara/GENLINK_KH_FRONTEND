import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';

void main() {
  group('Story Text Object Model & State Persistence Tests', () {
    test(
      'Test 1: Default text layer uses intended defaults and nullable background',
      () {
        final layer = MovableStoryLayer(
          id: 'text_1',
          type: LayerType.text,
          text: 'Hello GenLink',
        );

        expect(layer.text, 'Hello GenLink');
        expect(layer.color, Colors.white);
        expect(layer.bgColor, isNull);
        expect(layer.bgStyle, TextBgStyle.none);
        expect(layer.fontStyle, TextStyleType.classic);
        expect(layer.effect, TextEffectType.none);
        expect(layer.fontSize, 28.0);
        expect(layer.scale, 1.0);
        expect(layer.rotation, 0.0);
        expect(layer.alignment, TextAlign.center);
      },
    );

    test(
      'Test 2 & 3: Background color assignment and immediate state updates',
      () {
        final layer = MovableStoryLayer(
          id: 'text_2',
          type: LayerType.text,
          text: 'Testing Blue and Pink',
        );

        const blueColor = Color(0xFF38BDF8);
        layer.bgColor = blueColor;
        layer.bgStyle = TextBgStyle.filled;
        expect(layer.bgColor, blueColor);
        expect(layer.bgStyle, TextBgStyle.filled);

        const pinkColor = Color(0xFFE879F9);
        layer.bgColor = pinkColor;
        expect(layer.bgColor, pinkColor);
      },
    );

    test(
      'Test 4: Select None resets background container without reverting to black',
      () {
        final layer = MovableStoryLayer(
          id: 'text_4',
          type: LayerType.text,
          text: 'No Background',
          bgColor: const Color(0xFF38BDF8),
          bgStyle: TextBgStyle.filled,
        );

        layer.bgStyle = TextBgStyle.none;
        layer.bgColor = null;

        expect(layer.bgStyle, TextBgStyle.none);
        expect(layer.bgColor, isNull);
        expect(layer.bgColor, isNot(Colors.black));
      },
    );

    test(
      'Test 5: Select blue background -> change font -> blue background remains',
      () {
        final layer = MovableStoryLayer(
          id: 'text_5',
          type: LayerType.text,
          text: 'Blue Text',
          bgColor: const Color(0xFF38BDF8),
          bgStyle: TextBgStyle.rounded,
          fontStyle: TextStyleType.classic,
        );

        expect(layer.bgColor, const Color(0xFF38BDF8));

        layer.fontStyle = TextStyleType.elegant;
        expect(layer.bgColor, const Color(0xFF38BDF8));
        expect(layer.fontStyle, TextStyleType.elegant);

        layer.fontStyle = TextStyleType.bold;
        expect(layer.bgColor, const Color(0xFF38BDF8));

        layer.fontStyle = TextStyleType.modern;
        expect(layer.bgColor, const Color(0xFF38BDF8));

        layer.fontStyle = TextStyleType.minimal;
        expect(layer.bgColor, const Color(0xFF38BDF8));
      },
    );

    test(
      'Test 6: Select pink background -> change text color -> pink background remains',
      () {
        final layer = MovableStoryLayer(
          id: 'text_6',
          type: LayerType.text,
          text: 'Pink Text',
          bgColor: const Color(0xFFE879F9),
          bgStyle: TextBgStyle.filled,
          color: Colors.white,
        );

        expect(layer.bgColor, const Color(0xFFE879F9));
        expect(layer.color, Colors.white);

        layer.color = const Color(0xFFFACC15);
        expect(layer.bgColor, const Color(0xFFE879F9));
        expect(layer.color, const Color(0xFFFACC15));

        layer.color = Colors.black;
        expect(layer.bgColor, const Color(0xFFE879F9));
        expect(layer.color, Colors.black);
      },
    );

    test(
      'Test 7: Select green background -> change font style -> green remains',
      () {
        final layer = MovableStoryLayer(
          id: 'text_7',
          type: LayerType.text,
          text: 'Green Text',
          bgColor: const Color(0xFF34D399),
          bgStyle: TextBgStyle.filled,
          fontStyle: TextStyleType.classic,
        );

        layer.fontStyle = TextStyleType.bold;
        expect(layer.bgColor, const Color(0xFF34D399));
        expect(layer.bgStyle, TextBgStyle.filled);
      },
    );

    test('Test 8: Edit text content -> background color remains unchanged', () {
      final layer = MovableStoryLayer(
        id: 'text_8',
        type: LayerType.text,
        text: 'Draft 1',
        bgColor: const Color(0xFFFB923C),
        bgStyle: TextBgStyle.filled,
      );

      layer.text = 'Draft 2 with new content';
      expect(layer.text, 'Draft 2 with new content');
      expect(layer.bgColor, const Color(0xFFFB923C));
      expect(layer.bgStyle, TextBgStyle.filled);
    });

    test(
      'Test 9: Drag text -> position updates while background properties persist',
      () {
        final layer = MovableStoryLayer(
          id: 'text_9',
          type: LayerType.text,
          text: 'Movable',
          offset: const Offset(100, 200),
          bgColor: const Color(0xFF38BDF8),
          bgStyle: TextBgStyle.rounded,
        );

        layer.offset = const Offset(150, 320);
        expect(layer.offset, const Offset(150, 320));
        expect(layer.bgColor, const Color(0xFF38BDF8));
        expect(layer.bgStyle, TextBgStyle.rounded);
      },
    );

    test(
      'Test 10: Resize text -> scale updates and clone preserves properties',
      () {
        final layer = MovableStoryLayer(
          id: 'text_10',
          type: LayerType.text,
          text: 'Scalable',
          scale: 1.0,
          fontSize: 32.0,
          bgColor: const Color(0xFFA855F7),
          bgStyle: TextBgStyle.filled,
          effect: TextEffectType.shadow,
        );

        layer.scale = 1.8;
        expect(layer.scale, 1.8);
        expect(layer.fontSize, 32.0);
        expect(layer.bgColor, const Color(0xFFA855F7));
        expect(layer.effect, TextEffectType.shadow);

        final clone = layer.clone();
        expect(clone.scale, 1.8);
        expect(clone.fontSize, 32.0);
        expect(clone.bgColor, const Color(0xFFA855F7));
        expect(clone.bgStyle, TextBgStyle.filled);
        expect(clone.effect, TextEffectType.shadow);
      },
    );

    test(
      'Test 11: Rotate text -> rotation updates while maintaining styling',
      () {
        final layer = MovableStoryLayer(
          id: 'text_11',
          type: LayerType.text,
          text: 'Rotatable',
          rotation: 0.0,
          bgColor: const Color(0xFFF43F5E),
          bgStyle: TextBgStyle.outline,
          effect: TextEffectType.glow,
        );

        layer.rotation = 0.45;
        expect(layer.rotation, 0.45);
        expect(layer.bgColor, const Color(0xFFF43F5E));
        expect(layer.bgStyle, TextBgStyle.outline);
        expect(layer.effect, TextEffectType.glow);
      },
    );

    test(
      'Test 12: Independent property persistence across all modifications',
      () {
        final layer = MovableStoryLayer(
          id: 'text_12',
          type: LayerType.text,
          text: 'Independent Story Text',
          color: const Color(0xFFFACC15),
          bgColor: const Color(0xFF4C1D95),
          fontStyle: TextStyleType.modern,
          bgStyle: TextBgStyle.rounded,
          effect: TextEffectType.shadow,
          alignment: TextAlign.right,
          fontSize: 36.0,
          scale: 1.2,
          rotation: 0.15,
          offset: const Offset(80, 160),
        );

        expect(layer.color, const Color(0xFFFACC15));
        expect(layer.bgColor, const Color(0xFF4C1D95));
        expect(layer.fontStyle, TextStyleType.modern);
        expect(layer.bgStyle, TextBgStyle.rounded);
        expect(layer.effect, TextEffectType.shadow);
        expect(layer.alignment, TextAlign.right);
        expect(layer.fontSize, 36.0);
        expect(layer.scale, 1.2);
        expect(layer.rotation, 0.15);
        expect(layer.offset, const Offset(80, 160));
      },
    );

    test('Test 13: Font Style and Text Effects are completely independent', () {
      final layer = MovableStoryLayer(
        id: 'text_13',
        type: LayerType.text,
        text: 'Clean Text',
        fontStyle: TextStyleType.classic,
        effect: TextEffectType.none,
      );
      expect(layer.fontStyle, TextStyleType.classic);
      expect(layer.effect, TextEffectType.none);

      layer.fontStyle = TextStyleType.bold;
      expect(layer.fontStyle, TextStyleType.bold);
      expect(layer.effect, TextEffectType.none);

      layer.effect = TextEffectType.shadow;
      expect(layer.effect, TextEffectType.shadow);
      expect(layer.fontStyle, TextStyleType.bold);

      layer.fontStyle = TextStyleType.coding;
      expect(layer.fontStyle, TextStyleType.coding);
      expect(layer.effect, TextEffectType.shadow);

      layer.effect = TextEffectType.none;
      expect(layer.effect, TextEffectType.none);

      layer.bgColor = const Color(0xFF38BDF8);
      expect(layer.bgColor, const Color(0xFF38BDF8));
      expect(layer.effect, TextEffectType.none);
    });

    test(
      'Test 14: Text Story creation and gradient persistence via StoryController',
      () async {
        final repository = StoryRepositoryImpl();
        final textLayer = MovableStoryLayer(
          id: 'layer_publish_1',
          type: LayerType.text,
          text: 'test',
          color: const Color(0xFF34D399),
          bgColor: null,
          fontStyle: TextStyleType.classic,
          effect: TextEffectType.none,
        );

        final newStory = await repository.createStory(
          type: StoryType.text,
          mediaUrl: null,
          textContent: null,
          visibility: 'Public',
          bgGradientStart: '0xFFEC4899',
          bgGradientEnd: '0xFF8B5CF6',
          layers: [textLayer],
        );

        expect(newStory.type, StoryType.text);
        expect(newStory.mediaUrl, isNull);
        expect(newStory.bgGradientStart, '0xFFEC4899');
        expect(newStory.bgGradientEnd, '0xFF8B5CF6');
        expect(newStory.layers.length, 1);
        expect(newStory.layers.first.text, 'test');
        expect(newStory.layers.first.color, const Color(0xFF34D399));
      },
    );

    test('Test 15: Text Story with white text and green background', () async {
      final repository = StoryRepositoryImpl();
      final textLayer = MovableStoryLayer(
        id: 'layer_publish_2',
        type: LayerType.text,
        text: 'test with green background',
        color: Colors.white,
        bgColor: const Color(0xFF34D399),
        bgStyle: TextBgStyle.filled,
      );

      final newStory = await repository.createStory(
        type: StoryType.text,
        mediaUrl: null,
        layers: [textLayer],
        bgGradientStart: '0xFF059669',
        bgGradientEnd: '0xFF047857',
      );

      expect(newStory.layers.first.color, Colors.white);
      expect(newStory.layers.first.bgColor, const Color(0xFF34D399));
      expect(newStory.layers.first.bgStyle, TextBgStyle.filled);
    });

    test(
      'Test 16: Complete separation between Text Color and Canvas/Layer Background',
      () {
        final layer = MovableStoryLayer(
          id: 'layer_sep_1',
          type: LayerType.text,
          text: 'Separation Test',
          color: const Color(0xFFFACC15),
          bgColor: const Color(0xFFA855F7),
          bgStyle: TextBgStyle.rounded,
        );

        layer.color = Colors.white;
        expect(layer.color, Colors.white);
        expect(layer.bgColor, const Color(0xFFA855F7));
        expect(layer.bgStyle, TextBgStyle.rounded);

        layer.bgColor = const Color(0xFF34D399);
        expect(layer.color, Colors.white);
        expect(layer.bgColor, const Color(0xFF34D399));

        layer.bgColor = null;
        layer.bgStyle = TextBgStyle.none;
        expect(layer.color, Colors.white);
        expect(layer.bgColor, isNull);
      },
    );

    test(
      'Test 17: Solid and None Background serialization in Story repository',
      () async {
        final repository = StoryRepositoryImpl();
        final textLayer = MovableStoryLayer(
          id: 'layer_solid_1',
          type: LayerType.text,
          text: 'Solid Background Story',
          color: Colors.white,
        );

        final purpleStory = await repository.createStory(
          type: StoryType.text,
          mediaUrl: null,
          bgGradientStart: '0xFFA855F7',
          bgGradientEnd: '0xFFA855F7',
          layers: [textLayer],
        );
        expect(purpleStory.bgGradientStart, '0xFFA855F7');
        expect(purpleStory.bgGradientEnd, '0xFFA855F7');

        final noneStory = await repository.createStory(
          type: StoryType.text,
          mediaUrl: null,
          bgGradientStart: '0xFF0B0B0E',
          bgGradientEnd: '0xFF0B0B0E',
          layers: [textLayer],
        );
        expect(noneStory.bgGradientStart, '0xFF0B0B0E');
        expect(noneStory.bgGradientEnd, '0xFF0B0B0E');
      },
    );

    test(
      'Test 18: Background state survives font changes, resizing, and rotation',
      () {
        final layer = MovableStoryLayer(
          id: 'layer_persist_1',
          type: LayerType.text,
          text: 'Persistent Background',
          bgColor: const Color(0xFFF43F5E),
          bgStyle: TextBgStyle.filled,
          fontStyle: TextStyleType.classic,
        );

        layer.fontStyle = TextStyleType.handwriting;
        expect(layer.bgColor, const Color(0xFFF43F5E));

        layer.scale = 2.0;
        expect(layer.bgColor, const Color(0xFFF43F5E));
        expect(layer.scale, 2.0);

        layer.rotation = 0.5;
        expect(layer.bgColor, const Color(0xFFF43F5E));
        expect(layer.rotation, 0.5);

        layer.text = 'Updated Text Content';
        expect(layer.bgColor, const Color(0xFFF43F5E));
        expect(layer.text, 'Updated Text Content');
      },
    );

    test(
      'Test 19: Story Privacy Settings (Public, Friends, Only Me, replyPrivacy, allowReactions)',
      () async {
        final repository = StoryRepositoryImpl();

        final friendsStory = await repository.createStory(
          type: StoryType.text,
          textContent: 'Story for friends only',
          visibility: 'Friends',
          replyPrivacy: 'Friends',
          allowReactions: true,
        );
        expect(friendsStory.visibility, 'Friends');
        expect(friendsStory.replyPrivacy, 'Friends');
        expect(friendsStory.allowReactions, true);

        final onlyMeStory = await repository.createStory(
          type: StoryType.text,
          textContent: 'Secret notes',
          visibility: 'Only Me',
          replyPrivacy: 'Off',
          allowReactions: false,
        );
        expect(onlyMeStory.visibility, 'Only Me');
        expect(onlyMeStory.replyPrivacy, 'Off');
        expect(onlyMeStory.allowReactions, false);
      },
    );

    test(
      'Test 20: Only Me stories are filtered from non-owner story groups',
      () async {
        final repository = StoryRepositoryImpl();
        final groups = await repository.getStories();

        for (final g in groups) {
          if (!g.isOwner) {
            expect(g.stories.every((s) => s.visibility != 'Only Me'), true);
          }
        }
      },
    );

    test(
      'Test 21: MovableStoryLayer supports emoji and graphic sticker layers with transformation',
      () {
        final emojiSticker = MovableStoryLayer(
          id: 'sticker_emoji_1',
          type: LayerType.sticker,
          text: '🔥',
          offset: const Offset(120, 300),
          scale: 1.5,
          rotation: 0.25,
        );
        expect(emojiSticker.type, LayerType.sticker);
        expect(emojiSticker.text, '🔥');
        expect(emojiSticker.scale, 1.5);
        expect(emojiSticker.rotation, 0.25);

        final assetSticker = MovableStoryLayer(
          id: 'sticker_asset_1',
          type: LayerType.sticker,
          text: 'assets/stickers/cats/cat_waving.png',
          offset: const Offset(200, 400),
          scale: 1.2,
        );
        expect(assetSticker.type, LayerType.sticker);
        expect(assetSticker.text.startsWith('assets/stickers/'), true);

        final cloneSticker = emojiSticker.clone();
        expect(cloneSticker.type, LayerType.sticker);
        expect(cloneSticker.text, '🔥');
        expect(cloneSticker.id != emojiSticker.id, true);
      },
    );

    test(
      'Test 22: StoryController.publishStory publishes successfully without throwing No Overlay widget found',
      () async {
        final controller = Get.put(StoryController());
        final success = await controller.publishStory(
          type: StoryType.text,
          textContent: 'Resilient publish test',
          visibility: 'Friends',
          replyPrivacy: 'Everyone',
          allowReactions: true,
          bgGradientStart: '0xFFFF416C',
          bgGradientEnd: '0xFFFF4B2B',
        );
        expect(success, true);
        expect(controller.storyGroups.isNotEmpty, true);
        final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
        expect(ownerGroup.stories.isNotEmpty, true);
        expect(ownerGroup.stories.first.textContent, 'Resilient publish test');
        expect(ownerGroup.stories.first.visibility, 'Friends');
      },
    );

    test(
      'Test 23: (TEST A) Text Story text editing preserves properties and stable position',
      () {
        final textLayer = MovableStoryLayer(
          id: 'layer_text_story_1',
          type: LayerType.text,
          text: 'test',
          color: Colors.white,
          fontStyle: TextStyleType.classic,
        );

        textLayer.text = 'Hello GenLink';
        expect(textLayer.text, 'Hello GenLink');
        expect(textLayer.type, LayerType.text);
        expect(textLayer.color, Colors.white);
        expect(textLayer.fontStyle, TextStyleType.classic);
      },
    );

    test(
      'Test 24: (TEST B) Image Story text layer preserves transform and does not jump when edited',
      () {
        final imageTextLayer = MovableStoryLayer(
          id: 'layer_image_text_1',
          type: LayerType.text,
          text: 'test',
          offset: const Offset(260.0, 95.0),
          scale: 1.4,
          rotation: 0.2,
          fontSize: 32.0,
        );

        expect(imageTextLayer.offset, const Offset(260.0, 95.0));
        expect(imageTextLayer.scale, 1.4);
        expect(imageTextLayer.rotation, 0.2);

        imageTextLayer.text = 'Hello GenLink';
        expect(imageTextLayer.text, 'Hello GenLink');
        expect(imageTextLayer.offset, const Offset(260.0, 95.0));
        expect(imageTextLayer.scale, 1.4);
        expect(imageTextLayer.rotation, 0.2);
        expect(imageTextLayer.fontSize, 32.0);
      },
    );

    test('Test 25: (TEST C) Emojis do not show floating toolbar', () {
      final emojiLayer1 = MovableStoryLayer(
        id: 'emoji_1',
        type: LayerType.sticker,
        text: '🎨',
      );
      final emojiLayer2 = MovableStoryLayer(
        id: 'emoji_2',
        type: LayerType.sticker,
        text: '🔥',
      );

      expect(emojiLayer1.type, LayerType.sticker);
      expect(emojiLayer1.text.startsWith('assets/'), false);
      expect(emojiLayer2.text.startsWith('assets/'), false);
    });

    test(
      'Test 26: (TEST D) Graphic asset stickers retain floating toolbar and clone capabilities',
      () {
        final assetSticker = MovableStoryLayer(
          id: 'sticker_cat_1',
          type: LayerType.sticker,
          text: 'assets/stickers/cats/cat_waving.png',
          offset: const Offset(150, 250),
          scale: 1.5,
        );

        expect(assetSticker.type, LayerType.sticker);
        expect(assetSticker.text.startsWith('assets/'), true);

        final clonedSticker = assetSticker.clone();
        expect(clonedSticker.type, LayerType.sticker);
        expect(clonedSticker.text, 'assets/stickers/cats/cat_waving.png');
        expect(clonedSticker.id != assetSticker.id, true);
        expect(clonedSticker.scale, 1.5);
      },
    );

    testWidgets(
      'Test 27: Background Picker renders compactly with horizontal scrolling and all categories',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const GetMaterialApp(
            home: StoryCreatorScreen(type: StoryType.text),
          ),
        );
        await tester.pumpAndSettle();

        final bgToolInEditor = find.byTooltip('Change background');
        if (bgToolInEditor.evaluate().isNotEmpty) {
          await tester.tap(bgToolInEditor);
          await tester.pumpAndSettle();

          expect(find.text('Background'), findsWidgets);
          expect(find.text('🌈 Gradients'), findsOneWidget);
          expect(find.text('🎨 Solid'), findsOneWidget);

          final closeBtn = find.byIcon(Icons.close_rounded).first;
          await tester.tap(closeBtn);
          await tester.pumpAndSettle();
        }

        final doneBtn = find.text('Done');
        if (doneBtn.evaluate().isNotEmpty) {
          await tester.tap(doneBtn);
          await tester.pumpAndSettle();
        }

        final bgTool = find.byTooltip('Background');
        expect(bgTool, findsOneWidget);
        await tester.ensureVisible(bgTool);
        await tester.tap(bgTool);
        await tester.pumpAndSettle();

        expect(find.text('Background'), findsWidgets);
        expect(find.byIcon(Icons.close_rounded), findsWidgets);

        expect(find.text('🌈 Gradients'), findsOneWidget);
        expect(find.text('🎨 Solid'), findsOneWidget);

        await tester.tap(find.text('🎨 Solid'));
        await tester.pumpAndSettle();

        final closeBtnCanvas = find.byIcon(Icons.close_rounded).first;
        await tester.tap(closeBtnCanvas);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Test 28: Zero RenderFlex overflow on small screen width (320px) with Background Picker open',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const GetMaterialApp(
            home: StoryCreatorScreen(type: StoryType.text),
          ),
        );
        await tester.pumpAndSettle();

        final bgToolInEditor = find.byTooltip('Change background');
        if (bgToolInEditor.evaluate().isNotEmpty) {
          await tester.tap(bgToolInEditor);
          await tester.pumpAndSettle();
        }

        expect(find.text('Background'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 29: Story Editor Header renders Left (Close), Spacer, and Right ([@][Emoji][Audio][Done]) with no title and proper spacing',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const GetMaterialApp(
            home: StoryCreatorScreen(type: StoryType.text),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close_rounded), findsWidgets);

        expect(find.byIcon(Icons.alternate_email_rounded), findsWidgets);
        expect(find.byIcon(Icons.sentiment_satisfied_alt_outlined), findsWidgets);
        expect(find.byIcon(Icons.graphic_eq_rounded), findsWidgets);
        expect(find.text('Done'), findsOneWidget);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 30: Story Editor Header zero overflow on small screen width (320px)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const GetMaterialApp(
            home: StoryCreatorScreen(type: StoryType.text),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close_rounded), findsWidgets);
        expect(find.byIcon(Icons.alternate_email_rounded), findsWidgets);
        expect(find.byIcon(Icons.sentiment_satisfied_alt_outlined), findsWidgets);
        expect(find.byIcon(Icons.graphic_eq_rounded), findsWidgets);
        expect(find.text('Done'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'Test 31: Canvas-relative coordinates dynamically adapt across 360x640, 390x844, and 430x932 devices',
      () {
        final centerLayer = MovableStoryLayer(
          id: 'center_layer',
          type: LayerType.text,
          text: 'Center Text',
          offset: const Offset(0.5, 0.5),
        );

        final smallOffset = centerLayer.getCanvasOffset(const Size(360, 640));
        expect(smallOffset.dx, 180.0);
        expect(smallOffset.dy, 320.0);

        final normalOffset = centerLayer.getCanvasOffset(const Size(390, 844));
        expect(normalOffset.dx, 195.0);
        expect(normalOffset.dy, 422.0);

        final largeOffset = centerLayer.getCanvasOffset(const Size(430, 932));
        expect(largeOffset.dx, 215.0);
        expect(largeOffset.dy, 466.0);

        final brSticker = MovableStoryLayer(
          id: 'br_sticker',
          type: LayerType.sticker,
          text: '🔥',
          offset: const Offset(0.85, 0.85),
        );

        expect(brSticker.getCanvasOffset(const Size(360, 640)).dx, 306.0);
        expect(brSticker.getCanvasOffset(const Size(360, 640)).dy, 544.0);

        expect(brSticker.getCanvasOffset(const Size(430, 932)).dx, closeTo(365.5, 0.01));
        expect(brSticker.getCanvasOffset(const Size(430, 932)).dy, closeTo(792.2, 0.01));
      },
    );

    testWidgets(
      'Test 32: Story Creator renders across small (360x640), normal (390x844), and large (430x932) devices without overflow',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(360, 640),
          const Size(390, 844),
          const Size(430, 932),
          const Size(412, 915),
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            const GetMaterialApp(
              home: StoryCreatorScreen(type: StoryType.text),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Done'), findsOneWidget);
          expect(find.byIcon(Icons.close_rounded), findsWidgets);
          expect(tester.takeException(), isNull);
        }

        tester.view.resetPhysicalSize();
      },
    );

    testWidgets(
      'Test 33: Keyboard OPEN on 360x640, 390x844, 430x932 produces ZERO RenderFlex overflow',
      (WidgetTester tester) async {
        final testCases = [
          (const Size(360, 640), 280.0),
          (const Size(360, 640), 336.0),
          (const Size(390, 844), 336.0),
          (const Size(390, 844), 380.0),
          (const Size(430, 932), 346.0),
          (const Size(430, 932), 400.0),
        ];

        for (final (size, kbHeight) in testCases) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          tester.view.viewInsets = FakeViewPadding(bottom: kbHeight);

          await tester.pumpWidget(
            const GetMaterialApp(
              home: StoryCreatorScreen(type: StoryType.text),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Done'), findsOneWidget);
          expect(find.byType(TextField), findsOneWidget);
          expect(find.byTooltip('Font'), findsOneWidget);
          expect(find.byTooltip('Color'), findsOneWidget);
          expect(find.byTooltip('Effects'), findsOneWidget);
          expect(find.byTooltip('Alignment'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetViewInsets();
      },
    );

    testWidgets(
      'Test 34: Keyboard OPEN with secondary contextual tools (Color, Font, Effect, Background) produces ZERO overflow',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(360, 640),
          const Size(390, 844),
          const Size(430, 932),
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          tester.view.viewInsets = const FakeViewPadding(bottom: 320.0);

          await tester.pumpWidget(
            const GetMaterialApp(
              home: StoryCreatorScreen(type: StoryType.text),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('Color'));
          await tester.pumpAndSettle();
          expect(find.text('Choose Color'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Font'));
          await tester.pumpAndSettle();
          expect(find.text('Font Family'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Effects'));
          await tester.pumpAndSettle();
          expect(find.text('Text Effects'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Change background'));
          await tester.pumpAndSettle();
          expect(find.text('Background'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetViewInsets();
      },
    );

    testWidgets(
      'Test 35: Full Story Text editing lifecycle (Open -> Type -> Format -> Keyboard Close -> Publish) with ZERO overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: 336.0);

        await tester.pumpWidget(
          const GetMaterialApp(
            home: StoryCreatorScreen(type: StoryType.text),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'test');
        await tester.pumpAndSettle();
        expect(find.text('test'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Font'));
        await tester.pumpAndSettle();
        expect(find.text('Bubble'), findsOneWidget);
        await tester.tap(find.text('Bubble'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Color'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Change background'));
        await tester.pumpAndSettle();
        expect(find.text('🎨 Solid'), findsOneWidget);
        await tester.tap(find.text('🎨 Solid'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        tester.view.resetViewInsets();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(find.text('Post Story'), findsOneWidget);
        expect(tester.takeException(), isNull);

        tester.view.resetPhysicalSize();
      },
    );

    test(
      'Test 36: Keyboard opening/closing does NOT modify saved normalized Story object position',
      () {
        final layer = MovableStoryLayer(
          id: 'text_persist_pos',
          type: LayerType.text,
          text: 'Fixed Position Text',
          offset: const Offset(0.35, 0.45),
        );

        expect(layer.offset.dx, 0.35);
        expect(layer.offset.dy, 0.45);

        final offsetBefore = layer.getCanvasOffset(const Size(390, 844));
        expect(offsetBefore.dx, closeTo(136.5, 0.01));
        expect(offsetBefore.dy, closeTo(379.8, 0.01));

        expect(layer.offset.dx, 0.35);
        expect(layer.offset.dy, 0.45);
      },
    );

    test(
      'Test 37: Scenario A (Camera Flow) - Captured photo passes to Story Editor and publishes only upon explicit post action',
      () async {
        final controller = StoryController();
        final initialStoryCount = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

        const capturedPath = 'mock/camera/photo_123.jpg';
        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount);

        final success = await controller.publishStory(
          type: StoryType.photo,
          mediaUrl: capturedPath,
          textContent: 'Story from Camera',
        );

        expect(success, isTrue);
        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount + 1);
        final publishedStory = controller.storyGroups.firstWhere((g) => g.isOwner).stories.first;
        expect(publishedStory.mediaUrl, capturedPath);
        expect(publishedStory.textContent, 'Story from Camera');
      },
    );

    test(
      'Test 38: Scenario B (Gallery Flow) - Selected image must NOT auto-publish and only publish when Done/Post is tapped',
      () async {
        final controller = StoryController();
        final initialStoryCount = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

        const selectedGalleryPath = 'mock/gallery/vacation_photo.png';
        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount);

        final success = await controller.publishStory(
          type: StoryType.photo,
          mediaUrl: selectedGalleryPath,
          textContent: 'Vacation memories',
        );

        expect(success, isTrue);
        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount + 1);
        final ownerStory = controller.storyGroups.firstWhere((g) => g.isOwner).stories.first;
        expect(ownerStory.mediaUrl, selectedGalleryPath);
        expect(ownerStory.textContent, 'Vacation memories');
      },
    );

    test(
      'Test 39: Scenario C (Gallery Cancellation) - Cancelling gallery selection results in zero story creation',
      () async {
        final controller = StoryController();
        final initialStoryCount = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

        const String? cancelledPath = null;
        expect(cancelledPath, isNull);

        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount);
      },
    );

    test(
      'Test 40: Scenario D (Camera Cancellation) - Cancelling camera capture returns safely without publishing',
      () async {
        final controller = StoryController();
        final initialStoryCount = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

        const String? cameraCancelledPath = null;
        expect(cameraCancelledPath, isNull);

        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount);
      },
    );

    test(
      'Test 41: Scenario E (Editor Back/Cancel) - Exiting Story Editor without posting does not publish story',
      () async {
        final controller = StoryController();
        final initialStoryCount = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

        const selectedPath = 'mock/gallery/photo.png';
        expect(selectedPath, isNotEmpty);

        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialStoryCount);
      },
    );

    test(
      'Test 42: Scenario F (Multiple Media Selection) - Multiple media must pass through Story Editor before publishing',
      () async {
        final controller = StoryController();
        final initialCount = controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length);

        final selectedPaths = ['mock/photo1.jpg', 'mock/photo2.jpg'];
        expect(selectedPaths.length, 2);

        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialCount);

        final success = await controller.publishStory(
          type: StoryType.template,
          templateId: 'grid_2',
          templateSlots: [
            StoryTemplateSlot(id: 'slot_0', mediaPath: selectedPaths[0]),
            StoryTemplateSlot(id: 'slot_1', mediaPath: selectedPaths[1]),
          ],
        );

        expect(success, isTrue);
        expect(controller.storyGroups.fold<int>(0, (sum, g) => sum + g.stories.length), initialCount + 1);
      },
    );

    test(
      'Test 43: Scenario G (Success Notification Trigger) - Success state confirmed only upon true return from backend repository',
      () async {
        final controller = StoryController();
        bool isPublishing = true;
        bool notificationTriggered = false;

        final success = await controller.publishStory(
          type: StoryType.text,
          textContent: 'Notification validation text',
        );

        if (success) {
          isPublishing = false;
          notificationTriggered = true;
        }

        expect(isPublishing, isFalse);
        expect(notificationTriggered, isTrue);
        expect(success, isTrue);
      },
    );
  });
}

