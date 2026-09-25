import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_match_models.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_multiplayer_widgets.dart';

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

  group('MultiplayerHeader', () {
    testWidgets('renders title, subtitle, and responds to back tap', (tester) async {
      var backPressed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          MultiplayerHeader(
            onBack: () => backPressed = true,
            title: '1v1 Multiplayer Quiz',
            subtitle: 'Challenge a friend',
            showTrophy: true,
          ),
        ),
      );

      expect(find.text('1v1 Multiplayer Quiz'), findsOneWidget);
      expect(find.text('Challenge a friend'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(backPressed, isTrue);
    });

    testWidgets('responds to trophy tap and supports custom actions', (tester) async {
      var trophyTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          MultiplayerHeader(
            onBack: () {},
            title: '1v1 Multiplayer Quiz',
            showTrophy: true,
            onTrophyTap: () => trophyTapped = true,
            actions: const [Icon(Icons.more_vert)],
          ),
        ),
      );

      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.tap(find.byIcon(Icons.emoji_events_rounded));
      expect(trophyTapped, isTrue);
    });
  });

  group('MultiplayerQuizSearchBar', () {
    testWidgets('triggers onChanged and onClear callbacks', (tester) async {
      final controller = TextEditingController();
      String query = '';
      var cleared = false;

      await tester.pumpWidget(
        buildTestableWidget(
          MultiplayerQuizSearchBar(
            controller: controller,
            onChanged: (val) => query = val,
            onClear: () {
              cleared = true;
              controller.clear();
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Money');
      expect(query, 'Money');

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      expect(cleared, isTrue);
    });
  });

  group('MultiplayerCategoryFilterChips', () {
    testWidgets('renders category chips and triggers selection callback', (tester) async {
      String selected = 'ALL';
      const categories = [
        QuizCategory(id: 'FINANCE', name: 'Finance', icon: 'wallet', questionCount: 3),
        QuizCategory(id: 'TECH', name: 'Technology', icon: 'laptop', questionCount: 4),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          MultiplayerCategoryFilterChips(
            categories: categories,
            selectedCategoryId: selected,
            onCategorySelected: (catId) => selected = catId,
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);

      await tester.tap(find.text('Finance'));
      expect(selected, 'FINANCE');
    });
  });

  group('MultiplayerQuizCard', () {
    testWidgets('renders quiz card details without overflow on small screens', (tester) async {
      var tapped = false;
      const quiz = QuizSummary(
        quizId: 'quiz-1',
        title: 'Money Basics and Long Finance Principles',
        category: 'FINANCE',
        difficulty: 'EASY',
        xpReward: 30,
        questionCount: 3,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MultiplayerQuizCard(
            quiz: quiz,
            onTap: () => tapped = true,
          ),
          size: const Size(320, 568),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Money Basics and Long Finance Principles'), findsOneWidget);
      expect(find.textContaining('3 Questions'), findsOneWidget);
      expect(find.textContaining('30 XP'), findsOneWidget);

      await tester.tap(find.byType(MultiplayerQuizCard));
      expect(tapped, isTrue);
    });
  });

  group('MultiplayerMatchupHero', () {
    const testUser = UserEntity(
      id: 'user-1',
      fullName: 'Sophea Kim',
      username: 'sophea',
      email: 'sophea@genlink.kh',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 500,
      level: 3,
      preferredLanguage: 'ENGLISH',
      role: 'USER',
      active: true,
    );

    testWidgets('renders searching state with unknown opponent and user level', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MultiplayerMatchupHero(
            currentUser: testUser,
            opponent: null,
            isSearching: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('Finding an opponent...'), findsOneWidget);
      expect(find.text('???'), findsOneWidget);
      expect(find.byIcon(Icons.question_mark_rounded), findsOneWidget);
    });

    testWidgets('renders matched state with real opponent data', (tester) async {
      const opponent = QuizMatchPlayer(
        id: 'opp-1',
        name: 'Dara Chan',
        score: 0,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const MultiplayerMatchupHero(
            currentUser: testUser,
            opponent: opponent,
            isSearching: false,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Dara Chan'), findsOneWidget);
      expect(find.text('Opponent'), findsOneWidget);
      expect(find.byIcon(Icons.question_mark_rounded), findsNothing);
    });
  });

  group('MultiplayerFeatureHighlightsRow & CancelMatchButton', () {
    testWidgets('renders highlights and cancel match button with tap response', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              const MultiplayerFeatureHighlightsRow(),
              const SizedBox(height: 12),
              const MultiplayerDidYouKnowCard(),
              const SizedBox(height: 12),
              CancelMatchButton(onCancel: () => cancelled = true),
            ],
          ),
          size: const Size(360, 640),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Real-time'), findsOneWidget);
      expect(find.text('Fair Match'), findsOneWidget);
      expect(find.text('Safe & Fun'), findsOneWidget);
      expect(find.text('Did you know?'), findsOneWidget);
      expect(find.text('Cancel Match'), findsOneWidget);

      await tester.tap(find.text('Cancel Match'));
      expect(cancelled, isTrue);
    });
  });

  group('MultiplayerScoreboard', () {
    testWidgets('renders player and opponent names and scores with VS badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MultiplayerScoreboard(
            currentUserName: 'You',
            playerScore: 10,
            opponentName: 'Ren Makara',
            opponentScore: 20,
            highlightWinner: true,
            isWinner: false,
          ),
          size: const Size(360, 200),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });
  });

  group('MultiplayerProgressAndTimer', () {
    testWidgets('renders progress text, track, and countdown timer seconds', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MultiplayerProgressAndTimer(
            currentIndex: 0,
            totalQuestions: 3,
            timeRemaining: 11,
            totalDuration: 15,
          ),
          size: const Size(360, 100),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.text('11 s'), findsOneWidget);
    });
  });

  group('MultiplayerQuestionCard & MultiplayerOptionTile & MultiplayerSubmitButton', () {
    testWidgets('renders question, options, and handles selection and submission', (tester) async {
      var selectedId = 'opt-1';
      var submitted = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              const MultiplayerQuestionCard(
                category: 'Money Basics',
                question: 'What is a budget?',
              ),
              MultiplayerOptionTile(
                label: 'A plan for your income and spending',
                index: 0,
                isSelected: selectedId == 'opt-1',
                onTap: () => selectedId = 'opt-1',
              ),
              MultiplayerOptionTile(
                label: 'A type of bank account',
                index: 1,
                isSelected: selectedId == 'opt-2',
                onTap: () => selectedId = 'opt-2',
              ),
              MultiplayerSubmitButton(
                isEnabled: true,
                onSubmit: () => submitted = true,
              ),
            ],
          ),
          size: const Size(360, 600),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Money Basics'), findsOneWidget);
      expect(find.text('What is a budget?'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('A plan for your income and spending'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget);

      await tester.tap(find.text('Submit Answer'));
      expect(submitted, isTrue);
    });
  });

  group('MultiplayerResultBanner & MultiplayerXpCard & MultiplayerMotivationalCard', () {
    testWidgets('renders celebratory trophy, XP reward, and motivational card', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Column(
            children: [
              MultiplayerResultBanner(isWinner: true, isTie: false),
              MultiplayerXpCard(xp: 50),
              MultiplayerMotivationalCard(),
            ],
          ),
          size: const Size(360, 640),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('You won the match!'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);
      expect(find.text('Keep Going!'), findsOneWidget);
    });
  });
}

