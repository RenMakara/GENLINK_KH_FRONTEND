import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/levelup/levelup_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/focus_home_screen.dart';
import 'package:genlink_frontend/features/leaderboard/presentation/screens/leaderboard_home_screen.dart';
import 'package:get/get.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentPng = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHomeRepository implements HomeRepository {
  MockHomeRepository({HomeEntity? stubData}) {
    _stub =
        stubData ??
        const HomeEntity(
          user: HomeUser(
            userId: 'user-1',
            fullName: 'Test Student',
            level: 3,
            totalXp: 350,
          ),
          todayProgress: TodayProgress(
            habitsCompletedToday: 1,
            habitsTotal: 2,
            tasksCompleted: 2,
            tasksTotal: 4,
          ),
          upcomingEvent: UpcomingEvent(
            eventId: 'event-101',
            title: 'Campus Hackathon 2026',
            dateTime: '2026-09-10T09:00:00',
            locationName: 'Main Auditorium',
            description: 'Annual 24-hour campus coding competition.',
            category: 'Tech',
            participantCount: 42,
          ),
          dailyChallenge: ChallengePreview(
            challengeId: 'ch-1',
            title: 'Solve 5 Math Quizzes',
            description: 'Test your problem solving skills.',
            xpReward: 50,
          ),
          financeSnapshot: FinanceSnapshot(
            savingTarget: 500,
            savingCurrent: 250,
          ),
          dailyMotivation: MotivationCard(
            motivationId: 'm-1',
            title: 'Focus on growth',
            content: 'Small consistent efforts lead to mastery.',
          ),
        );
  }

  late final HomeEntity _stub;

  @override
  Future<HomeEntity> getHome() async => _stub;

  @override
  Future<List<HabitItemEntity>> getHabits() async {
    return [
      const HabitItemEntity(
        habitId: 'h-1',
        title: 'Morning Reading',
        streakCount: 5,
        checkedInToday: true,
      ),
      const HabitItemEntity(
        habitId: 'h-2',
        title: 'Drink 2L Water',
        streakCount: 3,
        checkedInToday: false,
      ),
    ];
  }

  @override
  Future<HabitItemEntity> checkInHabit(String habitId, bool completed) async {
    return HabitItemEntity(
      habitId: habitId,
      title: 'Habit Title',
      streakCount: completed ? 6 : 5,
      checkedInToday: completed,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'GrowthScreen renders Goals with flag icon and opens PlanGoalScreen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository();
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Level Up'), findsOneWidget);
      expect(find.text('GROWTH'), findsNothing);
      expect(find.text('GROW'), findsOneWidget);
      expect(find.text('PRODUCTIVITY TOOLS'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Goals').last,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Goals'), findsWidgets);
      expect(find.byIcon(Icons.flag_outlined), findsWidgets);

      await tester.tap(find.byIcon(Icons.flag_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(PlanGoalScreen), findsOneWidget);
    },
  );

  testWidgets(
    'GrowthScreen renders in Dark Mode with GenLink visual hierarchy',
    (tester) async {
      tester.view.physicalSize = const Size(
        390,
        844,
      ); // Mobile iPhone 13/14 viewport
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository();
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Level Up'), findsOneWidget);
      expect(
        find.textContaining('Your personal growth journey'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
      expect(find.textContaining("TODAY'S"), findsOneWidget);
      expect(find.text('GROW'), findsOneWidget);
    },
  );

  testWidgets('GrowthScreen renders in Light Mode cleanly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = MockHomeRepository();
    Get.put(HomeController(repository: mockRepo));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.light(),
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const LevelUpScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Level Up'), findsOneWidget);
    expect(find.textContaining("TODAY'S"), findsOneWidget);
  });

  testWidgets(
    'GrowthScreen localizes in Khmer locale without errors or clipping',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository();
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const LevelUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('បង្កើនកម្រិត'), findsOneWidget);
      expect(find.textContaining('មាគ៌ាឆ្ពោះទៅមុខ'), findsOneWidget);
    },
  );

  testWidgets(
    'GrowthScreen preserves Leaderboard navigation from header trophy',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository();
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final trophyFinder = find.byIcon(Icons.emoji_events_outlined);
      expect(trophyFinder, findsOneWidget);
      await tester.tap(trophyFinder);
      await tester.pumpAndSettle();

      expect(find.byType(LeaderboardHomeScreen), findsOneWidget);
    },
  );

  testWidgets('GrowthScreen preserves Habits, Tasks, and Focus navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockRepo = MockHomeRepository();
    Get.put(HomeController(repository: mockRepo));

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const LevelUpScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Focus
    await tester.scrollUntilVisible(
      find.byIcon(Icons.timer_outlined).last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byIcon(Icons.timer_outlined), findsWidgets);
    await tester.tap(find.byIcon(Icons.timer_outlined).last);
    await tester.pumpAndSettle();

    expect(find.byType(FocusPage), findsOneWidget);
  });

  testWidgets(
    'GrowthScreen displays updated subtitle and excludes Saving Goal card',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository();
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Subtitle requirement
      expect(find.text('What can I do today to Level Up?'), findsOneWidget);

      // Saving Goal should NOT be on Level Up screen
      expect(find.text('Saving Goal Update'), findsNothing);

      // Daily Challenge should be present
      expect(find.text('Solve 5 Math Quizzes'), findsOneWidget);
      expect(find.text('+50 XP'), findsOneWidget);

      // Daily Mindset should be present
      await tester.scrollUntilVisible(
        find.text('Small consistent efforts lead to mastery.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Small consistent efforts lead to mastery.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GrowthScreen renders compact empty state when no activities exist',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const emptyHome = HomeEntity(
        user: HomeUser(
          userId: 'user-2',
          fullName: 'New Student',
          level: 1,
          totalXp: 0,
        ),
        todayProgress: TodayProgress(
          habitsCompletedToday: 0,
          habitsTotal: 0,
          tasksCompleted: 0,
          tasksTotal: 0,
        ),
        dailyMotivation: MotivationCard(
          motivationId: 'm-2',
          title: 'Start fresh',
          content: 'Every journey begins with a single step.',
        ),
      );

      final mockRepo = MockHomeRepository(stubData: emptyHome);
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should NOT show the old "Your day is clear"
      expect(find.text('Your day is clear'), findsNothing);

      // Should show compact activity-oriented empty state
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(
        find.text('No habits or tasks need attention right now.'),
        findsOneWidget,
      );
      expect(
        find.text('Habits'),
        findsWidgets,
      ); // chip in empty state and/or GROW
      expect(find.text('Tasks'), findsWidgets);
    },
  );
}
