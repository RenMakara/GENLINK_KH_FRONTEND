import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/growth/presentation/screens/growth_screen.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/home/presentation/screens/home_screen.dart';

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

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStoryRepository implements StoryRepository {
  @override
  Future<List<StoryGroupModel>> getStories() async => [];

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
          dailyMotivation: MotivationCard(
            motivationId: 'mot-1',
            title: 'Quote of the Day',
            content: 'Success is the sum of small efforts repeated day in and day out.',
          ),
          recommendedCommunities: [
            CommunitySuggestion(
              communityId: 'c-1',
              name: 'Computer Science Society',
              memberCount: 156,
            ),
          ],
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

  test('HomeController loads data and calculates today progress safely', () async {
    final mockRepo = MockHomeRepository();
    final controller = HomeController(repository: mockRepo);

    await controller.load();

    expect(controller.isLoading.value, false);
    expect(controller.home.value, isNotNull);
    expect(controller.home.value?.user.safeLevel, 3);
    expect(controller.home.value?.todayProgress.percent, 50); // 3 of 6 = 50%
    expect(controller.habits.length, 2);
  });

  test('HomeController toggles habit check-in optimistically', () async {
    final mockRepo = MockHomeRepository();
    final controller = HomeController(repository: mockRepo);

    await controller.load();
    expect(controller.home.value?.todayProgress.habitsCompletedToday, 1);

    // Toggle check-in for habit h-2 (checkedInToday: false -> true)
    await controller.toggleHabitCheckIn(habitId: 'h-2', targetState: true);

    expect(controller.home.value?.todayProgress.habitsCompletedToday, 2);
    expect(controller.habits.firstWhere((h) => h.habitId == 'h-2').checkedInToday, true);
  });

  testWidgets('HomeScreen renders Campus Life & Connections with GenLink branding and tabs', (tester) async {
    Get.put(CommunityController(repository: MockCommunityRepository()));

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header has "Home" text title, search, chat, notifications
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Navigation tabs for Feed, Forum, Event are visible
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Forum'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Demo Stories and opens DemoStoryViewer on tap', (tester) async {
    Get.put(CommunityController(repository: MockCommunityRepository()));
    final storyController = Get.put(StoryController(repository: MockStoryRepository()));
    storyController.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. "Your Story" is present
    expect(find.text('Your Story'), findsOneWidget);

    // 2. Demo users are present in the horizontal tray
    expect(find.text('Dara'), findsOneWidget);
    expect(find.text('Lina'), findsOneWidget);
    expect(find.text('Sokha'), findsOneWidget);

    // 3. Tapping on a demo story opens DemoStoryViewerDialog
    await tester.tap(find.text('Dara'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Viewer displays user name, story content, and close button
    expect(find.text('Dara'), findsWidgets);
    expect(find.textContaining('Working on the Flutter mobile design system'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // 5. Tapping close button closes the viewer
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('GrowthScreen renders Personal Development & Productivity', (tester) async {
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

    // 1. Growth Header and Leaderboard icon
    expect(find.text('GROWTH'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

    // 2. Personal Greeting
    expect(find.textContaining('Test'), findsOneWidget);
    expect(find.text("Here's what's important today."), findsOneWidget);

    // 3. Level and XP progress
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.textContaining('350'), findsWidgets);
    expect(find.textContaining('XP'), findsWidgets);

    // 4. TODAY section with habits and tasks
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Check in your habits'), findsOneWidget);
    expect(find.text("Finish today's tasks"), findsOneWidget);
    expect(find.text('Daily progress'), findsOneWidget);

    // 5. Productivity Tools
    expect(find.text('PRODUCTIVITY TOOLS'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);

    // 6. For You recommendations
    await tester.scrollUntilVisible(find.text('RECOMMENDED FOR YOU'), 300);
    expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
    expect(find.text('Solve 5 Math Quizzes'), findsOneWidget);
  });

  testWidgets('GrowthScreen renders empty states when habits are zero', (tester) async {
    final mockRepo = MockHomeRepository(
      stubData: const HomeEntity(
        user: HomeUser(userId: 'u-empty', level: 1, totalXp: 0),
        todayProgress: TodayProgress(
          habitsCompletedToday: 0,
          habitsTotal: 0,
          tasksCompleted: 0,
          tasksTotal: 0,
        ),
      ),
    );
    Get.put(HomeController(repository: mockRepo));

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const GrowthScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Habit empty state
    expect(find.text('No habits for today'), findsOneWidget);
    expect(find.text('Start building a routine.'), findsOneWidget);

    // Task empty state
    expect(find.text('No tasks for today'), findsOneWidget);
    expect(find.text("You're all caught up."), findsOneWidget);
  });
}
