import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = _MockAuthRepository();
    controller =
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
        home: const VerifyOtpScreen(),
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

  testWidgets('uses custom keypad and enforces six-digit editing', (
    tester,
  ) async {
    await pumpScreen(tester);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);
    expect(find.byType(EditableText), findsNothing);
    expect(find.byKey(const ValueKey('otp-active-cursor')), findsOneWidget);
    expect(find.textContaining('Resend code in 0:47'), findsOneWidget);
    expect(
      find.text(
        "Didn't receive it? Check your spam folder or try a different email address.",
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('verify-email-button')))
          .onPressed,
      isNull,
    );

    await tapKey(tester, '*');
    expect(find.byKey(const ValueKey('otp-active-cursor')), findsOneWidget);

    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tapKey(tester, digit);
    }

    for (var index = 0; index < 6; index++) {
      expect(digitInCell(index, '${index + 1}'), findsOneWidget);
    }
    expect(
      tester
          .widget<AppButton>(find.byKey(const ValueKey('verify-email-button')))
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
          .widget<AppButton>(find.byKey(const ValueKey('verify-email-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('submits the entered code only after all six digits', (
    tester,
  ) async {
    when(
      () => repository.verifyEmail(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
      ),
    ).thenThrow(
      const AppError(message: 'Invalid code', errorCode: 'OTP_INVALID'),
    );
    await pumpScreen(tester);

    for (final digit in ['1', '2', '3', '4', '5']) {
      await tapKey(tester, digit);
    }
    verifyNever(
      () => repository.verifyEmail(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
      ),
    );

    await tapKey(tester, '6');
    final verifyButton = find.byKey(const ValueKey('verify-email-button'));
    await tester.ensureVisible(verifyButton);
    await tester.tap(verifyButton);
    await tester.pumpAndSettle();

    verify(
      () => repository.verifyEmail(email: 'makara.it@email.com', otp: '123456'),
    ).called(1);
    expect(find.text('Invalid code'), findsOneWidget);
  });
}
