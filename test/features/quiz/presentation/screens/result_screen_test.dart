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
import 'package:genlink_frontend/features/quiz/presentation/screens/result_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockQuizRepository extends Mock implements QuizRepository {}
class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockQuizRepository quizRepository;
  late AuthController authController;
  late QuizController quizController;

  final sampleResult = const QuizResult(
    attemptId: 'attempt-1',
    correct: 2,
    wrong: 1,
    total: 3,
    timeTakenSeconds: 27,
    xpEarned: 0,
    accuracyPercent: 66,
    results: [
      QuizQuestionResult(
        questionId: 'q1',
        selectedOptionId: 'o1',
        correctOptionId: 'o1',
        correct: true,
      ),
      QuizQuestionResult(
        questionId: 'q2',
        selectedOptionId: 'o2_1',
        correctOptionId: 'o2_2',
        correct: false,
      ),
      QuizQuestionResult(
        questionId: 'q3',
        selectedOptionId: 'o3_1',
        correctOptionId: 'o3_1',
        correct: true,
      ),
    ],
  );

  setUp(() {
    Get.testMode = true;
    Get.reset();

    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('km', 'KH');

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

  Widget buildTestWidget({Locale? locale, Size size = const Size(390, 844)}) {
    if (locale != null) {
      Get.locale = locale;
    }
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: GetMaterialApp(
        locale: locale ?? const Locale('km', 'KH'),
        translations: AppTranslations(),
        home: const ResultScreen(),
      ),
    );
  }

  testWidgets('ResultScreen renders in Khmer with 4 summary tiles and NO overflow', (tester) async {
    quizController.quizResult.value = sampleResult;

    await tester.pumpWidget(buildTestWidget(locale: const Locale('km', 'KH')));
    await tester.pumpAndSettle();

    // Verify 66% score ring
    expect(find.text('66%'), findsOneWidget);
    expect(find.text('2/3 ត្រឹមត្រូវ'), findsOneWidget);

    // Verify summary values
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('27 វិ.'), findsOneWidget);
    expect(find.text('+0'), findsOneWidget);

    // Verify summary labels
    expect(find.text('ត្រឹមត្រូវ'), findsOneWidget);
    expect(find.text('ខុស'), findsOneWidget);
    expect(find.text('ពេលវេលាប្រើ'), findsOneWidget);
    expect(find.text('XP ដែលទទួលបាន'), findsOneWidget);

    // Verify no exception / overflow occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultScreen renders on small phone screen (360x640) without overflow', (tester) async {
    quizController.quizResult.value = sampleResult;

    await tester.pumpWidget(buildTestWidget(
      size: const Size(360, 640),
      locale: const Locale('km', 'KH'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('66%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
