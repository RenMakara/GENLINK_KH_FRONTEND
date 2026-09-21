import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/levelup/widget/grow_section_widget.dart';
import 'package:get/get.dart';

void main() {
  Widget buildTestWidget({
    Locale locale = const Locale('en'),
    ThemeData? theme,
    VoidCallback? onTasksTap,
    VoidCallback? onHabitsTap,
    VoidCallback? onGoalsTap,
    VoidCallback? onFocusTap,
    VoidCallback? onQuizTap,
    VoidCallback? onLeaderboardTap,
    VoidCallback? onExploreAllTap,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GrowSectionWidget(
              onTasksTap: onTasksTap,
              onHabitsTap: onHabitsTap,
              onGoalsTap: onGoalsTap,
              onFocusTap: onFocusTap,
              onQuizTap: onQuizTap,
              onLeaderboardTap: onLeaderboardTap,
              onExploreAllTap: onExploreAllTap,
            ),
          ),
        ),
      ),
    );
  }

  group('GrowSectionWidget Tests', () {
    testWidgets('renders header GROW and Explore all > in English', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GROW'), findsOneWidget);
      expect(find.text('Explore all'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });

    testWidgets('renders all 6 gamified soft 3D feature cards with icons and subtitles',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Titles
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Habits'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);

      // Subtitles
      expect(find.text('Get things done\nand earn XP'), findsOneWidget);
      expect(find.text('Build better you\nday by day'), findsOneWidget);
      expect(find.text('Turn dreams into\nreality'), findsOneWidget);
      expect(find.text('Stay in the zone\nand be productive'), findsOneWidget);
      expect(find.text('Test your knowledge\nand earn XP'), findsOneWidget);
      expect(find.text('See who scores\nhighest in GenLink'), findsOneWidget);

      // Soft 3D Icons
      expect(find.byType(Soft3DTasksIcon), findsOneWidget);
      expect(find.byType(Soft3DHabitsIcon), findsOneWidget);
      expect(find.byType(Soft3DGoalsIcon), findsOneWidget);
      expect(find.byType(Soft3DFocusIcon), findsOneWidget);
      expect(find.byType(Soft3DQuizIcon), findsOneWidget);
      expect(find.byType(Soft3DLeaderboardIcon), findsOneWidget);

      // Exactly 6 cards
      expect(find.byType(GrowFeatureCard), findsNWidgets(6));
    });

    testWidgets('triggers callbacks when cards and explore all are tapped',
        (tester) async {
      bool tasksTapped = false;
      bool habitsTapped = false;
      bool goalsTapped = false;
      bool focusTapped = false;
      bool quizTapped = false;
      bool leaderboardTapped = false;
      bool exploreAllTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onTasksTap: () => tasksTapped = true,
          onHabitsTap: () => habitsTapped = true,
          onGoalsTap: () => goalsTapped = true,
          onFocusTap: () => focusTapped = true,
          onQuizTap: () => quizTapped = true,
          onLeaderboardTap: () => leaderboardTapped = true,
          onExploreAllTap: () => exploreAllTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Explore all
      await tester.tap(find.text('Explore all'));
      await tester.pumpAndSettle();
      expect(exploreAllTapped, isTrue);

      // Tap Tasks
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(tasksTapped, isTrue);

      // Tap Habits
      await tester.tap(find.text('Habits'));
      await tester.pumpAndSettle();
      expect(habitsTapped, isTrue);

      // Tap Goals
      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();
      expect(goalsTapped, isTrue);

      // Tap Focus
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();
      expect(focusTapped, isTrue);

      // Tap Quiz
      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();
      expect(quizTapped, isTrue);

      // Tap Leaderboard
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(leaderboardTapped, isTrue);
    });

    testWidgets('renders cleanly in Khmer locale without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('km', 'KH'),
        ),
      );
      await tester.pumpAndSettle();

      // Khmer Header
      expect(find.text('លូតលាស់'), findsOneWidget);
      expect(find.text('រុករកទាំងអស់'), findsOneWidget);

      // Khmer Titles
      expect(find.text('ភារកិច្ច'), findsOneWidget);
      expect(find.text('ទម្លាប់'), findsOneWidget);
      expect(find.text('គោលដៅ'), findsOneWidget);
      expect(find.text('ផ្តោតអារម្មណ៍'), findsOneWidget);
      expect(find.text('កម្រងសំណួរ'), findsOneWidget);
      expect(find.text('តារាងពិន្ទុ'), findsOneWidget);

      // Khmer Subtitles
      expect(find.text('សម្រេចការងារ\nនិងទទួលបាន XP'), findsOneWidget);
      expect(find.text('កសាងខ្លួនឯង\nពីមួយថ្ងៃទៅមួយថ្ងៃ'), findsOneWidget);
      expect(find.text('ប្រែក្លាយក្តីស្រមៃ\nទៅជាការពិត'), findsOneWidget);
      expect(find.text('រក្សាការផ្តោតអារម្មណ៍\nនិងបង្កើនផលិតភាព'), findsOneWidget);
      expect(find.text('សាកល្បងចំណេះដឹង\nនិងទទួលបាន XP'), findsOneWidget);
      expect(find.text('មើលអ្នកដែលរកពិន្ទុបាន\nខ្ពស់ជាងគេក្នុង GenLink'), findsOneWidget);

      // Verify no overflow or render exception occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in Dark Mode cleanly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GrowSectionWidget), findsOneWidget);
      expect(find.byType(GrowFeatureCard), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });
  });
}
