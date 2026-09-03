import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/finance/data/models/finance_models.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/domain/repositories/finance_repository.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_learning_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinanceRepository extends Mock implements FinanceRepository {}

FinanceLearningDashboardEntity _dashboard({int completed = 1, int total = 4}) {
  return FinanceLearningDashboardEntity(
    totalLessons: total,
    completedLessons: completed,
    literacyXp: 100,
    topics: const [
      FinanceLearningTopicProgressEntity(
        topic: 'INVESTING_BASICS',
        lessonCount: 2,
        completedCount: 1,
      ),
    ],
  );
}

FinanceLearningLessonSummaryEntity _summary({
  String id = 'lesson-1',
  String topic = 'INVESTING_BASICS',
  bool completed = false,
}) {
  return FinanceLearningLessonSummaryEntity(
    lessonId: id,
    title: 'Investing basics',
    topic: topic,
    contentType: 'ARTICLE',
    estimatedTime: 6,
    xpReward: 100,
    completed: completed,
    quizPassed: false,
  );
}

FinanceLearningLessonDetailEntity _detail({
  String id = 'lesson-1',
  String title = 'Investing basics',
  bool completed = false,
}) {
  return FinanceLearningLessonDetailEntity(
    lessonId: id,
    title: title,
    content: 'Read this lesson.',
    topic: 'INVESTING_BASICS',
    contentType: 'ARTICLE',
    mediaUrl: null,
    estimatedTime: 6,
    xpReward: 100,
    completed: completed,
    quizPassed: false,
    questionCount: 1,
  );
}

FinanceLearningQuizQuestionEntity _question({String id = 'question-1'}) {
  return FinanceLearningQuizQuestionEntity(
    questionId: id,
    questionText: 'Which option is correct?',
    options: const [
      FinanceLearningQuizOptionEntity(key: 'A', text: 'First'),
      FinanceLearningQuizOptionEntity(key: 'B', text: 'Second'),
    ],
  );
}

FinanceLearningQuizResultEntity _result() {
  return const FinanceLearningQuizResultEntity(
    score: 100,
    correctCount: 1,
    totalQuestions: 1,
    passed: true,
    xpEarned: 100,
    learningBudgetCredited: 1.5,
    results: [
      FinanceLearningQuizQuestionResultEntity(
        questionId: 'question-1',
        selectedOption: 'A',
        correctOption: 'A',
        correct: true,
        explanation: 'Correct.',
      ),
    ],
  );
}

