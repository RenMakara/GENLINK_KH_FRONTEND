import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';

import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/levelup/levelup_screen.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:genlink_frontend/main_controller.dart';
import 'package:genlink_frontend/main_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(_MockHttpClientRequest());
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(_MockHttpClientResponse());
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => 0;
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
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHomeRepo extends Mock implements HomeRepository {}
class _MockProfileRepo extends Mock implements ProfileRepository {}
class _MockCommunityRepo extends Mock implements CommunityRepository {}
class _MockStoryRepo extends Mock implements StoryRepository {}
class _MockFinanceRepo extends Mock implements FinanceRepository {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    registerFallbackValue(FinanceCurrency.usd);
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;

    final mockHome = _MockHomeRepo();
    final mockProfile = _MockProfileRepo();
    final mockCommunity = _MockCommunityRepo();
    final mockStory = _MockStoryRepo();
    final mockFinance = _MockFinanceRepo();

    when(() => mockHome.getHome()).thenAnswer((_) async => const HomeEntity(
      user: HomeUser(userId: 'u1', fullName: 'Test User', level: 1, totalXp: 10),
      todayProgress: TodayProgress(habitsCompletedToday: 0, habitsTotal: 0, tasksCompleted: 0, tasksTotal: 0),
      dailyChallenge: ChallengePreview(challengeId: 'c1', title: 'Ch', description: 'd', xpReward: 5),
    ));
    when(() => mockHome.getHabits()).thenAnswer((_) async => []);

    when(() => mockProfile.getMyProfile()).thenAnswer((_) async => ProfileEntity(
      userId: 'u1',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 10,
      level: 1,
      preferredLanguage: 'en',
    ));
    when(() => mockProfile.getMyInterests()).thenAnswer((_) async => []);
    when(() => mockProfile.getPortfolio()).thenAnswer((_) async => []);
    when(() => mockProfile.getSocialLinks()).thenAnswer((_) async => []);
    when(() => mockProfile.getBadges()).thenAnswer((_) async => []);
    when(() => mockProfile.getSavedItems()).thenAnswer((_) async => []);

    when(() => mockCommunity.getPosts(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockCommunity.getOpportunities(
      type: any(named: 'type'),
      includeExpired: any(named: 'includeExpired'),
      page: any(named: 'page'),
      size: any(named: 'size'),
    )).thenAnswer((_) async => []);
    when(() => mockStory.getStories()).thenAnswer((_) async => []);

    when(() => mockFinance.getFinanceDashboard(currency: any(named: 'currency')))
        .thenAnswer((_) async => const FinanceDashboardEntity(
              currency: FinanceCurrency.khr,
              month: FinanceMonthOverview(
                month: 8,
                year: 2026,
                currency: FinanceCurrency.khr,
                spent: 100,
              ),
              topCategories: [],
              recentExpenses: [],
              saving: FinanceSavingProgress(
                currency: FinanceCurrency.khr,
                totalTarget: 0,
                totalSaved: 0,
                progressPercent: 0,
                activeGoals: 0,
              ),
            ));

    Get.put<HomeRepository>(mockHome);
    Get.put<ProfileRepository>(mockProfile);
    Get.put<CommunityRepository>(mockCommunity);
    Get.put<StoryRepository>(mockStory);
    Get.put<FinanceRepository>(mockFinance);

    Get.put(MainController());
    Get.put(HomeController(repository: mockHome));
    Get.put(ProfileController(repository: mockProfile));
    Get.put(FinanceController(repository: mockFinance));
    Get.put(CommunityController(repository: mockCommunity));
    Get.put(StoryController(repository: mockStory));
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Switching tabs to Profile/LevelUp and back to Home preserves Feed tab', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const MainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final commController = Get.find<CommunityController>();
    final mainController = Get.find<MainController>();

    expect(mainController.currentIndex.value, 0);
    expect(commController.selectedCategory.value, 'Feed');

    // Tap LevelUp tab in BottomNavBar
    await tester.tap(find.text('LevelUp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(mainController.currentIndex.value, 1);

    // Scroll down in LevelUp
    await tester.drag(find.byType(LevelUpScreen), const Offset(0, -300));
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap Home tab in BottomNavBar
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Tap Profile in BottomNavBar
    await tester.tap(find.text('Profile'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(mainController.currentIndex.value, 3);

    // Scroll down in Profile
    await tester.drag(find.byType(ProfileScreen), const Offset(0, -300));
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap Home tab in BottomNavBar
    await tester.tap(find.text('Home'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(commController.selectedCategory.value, 'Feed');
  });

  testWidgets('Switching tabs to LevelUp/Finance and back to Home preserves Forum, Event, and Career tabs', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: const MainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final commController = Get.find<CommunityController>();
    final mainController = Get.find<MainController>();

    expect(mainController.currentIndex.value, 0);
    expect(commController.selectedCategory.value, 'Feed');

    // 1. Switch to Forum tab
    await tester.tap(find.text('Forum'));
    await tester.pumpAndSettle();
    expect(commController.selectedCategory.value, 'Forum');

    // Tap LevelUp
    await tester.tap(find.text('LevelUp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(mainController.currentIndex.value, 1);

    // Tap Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify it stayed in Forum!
    expect(commController.selectedCategory.value, 'Forum');

    // 2. Switch to Event tab
    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();
    expect(commController.selectedCategory.value, 'Event');

    // Tap Finance
    await tester.tap(find.text('Finance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(mainController.currentIndex.value, 2);

    // Tap Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify it stayed in Event!
    expect(commController.selectedCategory.value, 'Event');

    // 3. Switch to Career tab
    await tester.tap(find.text('Career'));
    await tester.pumpAndSettle();
    expect(commController.selectedCategory.value, 'Career');

    // Tap LevelUp
    await tester.tap(find.text('LevelUp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(mainController.currentIndex.value, 1);

    // Tap Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify it stayed in Career!
    expect(commController.selectedCategory.value, 'Career');

    // Tap Finance from Career
    await tester.tap(find.text('Finance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(mainController.currentIndex.value, 2);

    // Tap Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify it stayed in Career!
    expect(commController.selectedCategory.value, 'Career');

    // 4. Switch back to Feed tab
    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    expect(commController.selectedCategory.value, 'Feed');

    // Tap Finance from Feed
    await tester.tap(find.text('Finance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(mainController.currentIndex.value, 2);

    // Tap Home
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify it stayed in Feed, NOT Career!
    expect(commController.selectedCategory.value, 'Feed');
  });
}

