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
import 'package:genlink_frontend/features/quiz/presentation/screens/quiz_in_progress_screen.dart';
import 'package:genlink_frontend/features/quiz/presentation/screens/result_screen.dart';
import 'package:genlink_frontend/features/quiz/presentation/screens/review_submit_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockQuizRepository extends Mock implements QuizRepository {}
class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockQuizRepository quizRepository;
  late AuthController authController;
  late QuizController quizController;

  final sampleQuestions = [
    const QuizQuestion(
      id: 'q1',
      question: 'What is finance?',
      options: [
        QuizOptionModel(id: 'o1', text: 'Money management'),
        QuizOptionModel(id: 'o2', text: 'Cooking'),
      ],
      correctIndex: 0,
    ),
  ];

  final sampleResult = const QuizResult(
    attemptId: 'attempt-1',
    correct: 1,
    wrong: 0,
    total: 1,
    timeTakenSeconds: 10,
    xpEarned: 20,
    accuracyPercent: 100,
    results: [
      QuizQuestionResult(
        questionId: 'q1',
        selectedOptionId: 'o1',
        correctOptionId: 'o1',
        correct: true,
      ),
    ],
  );

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
    ).thenAnswer((_) async => const [
      QuizSummary(
        quizId: 'quiz_1',
        title: 'Finance 101',
        category: 'Finance',
        difficulty: 'EASY',
        xpReward: 10,
        questionCount: 1,
      ),
    ]);

    when(() => quizRepository.getQuizHistory()).thenAnswer((_) async => const []);

    when(() => quizRepository.getQuizDetails(any()))
        .thenAnswer((_) async => sampleQuestions);

    when(() => quizRepository.submitQuizAttempt(any(), any()))
        .thenAnswer((_) async => sampleResult);

    quizController = QuizController(
      quizRepository: quizRepository,
      authController: authController,
    );
    Get.put<QuizController>(quizController);
  });

  tearDown(() {
    quizController.resetQuiz();
    Get.reset();
  });

  testWidgets('sequential quiz completion cleans up QuizInProgress from backstack', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.quizDashboard,
        getPages: [
          GetPage(name: AppRoutes.home, page: () => const Scaffold(body: Text('Home Screen'))),
          GetPage(name: AppRoutes.quizDashboard, page: () => const QuizDashboardScreen()),
          GetPage(name: AppRoutes.quizInProgress, page: () => const QuizInProgressScreen()),
          GetPage(name: AppRoutes.quizReview, page: () => const ReviewSubmitScreen()),
          GetPage(name: AppRoutes.quizResult, page: () => const ResultScreen()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Verify on Dashboard
    expect(find.byType(QuizDashboardScreen), findsOneWidget);

    // 1. Start a quiz
    quizController.startSelectedQuiz('quiz_1');
    Get.toNamed(AppRoutes.quizInProgress);
    await tester.pumpAndSettle();
    expect(find.byType(QuizInProgressScreen), findsOneWidget);

    // Answer question & go to review
    quizController.selectAnswer('q1', 'o1');
    quizController.skipQuestion();
    await tester.pumpAndSettle();
    expect(find.byType(ReviewSubmitScreen), findsOneWidget);

    // Submit quiz -> ReviewSubmitScreen uses Get.offNamedUntil to transition to ResultScreen
    await tester.tap(find.widgetWithText(InkWell, 'Submit Quiz'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);

    // Tap "Back to Dashboard"
    await tester.tap(find.widgetWithText(InkWell, 'Back to Dashboard'));
    await tester.pumpAndSettle();

    // Verify back on Dashboard
    expect(find.byType(QuizDashboardScreen), findsOneWidget);
    expect(find.byType(QuizInProgressScreen), findsNothing);

    // 2. Start a SECOND quiz
    quizController.startSelectedQuiz('quiz_1');
    Get.toNamed(AppRoutes.quizInProgress);
    await tester.pumpAndSettle();
    expect(find.byType(QuizInProgressScreen), findsOneWidget);

    // Answer & submit second quiz
    quizController.selectAnswer('q1', 'o1');
    quizController.skipQuestion();
    await tester.pumpAndSettle();
    expect(find.byType(ReviewSubmitScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Submit Quiz'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);

    // Return to Dashboard again
    await tester.tap(find.widgetWithText(InkWell, 'Back to Dashboard'));
    await tester.pumpAndSettle();

    // Verify back on Dashboard with zero leftover QuizInProgress screens
    expect(find.byType(QuizDashboardScreen), findsOneWidget);
    expect(find.byType(QuizInProgressScreen), findsNothing);

    // 3. Tapping back button on Dashboard now pops directly to Home
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    // Verifies user is cleanly on Home with NO "Quit Quiz?" dialogs
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Quit Quiz?'), findsNothing);
  });
}
