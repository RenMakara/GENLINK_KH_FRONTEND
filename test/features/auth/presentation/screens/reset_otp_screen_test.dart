import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/reset_otp_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    final controller =
        AuthController(
            authRepository: repository,
            secureStorage: _MockSecureStorage(),
            localization: LocalizationService(localStorage: LocalStorage()),
          )
          ..pendingEmail.value = 'makara.it@email.com'
          ..resendCooldown.value = 47;
    Get
      ..testMode = true
      ..put<AuthController>(controller);
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.lightFor('en'),
        getPages: [
          GetPage<void>(
            name: AppRoutes.resetPassword,
            page: () => Scaffold(
              body: Text(
                'reset-password:${Get.arguments}',
                key: const ValueKey('reset-password-destination'),
              ),
            ),
          ),
        ],
        home: const ResetOtpScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String value) async {
    final finder = find.byKey(ValueKey('otp-key-$value'));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Finder digitInCell(int index, String digit) => find.descendant(
    of: find.byKey(ValueKey('otp-cell-$index')),
    matching: find.text(digit),
  );

  testWidgets('uses the shared keypad and enforces six-digit editing', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byType(EditableText), findsNothing);
    expect(find.byKey(const ValueKey('otp-keypad')), findsOneWidget);
    expect(find.textContaining('Resend code in 0:47'), findsOneWidget);
    expect(find.byKey(const ValueKey('otp-help-text')), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('reset-otp-continue-button')),
          )
          .onPressed,
      isNull,
    );

    await tapKey(tester, '*');
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tapKey(tester, digit);
    }

    for (var index = 0; index < 6; index++) {
      expect(digitInCell(index, '${index + 1}'), findsOneWidget);
    }
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('reset-otp-continue-button')),
          )
          .onPressed,
      isNotNull,
    );

    await tapKey(tester, '7');
    expect(digitInCell(5, '6'), findsOneWidget);
    expect(digitInCell(5, '7'), findsNothing);

    await tapKey(tester, 'backspace');
    expect(digitInCell(5, '6'), findsNothing);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const ValueKey('reset-otp-continue-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('carries the completed code to reset password', (tester) async {
    final verification = Completer<void>();
    when(
      () => repository.verifyResetOtp(
        email: 'makara.it@email.com',
        otp: '123456',
      ),
    ).thenAnswer((_) => verification.future);

    await pumpScreen(tester);

    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tapKey(tester, digit);
    }

    final continueButton = find.byKey(
      const ValueKey('reset-otp-continue-button'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    verification.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reset-password-destination')),
      findsOneWidget,
    );
    expect(find.text('reset-password:123456'), findsOneWidget);
  });

  testWidgets('shows invalid OTP without navigating to the password screen', (
    tester,
  ) async {
    when(
      () => repository.verifyResetOtp(
        email: 'makara.it@email.com',
        otp: '123456',
      ),
    ).thenThrow(
      const AppError(
        message: 'Invalid verification code',
        errorCode: 'OTP_INVALID',
        statusCode: 400,
      ),
    );

    await pumpScreen(tester);

    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tapKey(tester, digit);
    }

    await tester.tap(find.byKey(const ValueKey('reset-otp-continue-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reset-password-destination')), findsNothing);
    expect(find.byKey(const ValueKey('otp-error')), findsOneWidget);
    expect(find.text('Invalid verification code'), findsOneWidget);
  });
}
