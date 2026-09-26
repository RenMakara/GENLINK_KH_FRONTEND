import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_creation_bottom_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_creation_flow.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/quick_create_post_card.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('CommunityCreationBottomSheet Widget Tests', () {
    testWidgets('renders Create Post, Create Story, and Create Event options', (
      tester,
    ) async {
      bool postSelected = false;
      bool storySelected = false;
      bool eventSelected = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: CommunityCreationBottomSheet(
              onSelectCreatePost: () => postSelected = true,
              onSelectCreateStory: () => storySelected = true,
              onSelectCreateEvent: () => eventSelected = true,
            ),
          ),
        ),
      );

      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Create Post'), findsOneWidget);
      expect(find.text('Create Story'), findsOneWidget);
      expect(find.text('Create Event'), findsOneWidget);

      expect(find.byIcon(Icons.post_add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.amp_stories_rounded), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);

      await tester.tap(find.text('Create Post'));
      await tester.pumpAndSettle();
      expect(postSelected, isTrue);

      await tester.tap(find.text('Create Story'));
      await tester.pumpAndSettle();
      expect(storySelected, isTrue);

      await tester.tap(find.text('Create Event'));
      await tester.pumpAndSettle();
      expect(eventSelected, isTrue);
    });
  });

  group('QuickCreatePostCard Widget Tests', () {
    testWidgets('renders compact share composer with prompt and action icons', (
      tester,
    ) async {
      bool textTapped = false;
      bool photoTapped = false;
      bool cameraTapped = false;
      bool moreTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: QuickCreatePostCard(
              onTap: () => textTapped = true,
              onTapPhoto: () => photoTapped = true,
              onTapCamera: () => cameraTapped = true,
              onTapMore: () => moreTapped = true,
            ),
          ),
        ),
      );

      expect(find.text("What's on your mind?"), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

      await tester.tap(find.text("What's on your mind?"));
      await tester.pumpAndSettle();
      expect(textTapped, isTrue);

      await tester.tap(find.byIcon(Icons.image_outlined));
      await tester.pumpAndSettle();
      expect(photoTapped, isTrue);

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pumpAndSettle();
      expect(cameraTapped, isTrue);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(moreTapped, isTrue);
    });

    testWidgets('renders user avatar fallback when userName is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: QuickCreatePostCard(userName: 'Sokny')),
        ),
      );

      expect(find.text("What's on your mind?"), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
    });
  });

  group('CommunityCreationFlow Tests', () {
    testWidgets(
      'openCreateMenu displays bottom sheet with 3 creation actions',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      CommunityCreationFlow.openCreateMenu(context),
                  child: const Text('Open Menu'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Menu'));
        await tester.pumpAndSettle();

        expect(find.byType(CommunityCreationBottomSheet), findsOneWidget);
        expect(find.text('Create Post'), findsOneWidget);
        expect(find.text('Create Story'), findsOneWidget);
        expect(find.text('Create Event'), findsOneWidget);
      },
    );
  });
}
