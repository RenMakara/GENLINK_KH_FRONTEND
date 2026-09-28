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

  testWidgets(
    'Verify Release to Delete bin is positioned above audience selector without overlap and triggers deletion',
    (tester) async {
      const screenSize = Size(390, 844);
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final textLayer = MovableStoryLayer(
        id: 'test_text_layer',
        type: LayerType.text,
        text: 'Drag Me',
        offset: const Offset(0.5, 0.4),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: screenSize,
            padding: EdgeInsets.only(top: 44, bottom: 34),
          ),
          child: GetMaterialApp(
            home: StoryCreatorScreen(
              type: StoryType.photo,
              mediaPaths: const ['assets/images/user_profile.png'],
              existingStory: StoryItemModel(
                id: 'story_delete_zone_test',
                type: StoryType.photo,
                mediaUrl: 'assets/images/user_profile.png',
                timeAgo: 'Just now',
                createdAt: DateTime.now(),
                layers: [textLayer],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Locate the audience selector (e.g. Public / Friends)
      final audienceFinder = find.text('Public');
      expect(audienceFinder, findsOneWidget);
      final audienceRect = tester.getRect(audienceFinder);

      // Start drag interaction on the layer
      final layerFinder = find.text('Drag Me');
      expect(layerFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(layerFinder));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Measure the position of the delete zone pill
      final deleteZoneFinder = find.text('Drag here to delete');
      expect(deleteZoneFinder, findsOneWidget);
      final deleteZoneRect = tester.getRect(deleteZoneFinder);

      // Verify delete zone is positioned strictly above the audience selector
      // In Flutter, smaller Y coordinate is higher up on screen.
      expect(
        deleteZoneRect.bottom,
        lessThan(audienceRect.top),
        reason:
            'Delete zone bottom (${deleteZoneRect.bottom}) must be strictly above audience selector top (${audienceRect.top}) to prevent overlap',
      );

      // Drag into the delete zone threshold
      await gesture.moveTo(const Offset(195, 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // When hovering over the delete zone, it turns into "Release to Delete"
      expect(find.text('Release to Delete'), findsOneWidget);

      // Release finger over delete zone
      await gesture.up();
      await tester.pumpAndSettle();

      // Layer should be deleted
      expect(find.byKey(const ValueKey('test_text_layer')), findsNothing);
    },
  );
}
