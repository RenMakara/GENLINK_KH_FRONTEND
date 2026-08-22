import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Golden tests for the auth screens, used to check the rendered result
/// against the design. Regenerate with `flutter test --update-goldens`.
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
  }

  testWidgets('login', (tester) async {
    await pumpScreen(tester, const LoginScreen());
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('register', (tester) async {
    await pumpScreen(tester, const RegisterScreen());
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register.png'),
    );
  });

  // Dark mode specifically: the button label used to inherit an explicit
  // colour from the text theme and render white-on-white here.
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
}
