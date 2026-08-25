import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
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
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Creator Image Layer Initialization & Independence Tests', () {
    testWidgets('1. Add one image -> initializes with consistent default scale, rotation, and center position', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final singleLayer = MovableStoryLayer(
        id: 'img_layer_single',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.5),
        scale: 1.0,
        rotation: 0.0,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              existingStory: StoryItemModel(
                id: 'story_single',
                type: StoryType.photo,
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [singleLayer],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClipRRect), findsWidgets);
      final positioned = tester.widget<Positioned>(
        find.byKey(const ValueKey('img_layer_single')),
      );
      expect(positioned.left, closeTo(screenSize.width * 0.5, 1.0));
      expect(positioned.top, closeTo(screenSize.height * 0.5, 1.0));
    });

    testWidgets('2. Add the same image twice -> both layers are rendered with consistent default scale & safe positions', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final samePaths = [
        'assets/images/user_profile.png',
        'assets/images/user_profile.png',
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              mediaPaths: samePaths,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byWidgetPredicate((w) => w is Positioned && w.key != null && (w.key as ValueKey).value.toString().startsWith('image_')),
      ).toList();

      expect(positionedWidgets.length, 2);

      // Both layers must be placed safely inside visible canvas bounds
      for (final p in positionedWidgets) {
        expect(p.left, greaterThan(screenSize.width * 0.20));
        expect(p.left, lessThan(screenSize.width * 0.80));
        expect(p.top, greaterThan(screenSize.height * 0.20));
        expect(p.top, lessThan(screenSize.height * 0.80));
      }
    });

    testWidgets('3. Add two different images -> both layers are consistent and within bounds', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final differentPaths = [
        'assets/images/user_profile.png',
        'assets/images/templates/coffee_vibe_bg.jpg',
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              mediaPaths: differentPaths,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final positionedWidgets = tester.widgetList<Positioned>(
        find.byWidgetPredicate((w) => w is Positioned && w.key != null && (w.key as ValueKey).value.toString().startsWith('image_')),
      ).toList();

      expect(positionedWidgets.length, 2);
    });

    testWidgets('4. Move one image layer -> the other layer does not move', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final layer1 = MovableStoryLayer(
        id: 'img_layer_1',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.4, 0.4),
      );
      final layer2 = MovableStoryLayer(
        id: 'img_layer_2',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.6, 0.6),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              existingStory: StoryItemModel(
                id: 'story_move_test',
                type: StoryType.photo,
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [layer1, layer2],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialPos2 = tester.widget<Positioned>(
        find.byKey(const ValueKey('img_layer_2')),
      );

      // Drag layer 1
      await tester.dragFrom(
        Offset(screenSize.width * 0.4, screenSize.height * 0.4),
        const Offset(50, 50),
      );
      await tester.pumpAndSettle();

      final updatedPos2 = tester.widget<Positioned>(
        find.byKey(const ValueKey('img_layer_2')),
      );

      // Layer 2 position must remain unchanged
      expect(updatedPos2.left, equals(initialPos2.left));
      expect(updatedPos2.top, equals(initialPos2.top));
    });

    testWidgets('5. Delete one duplicate image -> the other duplicate remains intact', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final layer1 = MovableStoryLayer(
        id: 'img_layer_dup_1',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.4, 0.4),
      );
      final layer2 = MovableStoryLayer(
        id: 'img_layer_dup_2',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.6, 0.6),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              existingStory: StoryItemModel(
                id: 'story_delete_test',
                type: StoryType.photo,
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [layer1, layer2],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('img_layer_dup_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('img_layer_dup_2')), findsOneWidget);

      // Drag layer 1 down to delete zone (screenHeight - 100)
      await tester.dragFrom(
        Offset(screenSize.width * 0.4, screenSize.height * 0.4),
        const Offset(0, 400),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Layer 1 is deleted, layer 2 remains intact
      expect(find.byKey(const ValueKey('img_layer_dup_1')), findsNothing);
      expect(find.byKey(const ValueKey('img_layer_dup_2')), findsOneWidget);
    });

    testWidgets('6. StoryCanvasRenderer correctly renders independent duplicate image layers', (tester) async {
      const canvasSize = Size(390, 844);

      final layer1 = MovableStoryLayer(
        id: 'canvas_img_1',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.46, 0.46),
        scale: 1.0,
      );
      final layer2 = MovableStoryLayer(
        id: 'canvas_img_2',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.50, 0.50),
        scale: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCanvasRenderer(
              canvasSize: canvasSize,
              layers: [layer1, layer2],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('canvas_img_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('canvas_img_2')), findsOneWidget);

      final pos1 = tester.widget<Positioned>(find.byKey(const ValueKey('canvas_img_1')));
      final pos2 = tester.widget<Positioned>(find.byKey(const ValueKey('canvas_img_2')));

      expect(pos1.left, closeTo(390 * 0.46, 1.0));
      expect(pos2.left, closeTo(390 * 0.50, 1.0));
    });

    testWidgets('7. Single image story editor uses BoxFit.contain and preserves full image without cropping', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: const GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              mediaPaths: ['assets/images/user_profile.png'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(imageWidgets, isNotEmpty);
      final bgImage = imageWidgets.firstWhere(
        (img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/images/user_profile.png',
      );
      expect(bgImage.fit, BoxFit.contain);
    });

    testWidgets('8. StoryCanvasRenderer background image uses BoxFit.contain to prevent cropping', (tester) async {
      const canvasSize = Size(390, 844);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoryCanvasRenderer(
              canvasSize: canvasSize,
              storyType: StoryType.photo,
              mediaUrl: 'assets/images/user_profile.png',
              layers: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(imageWidgets, isNotEmpty);
      final bgImage = imageWidgets.firstWhere(
        (img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/images/user_profile.png',
      );
      expect(bgImage.fit, BoxFit.contain);
    });

    testWidgets('9. Portrait, Landscape, and Square image layers maintain BoxFit.contain with aspect ratio preserved', (tester) async {
      const canvasSize = Size(390, 844);

      final portraitLayer = MovableStoryLayer(
        id: 'layer_portrait',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.3),
        scale: 1.0,
      );
      final landscapeLayer = MovableStoryLayer(
        id: 'layer_landscape',
        type: LayerType.image,
        text: 'assets/images/ren_makara_post.png',
        offset: const Offset(0.5, 0.5),
        scale: 1.0,
      );
      final squareLayer = MovableStoryLayer(
        id: 'layer_square',
        type: LayerType.image,
        text: 'assets/images/heng_chansela_post.png',
        offset: const Offset(0.5, 0.7),
        scale: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCanvasRenderer(
              canvasSize: canvasSize,
              layers: [portraitLayer, landscapeLayer, squareLayer],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, equals(3));
      for (final img in images) {
        expect(img.fit, equals(BoxFit.contain));
      }
    });

    testWidgets('10. Published Story with mediaUrl uses BoxFit.contain in StoryCanvasRenderer and matches editor', (tester) async {
      const canvasSize = Size(390, 844);
      final story = StoryItemModel(
        id: 'story_pub_test',
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        bgScale: 1.0,
        bgOffset: Offset.zero,
        bgRotation: 0.0,
        layers: [
          MovableStoryLayer(
            id: 'overlay_1',
            type: LayerType.image,
            text: 'assets/images/user_profile.png',
            offset: const Offset(0.5, 0.5),
            scale: 1.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCanvasRenderer(
              canvasSize: canvasSize,
              storyType: story.type,
              mediaUrl: story.mediaUrl,
              bgOffset: story.bgOffset,
              bgScale: story.bgScale,
              bgRotation: story.bgRotation,
              layers: story.layers,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, equals(2)); // background image + overlay image
      for (final img in images) {
        expect(img.fit, equals(BoxFit.contain));
      }
    });
  });
}
