import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/growth/presentation/screens/growth_screen.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan.dart';
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
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
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
    _stub = stubData ??
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

  testWidgets('GrowthScreen renders Goals with flag icon and opens PlanGoalScreen', (tester) async {
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
        home: const GrowthScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Growth screen elements
    expect(find.text('GROWTH'), findsOneWidget);
    expect(find.text('PRODUCTIVITY TOOLS'), findsOneWidget);

    // 2. Scroll until Goals tool with flag icon is visible
    await tester.scrollUntilVisible(find.text('Goals'), 300);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);

    // 3. Verify tapping Goals opens PlanGoalScreen
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(PlanGoalScreen), findsOneWidget);
  });
}
