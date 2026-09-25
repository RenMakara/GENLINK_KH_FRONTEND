import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_category_widgets.dart';

void main() {
  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  Widget buildTestableWidget(Widget child, {Size size = const Size(360, 640)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('QuizCategoryCard', () {
    testWidgets('renders category details without overflow on small screen width', (tester) async {
      var tapped = false;
      const category = QuizCategory(
        id: 'FINANCE',
        name: 'Finance & Banking Master',
        icon: 'wallet',
        questionCount: 5,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          SizedBox(
            width: 155, // 2-column cell width on a 360px screen
            height: 84,
            child: QuizCategoryCard(
              category: category,
              onTap: () => tapped = true,
            ),
          ),
          size: const Size(360, 640),
        ),
      );

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Finance & Banking Master'), findsOneWidget);
      expect(find.text('5 Questions'), findsOneWidget);

      await tester.tap(find.byType(QuizCategoryCard));
      expect(tapped, isTrue);
    });

    testWidgets('handles extremely long names gracefully with text truncation', (tester) async {
      const category = QuizCategory(
        id: 'TECH',
        name: 'Very Long Advanced Computer Science Technology And Machine Learning',
        icon: 'laptop',
        questionCount: 42,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          SizedBox(
            width: 135, // Very narrow screen cell
            height: 84,
            child: QuizCategoryCard(
              category: category,
              onTap: () {},
            ),
          ),
          size: const Size(320, 568),
        ),
      );

      // Verify no RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
      expect(find.text('42 Questions'), findsOneWidget);
    });
  });

  group('QuizCategorySearchBar', () {
    testWidgets('triggers callbacks on search change and clear', (tester) async {
      final controller = TextEditingController();
      String query = '';
      var cleared = false;

      await tester.pumpWidget(
        buildTestableWidget(
          QuizCategorySearchBar(
            controller: controller,
            onChanged: (val) => query = val,
            onClear: () {
              cleared = true;
              controller.clear();
            },
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Finance');
      expect(query, 'Finance');

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(cleared, isTrue);
    });
  });

  group('QuizRecentlyPlayedCard', () {
    testWidgets('renders real data and handles continue tap', (tester) async {
      var continued = false;
      const category = QuizCategory(
        id: 'FINANCE',
        name: 'Finance',
        icon: 'wallet',
        questionCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          QuizRecentlyPlayedCard(
            category: category,
            onContinue: () => continued = true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('3 Questions'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      expect(continued, isTrue);
    });
  });

  group('QuizEmptyRecentlyPlayedCard', () {
    testWidgets('renders empty state messages', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const QuizEmptyRecentlyPlayedCard(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No quizzes played yet.'), findsOneWidget);
      expect(find.text('Start your first quiz to see it here.'), findsOneWidget);
    });
  });

  group('QuizMultiplayerChallengeCard', () {
    testWidgets('renders 1v1 multiplayer challenge card', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const QuizMultiplayerChallengeCard(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Challenge your friends!'), findsOneWidget);
      expect(find.text("Play 1v1 quizzes and see who's smarter."), findsOneWidget);
    });
  });
}
