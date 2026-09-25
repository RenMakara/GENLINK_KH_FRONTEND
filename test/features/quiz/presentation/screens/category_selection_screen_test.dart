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
import 'package:genlink_frontend/features/quiz/presentation/screens/category_selection_screen.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_category_widgets.dart';

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
          title: 'Internet Safety',
          category: 'TECHNOLOGY',
          difficulty: 'MEDIUM',
          xpReward: 15,
          questionCount: 4,
        ),
      ],
    );

    quizController = QuizController(quizRepository: quizRepository);
    Get.put<QuizController>(quizController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CategorySelectionScreen renders header, search bar, categories, and recently played',
      (tester) async {
    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const CategorySelectionScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header elements
    expect(find.text('Choose Quiz Category'), findsOneWidget);
    expect(find.text('Pick a category to start learning.'), findsOneWidget);

    // Verify search bar
    expect(find.byType(QuizCategorySearchBar), findsOneWidget);

    // Verify categories rendered
    expect(find.byType(QuizCategoryCard), findsWidgets);
    expect(find.text('Finance'), findsWidgets);
    expect(find.text('Technology'), findsWidgets);

    // Verify 1v1 challenge promotional card
    expect(find.byType(QuizMultiplayerChallengeCard), findsOneWidget);

    // Verify no RenderFlex overflow happened
    expect(tester.takeException(), isNull);
  });

  testWidgets('CategorySelectionScreen search filters categories dynamically',
      (tester) async {
    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const CategorySelectionScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Search for "Finance"
    await tester.enterText(find.byType(TextField), 'Finance');
    await tester.pumpAndSettle();

    expect(find.text('Finance'), findsWidgets);
    expect(find.text('Technology'), findsNothing);

    // Search for non-existent category
    await tester.enterText(find.byType(TextField), 'Astronomy');
    await tester.pumpAndSettle();

    expect(find.text('No categories match your search.'), findsOneWidget);
  });
}
