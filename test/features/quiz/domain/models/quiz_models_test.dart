import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/quiz/domain/models/quiz_models.dart';

void main() {
  group('QuizSummary', () {
    test('parses entertainment quiz list response fields', () {
      final quiz = QuizSummary.fromJson({
        'quizId': 'd0000000-0000-4000-8000-000000000001',
        'title': 'Money Basics',
        'category': 'FINANCE',
        'difficulty': 'EASY',
        'xpReward': 30,
        'questionCount': 3,
      });

      expect(quiz.quizId, 'd0000000-0000-4000-8000-000000000001');
      expect(quiz.title, 'Money Basics');
      expect(quiz.category, 'FINANCE');
      expect(quiz.difficulty, 'EASY');
      expect(quiz.xpReward, 30);
      expect(quiz.questionCount, 3);
    });
  });

  group('QuizAttemptSummary', () {
    test('parses entertainment quiz history response fields', () {
      final attempt = QuizAttemptSummary.fromJson({
        'attemptId': 'attempt-1',
        'quizId': 'quiz-1',
        'quizTitle': 'Money Basics',
        'score': 100,
        'correctCount': 3,
        'totalQuestions': 3,
        'xpEarned': 30,
        'completedAt': '2026-08-30T10:00:00',
      });

      expect(attempt.attemptId, 'attempt-1');
      expect(attempt.quizId, 'quiz-1');
      expect(attempt.quizTitle, 'Money Basics');
      expect(attempt.score, 100);
      expect(attempt.correctCount, 3);
      expect(attempt.totalQuestions, 3);
      expect(attempt.xpEarned, 30);
      expect(attempt.completedAt, '2026-08-30T10:00:00');
    });
  });
}
