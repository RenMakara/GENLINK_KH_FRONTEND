import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_canvas_renderer.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  List<XFile> nextImages = [];

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    return nextImages;
  }

  @override
  Future<List<XFile>> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return nextImages;
  }

  @override
  Future<List<XFile>> getMedia({
    required MediaOptions options,
  }) async {
    return nextImages;
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return nextImages.isNotEmpty ? nextImages.first : null;
  }
}

class _MockLocalStorage extends LocalStorage {
  _MockLocalStorage() : super(storage: const FlutterSecureStorage());
  @override
  Future<String?> readStoryDraft() async => null;
  @override
  Future<void> saveStoryDraft(String draftJson) async {}
  @override
  Future<void> deleteStoryDraft() async {}
}

class FakeVideoPlayerController extends VideoPlayerController {
  FakeVideoPlayerController() : super.file(File('dummy.mp4'));

  bool playCalled = false;
  bool pauseCalled = false;
  bool loopingSet = false;
  bool disposeCalled = false;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 15),
      size: const Size(1080, 1920),
    );
  }

  @override
  Future<void> play() async {
    playCalled = true;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setLooping(bool looping) async {
    loopingSet = looping;
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    super.dispose();
  }
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

  group('Video Story + Image Layer Playback & Rendering Tests', () {
    testWidgets('1. Video Story initializes with real VideoPlayerController, plays automatically, and sets looping', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeCtrl.playCalled, isTrue);
      expect(fakeCtrl.loopingSet, isTrue);
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(find.byKey(const ValueKey('story_video_player')), findsOneWidget);
    });

    testWidgets('2. Adding one image layer above video does NOT stop, pause, or dispose video playback', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      final imageLayer = MovableStoryLayer(
        id: 'overlay_img_1',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.4),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
              existingStory: StoryItemModel(
                id: 'video_story_1',
                type: StoryType.video,
                mediaUrl: 'assets/sample_video.mp4',
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [imageLayer],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Video must still be playing and never paused or disposed
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);
      expect(fakeCtrl.disposeCalled, isFalse);
      expect(find.byType(VideoPlayer), findsOneWidget);

      // Overlay image must be rendered
      expect(find.byKey(const ValueKey('overlay_img_1')), findsOneWidget);
    });

    testWidgets('3. Adding multiple image layers above video preserves continuous playback', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      final layers = [
        MovableStoryLayer(
          id: 'multi_img_1',
          type: LayerType.image,
          text: 'assets/images/user_profile.png',
          offset: const Offset(0.3, 0.3),
        ),
        MovableStoryLayer(
          id: 'multi_img_2',
          type: LayerType.image,
          text: 'assets/images/user_profile.png',
          offset: const Offset(0.7, 0.3),
        ),
        MovableStoryLayer(
          id: 'multi_img_3',
          type: LayerType.image,
          text: 'assets/images/user_profile.png',
          offset: const Offset(0.5, 0.7),
        ),
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
              existingStory: StoryItemModel(
                id: 'video_story_multi',
                type: StoryType.video,
                mediaUrl: 'assets/sample_video.mp4',
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: layers,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Video remains playing
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);
      expect(fakeCtrl.disposeCalled, isFalse);
      expect(find.byType(VideoPlayer), findsOneWidget);

      // All 3 image layers must be present
      expect(find.byKey(const ValueKey('multi_img_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('multi_img_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('multi_img_3')), findsOneWidget);
    });

    testWidgets('4. Image layer on top of video has NO forced rounded card, ClipRRect, or BoxShadow', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      final imageLayer = MovableStoryLayer(
        id: 'clean_img_layer',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
              existingStory: StoryItemModel(
                id: 'clean_image_story',
                type: StoryType.video,
                mediaUrl: 'assets/sample_video.mp4',
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [imageLayer],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final layerFinder = find.byKey(const ValueKey('clean_img_layer'));
      expect(layerFinder, findsOneWidget);

      // Must NOT wrap the image in a ClipRRect
      expect(find.descendant(of: layerFinder, matching: find.byType(ClipRRect)), findsNothing);

      // Container inside the unselected layer must not have a BoxShadow
      final containers = tester.widgetList<Container>(
        find.descendant(of: layerFinder, matching: find.byType(Container)),
      );
      for (final c in containers) {
        final boxDecoration = c.decoration as BoxDecoration?;
        if (boxDecoration != null) {
          expect(boxDecoration.boxShadow, isNull, reason: 'Image layer must not have a forced BoxShadow');
          expect(boxDecoration.borderRadius, isNull, reason: 'Image layer must not have forced rounded corners');
        }
      }
    });

    testWidgets('5. Image layer on top of video remains interactive (selectable, scalable, rotatable)', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      final imageLayer = MovableStoryLayer(
        id: 'interactive_img',
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
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
              existingStory: StoryItemModel(
                id: 'interactive_story',
                type: StoryType.video,
                mediaUrl: 'assets/sample_video.mp4',
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [imageLayer],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on image layer to select it (layer center is at screen center 195, 422)
      await tester.tapAt(const Offset(195.0, 422.0));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // When selected, white selection outline border is applied
      final selectedContainer = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('interactive_img')),
          matching: find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null),
        ).first,
      );
      final border = (selectedContainer.decoration as BoxDecoration?)?.border;
      expect(border, isNotNull);
      expect((border as Border).top.color, equals(Colors.white));

      // Video must still be playing after selection
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);
    });

    testWidgets('6. Multi-media input with video preserves video as primary media and converts other items to image overlays', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const [
                'assets/main_clip.mp4',
                'assets/images/sticker1.png',
                'assets/images/sticker2.png',
              ],
              videoPlayerController: fakeCtrl,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Video player is rendered as background canvas
      expect(find.byType(VideoPlayer), findsOneWidget);

      // Additional images must be present as movable layer overlays
      final overlayLayers = tester.widgetList<Positioned>(
        find.byWidgetPredicate((w) => w is Positioned && w.key != null && (w.key as ValueKey).value.toString().startsWith('image_')),
      ).toList();
      expect(overlayLayers.length, 2);
    });

    testWidgets('7. StoryCanvasRenderer renders image layer cleanly without ClipRRect or BoxShadow', (tester) async {
      const canvasSize = Size(390, 844);

      final layer = MovableStoryLayer(
        id: 'renderer_img',
        type: LayerType.image,
        text: 'assets/images/user_profile.png',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: Stack(
                children: [
                  buildStoryLayerContent(
                    layer: layer,
                    maxCanvasWidth: canvasSize.width * 0.85,
                    isSelected: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClipRRect), findsNothing);
      final container = tester.widget<Container>(find.byType(Container));
      final dec = container.decoration as BoxDecoration?;
      if (dec != null) {
        expect(dec.boxShadow, isNull);
        expect(dec.borderRadius, isNull);
      }
    });

    testWidgets('8. Existing Story layers (text, mention, stickers) continue functioning on top of video', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      final layers = [
        MovableStoryLayer(
          id: 'text_layer_1',
          type: LayerType.text,
          text: 'Video Story Header',
          offset: const Offset(0.5, 0.2),
        ),
        MovableStoryLayer(
          id: 'mention_layer_1',
          type: LayerType.mention,
          text: '@chansela',
          offset: const Offset(0.5, 0.5),
        ),
        MovableStoryLayer(
          id: 'sticker_layer_1',
          type: LayerType.sticker,
          text: '🔥',
          offset: const Offset(0.5, 0.8),
        ),
      ];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
              existingStory: StoryItemModel(
                id: 'multi_layer_video_story',
                type: StoryType.video,
                mediaUrl: 'assets/sample_video.mp4',
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: layers,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Video plays
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(find.byType(VideoPlayer), findsOneWidget);

      // Text, Mention, Sticker all rendered
      expect(find.text('Video Story Header'), findsOneWidget);
      expect(find.text('@chansela'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('9. Complete flow: Video story -> plays -> Add Image 1 -> plays -> Add Image 2 -> plays -> move Image 1 -> scale Image 1 -> rotate Image 1 -> move Image 2 -> video still playing', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final originalPicker = ImagePickerPlatform.instance;
      final fakePicker = _FakeImagePickerPlatform();
      ImagePickerPlatform.instance = fakePicker;
      addTearDown(() => ImagePickerPlatform.instance = originalPicker);

      final fakeCtrl = FakeVideoPlayerController();
      await fakeCtrl.initialize();

      // Step 1: Video Story launches
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: screenSize),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.video,
              mediaPaths: const ['assets/sample_video.mp4'],
              videoPlayerController: fakeCtrl,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 2: Video starts playing
      expect(fakeCtrl.playCalled, isTrue);
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(find.byType(VideoPlayer), findsOneWidget);

      // Step 3: Add Image 1
      fakePicker.nextImages = [XFile('assets/images/user_profile.png')];
      final photoBtnFinder = find.byTooltip('Photo');
      expect(photoBtnFinder, findsOneWidget);
      await tester.ensureVisible(photoBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(photoBtnFinder);
      await tester.pumpAndSettle();

      // Step 4: Video continues playing after adding Image 1
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);
      expect(fakeCtrl.disposeCalled, isFalse);

      // Step 5: Add Image 2
      fakePicker.nextImages = [XFile('assets/images/user_profile.png')];
      await tester.ensureVisible(photoBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(photoBtnFinder);
      await tester.pumpAndSettle();

      // Step 6: Video continues playing after adding Image 2
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);
      expect(fakeCtrl.disposeCalled, isFalse);

      final imageLayers = find.byWidgetPredicate(
        (w) => w is Positioned && w.key != null && (w.key as ValueKey).value.toString().startsWith('image_'),
      );
      expect(imageLayers, findsNWidgets(2));
      final img1 = imageLayers.at(0);
      final img2 = imageLayers.at(1);

      // Step 7: Move Image 1
      final img1GestureFinder = find.descendant(of: img1, matching: find.byType(GestureDetector)).first;
      await tester.drag(img1GestureFinder, const Offset(30, 20), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);

      // Step 8: Scale & Rotate Image 1
      final img1Gesture = tester.widget<GestureDetector>(img1GestureFinder);
      img1Gesture.onScaleStart!(ScaleStartDetails(focalPoint: const Offset(100, 100)));
      img1Gesture.onScaleUpdate!(ScaleUpdateDetails(
        focalPoint: const Offset(120, 110),
        focalPointDelta: const Offset(20, 10),
        scale: 1.5,
        rotation: 0.35,
      ));
      img1Gesture.onScaleEnd!(ScaleEndDetails());
      await tester.pumpAndSettle();
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);

      // Step 9: Move Image 2
      final img2GestureFinder = find.descendant(of: img2, matching: find.byType(GestureDetector)).first;
      await tester.drag(img2GestureFinder, const Offset(-25, 30), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Step 10: Video still playing
      expect(fakeCtrl.value.isPlaying, isTrue);
      expect(fakeCtrl.pauseCalled, isFalse);
      expect(fakeCtrl.disposeCalled, isFalse);
      expect(find.byType(VideoPlayer), findsOneWidget);
    });
  });
}
