import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/challenge/domain/models/challenge_models.dart';
import 'package:genlink_frontend/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:genlink_frontend/features/challenge/presentation/controllers/challenge_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockChallengeRepository extends Mock implements ChallengeRepository {}

ChallengeModel _challenge({
  ChallengeStatus status = ChallengeStatus.notStarted,
  int progress = 0,
}) {
  return ChallengeModel(
    challengeId: 'challenge-1',
    title: 'Daily quiz',
    description: 'Complete the quiz',
    challengeType: ChallengeType.quiz,
    xpReward: 50,
    deadline: DateTime.utc(2026, 9, 20),
    status: status,
    progress: progress,
  );
}

void main() {
  late _MockChallengeRepository repository;
  late ChallengeController controller;

  setUp(() {
    repository = _MockChallengeRepository();
    controller = ChallengeController(repository: repository);
  });

  tearDown(() {
    controller.onClose();
  });

  test('loads real list state and clears loading state', () async {
    final completer = Completer<List<ChallengeModel>>();
    when(
      () => repository.getActiveChallenges(),
    ).thenAnswer((_) => completer.future);

    final request = controller.loadChallenges();
    expect(controller.isLoading.value, isTrue);

    completer.complete([_challenge()]);
    await request;

    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, isNull);
    expect(controller.challenges.single.challengeId, 'challenge-1');
    expect(controller.challenges.single.status, ChallengeStatus.notStarted);
  });

  test(
    'preserves an empty result without creating placeholder challenges',
    () async {
      when(
        () => repository.getActiveChallenges(),
      ).thenAnswer((_) async => const []);

      await controller.loadChallenges();

      expect(controller.challenges, isEmpty);
      expect(controller.errorMessage.value, isNull);
    },
  );

  test('exposes backend load errors to the error state', () async {
    when(() => repository.getActiveChallenges()).thenThrow(
      const AppError(message: 'Service unavailable', errorCode: 'API_ERROR'),
    );

    await controller.loadChallenges();

    expect(controller.isLoading.value, isFalse);
    expect(controller.errorMessage.value, 'Service unavailable');
  });

  test(
    'joins once, updates status, and blocks duplicate join requests',
    () async {
      controller.challenges.assignAll([_challenge()]);
      final completer = Completer<ChallengeModel>();
      when(
        () => repository.joinChallenge('challenge-1'),
      ).thenAnswer((_) => completer.future);

      final first = controller.joinChallenge('challenge-1');
      final duplicate = controller.joinChallenge('challenge-1');

      expect(controller.isJoining('challenge-1'), isTrue);
      verify(() => repository.joinChallenge('challenge-1')).called(1);

      completer.complete(
        _challenge(status: ChallengeStatus.inProgress, progress: 0),
      );
      await Future.wait([first, duplicate]);

      expect(controller.isJoining('challenge-1'), isFalse);
      expect(controller.challenges.single.status, ChallengeStatus.inProgress);
    },
  );

  test('completes once and blocks repeated completion calls', () async {
    controller.challenges.assignAll([
      _challenge(status: ChallengeStatus.inProgress, progress: 80),
    ]);
    when(() => repository.completeChallenge('challenge-1')).thenAnswer(
      (_) async => _challenge(status: ChallengeStatus.completed, progress: 100),
    );

    await controller.completeChallenge('challenge-1');
    await controller.completeChallenge('challenge-1');

    verify(() => repository.completeChallenge('challenge-1')).called(1);
    expect(controller.challenges.single.status, ChallengeStatus.completed);
    expect(controller.challenges.single.progress, 100);
  });

  test(
    'claims once, reflects claimed state, and blocks duplicate claims',
    () async {
      controller.challenges.assignAll([
        _challenge(status: ChallengeStatus.completed, progress: 100),
      ]);
      when(() => repository.claimReward('challenge-1')).thenAnswer(
        (_) async => _challenge(status: ChallengeStatus.claimed, progress: 100),
      );

      await controller.claimReward('challenge-1');
      await controller.claimReward('challenge-1');

      verify(() => repository.claimReward('challenge-1')).called(1);
      expect(controller.challenges.single.status, ChallengeStatus.claimed);
      expect(controller.challenges.single.isRewardClaimed, isTrue);
    },
  );

  test(
    'surfaces action errors and releases the duplicate-action lock',
    () async {
      controller.challenges.assignAll([_challenge()]);
      when(() => repository.joinChallenge('challenge-1')).thenThrow(
        const AppError(message: 'Join failed', errorCode: 'API_ERROR'),
      );

      await controller.joinChallenge('challenge-1');

      expect(controller.actionErrorMessage.value, 'Join failed');
      expect(controller.isJoining('challenge-1'), isFalse);
    },
  );
}
