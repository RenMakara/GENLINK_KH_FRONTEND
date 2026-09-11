import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:genlink_frontend/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockQuizRepository extends Mock implements QuizRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

const _accountA = UserEntity(
  id: 'account-a',
  fullName: 'Account A',
  username: 'account_a',
  email: 'a@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 245,
  level: 3,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

const _accountB = UserEntity(
  id: 'account-b',
  fullName: 'Account B',
  username: 'account_b',
  email: 'b@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 820,
  level: 9,
  preferredLanguage: 'KHMER',
  role: 'USER',
  active: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;

  setUp(() {
    Get.testMode = true;
    Get.put<QuizRepository>(_MockQuizRepository());
    authController = AuthController(
      authRepository: _MockAuthRepository(),
      secureStorage: _MockSecureStorage(),
      localization: LocalizationService(localStorage: LocalStorage()),
    );
    Get.put<AuthController>(authController);
  });

  tearDown(Get.reset);

  test('Quiz profile follows the shared authenticated account', () {
    final controller = QuizController();

    controller.syncAuthenticatedUser(_accountA);
    expect(controller.userStats.value.name, 'Account A');
    expect(controller.userStats.value.avatarUrl, isNull);
    expect(controller.userStats.value.xp, 245);
    expect(controller.userStats.value.level, 3);
    expect(controller.userStats.value.streak, isNull);
    expect(controller.userStats.value.coins, isNull);

    controller.syncAuthenticatedUser(_accountB);
    expect(controller.userStats.value.name, 'Account B');
    expect(controller.userStats.value.xp, 820);
    expect(controller.userStats.value.level, 9);

    controller.syncAuthenticatedUser(null);
    expect(controller.userStats.value.name, isEmpty);
    expect(controller.userStats.value.xp, 0);
  });

  test('Quiz profile progress uses the backend level band', () {
    final controller = QuizController();

    controller.syncAuthenticatedUser(_accountA);

    expect(controller.userStats.value.levelProgress, 0.45);
  });
}
