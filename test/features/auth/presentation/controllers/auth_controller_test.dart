import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/auth_session.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/domain/services/google_auth_service.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/main_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

const _user = UserEntity(
  id: 'user-1',
  fullName: 'Sopheap Ren',
  username: 'sopheap',
  email: 'sopheap@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 2,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

const _session = AuthSession(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  tokenType: 'Bearer',
  user: _user,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository repository;
  late _MockSecureStorage storage;
  late _MockGoogleAuthService google;
  late MainController mainController;
  late AuthController controller;

  setUp(() {
    repository = _MockAuthRepository();
    storage = _MockSecureStorage();
    google = _MockGoogleAuthService();
    mainController = MainController();
    controller = AuthController(
      authRepository: repository,
      secureStorage: storage,
      localization: LocalizationService(localStorage: LocalStorage()),
      googleAuthService: google,
      onSessionCleared: mainController.reset,
    );
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('Google sign-in', () {
    test('keeps account-picker cancellation as a cancellation', () async {
      when(() => google.signIn()).thenAnswer((_) async => null);

      final result = await controller.signInWithGoogle();

      expect(result, isFalse);
      expect(controller.errorMessage.value, isNull);
      expect(controller.lastErrorCode.value, isNull);
      expect(controller.isLoading.value, isFalse);
      verifyNever(() => repository.googleLogin(idToken: any(named: 'idToken')));
    });

    test(
      'surfaces the native Google error without fabricating a token',
      () async {
        when(() => google.signIn()).thenThrow(
          const AppError(
            message: 'Google Sign-In is not configured.',
            errorCode: 'GOOGLE_SIGN_IN_NOT_CONFIGURED',
          ),
        );

        final result = await controller.signInWithGoogle();

        expect(result, isFalse);
        expect(controller.lastErrorCode.value, 'GOOGLE_SIGN_IN_NOT_CONFIGURED');
        expect(
          controller.errorMessage.value,
          'Google Sign-In is not configured.',
        );
        verifyNever(
          () => repository.googleLogin(idToken: any(named: 'idToken')),
        );
      },
    );

    test('persists a real Google session', () async {
      when(() => google.signIn()).thenAnswer((_) async => 'real-id-token');
      when(
        () => repository.googleLogin(idToken: 'real-id-token'),
      ).thenAnswer((_) async => _session);
      when(
        () => storage.saveTokenPair(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});
      when(() => storage.saveUserEmail(any())).thenAnswer((_) async {});
      when(() => storage.saveUserId(any())).thenAnswer((_) async {});

      final result = await controller.signInWithGoogle();

      expect(result, isTrue);
      expect(controller.isAuthenticated.value, isTrue);
      expect(controller.currentUser.value, same(_user));
      verify(
        () => storage.saveTokenPair(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        ),
      ).called(1);
    });
  });

  group('Session restoration', () {
    test(
      'preserves stored credentials during a transient network failure',
      () async {
        when(
          () => storage.readAccessToken(),
        ).thenAnswer((_) async => 'stored-access-token');
        when(() => repository.getCurrentUser()).thenThrow(
          const AppError(
            message: 'Connection refused',
            errorCode: 'NETWORK_ERROR',
          ),
        );

        final result = await controller.restoreSession();

        expect(result, isFalse);
        verifyNever(() => storage.clearAll());
      },
    );

    test('clears a confirmed expired session', () async {
      when(
        () => storage.readAccessToken(),
      ).thenAnswer((_) async => 'expired-access-token');
      when(() => repository.getCurrentUser()).thenThrow(
        const AppError(
          message: 'Token expired',
          errorCode: 'TOKEN_EXPIRED',
          statusCode: 401,
        ),
      );
      when(() => storage.clearAll()).thenAnswer((_) async {});

      final result = await controller.restoreSession();

      expect(result, isFalse);
      verify(() => storage.clearAll()).called(1);
    });

    test('restores an active user without rewriting the token pair', () async {
      when(
        () => storage.readAccessToken(),
      ).thenAnswer((_) async => 'stored-access-token');
      when(() => repository.getCurrentUser()).thenAnswer((_) async => _user);

      final result = await controller.restoreSession();

      expect(result, isTrue);
      expect(controller.isAuthenticated.value, isTrue);
      expect(controller.currentUser.value, same(_user));
      verifyNever(() => storage.clearAll());
    });
  });

  test('logout resets the main navigation tab to Home', () async {
    mainController.changeIndex(3);
    when(() => google.signOut()).thenAnswer((_) async {});
    when(() => repository.logout()).thenAnswer((_) async {});
    when(() => storage.clearAll()).thenAnswer((_) async {});

    await controller.logout();

    expect(mainController.currentIndex.value, MainController.defaultIndex);
    verify(() => storage.clearAll()).called(1);
  });
}
