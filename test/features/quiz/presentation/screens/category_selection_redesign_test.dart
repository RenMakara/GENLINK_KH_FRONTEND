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

  final sampleQuizzes = [
    const QuizSummary(
      quizId: 'quiz-gen-1',
      title: 'General Knowledge 1',
      category: 'GENERAL',
      difficulty: 'EASY',
      xpReward: 10,
      questionCount: 9,
    ),
    const QuizSummary(
      quizId: 'quiz-biz-1',
      title: 'Business Basics',
      category: 'BUSINESS',
      difficulty: 'MEDIUM',
      xpReward: 15,
      questionCount: 9,
    ),
    const QuizSummary(
      quizId: 'quiz-food-1',
      title: 'World Cuisine',
      category: 'FOOD',
      difficulty: 'EASY',
      xpReward: 10,
      questionCount: 9,
    ),
    const QuizSummary(
      quizId: 'quiz-sci-1',
      title: 'Physics & Nature',
      category: 'SCIENCE',
      difficulty: 'HARD',
      xpReward: 25,
      questionCount: 9,
    ),
    const QuizSummary(
      quizId: 'quiz-fin-1',
      title: 'Finance & Wealth',
      category: 'FINANCE',
      difficulty: 'EASY',
      xpReward: 30,
      questionCount: 31,
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
    ).thenAnswer((_) async => sampleQuizzes);

    when(() => quizRepository.getQuizHistory()).thenAnswer((_) async => const []);

    quizController = QuizController(
      quizRepository: quizRepository,
      authController: authController,
    );
    Get.put<QuizController>(quizController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CategorySelectionScreen renders full gamified 3D hierarchy properly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    // 1. Header with Title, Subtitle, and 3D Books Illustration
    expect(find.text('Choose Quiz Category'), findsOneWidget);
    expect(find.text('Pick a category to start learning.'), findsOneWidget);
    expect(find.byType(GraduationBooksIllustration), findsOneWidget);

    // 2. Search Bar with Filter Sliders
    expect(find.byType(QuizCategorySearchBar), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // 3. Filter Chips
    expect(find.byType(QuizCategoryFilterChips), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('My Favorites'), findsOneWidget);

    // 4. Soft 3D Category Cards rendered (General, Business, Food, Science, and Finance)
    expect(find.byType(QuizCategoryCard), findsNWidgets(5));
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);

    // Finance card rendered with full width and 31 Questions
    expect(find.text('31 Questions'), findsOneWidget);

    // 5. 1v1 Multiplayer Promo Card
    expect(find.byType(QuizMultiplayerChallengeCard), findsOneWidget);

    // Verify zero exceptions
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filter chips change ordering and filter categories interactively', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    // Tap "Popular" filter
    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();

    // Still displays categories without error
    expect(find.byType(QuizCategoryCard), findsWidgets);

    // Tap "New" filter
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    expect(find.byType(QuizCategoryCard), findsWidgets);

    // Tap "All" to return
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
  });

  testWidgets('Empty search state displays polished illustration and clear action', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    // Search for non-existing category
    await tester.enterText(find.byType(TextField), 'QuantumPhysics');
    await tester.pumpAndSettle();

    expect(find.text('No categories match your search.'), findsOneWidget);
    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);

    // Tap "Clear search"
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
  });

  testWidgets('CategorySelectionScreen renders cleanly in Khmer locale on 360x640 phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('km', 'KH'),
        theme: ThemeData.light(useMaterial3: true),
        home: const CategorySelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Khmer strings
    expect(find.text('ជ្រើសរើសប្រភេទកម្រងសំណួរ'), findsOneWidget);
    expect(find.text('ទាំងអស់'), findsOneWidget);

    // Verify zero RenderFlex overflows
    expect(tester.takeException(), isNull);
  });

  testWidgets('CategorySelectionScreen renders cleanly in Dark Mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.dark(useMaterial3: true),
        home: const CategorySelectionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CategorySelectionScreen), findsOneWidget);
    expect(find.byType(QuizCategoryCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
