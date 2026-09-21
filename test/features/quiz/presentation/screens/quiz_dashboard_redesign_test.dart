import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';
import 'package:genlink_frontend/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:genlink_frontend/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:genlink_frontend/features/quiz/presentation/screens/quiz_dashboard_screen.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_gamified_components.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockQuizRepository extends Mock implements QuizRepository {}
class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockQuizRepository quizRepository;
  late AuthController authController;
  late QuizController quizController;

  setUp(() {
    Get.testMode = true;
    Get.reset();

    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    quizRepository = _MockQuizRepository();
    Get.put<QuizRepository>(quizRepository);

    authController = AuthController(
      authRepository: _MockAuthRepository(),
      secureStorage: _MockSecureStorage(),
      localization: LocalizationService(localStorage: LocalStorage()),
    );
    Get.put<AuthController>(authController);

    when(
      () => quizRepository.getQuizzes(
        category: any(named: 'category'),
        difficulty: any(named: 'difficulty'),
      ),
    ).thenAnswer(
      (_) async => [
        const QuizSummary(
          quizId: 'quiz-finance-1',
          title: 'Budgeting Basics',
          category: 'FINANCE',
          difficulty: 'EASY',
          xpReward: 10,
          questionCount: 3,
        ),
        const QuizSummary(
          quizId: 'quiz-tech-1',
          title: 'Tech Skills',
          category: 'TECHNOLOGY',
          difficulty: 'MEDIUM',
          xpReward: 15,
          questionCount: 4,
        ),
        const QuizSummary(
          quizId: 'quiz-growth-1',
          title: 'Growth Habits',
          category: 'SELF_GROWTH',
          difficulty: 'EASY',
          xpReward: 10,
          questionCount: 5,
        ),
        const QuizSummary(
          quizId: 'quiz-science-1',
          title: 'Science 101',
          category: 'SCIENCE',
          difficulty: 'HARD',
          xpReward: 20,
          questionCount: 5,
        ),
      ],
    );

    when(() => quizRepository.getQuizHistory()).thenAnswer(
      (_) async => [
        const QuizAttemptSummary(
          attemptId: 'att-1',
          quizId: 'quiz-1',
          quizTitle: 'General Knowledge',
          score: 3,
          correctCount: 3,
          totalQuestions: 3,
          xpEarned: 25,
          completedAt: '2026-09-20T10:00:00Z',
        ),
        const QuizAttemptSummary(
          attemptId: 'att-2',
          quizId: 'quiz-2',
          quizTitle: 'Science 101',
          score: 3,
          correctCount: 3,
          totalQuestions: 3,
          xpEarned: 25,
          completedAt: '2026-09-20T11:00:00Z',
        ),
        const QuizAttemptSummary(
          attemptId: 'att-3',
          quizId: 'quiz-3',
          quizTitle: 'Khmer History',
          score: 3,
          correctCount: 3,
          totalQuestions: 3,
          xpEarned: 25,
          completedAt: '2026-09-20T12:00:00Z',
        ),
        const QuizAttemptSummary(
          attemptId: 'att-4',
          quizId: 'quiz-4',
          quizTitle: 'Tech Basics',
          score: 3,
          correctCount: 3,
          totalQuestions: 3,
          xpEarned: 25,
          completedAt: '2026-09-20T13:00:00Z',
        ),
      ],
    );

    quizController = QuizController(quizRepository: quizRepository);
    Get.put<QuizController>(quizController);

    // Seed mock user stats
    quizController.userStats.value = const UserStats(
      name: 'Ren Makara',
      avatarUrl: null,
      level: 1,
      xp: 95,
      xpToNextLevel: 100,
    );

    // Seed categories
    quizController.categories.assignAll([
      const QuizCategory(
        id: 'finance',
        name: 'Finance',
        icon: 'account_balance_wallet',
        questionCount: 10,
        colorIndex: 0,
      ),
      const QuizCategory(
        id: 'tech',
        name: 'Technology',
        icon: 'devices',
        questionCount: 8,
        colorIndex: 1,
      ),
      const QuizCategory(
        id: 'growth',
        name: 'Self Growth',
        icon: 'biotech',
        questionCount: 12,
        colorIndex: 2,
      ),
      const QuizCategory(
        id: 'science',
        name: 'Science',
        icon: 'biotech',
        questionCount: 6,
        colorIndex: 3,
      ),
    ]);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget({
    Locale locale = const Locale('en', 'US'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const QuizDashboardScreen(),
      getPages: [
        GetPage(
          name: AppRoutes.quizDashboard,
          page: () => const QuizDashboardScreen(),
        ),
        GetPage(
          name: AppRoutes.quizCategories,
          page: () => const Scaffold(body: Text('Categories Destination')),
        ),
        GetPage(
          name: AppRoutes.quizMultiplayer,
          page: () => const Scaffold(body: Text('Multiplayer Destination')),
        ),
        GetPage(
          name: AppRoutes.shortContent,
          page: () => const Scaffold(body: Text('Short Content Destination')),
        ),
        GetPage(
          name: AppRoutes.leaderboard,
          page: () => const Scaffold(body: Text('Leaderboard Destination')),
        ),
        GetPage(
          name: AppRoutes.notifications,
          page: () => const Scaffold(body: Text('Notifications Destination')),
        ),
      ],
    );
  }

  testWidgets('QuizDashboardScreen renders full UI hierarchy properly',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.byType(QuizGamifiedHeader), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Test your knowledge and level up your skills.'), findsOneWidget);

    // 2. XP Hero Card with 3D Trophy
    expect(find.byType(QuizXpHeroCard), findsOneWidget);
    expect(find.text('Hi, Ren Makara 👋'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('95 / 100 XP'), findsOneWidget);
    expect(find.text('5 XP to Next Level'), findsOneWidget);
    expect(find.byType(Soft3DTrophyWidget), findsOneWidget);

    // 3. Quiz Statistics Card
    expect(find.byType(QuizStatsCard), findsOneWidget);
    expect(
      find.descendant(of: find.byType(QuizStatsCard), matching: find.text('4')),
      findsNWidgets(2),
    );
    expect(find.text('Completed Quizzes'), findsOneWidget);
    expect(find.text('Available Quizzes'), findsOneWidget);

    // 4. Choose Your Challenge Section
    expect(find.text('Choose Your Challenge'), findsOneWidget);
    expect(find.byType(QuizChallengeCard), findsNWidgets(4));
    expect(find.text('Single Quiz'), findsOneWidget);
    expect(find.text('Practice and learn at your own pace.'), findsOneWidget);
    expect(find.text('1v1 Multiplayer Quiz'), findsOneWidget);
    expect(find.text('Find an opponent and compete live.'), findsOneWidget);
    expect(find.text('Short Content'), findsOneWidget);
    expect(find.text('Explore bite-sized learning and inspiration from the community.'), findsOneWidget);
    expect(find.text('Learning Progress'), findsOneWidget);
    expect(find.text("Track your quiz history and see how you're growing."), findsOneWidget);

    // 5. Categories Section
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('All Categories'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);

    // 6. Motivational CTA Card
    expect(find.byType(QuizMotivationCard), findsOneWidget);
    expect(find.text('Knowledge today, a brighter tomorrow.'), findsOneWidget);
    expect(find.text('Keep learning and earn more XP!'), findsOneWidget);
    expect(find.text('Take a Quiz'), findsOneWidget);
    expect(find.byType(Soft3DLightbulbWidget), findsOneWidget);
  });

  testWidgets('Challenge cards navigate to corresponding routes when tapped',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap 1v1 Multiplayer Quiz
    await tester.tap(find.text('1v1 Multiplayer Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Multiplayer Destination'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Tap Short Content
    await tester.tap(find.text('Short Content'));
    await tester.pumpAndSettle();
    expect(find.text('Short Content Destination'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Tap Learning Progress
    await tester.tap(find.text('Learning Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard Destination'), findsOneWidget);

    // Go back
    Get.back();
    await tester.pumpAndSettle();

    // Tap Take a Quiz CTA button
    await tester.ensureVisible(find.text('Take a Quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Categories Destination'), findsOneWidget);
  });

  testWidgets('QuizDashboardScreen renders cleanly in Khmer locale without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget(locale: const Locale('km', 'KH')));
    await tester.pumpAndSettle();

    // Khmer Title & Subtitle
    expect(find.text('កម្រងសំណួរ'), findsOneWidget);
    expect(find.text('សាកល្បងចំណេះដឹង និងបង្កើនជំនាញរបស់អ្នក'), findsOneWidget);

    // Khmer greeting and challenge section
    expect(find.text('ជ្រើសរើសការប្រកួតប្រជែងរបស់អ្នក'), findsOneWidget);
    expect(find.text('ធ្វើកម្រងសំណួរ'), findsOneWidget);

    // No overflows
    expect(tester.takeException(), isNull);
  });

  testWidgets('QuizDashboardScreen renders cleanly in Dark Mode',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.byType(QuizDashboardScreen), findsOneWidget);
    expect(find.byType(QuizXpHeroCard), findsOneWidget);
    expect(find.byType(QuizStatsCard), findsOneWidget);
    expect(find.byType(QuizMotivationCard), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
