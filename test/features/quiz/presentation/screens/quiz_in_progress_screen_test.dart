import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';
import 'package:genlink_frontend/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:genlink_frontend/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:genlink_frontend/features/quiz/presentation/screens/quiz_in_progress_screen.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_question_card.dart';

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
      question: 'What is a budget?\nតើ Budget មានន័យដូចម្តេច?',
      options: [
        QuizOptionModel(id: 'o1', text: 'A plan for your money'),
        QuizOptionModel(id: 'o2', text: 'A type of loan'),
        QuizOptionModel(id: 'o3', text: 'A credit card'),
        QuizOptionModel(id: 'o4', text: 'A bank account'),
      ],
      correctIndex: 0,
    ),
    const QuizQuestion(
      id: 'q2',
      question: 'What is emergency savings?',
      options: [
        QuizOptionModel(id: 'o2_1', text: 'Money for vacation'),
        QuizOptionModel(id: 'o2_2', text: 'Funds reserved for unexpected expenses'),
        QuizOptionModel(id: 'o2_3', text: 'Investment portfolio'),
        QuizOptionModel(id: 'o2_4', text: 'Lottery tickets'),
      ],
      correctIndex: 1,
    ),
  ];

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
    ).thenAnswer((_) async => const []);

    when(() => quizRepository.getQuizDetails(any()))
        .thenAnswer((_) async => sampleQuestions);

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

  Widget buildTestWidget({Locale? locale}) {
    if (locale != null) {
      Get.locale = locale;
    }
    return GetMaterialApp(
      locale: locale ?? const Locale('en', 'US'),
      translations: AppTranslations(),
      home: const QuizInProgressScreen(),
    );
  }

  testWidgets('renders top header with close button, question counter, and timer', (tester) async {
    quizController.questions.assignAll(sampleQuestions);
    quizController.currentQuestionIndex.value = 0;
    quizController.timeRemaining.value = 15;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Check Close Button
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Check Question Counter in English
    expect(find.text('Question 1 of 2'), findsOneWidget);

    // Check Timer text
    expect(find.text('15'), findsOneWidget);

    // Check Question Card
    expect(find.byType(QuizQuestionCard), findsOneWidget);
    expect(find.text('What is a budget?'), findsOneWidget);
    expect(find.text('តើ Budget មានន័យដូចម្តេច?'), findsOneWidget);

    // Check 4 answer options
    expect(find.byType(QuizOptionTile), findsNWidgets(4));
    expect(find.text('A plan for your money'), findsOneWidget);
    expect(find.text('A type of loan'), findsOneWidget);
  });

  testWidgets('renders Khmer header and navigation buttons in Khmer locale', (tester) async {
    quizController.questions.assignAll(sampleQuestions);
    quizController.currentQuestionIndex.value = 0;

    await tester.pumpWidget(buildTestWidget(locale: const Locale('km', 'KH')));
    await tester.pumpAndSettle();

    // Khmer progress
    expect(find.text('សំណួរ 1 ក្នុង 2'), findsOneWidget);

    // Khmer Previous button "មុន"
    expect(find.text('មុន'), findsOneWidget);

    // Khmer Next button "បន្ទាប់"
    expect(find.text('បន្ទាប់'), findsOneWidget);
  });

  testWidgets('selecting an answer updates option state and shows feedback card', (tester) async {
    quizController.questions.assignAll(sampleQuestions);
    quizController.currentQuestionIndex.value = 0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap first option (correct answer: A plan for your money)
    await tester.tap(find.text('A plan for your money'));
    await tester.pumpAndSettle();

    expect(quizController.selectedOptionIndexForQuestion(0), equals(0));

    // Correct feedback card should appear
    expect(find.text('Correct! Great job.'), findsOneWidget);
  });

  testWidgets('Previous button is disabled on question 1 and active on question 2', (tester) async {
    quizController.questions.assignAll(sampleQuestions);
    quizController.currentQuestionIndex.value = 0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // On question 1, select an answer so Next is active
    await tester.tap(find.text('A plan for your money'));
    await tester.pumpAndSettle();

    // Tap Next to advance to question 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(quizController.currentQuestionIndex.value, equals(1));
    expect(find.text('Question 2 of 2'), findsOneWidget);

    // On question 2, tap Previous to go back
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(quizController.currentQuestionIndex.value, equals(0));
    expect(find.text('Question 1 of 2'), findsOneWidget);

    quizController.resetQuiz();
  });
}
