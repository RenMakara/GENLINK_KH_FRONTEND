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
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildStoryCreatorScreen({
    required Size screenSize,
    List<MovableStoryLayer>? initialLayers,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        viewInsets: viewInsets,
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: GetMaterialApp(
        home: StoryCreatorScreen(
          type: StoryType.photo,
          mediaPaths: const ['assets/images/user_profile.png'],
          existingStory: initialLayers != null
              ? StoryItemModel(
                  id: 'story_pos_test',
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

  group('Story Creator Text Editing Position Invariance Tests', () {
    testWidgets('Case 1: Center text -> tap Edit -> center position stays identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final centerLayer = MovableStoryLayer(
        id: 'layer_center',
        type: LayerType.text,
        text: 'Center Text',
        offset: const Offset(0.5, 0.5),
        fontSize: 28.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [centerLayer],
      ));
      await tester.pumpAndSettle();

      final textFinder = find.text('Center Text');
      expect(textFinder, findsOneWidget);
      final displayCenter = tester.getCenter(textFinder);

      expect((displayCenter.dx - 195.0).abs() < 1.0, true);
      expect((displayCenter.dy - 422.0).abs() < 1.0, true);

      await tester.tap(textFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editFieldFinder = find.byType(TextField);
      expect(editFieldFinder, findsOneWidget);
      final editCenter = tester.getCenter(editFieldFinder);

      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final finalCenter = tester.getCenter(find.text('Center Text'));
      expect((finalCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((finalCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 2: Left text -> tap Edit -> position stays identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final leftLayer = MovableStoryLayer(
        id: 'layer_left',
        type: LayerType.text,
        text: 'Left Text',
        offset: const Offset(0.2, 0.4),
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [leftLayer],
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Left Text'));

      await tester.tap(find.text('Left Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 3: Right text -> tap Edit -> position stays identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final rightLayer = MovableStoryLayer(
        id: 'layer_right',
        type: LayerType.text,
        text: 'Right Text',
        offset: const Offset(0.8, 0.4),
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [rightLayer],
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Right Text'));

      await tester.tap(find.text('Right Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 4: Top text -> tap Edit -> position stays identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final topLayer = MovableStoryLayer(
        id: 'layer_top',
        type: LayerType.text,
        text: 'Top Text',
        offset: const Offset(0.5, 0.15),
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [topLayer],
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Top Text'));

      await tester.tap(find.text('Top Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 5: Bottom text -> tap Edit -> position stays identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final bottomLayer = MovableStoryLayer(
        id: 'layer_bottom',
        type: LayerType.text,
        text: 'Bottom Text',
        offset: const Offset(0.5, 0.65),
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [bottomLayer],
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Bottom Text'));

      await tester.tap(find.text('Bottom Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 6: Scaled text -> tap Edit -> scale and position stay identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final scaledLayer = MovableStoryLayer(
        id: 'layer_scaled',
        type: LayerType.text,
        text: 'Scaled Text',
        offset: const Offset(0.4, 0.4),
        scale: 1.6,
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [scaledLayer],
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Scaled Text'));

      await tester.tap(find.text('Scaled Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 7: Rotated text -> tap Edit -> rotation and position stay identical', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final rotatedLayer = MovableStoryLayer(
        id: 'layer_rotated',
        type: LayerType.text,
        text: 'Rotated Text',
        offset: const Offset(0.5, 0.4),
        rotation: 0.35,
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [rotatedLayer],
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Rotated Text'));

      await tester.tap(find.text('Rotated Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 8: Edit text content -> Done -> position remains unchanged', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final layer = MovableStoryLayer(
        id: 'layer_content',
        type: LayerType.text,
        text: 'Old Text',
        offset: const Offset(0.35, 0.45),
        fontSize: 26.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [layer],
      ));
      await tester.pumpAndSettle();

      final initialCenter = tester.getCenter(find.text('Old Text'));

      await tester.tap(find.text('Old Text'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'New Updated Text');
      await tester.pump();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('New Updated Text'), findsOneWidget);
      final finalCenter = tester.getCenter(find.text('New Updated Text'));
      expect((finalCenter.dx - initialCenter.dx).abs() < 2.0, true);
      expect((finalCenter.dy - initialCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 9: Open keyboard -> keyboard does not cause text to jump', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final layer = MovableStoryLayer(
        id: 'layer_kb',
        type: LayerType.text,
        text: 'Keyboard Test',
        offset: const Offset(0.6, 0.35),
        fontSize: 24.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [layer],
        viewInsets: EdgeInsets.zero,
      ));
      await tester.pumpAndSettle();

      final displayCenter = tester.getCenter(find.text('Keyboard Test'));

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: screenSize,
        initialLayers: [layer],
        viewInsets: const EdgeInsets.only(bottom: 300),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keyboard Test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final editCenter = tester.getCenter(find.byType(TextField));
      expect((editCenter.dx - displayCenter.dx).abs() < 2.0, true);
      expect((editCenter.dy - displayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 10: Responsive Screen Sizes - Small Screen (360x640)', (tester) async {
      const smallSize = Size(360, 640);
      tester.view.physicalSize = smallSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final smallLayer = MovableStoryLayer(
        id: 'layer_small',
        type: LayerType.text,
        text: 'Small Screen',
        offset: const Offset(0.7, 0.3),
        fontSize: 22.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: smallSize,
        initialLayers: [smallLayer],
      ));
      await tester.pumpAndSettle();

      final smallDisplayCenter = tester.getCenter(find.text('Small Screen'));
      await tester.tap(find.text('Small Screen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final smallEditCenter = tester.getCenter(find.byType(TextField));
      expect((smallEditCenter.dx - smallDisplayCenter.dx).abs() < 2.0, true);
      expect((smallEditCenter.dy - smallDisplayCenter.dy).abs() < 2.0, true);
    });

    testWidgets('Case 11: Responsive Screen Sizes - Large Screen (430x932)', (tester) async {
      const largeSize = Size(430, 932);
      tester.view.physicalSize = largeSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final largeLayer = MovableStoryLayer(
        id: 'layer_large',
        type: LayerType.text,
        text: 'Large Screen',
        offset: const Offset(0.3, 0.5),
        fontSize: 26.0,
      );

      await tester.pumpWidget(buildStoryCreatorScreen(
        screenSize: largeSize,
        initialLayers: [largeLayer],
      ));
      await tester.pumpAndSettle();

      final largeDisplayCenter = tester.getCenter(find.text('Large Screen'));
      await tester.tap(find.text('Large Screen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final largeEditCenter = tester.getCenter(find.byType(TextField));
      expect((largeEditCenter.dx - largeDisplayCenter.dx).abs() < 2.0, true);
      expect((largeEditCenter.dy - largeDisplayCenter.dy).abs() < 2.0, true);
    });
  });
}
