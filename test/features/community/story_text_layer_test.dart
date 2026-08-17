import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';

void main() {
  group('Story Text Object Model & State Persistence Tests', () {
    test('Test 1: Default text layer uses intended defaults and nullable background', () {
      final layer = MovableStoryLayer(
        id: 'text_1',
        type: LayerType.text,
        text: 'Hello GenLink',
      );

      expect(layer.text, 'Hello GenLink');
      expect(layer.color, Colors.white);
      expect(layer.bgColor, isNull); // Null represents no background
      expect(layer.bgStyle, TextBgStyle.none);
      expect(layer.fontStyle, TextStyleType.classic);
      expect(layer.effect, TextEffectType.none);
      expect(layer.fontSize, 28.0);
      expect(layer.scale, 1.0);
      expect(layer.rotation, 0.0);
      expect(layer.alignment, TextAlign.center);
    });

    test('Test 2 & 3: Background color assignment and immediate state updates', () {
      final layer = MovableStoryLayer(
        id: 'text_2',
        type: LayerType.text,
        text: 'Testing Blue and Pink',
      );

      // Select blue background
      const blueColor = Color(0xFF38BDF8);
      layer.bgColor = blueColor;
      layer.bgStyle = TextBgStyle.filled;
      expect(layer.bgColor, blueColor);
      expect(layer.bgStyle, TextBgStyle.filled);

      // Select pink background
      const pinkColor = Color(0xFFE879F9);
      layer.bgColor = pinkColor;
      expect(layer.bgColor, pinkColor);
    });

    test('Test 4: Select None resets background container without reverting to black', () {
      final layer = MovableStoryLayer(
        id: 'text_4',
        type: LayerType.text,
        text: 'No Background',
        bgColor: const Color(0xFF38BDF8),
        bgStyle: TextBgStyle.filled,
      );

      // User selects None
      layer.bgStyle = TextBgStyle.none;
      layer.bgColor = null;

      expect(layer.bgStyle, TextBgStyle.none);
      expect(layer.bgColor, isNull);
      expect(layer.bgColor, isNot(Colors.black));
    });

    test('Test 5: Select blue background -> change font -> blue background remains', () {
      final layer = MovableStoryLayer(
        id: 'text_5',
        type: LayerType.text,
        text: 'Blue Text',
        bgColor: const Color(0xFF38BDF8),
        bgStyle: TextBgStyle.rounded,
        fontStyle: TextStyleType.classic,
      );

      expect(layer.bgColor, const Color(0xFF38BDF8));

      // User changes font to Deco, Bubble, Modern, Minimal
      layer.fontStyle = TextStyleType.elegant;
      expect(layer.bgColor, const Color(0xFF38BDF8));
      expect(layer.fontStyle, TextStyleType.elegant);

      layer.fontStyle = TextStyleType.bold;
      expect(layer.bgColor, const Color(0xFF38BDF8));

      layer.fontStyle = TextStyleType.modern;
      expect(layer.bgColor, const Color(0xFF38BDF8));

      layer.fontStyle = TextStyleType.minimal;
      expect(layer.bgColor, const Color(0xFF38BDF8));
    });

    test('Test 6: Select pink background -> change text color -> pink background remains', () {
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

      // User changes text color to Yellow / Black / Emerald
      layer.color = const Color(0xFFFACC15);
      expect(layer.bgColor, const Color(0xFFE879F9));
      expect(layer.color, const Color(0xFFFACC15));

      layer.color = Colors.black;
      expect(layer.bgColor, const Color(0xFFE879F9));
      expect(layer.color, Colors.black);
    });

    test('Test 7: Select green background -> change font style -> green remains', () {
      final layer = MovableStoryLayer(
        id: 'text_7',
        type: LayerType.text,
        text: 'Green Text',
        bgColor: const Color(0xFF34D399),
        bgStyle: TextBgStyle.filled,
        fontStyle: TextStyleType.classic,
      );

      // Font style change
      layer.fontStyle = TextStyleType.bold;
      expect(layer.bgColor, const Color(0xFF34D399));
      expect(layer.bgStyle, TextBgStyle.filled);
    });

    test('Test 8: Edit text content -> background color remains unchanged', () {
      final layer = MovableStoryLayer(
        id: 'text_8',
        type: LayerType.text,
        text: 'Draft 1',
        bgColor: const Color(0xFFFB923C),
        bgStyle: TextBgStyle.filled,
      );

      // User modifies text
      layer.text = 'Draft 2 with new content';
      expect(layer.text, 'Draft 2 with new content');
      expect(layer.bgColor, const Color(0xFFFB923C));
      expect(layer.bgStyle, TextBgStyle.filled);
    });

    test('Test 9: Drag text -> position updates while background properties persist', () {
      final layer = MovableStoryLayer(
        id: 'text_9',
        type: LayerType.text,
        text: 'Movable',
        offset: const Offset(100, 200),
        bgColor: const Color(0xFF38BDF8),
        bgStyle: TextBgStyle.rounded,
      );

      // Drag
      layer.offset = const Offset(150, 320);
      expect(layer.offset, const Offset(150, 320));
      expect(layer.bgColor, const Color(0xFF38BDF8));
      expect(layer.bgStyle, TextBgStyle.rounded);
    });

    test('Test 10: Resize text -> scale updates and clone preserves properties', () {
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
    });

    test('Test 11: Rotate text -> rotation updates while maintaining styling', () {
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
    });

    test('Test 12: Independent property persistence across all modifications', () {
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
    });

    test('Test 13: Font Style and Text Effects are completely independent', () {
      // 1. Classic has NO shadow by default (effect = none)
      final layer = MovableStoryLayer(
        id: 'text_13',
        type: LayerType.text,
        text: 'Clean Text',
        fontStyle: TextStyleType.classic,
        effect: TextEffectType.none,
      );
      expect(layer.fontStyle, TextStyleType.classic);
      expect(layer.effect, TextEffectType.none);

      // 2. Bold font also has NO shadow by default
      layer.fontStyle = TextStyleType.bold;
      expect(layer.fontStyle, TextStyleType.bold);
      expect(layer.effect, TextEffectType.none);

      // 3. User explicitly enables Shadow effect
      layer.effect = TextEffectType.shadow;
      expect(layer.effect, TextEffectType.shadow);
      expect(layer.fontStyle, TextStyleType.bold);

      // 4. Changing font while Shadow is enabled keeps Shadow
      layer.fontStyle = TextStyleType.coding;
      expect(layer.fontStyle, TextStyleType.coding);
      expect(layer.effect, TextEffectType.shadow);

      // 5. User selects Effects -> None, shadow is removed
      layer.effect = TextEffectType.none;
      expect(layer.effect, TextEffectType.none);

      // 6. Changing background color preserves effect state
      layer.bgColor = const Color(0xFF38BDF8);
      expect(layer.bgColor, const Color(0xFF38BDF8));
      expect(layer.effect, TextEffectType.none);
    });

    test('Test 14: Text Story creation and gradient persistence via StoryController', () async {
      final repository = StoryRepositoryImpl();
      final textLayer = MovableStoryLayer(
        id: 'layer_publish_1',
        type: LayerType.text,
        text: 'test',
        color: const Color(0xFF34D399), // green
        bgColor: null,
        fontStyle: TextStyleType.classic,
        effect: TextEffectType.none,
      );

      final newStory = await repository.createStory(
        type: StoryType.text,
        mediaUrl: null, // text-only story has no media file
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
    });

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

    test('Test 16: Complete separation between Text Color and Canvas/Layer Background', () {
      final layer = MovableStoryLayer(
        id: 'layer_sep_1',
        type: LayerType.text,
        text: 'Separation Test',
        color: const Color(0xFFFACC15), // Amber
        bgColor: const Color(0xFFA855F7), // Purple
        bgStyle: TextBgStyle.rounded,
      );

      // Changing text color to White does NOT alter purple background
      layer.color = Colors.white;
      expect(layer.color, Colors.white);
      expect(layer.bgColor, const Color(0xFFA855F7));
      expect(layer.bgStyle, TextBgStyle.rounded);

      // Changing background to Green does NOT alter white text color
      layer.bgColor = const Color(0xFF34D399); // Green
      expect(layer.color, Colors.white);
      expect(layer.bgColor, const Color(0xFF34D399));

      // Removing background does NOT alter text color
      layer.bgColor = null;
      layer.bgStyle = TextBgStyle.none;
      expect(layer.color, Colors.white);
      expect(layer.bgColor, isNull);
    });

    test('Test 17: Solid and None Background serialization in Story repository', () async {
      final repository = StoryRepositoryImpl();
      final textLayer = MovableStoryLayer(
        id: 'layer_solid_1',
        type: LayerType.text,
        text: 'Solid Background Story',
        color: Colors.white,
      );

      // 1. Solid Purple Story (same start & end color)
      final purpleStory = await repository.createStory(
        type: StoryType.text,
        mediaUrl: null,
        bgGradientStart: '0xFFA855F7',
        bgGradientEnd: '0xFFA855F7',
        layers: [textLayer],
      );
      expect(purpleStory.bgGradientStart, '0xFFA855F7');
      expect(purpleStory.bgGradientEnd, '0xFFA855F7');

      // 2. None / Transparent minimal Story
      final noneStory = await repository.createStory(
        type: StoryType.text,
        mediaUrl: null,
        bgGradientStart: '0xFF0B0B0E',
        bgGradientEnd: '0xFF0B0B0E',
        layers: [textLayer],
      );
      expect(noneStory.bgGradientStart, '0xFF0B0B0E');
      expect(noneStory.bgGradientEnd, '0xFF0B0B0E');
    });

    test('Test 18: Background state survives font changes, resizing, and rotation', () {
      final layer = MovableStoryLayer(
        id: 'layer_persist_1',
        type: LayerType.text,
        text: 'Persistent Background',
        bgColor: const Color(0xFFF43F5E), // Rose Pink
        bgStyle: TextBgStyle.filled,
        fontStyle: TextStyleType.classic,
      );

      // 1. Change font
      layer.fontStyle = TextStyleType.handwriting;
      expect(layer.bgColor, const Color(0xFFF43F5E));

      // 2. Resize scale
      layer.scale = 2.0;
      expect(layer.bgColor, const Color(0xFFF43F5E));
      expect(layer.scale, 2.0);

      // 3. Rotate
      layer.rotation = 0.5;
      expect(layer.bgColor, const Color(0xFFF43F5E));
      expect(layer.rotation, 0.5);

      // 4. Edit text content
      layer.text = 'Updated Text Content';
      expect(layer.bgColor, const Color(0xFFF43F5E));
      expect(layer.text, 'Updated Text Content');
    });

    test('Test 19: Story Privacy Settings (Public, Friends, Only Me, replyPrivacy, allowReactions)', () async {
      final repository = StoryRepositoryImpl();

      // 1. Publish Friends story
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

      // 2. Publish Only Me story
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
    });

    test('Test 20: Only Me stories are filtered from non-owner story groups', () async {
      final repository = StoryRepositoryImpl();
      final groups = await repository.getStories();

      // Non-owner groups must not expose stories with visibility == 'Only Me'
      for (final g in groups) {
        if (!g.isOwner) {
          expect(g.stories.every((s) => s.visibility != 'Only Me'), true);
        }
      }
    });

    test('Test 21: MovableStoryLayer supports emoji and graphic sticker layers with transformation', () {
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
    });

    test('Test 22: StoryController.publishStory publishes successfully without throwing No Overlay widget found', () async {
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
    });
  });
}

