import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/set_password_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/animated_auth_background.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = _MockAuthRepository();
    controller = AuthController(
      authRepository: repository,
      secureStorage: SecureStorage(),
      localization: LocalizationService(localStorage: LocalStorage()),
    );
    Get
      ..testMode = true
      ..put<LocalStorage>(LocalStorage())
      ..put<LocalizationService>(
        LocalizationService(localStorage: Get.find<LocalStorage>()),
      )
      ..put<AuthController>(controller);
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool optionalPrompt = false,
    UserEntity? user,
  }) async {
    if (user != null) {
      controller.currentUser.value = user;
    }

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.lightFor('en'),
        initialRoute: AppRoutes.setPassword,
        getPages: [
          GetPage(
            name: AppRoutes.setPassword,
            page: () => PasswordSetupScreen(optionalPrompt: optionalPrompt),
          ),
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Text('home destination')),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('login destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders set password mode with AuthScaffold, background, and inputs',
    (tester) async {
      await pumpScreen(tester);

      expect(find.byType(AuthScaffold), findsOneWidget);
      expect(find.byType(AnimatedAuthBackground), findsOneWidget);
      expect(find.text('Set up your password'), findsOneWidget);
      expect(
        find.text(
          'Create a password so you can also sign in to GenLink with your email and password.',
        ),
        findsOneWidget,
      );

      // Back button visible when not optionalPrompt
      expect(find.byType(AppBackButton), findsOneWidget);

      // Inputs
      expect(find.byKey(const ValueKey('current-password-input')), findsNothing);
      expect(find.byKey(const ValueKey('password-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm-password-input')), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);

      // Submit button
      final submitButton = find.byKey(const ValueKey('password-submit-button'));
      expect(submitButton, findsOneWidget);
      expect(find.descendant(of: submitButton, matching: find.text('Set Password')), findsOneWidget);
    },
  );

  testWidgets('renders change password mode when user already has password', (
    tester,
  ) async {
    const userWithPassword = UserEntity(
      id: 'u1',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 1,
      preferredLanguage: 'ENGLISH',
      role: 'USER',
      active: true,
      hasPassword: true,
    );

    await pumpScreen(tester, user: userWithPassword);

    expect(find.text('Change Password'), findsWidgets);
    expect(
      find.byKey(const ValueKey('current-password-input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('password-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-password-input')), findsOneWidget);

    final submitButton = find.byKey(const ValueKey('password-submit-button'));
    expect(
      find.descendant(of: submitButton, matching: find.text('Change Password')),
      findsOneWidget,
    );
  });

  testWidgets(
    'optional prompt hides back button and shows maybe later button',
    (tester) async {
      await pumpScreen(tester, optionalPrompt: true);

      // Back button is hidden
      expect(find.byType(AppBackButton), findsNothing);

      // Maybe later button is visible
      final maybeLater = find.byKey(const ValueKey('maybe-later-button'));
      expect(maybeLater, findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);

      await tester.tap(maybeLater);
      await tester.pumpAndSettle();

      expect(find.text('home destination'), findsOneWidget);
    },
  );

  testWidgets('validates password length and matching passwords', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('password-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);

    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('password-input')),
      matching: find.byType(EditableText),
    );
    final confirmField = find.descendant(
      of: find.byKey(const ValueKey('confirm-password-input')),
      matching: find.byType(EditableText),
    );

    // Enter short password
    await tester.enterText(passwordField, '12345');
    await tester.enterText(confirmField, '12345678');
    await tester.tap(find.byKey(const ValueKey('password-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters'), findsWidgets);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('successfully submits set password and routes', (tester) async {
    when(
      () => repository.setPassword(password: any(named: 'password')),
    ).thenAnswer((_) async => true);

    await pumpScreen(tester, optionalPrompt: true);

    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('password-input')),
      matching: find.byType(EditableText),
    );
    final confirmField = find.descendant(
      of: find.byKey(const ValueKey('confirm-password-input')),
      matching: find.byType(EditableText),
    );

    await tester.enterText(passwordField, 'NewSecurePass123');
    await tester.enterText(confirmField, 'NewSecurePass123');

    await tester.tap(find.byKey(const ValueKey('password-submit-button')));
    await tester.pumpAndSettle();

    verify(() => repository.setPassword(password: 'NewSecurePass123')).called(1);
    expect(find.text('home destination'), findsOneWidget);
  });

  testWidgets(
    'optional prompt immediately routes to home when user already has password',
    (tester) async {
      const userWithPassword = UserEntity(
        id: 'u1',
        fullName: 'Test User',
        username: 'testuser',
        email: 'test@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: true,
      );

      await pumpScreen(tester, optionalPrompt: true, user: userWithPassword);
      await tester.pumpAndSettle();

      expect(find.text('home destination'), findsOneWidget);
    },
  );

  testWidgets(
    'handles AUTH_PASSWORD_ALREADY_SET gracefully on optional prompt by routing to home',
    (tester) async {
      when(
        () => repository.setPassword(password: any(named: 'password')),
      ).thenThrow(
        const AppError(
          message: 'This account already has a password set',
          errorCode: 'AUTH_PASSWORD_ALREADY_SET',
        ),
      );

      const userWithoutPassword = UserEntity(
        id: 'u1',
        fullName: 'Test User',
        username: 'testuser',
        email: 'test@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'ENGLISH',
        role: 'USER',
        active: true,
        hasPassword: false,
      );

      await pumpScreen(tester, optionalPrompt: true, user: userWithoutPassword);

      final passwordField = find.descendant(
        of: find.byKey(const ValueKey('password-input')),
        matching: find.byType(EditableText),
      );
      final confirmField = find.descendant(
        of: find.byKey(const ValueKey('confirm-password-input')),
        matching: find.byType(EditableText),
      );

      await tester.enterText(passwordField, 'NewSecurePass123');
      await tester.enterText(confirmField, 'NewSecurePass123');

      await tester.tap(find.byKey(const ValueKey('password-submit-button')));
      await tester.pumpAndSettle();

      expect(controller.currentUser.value?.hasPassword, isTrue);
      expect(find.text('home destination'), findsOneWidget);
    },
  );
}
