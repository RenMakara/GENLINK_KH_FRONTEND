import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/community/data/datasources/demo_community_data_provider.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/quick_create_post_card.dart';
import 'package:genlink_frontend/main_controller.dart';
import 'package:genlink_frontend/main_screen.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put<MainController>(MainController());
    Get.put<CommunityController>(CommunityController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestApp({Widget? home, Locale? locale}) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale ?? LocalizationService.englishLocale,
      fallbackLocale: LocalizationService.englishLocale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: home ?? const MainScreen(),
    );
  }

  testWidgets(
    'FadeIndexedStack preserves page state and text input when switching tabs',
    (tester) async {
      int activeIndex = 0;
      final textController = TextEditingController();

      await tester.pumpWidget(
        createTestApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: FadeIndexedStack(
                  index: activeIndex,
                  children: [
                    TextField(
                      key: const ValueKey('tab_0_field'),
                      controller: textController,
                    ),
                    const Text('LevelUp Tab Page', key: ValueKey('tab_1_text')),
                  ],
                ),
                bottomNavigationBar: Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => activeIndex = 0),
                      child: const Text('Tab 0'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => activeIndex = 1),
                      child: const Text('Tab 1'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('tab_0_field')),
        'Preserved form state',
      );
      expect(textController.text, 'Preserved form state');

      await tester.tap(find.text('Tab 1'));
      await tester.pumpAndSettle();
      expect(find.text('LevelUp Tab Page'), findsOneWidget);

      await tester.tap(find.text('Tab 0'));
      await tester.pumpAndSettle();

      expect(textController.text, 'Preserved form state');
      expect(find.byKey(const ValueKey('tab_0_field')), findsOneWidget);
    },
  );

  testWidgets('QuickCreatePostCard triggers callbacks with tactile feedback', (
    tester,
  ) async {
    bool postTapped = false;
    bool discussionTapped = false;
    bool eventTapped = false;

    await tester.pumpWidget(
      createTestApp(
        home: Scaffold(
          body: QuickCreatePostCard(
            onTapPost: () => postTapped = true,
            onTapDiscussion: () => discussionTapped = true,
            onTapEvent: () => eventTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.image_outlined));
    await tester.pumpAndSettle();
    expect(postTapped, isTrue);

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(discussionTapped, isTrue);

    await tester.tap(find.byIcon(Icons.add_box_outlined));
    await tester.pumpAndSettle();
    expect(eventTapped, isTrue);
  });

  testWidgets(
    'Demo posts follow structured Feed sequence: Normal -> Discussion -> Event -> Normal -> Discussion',
    (tester) async {
      final posts = DemoCommunityDataProvider.getDay15DemoPosts();
      expect(posts.length, greaterThanOrEqualTo(5));

      expect(posts[0].postType, isNull);
      expect(posts[0].attachedEvent, isNull);
      expect(posts[0].content, contains('Flutter workshop was amazing'));

      expect(posts[1].postType, 'DISCUSSION');
      expect(
        posts[1].discussionTitle,
        contains('structure a large Flutter application'),
      );

      expect(posts[2].postType, 'event');
      expect(posts[2].attachedEvent, isNotNull);
      expect(posts[2].attachedEvent!.title, 'Flutter Workshop 2026');

      expect(posts[3].content, contains('Tech in Banking'));

      expect(posts[4].postType, 'DISCUSSION');
      expect(
        posts[4].discussionTitle,
        contains('software engineering internship'),
      );
    },
  );

  testWidgets(
    'PostCardWidget renders Joined with check when attached event is RSVPed',
    (tester) async {
      final controller = Get.find<CommunityController>();
      final posts = DemoCommunityDataProvider.getDay15DemoPosts();
      final eventPost = posts[2];

      eventPost.attachedEvent!.isRsvped = true;

      await tester.pumpWidget(
        createTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(post: eventPost, controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Joined ✓'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'FadeIndexedStack uses FadeTransition and has no Transform.scale warping',
    (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: FadeIndexedStack(
                  index: activeIndex,
                  children: const [
                    Text('Page Home', key: ValueKey('page_home')),
                    Text('Page LevelUp', key: ValueKey('page_levelup')),
                    Text('Page Finance', key: ValueKey('page_finance')),
                    Text('Page Profile', key: ValueKey('page_profile')),
                  ],
                ),
                bottomNavigationBar: Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => activeIndex = 0),
                      child: const Text('Tab 0'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => activeIndex = 1),
                      child: const Text('Tab 1'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => activeIndex = 2),
                      child: const Text('Tab 2'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => activeIndex = 3),
                      child: const Text('Tab 3'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page Home'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FadeIndexedStack),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(FadeIndexedStack),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );

      // Switch to Tab 1 (LevelUp)
      await tester.tap(find.text('Tab 1'));
      // Pump 100ms (halfway through 200ms transition)
      await tester.pump(const Duration(milliseconds: 100));
      // Verify no scale transform inside FadeIndexedStack during animation
      expect(
        find.descendant(
          of: find.byType(FadeIndexedStack),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      // Settle transition
      await tester.pumpAndSettle();
      expect(find.text('Page LevelUp'), findsOneWidget);

      // Switch to Tab 2 (Finance)
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();
      expect(find.text('Page Finance'), findsOneWidget);

      // Switch to Tab 3 (Profile)
      await tester.tap(find.text('Tab 3'));
      await tester.pumpAndSettle();
      expect(find.text('Page Profile'), findsOneWidget);

      // Switch back to Tab 0 (Home)
      await tester.tap(find.text('Tab 0'));
      await tester.pumpAndSettle();
      expect(find.text('Page Home'), findsOneWidget);
    },
  );
}
