import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/levelup/levelup_screen.dart';
import 'package:genlink_frontend/features/levelup/widget/grow_section_widget.dart';
import 'package:genlink_frontend/features/levelup/widget/levelup_widget.dart';
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
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
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
            userId: 'user-ren',
            fullName: 'Ren Makara',
            level: 1,
            totalXp: 95,
          ),
          todayProgress: TodayProgress(
            habitsCompletedToday: 1,
            habitsTotal: 1,
            tasksCompleted: 1,
            tasksTotal: 1,
          ),
          dailyChallenge: ChallengePreview(
            challengeId: 'ch-1',
            title: 'Practice Focus Session',
            description: 'Complete 25 minutes of deep work to level up.',
            xpReward: 30,
          ),
        );
  }

  late final HomeEntity _stub;

  @override
  Future<HomeEntity> getHome() async => _stub;

  @override
  Future<List<HabitItemEntity>> getHabits() async => [];

  @override
  Future<HabitItemEntity> checkInHabit(String habitId, bool completed) async {
    return HabitItemEntity(
      habitId: habitId,
      title: 'Habit',
      checkedInToday: completed,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HomeEntity _createMockHome({
  int level = 1,
  int totalXp = 95,
  int habitsDone = 1,
  int habitsTotal = 1,
  int tasksDone = 1,
  int tasksTotal = 1,
}) {
  return HomeEntity(
    user: HomeUser(
      userId: 'user-ren',
      fullName: 'Ren Makara',
      level: level,
      totalXp: totalXp,
    ),
    todayProgress: TodayProgress(
      habitsCompletedToday: habitsDone,
      habitsTotal: habitsTotal,
      tasksCompleted: tasksDone,
      tasksTotal: tasksTotal,
    ),
    dailyChallenge: const ChallengePreview(
      challengeId: 'ch-1',
      title: 'Practice Focus Session',
      description: 'Complete 25 minutes of deep work to level up.',
      xpReward: 30,
    ),
  );
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
    'LevelUpScreen renders complete new architecture in order without duplicated list',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository(
        stubData: _createMockHome(
          level: 1,
          totalXp: 95,
          habitsDone: 1,
          habitsTotal: 1,
          tasksDone: 1,
          tasksTotal: 1,
        ),
      );
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Level Up'), findsOneWidget);
      expect(find.textContaining('Welcome, Ren'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

      // 2. Calendar / Day Selector
      expect(find.byType(GrowthDateCard), findsOneWidget);
      expect(find.text('View day details'), findsOneWidget);
      expect(
        find.text("Select a date to view that day's activities"),
        findsOneWidget,
      );

      // 3. Level & XP Card
      expect(find.byType(LevelProgressCard), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('95 / 100 XP'), findsOneWidget);
      expect(find.text('Only 5 XP to Level 2'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);

      // 4. Today's Progress (Compact Summary)
      expect(find.byType(GrowthTodayProgressCard), findsOneWidget);
      expect(find.text("TODAY'S PROGRESS"), findsOneWidget);
      expect(find.text('Daily goal completed'), findsOneWidget);
      expect(find.text('2 / 2 activities completed'), findsOneWidget);
      expect(find.text('+25 XP earned'), findsOneWidget);
      expect(find.text('100%'), findsWidgets);

      // Verify duplicated activity list is NOT rendered on main screen
      expect(find.byType(GrowthTodayChecklist), findsNothing);
      expect(find.text("TODAY'S JOURNEY"), findsNothing);

      // 5. Grow Section (3x2 grid)
      expect(find.byType(GrowSectionWidget), findsOneWidget);
      expect(find.text('GROW'), findsOneWidget);
      expect(find.text('Explore all'), findsOneWidget);
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Habits'), findsWidgets);
      expect(find.text('Goals'), findsWidgets);
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Quiz'), findsWidgets);
      expect(find.text('Leaderboard'), findsWidgets);

      // 6. Your Next Move
      expect(find.text('YOUR NEXT MOVE'), findsOneWidget);
      expect(find.text('Practice Focus Session'), findsOneWidget);
      expect(find.text('+30 XP'), findsOneWidget);
    },
  );

  testWidgets(
    'GrowthTodayProgressCard dynamically displays partial progress state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1 of 3 activities done (1 habit done, 2 tasks total, 0 tasks done) -> 33%
      final mockRepo = MockHomeRepository(
        stubData: _createMockHome(
          habitsDone: 1,
          habitsTotal: 1,
          tasksDone: 0,
          tasksTotal: 2,
        ),
      );
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GrowthTodayProgressCard), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('1 / 3 activities'), findsOneWidget);
      expect(find.text('+10 XP earned'), findsOneWidget);
      expect(find.text('33%'), findsWidgets);
    },
  );

  testWidgets(
    'GrowthTodayProgressCard dynamically displays empty progress state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository(
        stubData: _createMockHome(
          habitsDone: 0,
          habitsTotal: 0,
          tasksDone: 0,
          tasksTotal: 0,
        ),
      );
      Get.put(HomeController(repository: mockRepo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LevelUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GrowthTodayProgressCard), findsOneWidget);
      expect(find.text('Start your day'), findsOneWidget);
      expect(find.text('0 / 0 activities'), findsOneWidget);
      expect(find.text('+0 XP earned'), findsOneWidget);
      expect(find.text('0%'), findsWidgets);
    },
  );

  testWidgets(
    'LevelUpScreen supports Dark Mode with high contrast and proper cards',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository(stubData: _createMockHome());
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

      expect(find.byType(GrowthTodayProgressCard), findsOneWidget);
      expect(find.byType(LevelProgressCard), findsOneWidget);
      expect(find.byType(GrowSectionWidget), findsOneWidget);
    },
  );

  testWidgets(
    'LevelUpScreen localizes in Khmer locale without RenderFlex errors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHomeRepository(stubData: _createMockHome());
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
      expect(find.text('វឌ្ឍនភាពថ្ងៃនេះ'), findsOneWidget);
      expect(find.text('លូតលាស់'), findsOneWidget);
      expect(find.text('ជំហានបន្ទាប់របស់អ្នក'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
