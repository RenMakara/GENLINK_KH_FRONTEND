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
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/features/challenge/domain/models/challenge_models.dart';
import 'package:genlink_frontend/features/productivity/presentation/habit_feature/habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/task_feature/task_home_screen.dart';
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
  ChallengePreview? dailyChallenge,
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
    dailyChallenge: dailyChallenge ??
        const ChallengePreview(
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

  group('Smart Direct Action for YOUR NEXT MOVE', () {
    testWidgets(
      'Test 1 — Habit challenge (type = HABIT) navigates to HabitHomeScreen',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockHomeRepository(
          stubData: _createMockHome(
            dailyChallenge: const ChallengePreview(
              challengeId: 'f0000000-0000-4000-8000-000000000001',
              title: 'Check in on a habit',
              description: 'Complete one habit check-in today.',
              xpReward: 15,
              type: 'HABIT',
              challengeType: ChallengeType.habit,
            ),
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

        expect(find.text('YOUR NEXT MOVE'), findsOneWidget);
        expect(find.text('Check in on a habit'), findsOneWidget);

        await tester.tap(find.widgetWithText(GrowthActionCard, 'Check in on a habit'));
        await tester.pumpAndSettle();

        expect(find.byType(HabitHomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2 — Task challenge (type = TASK) navigates to TasksPage',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockHomeRepository(
          stubData: _createMockHome(
            dailyChallenge: const ChallengePreview(
              challengeId: 'f0000000-0000-4000-8000-000000000004',
              title: 'Complete today task',
              description: 'Finish at least one task on your list.',
              xpReward: 20,
              type: 'TASK',
              challengeType: ChallengeType.task,
            ),
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

        expect(find.text('YOUR NEXT MOVE'), findsOneWidget);
        expect(find.text('Complete today task'), findsOneWidget);

        await tester.tap(find.widgetWithText(GrowthActionCard, 'Complete today task'));
        await tester.pumpAndSettle();

        expect(find.byType(TasksPage), findsOneWidget);
      },
    );

    testWidgets(
      'Test 3 — Quiz challenge (type = QUIZ) navigates to quizDashboard',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockHomeRepository(
          stubData: _createMockHome(
            dailyChallenge: const ChallengePreview(
              challengeId: 'f0000000-0000-4000-8000-000000000002',
              title: 'Take a quiz',
              description: 'Finish any quiz and see your score.',
              xpReward: 20,
              type: 'QUIZ',
              challengeType: ChallengeType.quiz,
            ),
          ),
        );
        Get.put(HomeController(repository: mockRepo));

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en'),
            home: const LevelUpScreen(),
            getPages: [
              GetPage(
                name: AppRoutes.quizDashboard,
                page: () => const Scaffold(body: Text('Quiz Dashboard Screen')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('YOUR NEXT MOVE'), findsOneWidget);
        expect(find.text('Take a quiz'), findsOneWidget);

        await tester.tap(find.widgetWithText(GrowthActionCard, 'Take a quiz'));
        await tester.pumpAndSettle();

        expect(find.text('Quiz Dashboard Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 4 — Unknown challenge type navigates to Challenge Detail with challengeId',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockHomeRepository(
          stubData: _createMockHome(
            dailyChallenge: const ChallengePreview(
              challengeId: 'custom-challenge-id-999',
              title: 'Mystery Adventure',
              description: 'Explore the uncharted territories.',
              xpReward: 50,
              type: 'CUSTOM_UNKNOWN',
              challengeType: ChallengeType.unknown,
            ),
          ),
        );
        Get.put(HomeController(repository: mockRepo));

        String? detailReceivedId;
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en'),
            home: const LevelUpScreen(),
            getPages: [
              GetPage(
                name: AppRoutes.challengeDetail,
                page: () {
                  detailReceivedId = Get.arguments?.toString();
                  return Scaffold(body: Text('Detail for: $detailReceivedId'));
                },
              ),
              GetPage(
                name: AppRoutes.challengeList,
                page: () => const Scaffold(body: Text('Challenge List Screen')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('YOUR NEXT MOVE'), findsOneWidget);
        expect(find.text('Mystery Adventure'), findsOneWidget);

        await tester.tap(find.widgetWithText(GrowthActionCard, 'Mystery Adventure'));
        await tester.pumpAndSettle();

        expect(find.text('Detail for: custom-challenge-id-999'), findsOneWidget);
        expect(detailReceivedId, 'custom-challenge-id-999');
        expect(find.text('Challenge List Screen'), findsNothing);
      },
    );

    testWidgets(
      'Test 5 — Tap action does NOT award duplicate XP',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockHomeRepository(
          stubData: _createMockHome(
            totalXp: 95,
            dailyChallenge: const ChallengePreview(
              challengeId: 'f0000000-0000-4000-8000-000000000001',
              title: 'Check in on a habit',
              description: 'Complete one habit check-in today.',
              xpReward: 15,
              type: 'HABIT',
              challengeType: ChallengeType.habit,
            ),
          ),
        );
        final controller = Get.put(HomeController(repository: mockRepo));

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en'),
            home: const LevelUpScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final xpBefore = controller.home.value?.user.totalXp;
        expect(xpBefore, 95);

        await tester.tap(find.widgetWithText(GrowthActionCard, 'Check in on a habit'));
        await tester.pumpAndSettle();

        final xpAfter = controller.home.value?.user.totalXp;
        expect(xpAfter, 95);
      },
    );

    testWidgets(
      'Expense/Finance challenge navigates via onNavigateTab when provided',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        int? navigatedTab;
        final mockRepo = MockHomeRepository(
          stubData: _createMockHome(
            dailyChallenge: const ChallengePreview(
              challengeId: 'f0000000-0000-4000-8000-000000000003',
              title: 'Log an expense',
              description: 'Track one expense to stay on top of your budget.',
              xpReward: 15,
              type: 'EXPENSE',
              challengeType: ChallengeType.finance,
            ),
          ),
        );
        Get.put(HomeController(repository: mockRepo));

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en'),
            home: LevelUpScreen(
              onNavigateTab: (index) => navigatedTab = index,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(GrowthActionCard, 'Log an expense'));
        await tester.pumpAndSettle();

        expect(navigatedTab, 2);
      },
    );
  });
}