void main() {
  late _MockFinanceRepository repository;
  late FinanceLearningController controller;

  setUp(() {
    repository = _MockFinanceRepository();
    controller = FinanceLearningController(repository: repository);
    when(
      () => repository.getLearningDashboard(),
    ).thenAnswer((_) async => _dashboard());
    when(
      () => repository.getLearningLessons(topic: any<String?>(named: 'topic')),
    ).thenAnswer((_) async => [_summary()]);
    when(
      () => repository.getLearningLesson(any()),
    ).thenAnswer((_) async => _detail());
    when(
      () => repository.getLearningQuiz(any()),
    ).thenAnswer((_) async => [_question()]);
  });

  tearDown(Get.reset);

  test('loads dashboard progress and lesson list from backend', () async {
    await controller.loadDashboard();
    await controller.loadLessons();

    expect(controller.dashboard.value?.completedLessons, 1);
    expect(controller.lessons.single.lessonId, 'lesson-1');
    verify(() => repository.getLearningDashboard()).called(1);
    verify(() => repository.getLearningLessons(topic: null)).called(1);
  });

  test('dashboard and lesson errors expose errors without mock data', () async {
    when(() => repository.getLearningDashboard()).thenThrow(
      const AppError(message: 'Dashboard unavailable', errorCode: 'NETWORK'),
    );
    when(
      () => repository.getLearningLessons(topic: any<String?>(named: 'topic')),
    ).thenThrow(
      const AppError(message: 'Lessons unavailable', errorCode: 'NETWORK'),
    );

    await controller.loadDashboard();
    await controller.loadLessons();

    expect(controller.dashboard.value, isNull);
    expect(controller.lessons, isEmpty);
    expect(controller.dashboardErrorMessage.value, 'Dashboard unavailable');
    expect(controller.lessonsErrorMessage.value, 'Lessons unavailable');
  });

  test(
    'topic selection sends canonical backend enum and resets the list',
    () async {
      when(
        () => repository.getLearningLessons(topic: 'SAVING_MONEY'),
      ).thenAnswer((_) async => [_summary(topic: 'SAVING_MONEY')]);

      await controller.selectTopic(' saving_money ');

      expect(controller.selectedTopic.value, 'SAVING_MONEY');
      expect(controller.lessons.single.topic, 'SAVING_MONEY');
      verify(
        () => repository.getLearningLessons(topic: 'SAVING_MONEY'),
      ).called(1);
    },
  );

  test('a late detail response cannot overwrite the newer lesson', () async {
    final first = Completer<FinanceLearningLessonDetailEntity>();
    when(
      () => repository.getLearningLesson('lesson-1'),
    ).thenAnswer((_) => first.future);
    when(
      () => repository.getLearningLesson('lesson-2'),
    ).thenAnswer((_) async => _detail(id: 'lesson-2', title: 'Second'));

    final firstRequest = controller.loadLesson('lesson-1');
    await controller.loadLesson('lesson-2');
    first.complete(_detail(id: 'lesson-1', title: 'First'));
    await firstRequest;

    expect(controller.selectedLesson.value?.lessonId, 'lesson-2');
  });

  test('completion uses server detail and refreshes learning scopes', () async {
    final completed = _detail(completed: true);
    when(
      () => repository.completeLearningLesson('lesson-1'),
    ).thenAnswer((_) async => completed);

    expect(await controller.completeLesson('lesson-1'), isTrue);

    expect(controller.selectedLesson.value, same(completed));
    verify(() => repository.completeLearningLesson('lesson-1')).called(1);
    verify(() => repository.getLearningDashboard()).called(1);
    verify(() => repository.getLearningLessons(topic: null)).called(1);
  });

  test(
    'completion failure leaves authoritative lesson state unchanged',
    () async {
      final existing = _detail();
      controller.selectedLesson.value = existing;
      when(
        () => repository.completeLearningLesson('lesson-1'),
      ).thenThrow(const AppError(message: 'Cannot complete', errorCode: 'API'));

      expect(await controller.completeLesson('lesson-1'), isFalse);
      expect(controller.selectedLesson.value, same(existing));
      expect(controller.mutationErrorMessage.value, 'Cannot complete');
    },
  );

  test('duplicate completion taps produce one mutation request', () async {
    final completer = Completer<FinanceLearningLessonDetailEntity>();
    when(
      () => repository.completeLearningLesson('lesson-1'),
    ).thenAnswer((_) => completer.future);
    final first = controller.completeLesson('lesson-1');
    final second = controller.completeLesson('lesson-1');
    expect(await second, isFalse);
    completer.complete(_detail(completed: true));
    expect(await first, isTrue);
    verify(() => repository.completeLearningLesson('lesson-1')).called(1);
  });

  test('loads quiz questions without exposing correct answers', () async {
    await controller.loadQuiz('lesson-1');

    expect(controller.quizQuestions.single.options, hasLength(2));
    expect(controller.quizQuestions.single.options.first.key, 'A');
    expect(controller.quizResult.value, isNull);
    verify(() => repository.getLearningQuiz('lesson-1')).called(1);
  });

  test('submits quiz answers and refreshes progress/detail', () async {
    final result = _result();
    when(
      () => repository.submitLearningQuiz(
        lessonId: 'lesson-1',
        answers: [
          const FinanceLearningQuizAnswerEntity(
            questionId: 'question-1',
            selectedOption: 'A',
          ),
        ],
      ),
    ).thenAnswer((_) async => result);

    expect(
      await controller.submitQuiz(
        lessonId: 'lesson-1',
        answers: const [
          FinanceLearningQuizAnswerEntity(
            questionId: 'question-1',
            selectedOption: 'A',
          ),
        ],
      ),
      isTrue,
    );

    expect(controller.quizResult.value, same(result));
    verify(
      () => repository.submitLearningQuiz(
        lessonId: 'lesson-1',
        answers: any(named: 'answers'),
      ),
    ).called(1);
    verify(() => repository.getLearningDashboard()).called(1);
    verify(() => repository.getLearningLessons(topic: null)).called(1);
    verify(() => repository.getLearningLesson('lesson-1')).called(1);
  });

  test('empty quiz answers are blocked before the backend request', () async {
    expect(
      await controller.submitQuiz(lessonId: 'lesson-1', answers: const []),
      isFalse,
    );
    verifyNever(
      () => repository.submitLearningQuiz(
        lessonId: any(named: 'lessonId'),
        answers: any(named: 'answers'),
      ),
    );
  });

  test('duplicate quiz taps produce one submission request', () async {
    final completer = Completer<FinanceLearningQuizResultEntity>();
    when(
      () => repository.submitLearningQuiz(
        lessonId: 'lesson-1',
        answers: any(named: 'answers'),
      ),
    ).thenAnswer((_) => completer.future);
    final answers = const [
      FinanceLearningQuizAnswerEntity(
        questionId: 'question-1',
        selectedOption: 'A',
      ),
    ];
    final first = controller.submitQuiz(lessonId: 'lesson-1', answers: answers);
    final second = controller.submitQuiz(
      lessonId: 'lesson-1',
      answers: answers,
    );
    expect(await second, isFalse);
    completer.complete(_result());
    expect(await first, isTrue);
    verify(
      () => repository.submitLearningQuiz(
        lessonId: 'lesson-1',
        answers: any(named: 'answers'),
      ),
    ).called(1);
  });

  test(
    'learning mapper preserves detail, nullable metadata, and quiz result',
    () {
      final detail = FinanceMapper.learningLessonDetail({
        'lessonId': 'lesson-1',
        'title': 'Saving',
        'content': 'Content',
        'topic': 'SAVING_MONEY',
        'contentType': 'ARTICLE',
        'mediaUrl': null,
        'estimatedTime': null,
        'xpReward': 50,
        'completed': false,
        'quizPassed': false,
        'questionCount': 0,
      });
      final result = FinanceMapper.learningQuizResult({
        'score': 75,
        'correctCount': 3,
        'totalQuestions': 4,
        'passed': true,
        'xpEarned': 50,
        'learningBudgetCredited': '0.50',
        'results': [
          {
            'questionId': 'question-1',
            'selectedOption': 'B',
            'correctOption': 'A',
            'correct': false,
            'explanation': 'Try again.',
          },
        ],
      });

      expect(detail.estimatedTime, isNull);
      expect(detail.questionCount, 0);
      expect(result.learningBudgetCredited, 0.5);
      expect(result.results.single.correct, isFalse);
    },
  );

  test('quiz submit request serializes the documented answer shape', () {
    final request = FinanceLearningQuizSubmitRequestModel(
      answers: const [
        FinanceLearningQuizAnswerRequestModel(
          questionId: 'question-1',
          selectedOption: 'C',
        ),
      ],
    );
    expect(request.toJson(), {
      'answers': [
        {'questionId': 'question-1', 'selectedOption': 'C'},
      ],
    });
  });
}
