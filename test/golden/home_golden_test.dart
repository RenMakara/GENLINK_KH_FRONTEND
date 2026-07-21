import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/home/data/home_repository.dart';
import 'package:genlink_frontend/features/home/domain/entities/home_entity.dart';
import 'package:genlink_frontend/features/home/presentation/controllers/home_controller.dart';
import 'package:genlink_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

HomeEntity _fullHome() => HomeEntity(
      user: const HomeUser(
        userId: 'u1',
        fullName: 'Ren Makara',
        level: 4,
        totalXp: 362,
      ),
      todayProgress: const TodayProgress(
        habitsCompletedToday: 1,
        habitsTotal: 2,
        tasksCompleted: 0,
        tasksTotal: 1,
      ),
      dailyChallenge: const ChallengePreview(
        challengeId: 'c1',
        title: 'Complete a focus task',
        xpReward: 15,
      ),
      financeSnapshot: const FinanceSnapshot(
        totalBudget: 300,
        spentAmount: 180,
        remainingAmount: 120,
        budgetStatus: 'WARNING',
      ),
      upcomingEvent: const UpcomingEvent(
        eventId: 'e1',
        title: 'Design Guild event',
        locationName: 'Community',
      ),
      recommendedCommunities: const [
        CommunitySuggestion(communityId: 'g1', name: 'Flutter KH'),
        CommunitySuggestion(communityId: 'g2', name: 'Design Guild'),
      ],
      dailyMotivation: const MotivationCard(
        motivationId: 'm1',
        title: 'Start small',
        content: 'Consistency beats intensity — one block at a time.',
      ),
      feedPreview: [
        FeedPreview(
          postId: 'p1',
          authorName: 'Aisha L.',
          contentText: 'shared a finance tip',
          createdAt:
              DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        ),
        FeedPreview(
          postId: 'p2',
          authorName: 'Kai R.',
          contentText: 'posted in Design Guild',
          createdAt:
              DateTime.now().subtract(const Duration(minutes: 18)).toIso8601String(),
        ),
        FeedPreview(
          postId: 'p3',
          authorName: 'Marco O.',
          contentText: 'completed Sprint #12',
          createdAt:
              DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        ),
      ],
    );

/// A brand-new account: every nullable card null, every list empty,
/// totals zero — the divide-by-zero and empty-state paths.
const _emptyHome = HomeEntity(
  user: HomeUser(userId: 'u1', fullName: 'Ren Makara', level: 1, totalXp: 0),
  todayProgress: TodayProgress(
    habitsCompletedToday: 0,
    habitsTotal: 0,
    tasksCompleted: 0,
    tasksTotal: 0,
  ),
);

void main() {
  const phone = Size(390, 1000);

  late _MockHomeRepository repository;

  setUp(() {
    repository = _MockHomeRepository();
    Get.put<HomeRepository>(repository);
  });

  tearDown(Get.reset);

  Future<void> pumpHome(WidgetTester tester) async {
    Get.put<HomeController>(
      HomeController(repository: Get.find<HomeRepository>()),
    );

    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.lightFor('en'),
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home with full data', (tester) async {
    when(repository.getHome).thenAnswer((_) async => _fullHome());
    await pumpHome(tester);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('home for a brand-new user', (tester) async {
    when(repository.getHome).thenAnswer((_) async => _emptyHome);
    await pumpHome(tester);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_empty.png'),
    );
  });
}
