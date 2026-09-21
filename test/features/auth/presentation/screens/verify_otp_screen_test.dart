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

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
  }) async {
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
        locale: locale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: theme ?? AppTheme.lightFor(locale.languageCode),
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
    expect(find.textContaining('Resend code in 00:47'), findsOneWidget);
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
    expect(
      find.text('The code you entered is incorrect. Please check and try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'displays compact error card on invalid code, preserves digits, and supports re-editing',
    (tester) async {
      when(
        () => repository.verifyEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(
        const AppError(
          message: 'Invalid verification code',
          errorCode: 'OTP_INVALID',
        ),
      );
      await pumpScreen(tester);

      // Enter 6 digits: 6, 9, 5, 0, 8, 5
      for (final digit in ['6', '9', '5', '0', '8', '5']) {
        await tapKey(tester, digit);
      }

      final continueButton = find.byKey(const ValueKey('verify-email-button'));
      expect(tester.widget<AppButton>(continueButton).onPressed, isNotNull);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Error message card is shown with proper title and description
      expect(find.byKey(const ValueKey('otp-error')), findsOneWidget);
      expect(find.text('Invalid verification code'), findsOneWidget);
      expect(
        find.text(
          'The code you entered is incorrect. Please check and try again.',
        ),
        findsOneWidget,
      );

      // Entered digits remain visible
      expect(digitInCell(0, '6'), findsOneWidget);
      expect(digitInCell(1, '9'), findsOneWidget);
      expect(digitInCell(2, '5'), findsOneWidget);
      expect(digitInCell(3, '0'), findsOneWidget);
      expect(digitInCell(4, '8'), findsOneWidget);
      expect(digitInCell(5, '5'), findsOneWidget);

      // User backspaces to edit code
      await tapKey(tester, 'backspace');
      expect(digitInCell(5, '5'), findsNothing);
      expect(tester.widget<AppButton>(continueButton).onPressed, isNull);

      // Re-enter 6th digit
      await tapKey(tester, '7');
      expect(digitInCell(5, '7'), findsOneWidget);
      expect(tester.widget<AppButton>(continueButton).onPressed, isNotNull);
    },
  );

  testWidgets('shows resend code action when cooldown finishes', (tester) async {
    controller.resendCooldown.value = 0;
    when(
      () => repository.resendVerificationOtp(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    await pumpScreen(tester);

    final resendButton = find.text('Resend code');
    expect(resendButton, findsOneWidget);

    await tester.tap(resendButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 61));

    verify(
      () => repository.resendVerificationOtp(email: 'makara.it@email.com'),
    ).called(1);
  });

  testWidgets(
    'displays solid error card with high contrast colors and 40px icon',
    (tester) async {
      when(
        () => repository.verifyEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(
        const AppError(
          message: 'Invalid verification code',
          errorCode: 'OTP_INVALID',
        ),
      );
      await pumpScreen(tester);

      for (final digit in ['6', '9', '5', '0', '8', '5']) {
        await tapKey(tester, digit);
      }

      await tester.tap(find.byKey(const ValueKey('verify-email-button')));
      await tester.pumpAndSettle();

      // 1. Solid opaque error card styling
      final errorCardFinder = find.byKey(const ValueKey('otp-error'));
      expect(errorCardFinder, findsOneWidget);
      final errorCard = tester.widget<Container>(errorCardFinder);
      final decoration = errorCard.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFF1F2));
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.border?.top.color, const Color(0xFFFECDD3));
      expect(decoration.boxShadow, isNotEmpty);

      // 2. 40px circular error icon container
      final iconFinder =
          find.byKey(const ValueKey('otp-error-icon-container'));
      expect(iconFinder, findsOneWidget);
      final iconSize = tester.getSize(iconFinder);
      expect(iconSize.width, 40.0);
      expect(iconSize.height, 40.0);

      // 3. High-contrast typography
      final titleText = tester.widget<Text>(
        find.byKey(const ValueKey('otp-error-title')),
      );
      expect(titleText.style?.fontWeight, FontWeight.w700);
      expect(titleText.style?.color, const Color(0xFF881337));

      final descText = tester.widget<Text>(
        find.byKey(const ValueKey('otp-error-description')),
      );
      expect(descText.style?.fontWeight, FontWeight.w500);
      expect(descText.style?.color, const Color(0xFF5A1E24));
      expect(descText.style?.height, 1.45);
    },
  );

  testWidgets(
    'only invalid active cell receives red border and soft pink background while others stay neutral',
    (tester) async {
      when(
        () => repository.verifyEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(
        const AppError(
          message: 'Invalid verification code',
          errorCode: 'OTP_INVALID',
        ),
      );
      await pumpScreen(tester);

      for (final digit in ['6', '9', '5', '0', '8', '5']) {
        await tapKey(tester, digit);
      }

      await tester.tap(find.byKey(const ValueKey('verify-email-button')));
      await tester.pumpAndSettle();

      // Cell 5 (active / last edited) has red border and soft pink fill
      final cell5Finder = find.descendant(
        of: find.byKey(const ValueKey('otp-cell-5')),
        matching: find.byType(AnimatedContainer),
      );
      expect(cell5Finder, findsOneWidget);
      final cell5 = tester.widget<AnimatedContainer>(cell5Finder);
      final cell5Deco = cell5.decoration as BoxDecoration;
      expect(cell5Deco.color, const Color(0xFFFFF1F2));
      expect(cell5Deco.border?.top.color, const Color(0xFFE11D48));

      // Cell 0 (inactive) remains neutral white with subtle gray border
      final cell0Finder = find.descendant(
        of: find.byKey(const ValueKey('otp-cell-0')),
        matching: find.byType(AnimatedContainer),
      );
      expect(cell0Finder, findsOneWidget);
      final cell0 = tester.widget<AnimatedContainer>(cell0Finder);
      final cell0Deco = cell0.decoration as BoxDecoration;
      expect(cell0Deco.color, Colors.white);
      expect(cell0Deco.border?.top.color, const Color(0xFFE5E7EB));
    },
  );

  testWidgets('editing any digit immediately dismisses the error card', (
    tester,
  ) async {
    when(
      () => repository.verifyEmail(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
      ),
    ).thenThrow(
      const AppError(
        message: 'Invalid verification code',
        errorCode: 'OTP_INVALID',
      ),
    );
    await pumpScreen(tester);

    for (final digit in ['6', '9', '5', '0', '8', '5']) {
      await tapKey(tester, digit);
    }

    await tester.tap(find.byKey(const ValueKey('verify-email-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('otp-error')), findsOneWidget);

    // Press backspace to edit
    await tapKey(tester, 'backspace');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Error card is dismissed
    expect(find.byKey(const ValueKey('otp-error')), findsNothing);
  });

  testWidgets(
    'renders in Khmer locale with KantumruyPro font and Khmer strings',
    (tester) async {
      await pumpScreen(tester, locale: const Locale('km', 'KH'));

      expect(find.text('ផ្ទៀងផ្ទាត់អ៊ីមែលរបស់អ្នក'), findsOneWidget);
      expect(find.textContaining('យើងបានផ្ញើលេខកូដ ៦ ខ្ទង់ទៅ'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'បន្ត'), findsOneWidget);
    },
  );
}
