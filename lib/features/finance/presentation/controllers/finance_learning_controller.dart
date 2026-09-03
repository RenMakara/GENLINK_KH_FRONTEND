import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';

/// Owns the server-backed Finance Learning state.
///
/// The learning API returns raw lists (not PageResponse) and has no currency
/// dimension. Request sequencing still protects topic/detail/progress reads
/// from late responses, while completion and quiz mutations only update state
/// after the backend confirms them.
class FinanceLearningController extends GetxController {
  FinanceLearningController({required this.repository});

  final FinanceRepository repository;

  final selectedTopic = RxnString();
  final dashboard = Rxn<FinanceLearningDashboardEntity>();
  final lessons = <FinanceLearningLessonSummaryEntity>[].obs;
  final selectedLesson = Rxn<FinanceLearningLessonDetailEntity>();
  final quizQuestions = <FinanceLearningQuizQuestionEntity>[].obs;
  final quizResult = Rxn<FinanceLearningQuizResultEntity>();

  final isDashboardLoading = false.obs;
  final isLessonsLoading = false.obs;
  final isDetailLoading = false.obs;
  final isQuizLoading = false.obs;
  final isRefreshing = false.obs;
  final isCompleteSubmitting = false.obs;
  final isQuizSubmitting = false.obs;

  final dashboardErrorMessage = RxnString();
  final lessonsErrorMessage = RxnString();
  final detailErrorMessage = RxnString();
  final quizErrorMessage = RxnString();
  final mutationErrorMessage = RxnString();

  int _dashboardRequestSequence = 0;
  int _lessonsRequestSequence = 0;
  int _detailRequestSequence = 0;
  int _quizRequestSequence = 0;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    loadLessons();
  }

  Future<void> loadDashboard({bool preserveExisting = false}) async {
    final request = ++_dashboardRequestSequence;
    isDashboardLoading.value = true;
    dashboardErrorMessage.value = null;
    if (!preserveExisting) dashboard.value = null;
    try {
      final result = await repository.getLearningDashboard();
      if (request != _dashboardRequestSequence) return;
      dashboard.value = result;
    } on AppError catch (error) {
      if (request != _dashboardRequestSequence) return;
      dashboardErrorMessage.value = error.message;
    } on FormatException catch (error) {
      if (request != _dashboardRequestSequence) return;
      dashboardErrorMessage.value = error.message;
    } catch (_) {
      if (request != _dashboardRequestSequence) return;
      dashboardErrorMessage.value = 'common.error'.tr;
    } finally {
      if (request == _dashboardRequestSequence) {
        isDashboardLoading.value = false;
      }
    }
  }

  Future<void> loadLessons({bool preserveExisting = false}) async {
    final request = ++_lessonsRequestSequence;
    final previous = List<FinanceLearningLessonSummaryEntity>.from(lessons);
    isLessonsLoading.value = true;
    lessonsErrorMessage.value = null;
    if (!preserveExisting) lessons.clear();
    try {
      final result = await repository.getLearningLessons(
        topic: selectedTopic.value,
      );
      if (request != _lessonsRequestSequence) return;
      lessons.assignAll(result);
    } on AppError catch (error) {
      if (request != _lessonsRequestSequence) return;
      if (preserveExisting) lessons.assignAll(previous);
      lessonsErrorMessage.value = error.message;
    } on FormatException catch (error) {
      if (request != _lessonsRequestSequence) return;
      if (preserveExisting) lessons.assignAll(previous);
      lessonsErrorMessage.value = error.message;
    } catch (_) {
      if (request != _lessonsRequestSequence) return;
      if (preserveExisting) lessons.assignAll(previous);
      lessonsErrorMessage.value = 'common.error'.tr;
    } finally {
      if (request == _lessonsRequestSequence) isLessonsLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    isRefreshing.value = true;
    try {
      await Future.wait<void>([
        loadDashboard(preserveExisting: true),
        loadLessons(preserveExisting: true),
      ]);
      final lessonId = selectedLesson.value?.lessonId;
      if (lessonId != null) await loadLesson(lessonId);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> selectTopic(String? topic) async {
    final trimmed = topic?.trim();
    final normalized = trimmed == null || trimmed.isEmpty
        ? null
        : trimmed.toUpperCase();
    if (normalized == selectedTopic.value) {
      return;
    }
    selectedTopic.value = normalized;
    await loadLessons();
  }

  Future<void> loadLesson(String lessonId) async {
    final request = ++_detailRequestSequence;
    isDetailLoading.value = true;
    detailErrorMessage.value = null;
    selectedLesson.value = null;
    try {
      final result = await repository.getLearningLesson(lessonId);
      if (request != _detailRequestSequence) return;
      selectedLesson.value = result;
    } on AppError catch (error) {
      if (request == _detailRequestSequence) {
        detailErrorMessage.value = error.message;
      }
    } on FormatException catch (error) {
      if (request == _detailRequestSequence) {
        detailErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _detailRequestSequence) {
        detailErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _detailRequestSequence) isDetailLoading.value = false;
    }
  }

  Future<bool> completeLesson(String lessonId) async {
    if (isCompleteSubmitting.value) return false;
    isCompleteSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      final result = await repository.completeLearningLesson(lessonId);
      selectedLesson.value = result;
      await Future.wait<void>([
        loadDashboard(preserveExisting: true),
        loadLessons(preserveExisting: true),
      ]);
      return true;
    } on AppError catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } on FormatException catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      mutationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isCompleteSubmitting.value = false;
    }
  }

  Future<void> loadQuiz(String lessonId) async {
    final request = ++_quizRequestSequence;
    isQuizLoading.value = true;
    quizErrorMessage.value = null;
    quizResult.value = null;
    quizQuestions.clear();
    try {
      final result = await repository.getLearningQuiz(lessonId);
      if (request != _quizRequestSequence) return;
      quizQuestions.assignAll(result);
    } on AppError catch (error) {
      if (request == _quizRequestSequence) {
        quizErrorMessage.value = error.message;
      }
    } on FormatException catch (error) {
      if (request == _quizRequestSequence) {
        quizErrorMessage.value = error.message;
      }
    } catch (_) {
      if (request == _quizRequestSequence) {
        quizErrorMessage.value = 'common.error'.tr;
      }
    } finally {
      if (request == _quizRequestSequence) isQuizLoading.value = false;
    }
  }

  Future<bool> submitQuiz({
    required String lessonId,
    required List<FinanceLearningQuizAnswerEntity> answers,
  }) async {
    if (isQuizSubmitting.value) return false;
    if (answers.isEmpty) {
      mutationErrorMessage.value = 'finance.learning.selectAllAnswers'.tr;
      return false;
    }
    isQuizSubmitting.value = true;
    mutationErrorMessage.value = null;
    try {
      final result = await repository.submitLearningQuiz(
        lessonId: lessonId,
        answers: answers,
      );
      quizResult.value = result;
      await Future.wait<void>([
        loadDashboard(preserveExisting: true),
        loadLessons(preserveExisting: true),
        loadLesson(lessonId),
      ]);
      return true;
    } on AppError catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } on FormatException catch (error) {
      mutationErrorMessage.value = error.message;
      return false;
    } catch (_) {
      mutationErrorMessage.value = 'common.error'.tr;
      return false;
    } finally {
      isQuizSubmitting.value = false;
    }
  }

  void clearMutationError() => mutationErrorMessage.value = null;
}
