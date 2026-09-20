import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_gallery_screen.dart';
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

  group('Story Creator Multi-Image Selection & Gallery Tests', () {
    testWidgets('Test 1: Search icon is removed from Camera roll subheader', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camera roll'), findsOneWidget);
      expect(find.text('Select multiple'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsNothing);
      expect(find.byTooltip('Search photos'), findsNothing);
    });

    testWidgets('Test 2: Permission state - shows Allow Photos and handles permission toggle', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = false;
      galleryController.isPermanentlyDenied.value = false;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos permission needed'), findsOneWidget);
      expect(find.text('Allow Photos'), findsOneWidget);

      galleryController.hasPermission.value = true;
      await tester.pumpAndSettle();

      expect(find.text('Photos permission needed'), findsNothing);
    });

    testWidgets('Test 3: Select multiple toggle mode updates button label and state', (tester) async {
      final galleryController = Get.put(StoryGalleryController());
      galleryController.hasPermission.value = true;
      galleryController.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryGalleryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select multiple'), findsOneWidget);

      await tester.tap(find.text('Select multiple'));
      await tester.pumpAndSettle();

      expect(galleryController.isMultiSelectMode.value, true);

      await tester.tap(find.text('Select multiple'));
      await tester.pumpAndSettle();

      expect(galleryController.isMultiSelectMode.value, false);
    });

    testWidgets('Test 4: Single image passed to StoryCreatorScreen initializes as canvas background', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: ['assets/images/user_profile.png'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);
      expect(find.byTooltip('Duplicate'), findsNothing);
    });

    testWidgets('Test 5: Multiple images passed to StoryCreatorScreen are initialized as independent movable layers', (tester) async {
      final multiplePaths = [
        'assets/images/user_profile.png',
        'assets/images/user_profile.png',
        'assets/images/user_profile.png',
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.photo,
            mediaPaths: multiplePaths,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageLayers = find.byWidgetPredicate(
        (w) => w is Positioned && w.key != null && (w.key as ValueKey).value.toString().startsWith('image_'),
      );
      expect(imageLayers, findsNWidgets(3));
      expect(find.descendant(of: imageLayers, matching: find.byType(ClipRRect)), findsNothing);

      await tester.tap(imageLayers.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Duplicate'), findsNothing);
      expect(find.byTooltip('Delete'), findsNothing);

      expect(find.text('Post Story'), findsOneWidget);
    });

    testWidgets('Test 6: Publishing multiple image story succeeds and unwinds stack', (tester) async {
      final multiplePaths = [
        'assets/images/user_profile.png',
        'assets/images/user_profile.png',
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(name: '/home', page: () => const Scaffold(body: Text('Home Feed'))),
            GetPage(
              name: '/StoryCreatorScreen',
              page: () => StoryCreatorScreen(
                type: StoryType.photo,
                mediaPaths: multiplePaths,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/StoryCreatorScreen');
      await tester.pumpAndSettle();

      expect(find.text('Post Story'), findsOneWidget);

      await tester.tap(find.text('Post Story'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Home Feed'), findsOneWidget);
    });
  });
}
