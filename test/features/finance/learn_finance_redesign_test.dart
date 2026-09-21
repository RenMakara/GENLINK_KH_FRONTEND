import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_learning_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/learn_finance_feature/investing_basics.dart';
import 'package:genlink_frontend/features/finance/presentation/learn_finance_feature/learn_finance.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceLearningDashboardEntity _mockDashboard({
  int completed = 0,
  int total = 6,
  int xp = 0,
}) {
  return FinanceLearningDashboardEntity(
    totalLessons: total,
    completedLessons: completed,
    literacyXp: xp,
    topics: const [
      FinanceLearningTopicProgressEntity(
        topic: 'SAVING_MONEY',
        lessonCount: 2,
        completedCount: 0,
      ),
      FinanceLearningTopicProgressEntity(
        topic: 'BUDGETING',
        lessonCount: 1,
        completedCount: 0,
      ),
      FinanceLearningTopicProgressEntity(
        topic: 'DEBT_AWARENESS',
        lessonCount: 1,
        completedCount: 0,
      ),
      FinanceLearningTopicProgressEntity(
        topic: 'INVESTING_BASICS',
        lessonCount: 1,
        completedCount: 0,
      ),
      FinanceLearningTopicProgressEntity(
        topic: 'EMERGENCY_FUND',
        lessonCount: 1,
        completedCount: 0,
      ),
    ],
  );
}

FinanceLearningLessonSummaryEntity _mockLesson({
  required String id,
  required String title,
  required String topic,
  required String contentType,
  int xp = 20,
  int? estimatedTime = 5,
  bool completed = false,
}) {
  return FinanceLearningLessonSummaryEntity(
    lessonId: id,
    title: title,
    topic: topic,
    contentType: contentType,
    estimatedTime: estimatedTime,
    xpReward: xp,
    completed: completed,
    quizPassed: false,
  );
}

