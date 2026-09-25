import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/network/app_realtime_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/quiz/data/datasources/quiz_match_realtime_data_source.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_match_models.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';
import 'package:genlink_frontend/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:genlink_frontend/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:genlink_frontend/features/quiz/presentation/controllers/quiz_match_controller.dart';
import 'package:genlink_frontend/features/quiz/presentation/screens/multiplayer_quiz_screen.dart';
import 'package:genlink_frontend/features/quiz/presentation/widgets/quiz_multiplayer_widgets.dart';

class _MockQuizRepository extends Mock implements QuizRepository {}
class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockSecureStorage extends Mock implements SecureStorage {}

class _FakeQuizMatchRealtimeDataSource implements QuizMatchRealtimeDataSource {
  final _eventController = StreamController<QuizMatchEvent>.broadcast();
  final _connectionController = StreamController<RealtimeConnectionState>.broadcast();
  final _errorController = StreamController<RealtimeErrorEvent>.broadcast();

  final findMatchQuizIds = <String>[];
  final unsubscribedMatchIds = <String>[];

  @override
  Stream<QuizMatchEvent> get events => _eventController.stream;

  @override
  Stream<RealtimeConnectionState> get connectionStates => _connectionController.stream;

  @override
  Stream<RealtimeErrorEvent> get errors => _errorController.stream;

  @override
  Future<bool> connect() async => true;

  @override
  Future<void> findMatch(String quizId) async {
    findMatchQuizIds.add(quizId);
  }

  @override
  Future<bool> subscribeMatch(String matchId) async => true;

  @override
  Future<void> unsubscribeMatch(String matchId) async {
    unsubscribedMatchIds.add(matchId);
  }

  @override
  Future<void> submitAnswer({
    required String matchId,
    required String questionId,
    required String optionId,
  }) async {}

  @override
  Future<void> finishMatch(String matchId) async {}
}

const _testUser = UserEntity(
  id: 'user-1',
  fullName: 'Makara Ren',
  username: 'makara',
  email: 'makara@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 1200,
  level: 4,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockQuizRepository quizRepository;
  late _FakeQuizMatchRealtimeDataSource realtimeDataSource;
  late AuthController authController;
  late QuizController quizController;
  late QuizMatchController matchController;

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
    authController.currentUser.value = _testUser;
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
          title: 'Money Basics',
          category: 'FINANCE',
          difficulty: 'EASY',
          xpReward: 30,
          questionCount: 3,
        ),
        const QuizSummary(
          quizId: 'quiz-tech-1',
          title: 'Digital Privacy',
          category: 'TECHNOLOGY',
          difficulty: 'MEDIUM',
          xpReward: 40,
          questionCount: 5,
        ),
      ],
    );

    quizController = QuizController(quizRepository: quizRepository);
    Get.put<QuizController>(quizController);

    realtimeDataSource = _FakeQuizMatchRealtimeDataSource();
    matchController = QuizMatchController(
      quizRepository: quizRepository,
      realtimeDataSource: realtimeDataSource,
      authController: authController,
    );
    Get.put<QuizMatchController>(matchController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('MultiplayerQuizScreen renders selection screen with header, search, chips, and cards',
      (tester) async {
    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const MultiplayerQuizScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1v1 Multiplayer Quiz'), findsOneWidget);
    expect(find.text('Choose a quiz to play 1v1'), findsOneWidget);
    expect(find.byType(MultiplayerQuizSearchBar), findsOneWidget);
    expect(find.byType(MultiplayerCategoryFilterChips), findsOneWidget);
    expect(find.byType(MultiplayerQuizCard), findsNWidgets(2));
    expect(find.text('Money Basics'), findsOneWidget);
    expect(find.text('Digital Privacy'), findsOneWidget);
    expect(find.byType(MultiplayerDiscoveryCard), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('MultiplayerQuizScreen search filters quizzes dynamically',
      (tester) async {
    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const MultiplayerQuizScreen(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Digital');
    await tester.pumpAndSettle();

    expect(find.text('Digital Privacy'), findsOneWidget);
    expect(find.text('Money Basics'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Unknown Quiz');
    await tester.pumpAndSettle();

    expect(find.text('No quizzes match your search.'), findsOneWidget);
  });

  testWidgets('MultiplayerQuizScreen category filter chips filter quizzes',
      (tester) async {
    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const MultiplayerQuizScreen(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();

    expect(find.text('Money Basics'), findsOneWidget);
    expect(find.text('Digital Privacy'), findsNothing);
  });

  testWidgets('MultiplayerQuizScreen renders matchmaking phase and handles cancel',
      (tester) async {
    await quizController.loadQuizzes();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const MultiplayerQuizScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the quiz to start match
    await tester.tap(find.text('Money Basics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Now in matchmaking phase
    expect(find.byType(MultiplayerMatchupHero), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Level 4'), findsOneWidget);
    expect(find.byType(CancelMatchButton), findsOneWidget);

    // Cancel match
    await tester.tap(find.byType(CancelMatchButton));
    await tester.pumpAndSettle();

    expect(realtimeDataSource.unsubscribedMatchIds.isNotEmpty ||
        matchController.phase.value == QuizMatchPhase.idle, isTrue);
  });

  testWidgets('MultiplayerQuizScreen renders playing state with scoreboard, question, and submit',
      (tester) async {
    const testQuestion = QuizQuestion(
      id: 'q-1',
      question: 'What is a budget?',
      options: [
        QuizOptionModel(
          id: 'opt-1',
          text: 'A plan for your income and spending',
        ),
        QuizOptionModel(id: 'opt-2', text: 'A type of bank account'),
      ],
    );

    matchController.questions.assignAll([testQuestion]);
    matchController.matchId.value = 'match-123';
    matchController.phase.value = QuizMatchPhase.playing;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const MultiplayerQuizScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MultiplayerScoreboard), findsOneWidget);
    expect(find.byType(MultiplayerProgressAndTimer), findsOneWidget);
    expect(find.byType(MultiplayerQuestionCard), findsOneWidget);
    expect(find.text('What is a budget?'), findsOneWidget);
    expect(find.byType(MultiplayerOptionTile), findsNWidgets(2));
    expect(find.byType(MultiplayerSubmitButton), findsOneWidget);

    // Tap first option
    await tester.tap(find.text('A plan for your income and spending'));
    await tester.pumpAndSettle();

    // Tap Submit Answer
    await tester.tap(find.text('Submit Answer'));
    await tester.pumpAndSettle();

    expect(matchController.submittedQuestionIds.contains('q-1'), isTrue);
  });

  testWidgets('MultiplayerQuizScreen renders completed state with result banner, scores, XP and play again',
      (tester) async {
    const event = QuizMatchEvent(
      matchId: 'match-123',
      quizId: 'quiz-1',
      status: QuizMatchStatus.completed,
      player1: QuizMatchPlayer(id: 'user-1', name: 'Makara Ren', score: 30),
      player2: QuizMatchPlayer(id: 'opp-1', name: 'Opponent', score: 10),
      winnerId: 'user-1',
    );

    matchController.matchId.value = 'match-123';
    matchController.matchEvent.value = event;
    matchController.phase.value = QuizMatchPhase.completed;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData.light(useMaterial3: true),
        home: const MultiplayerQuizScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MultiplayerResultBanner), findsOneWidget);
    expect(find.text('You won the match!'), findsOneWidget);
    expect(find.byType(MultiplayerScoreboard), findsOneWidget);
    expect(find.byType(MultiplayerXpCard), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.byType(MultiplayerMotivationalCard), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Back to Dashboard'), findsOneWidget);
  });
}

