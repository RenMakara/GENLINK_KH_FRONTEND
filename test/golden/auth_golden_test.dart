import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/design_system/widgets/branding/app_logo.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/auth_choice_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/reset_otp_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/animated_auth_background.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const phone = Size(390, 844);

  setUpAll(() => EditableText.debugDeterministicCursor = true);
  tearDownAll(() => EditableText.debugDeterministicCursor = false);

  setUp(() {
    Get
      ..put<LocalStorage>(LocalStorage())
      ..put<LocalizationService>(
        LocalizationService(localStorage: Get.find<LocalStorage>()),
      )
      ..put<AuthController>(
        AuthController(
          authRepository: _MockAuthRepository(),
          secureStorage: SecureStorage(),
          localization: Get.find<LocalizationService>(),
        ),
      );
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
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
        theme: brightness == Brightness.dark
            ? AppTheme.darkFor('en')
            : AppTheme.lightFor('en'),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedAuthBackground), findsOneWidget);
  }

  testWidgets('login', (tester) async {
    await pumpScreen(tester, const LoginScreen());
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('auth choice', (tester) async {
    await pumpScreen(tester, const AuthChoiceScreen());
    await expectLater(
      find.byType(AuthChoiceScreen),
      matchesGoldenFile('goldens/auth_choice.png'),
    );
  });

  testWidgets('auth choice (dark)', (tester) async {
    await pumpScreen(
      tester,
      const AuthChoiceScreen(),
      brightness: Brightness.dark,
    );
    final markSvg = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byType(AppLogoMark),
        matching: find.byType(SvgPicture),
      ),
    );
    expect((markSvg.bytesLoader as SvgAssetLoader).assetName, AppLogoAssets.glDark);
    await expectLater(
      find.byType(AuthChoiceScreen),
      matchesGoldenFile('goldens/auth_choice_dark.png'),
    );
  });

  testWidgets('register', (tester) async {
    await pumpScreen(tester, const RegisterScreen());
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register.png'),
    );
  });

  testWidgets('register (dark)', (tester) async {
    await pumpScreen(
      tester,
      const RegisterScreen(),
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register_dark.png'),
    );
  });

  testWidgets('verify otp', (tester) async {
    Get.find<AuthController>()
      ..pendingEmail.value = 'makara.it@email.com'
      ..resendCooldown.value = 47;

    await pumpScreen(tester, const VerifyOtpScreen());
    await expectLater(
      find.byType(VerifyOtpScreen),
      matchesGoldenFile('goldens/verify_otp.png'),
    );
  });

  testWidgets('reset otp', (tester) async {
    Get.find<AuthController>()
      ..pendingEmail.value = 'makara.it@email.com'
      ..resendCooldown.value = 47;

    await pumpScreen(tester, const ResetOtpScreen());
    await expectLater(
      find.byType(ResetOtpScreen),
      matchesGoldenFile('goldens/reset_otp.png'),
    );
  });

  testWidgets('forgot password', (tester) async {
    await pumpScreen(tester, const ForgotPasswordScreen());
    await expectLater(
      find.byType(ForgotPasswordScreen),
      matchesGoldenFile('goldens/forgot_password.png'),
    );
  });

  testWidgets('reset password', (tester) async {
    Get.find<AuthController>().pendingEmail.value = 'makara.it@email.com';
    await pumpScreen(tester, const ResetPasswordScreen());
    await expectLater(
      find.byType(ResetPasswordScreen),
      matchesGoldenFile('goldens/reset_password.png'),
    );
  });
}