FinanceLearningLessonDetailEntity _mockLessonDetail({
  required String id,
  required String title,
}) {
  return FinanceLearningLessonDetailEntity(
    lessonId: id,
    title: title,
    content: 'Lesson content here',
    topic: 'BUDGETING',
    contentType: 'ARTICLE',
    mediaUrl: null,
    estimatedTime: 5,
    xpReward: 20,
    completed: false,
    quizPassed: false,
    questionCount: 1,
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceLearningController controller;

  final sampleLessons = [
    _mockLesson(
      id: 'lesson-1',
      title: 'Build your first budget',
      topic: 'BUDGETING',
      contentType: 'ARTICLE',
      xp: 20,
      estimatedTime: 5,
      completed: false,
    ),
    _mockLesson(
      id: 'lesson-2',
      title: 'Understand debt before you borrow',
      topic: 'DEBT_AWARENESS',
      contentType: 'KHMER_TIP',
      xp: 20,
      estimatedTime: 4,
      completed: false,
    ),
    _mockLesson(
      id: 'lesson-3',
      title: 'Your emergency fund',
      topic: 'EMERGENCY_FUND',
      contentType: 'ARTICLE',
      xp: 20,
      estimatedTime: 6,
      completed: false,
    ),
    _mockLesson(
      id: 'lesson-4',
      title: 'Investing basics',
      topic: 'INVESTING_BASICS',
      contentType: 'VIDEO',
      xp: 25,
      estimatedTime: 8,
      completed: false,
    ),
    _mockLesson(
      id: 'lesson-5',
      title: 'Why saving early matters',
      topic: 'SAVING_MONEY',
      contentType: 'ARTICLE',
      xp: 20,
      estimatedTime: 5,
      completed: false,
    ),
  ];

  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    repository = _MockFinanceRepository();
    when(() => repository.getLearningDashboard())
        .thenAnswer((_) async => _mockDashboard());

    when(() => repository.getLearningLessons(topic: any(named: 'topic')))
        .thenAnswer((invocation) async {
      final topic = invocation.namedArguments[#topic] as String?;
      if (topic == null || topic.isEmpty) return sampleLessons;
      return sampleLessons
          .where((l) => l.topic.toUpperCase() == topic.toUpperCase())
          .toList();
    });

    when(() => repository.getLearningLesson(any()))
        .thenAnswer((_) async => _mockLessonDetail(
              id: 'lesson-1',
              title: 'Build your first budget',
            ));

    controller = FinanceLearningController(repository: repository);
    Get.put<FinanceLearningController>(controller);
  });

  tearDown(Get.reset);

  Widget buildTestApp({
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en', 'US'),
    Widget? home,
  }) {
    final isDark = brightness == Brightness.dark;
    Get.locale = locale;
    return GetMaterialApp(
      locale: locale,
      theme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor:
            isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
      ),
      home: home ?? const LearnFinanceScreen(),
    );
  }

  Finder mainScrollable() => find.byType(Scrollable).first;

  testWidgets(
    'renders redesigned LearnFinanceScreen with header, hero banner, progress, topics, featured, lessons, and motivation',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Learn Finance'), findsOneWidget);
      expect(
        find.text('Build better money habits, one lesson at a time'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Hero Banner
      expect(
        find.text('Small Steps\nBig Financial Freedom'),
        findsOneWidget,
      );
      expect(find.text('Learn. Apply. Grow.'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);

      // Progress Card
      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('0/6'), findsOneWidget);
      expect(find.text('0 of 6 lessons completed'), findsOneWidget);
      expect(find.text('XP earned'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('Day streak'), findsOneWidget);

      // Topics Section
      expect(find.text('Topics'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('Saving Money'), findsWidgets);
      expect(find.text('Budgeting'), findsWidgets);

      // Featured for You Section
      expect(find.text('Featured for You'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('Build your first budget'), findsWidgets);

      // Lessons Section Header
      expect(find.text('Lessons'), findsOneWidget);

      // Scroll down to view motivation banner
      await tester.scrollUntilVisible(
        find.text('Keep learning, keep growing!'),
        300,
        scrollable: mainScrollable(),
      );

      expect(find.text('Keep learning, keep growing!'), findsOneWidget);
      expect(
        find.text('Complete lessons to earn XP and unlock badges.'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'toggling search expands input and filters lessons dynamically',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap search button in header
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      // Search bar is now visible
      expect(find.text('Search lessons...'), findsOneWidget);

      // Enter query "debt"
      await tester.enterText(find.byType(TextField), 'debt');
      await tester.pumpAndSettle();

      // Only debt lesson is shown in filtered list
      expect(find.text('Understand debt before you borrow'), findsOneWidget);
      expect(find.text('Build your first budget'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      // All lessons return
      expect(find.text('Build your first budget'), findsWidgets);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hero banner "Continue Learning" navigates to InvestingBasicsScreen',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap Continue Learning CTA
      await tester.tap(find.text('Continue Learning'));
      await tester.pumpAndSettle();

      // Navigates to InvestingBasicsScreen
      expect(find.byType(InvestingBasicsScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'topics filter updates selected topic and can be reset with See All',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap "Budgeting" topic chip in horizontal list
      final budgetingChip = find.text('Budgeting').first;
      await tester.tap(budgetingChip);
      await tester.pumpAndSettle();

      verify(() => repository.getLearningLessons(topic: 'BUDGETING')).called(1);

      // Tap "See All" to reset
      await tester.tap(find.text('See All'));
      await tester.pumpAndSettle();

      // topic: null was called once on init, and once on reset = 2 calls
      verify(() => repository.getLearningLessons(topic: null)).called(2);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping a lesson card navigates to InvestingBasicsScreen',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap lesson item
      final lessonItem = find.text('Understand debt before you borrow');
      await tester.scrollUntilVisible(
        lessonItem,
        200,
        scrollable: mainScrollable(),
      );
      await tester.tap(lessonItem);
      await tester.pumpAndSettle();

      expect(find.byType(InvestingBasicsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders correctly in Dark Mode with dark theme styling',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      // Verifies render without crashes
      expect(find.text('Learn Finance'), findsOneWidget);
      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('Topics'), findsOneWidget);
      expect(find.text('Featured for You'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders cleanly with Khmer locale (km_KH) without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestApp(locale: const Locale('km', 'KH')),
      );
      await tester.pumpAndSettle();

      // Khmer localized texts
      expect(find.text('រៀនអំពីហិរញ្ញវត្ថុ'), findsOneWidget);
      expect(
        find.text('បង្កើតទម្លាប់ហិរញ្ញវត្ថុកាន់តែប្រសើរ មេរៀនម្តងមួយៗ'),
        findsOneWidget,
      );
      expect(
        find.text('ជំហានតូចៗ\nសេរីភាពហិរញ្ញវត្ថុធំធេង'),
        findsOneWidget,
      );
      expect(find.text('រៀន។ អនុវត្ត។ រីកចម្រើន។'), findsOneWidget);
      expect(find.text('បន្តការសិក្សា'), findsOneWidget);
      expect(find.text('វឌ្ឍនភាពរបស់អ្នក'), findsOneWidget);
      expect(find.text('ផ្លាកសញ្ញា'), findsOneWidget);
      expect(find.text('ថ្ងៃជាប់ៗគ្នា'), findsOneWidget);
      expect(find.text('ប្រធានបទ'), findsOneWidget);
      expect(find.text('មើលទាំងអស់'), findsOneWidget);
      expect(find.text('ពិសេសសម្រាប់អ្នក'), findsOneWidget);
      expect(find.text('ពេញនិយម'), findsOneWidget);
      expect(find.text('មេរៀន'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'responsive check: renders cleanly on 320px narrow device without RenderFlex overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Learn Finance'), findsOneWidget);
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('0/6'), findsOneWidget);

      // Verify no exceptions or overflow occurred
      expect(tester.takeException(), isNull);
    },
  );
}
