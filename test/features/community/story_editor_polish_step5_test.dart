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

  Widget buildStoryCreator({
    List<String> mediaPaths = const ['assets/images/user_profile.png'],
    List<MovableStoryLayer>? initialLayers,
  }) {
    return MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        padding: EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: GetMaterialApp(
        home: StoryCreatorScreen(
          type: StoryType.photo,
          mediaPaths: mediaPaths,
          existingStory: initialLayers != null
              ? StoryItemModel(
                  id: 'step5_test_story',
                  type: StoryType.photo,
                  mediaUrl: mediaPaths.first,
                  timeAgo: 'Just now',
                  createdAt: DateTime.now(),
                  layers: initialLayers,
                )
              : null,
        ),
      ),
    );
  }

  group('Story Editor Step 5 Polish & Invariance Tests', () {
    testWidgets('Requirement 1: Tapping Text tool opens full-screen text editor', (tester) async {
      await tester.pumpWidget(buildStoryCreator());
      await tester.pumpAndSettle();

      final textTool = find.byTooltip('Text');
      expect(textTool, findsOneWidget);

      await tester.tap(textTool);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Start typing...'), findsOneWidget);
    });

    testWidgets('Requirement 2: Plain text with bgStyle == none has zero box border and renders cleanly', (tester) async {
      final plainTextLayer = MovableStoryLayer(
        id: 'plain_text_1',
        type: LayerType.text,
        text: 'Hello GenLink',
        bgStyle: TextBgStyle.none,
        color: Colors.white,
        offset: const Offset(0.5, 0.5),
        fontSize: 28.0,
      );

      await tester.pumpWidget(buildStoryCreator(initialLayers: [plainTextLayer]));
      await tester.pumpAndSettle();

      expect(find.text('Hello GenLink'), findsOneWidget);

      // Verify that plain text is rendered with text contrast shadow and not a boxed border
      final textWidget = tester.widget<Text>(find.text('Hello GenLink'));
      expect(textWidget.style?.shadows, isNotNull);
      expect(textWidget.style?.shadows!.isNotEmpty, isTrue);
    });

    testWidgets('Requirement 3: Emptying out text on existing layer deletes it cleanly', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final textLayer = MovableStoryLayer(
        id: 'deletable_text',
        type: LayerType.text,
        text: 'Delete Me',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(buildStoryCreator(initialLayers: [textLayer]));
      await tester.pumpAndSettle();

      final textFinder = find.text('Delete Me');
      expect(textFinder, findsOneWidget);

      // Tap on text to edit
      await tester.tap(textFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      // Clear text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '');
      await tester.pump();

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Layer must be deleted cleanly
      expect(find.text('Delete Me'), findsNothing);
    });

    testWidgets('Requirement 4: Delete button in text editor removes existing text layer immediately', (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final textLayer = MovableStoryLayer(
        id: 'trash_text',
        type: LayerType.text,
        text: 'Remove with trash',
        offset: const Offset(0.5, 0.5),
      );

      await tester.pumpWidget(buildStoryCreator(initialLayers: [textLayer]));
      await tester.pumpAndSettle();

      final textFinder = find.text('Remove with trash');
      expect(textFinder, findsOneWidget);

      // Tap to edit
      await tester.tap(textFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      // Find delete button
      final deleteBtn = find.byTooltip('Delete text');
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Remove with trash'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Requirement 5: Top header Done button clears tool/selection and does NOT publish', (tester) async {
      await tester.pumpWidget(buildStoryCreator());
      await tester.pumpAndSettle();

      final controller = Get.find<StoryController>();
      final initialStoryGroupCount = controller.storyGroups.length;

      // Tap top header Done button
      final doneBtn = find.text('Done');
      expect(doneBtn, findsOneWidget);
      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      // Story was NOT published
      expect(controller.storyGroups.length, equals(initialStoryGroupCount));
      expect(controller.isUploading.value, isFalse);
      // Still on creator screen
      expect(find.byType(StoryCreatorScreen), findsOneWidget);
    });

    testWidgets('Requirement 6: Close button on unedited media exits without discard prompt', (tester) async {
      await tester.pumpWidget(buildStoryCreator());
      await tester.pumpAndSettle();

      // Freshly selected media with zero edits
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsWidgets);

      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();

      // "Discard Story?" dialog should NOT appear
      expect(find.text('Discard Story?'), findsNothing);
    });

    testWidgets('Requirement 7: Close button with added text shows Discard Draft dialog', (tester) async {
      await tester.pumpWidget(buildStoryCreator());
      await tester.pumpAndSettle();

      // Add a text layer
      await tester.tap(find.byTooltip('Text'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My new text');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Try to close
      final closeBtn = find.byIcon(Icons.close_rounded);
      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();

      // "Discard Story?" dialog MUST appear
      expect(find.text('Discard Story?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard Draft'), findsOneWidget);

      // Tapping Keep Editing dismisses dialog and keeps editor open
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Story?'), findsNothing);
      expect(find.text('My new text'), findsOneWidget);
    });
  });
}
