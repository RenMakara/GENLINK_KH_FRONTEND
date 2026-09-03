import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/presentation/screens/auth_choice_screen.dart';
import 'package:genlink_frontend/features/auth/presentation/widgets/animated_auth_background.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/auth_provider_button.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
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

  testWidgets('mail and create actions route to the expected auth screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        translations: AppTranslations(),
        initialRoute: AppRoutes.authChoice,
        getPages: [
          GetPage(
            name: AppRoutes.authChoice,
            page: () => const AuthChoiceScreen(),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('login destination')),
          ),
          GetPage(
            name: AppRoutes.register,
            page: () => const Scaffold(body: Text('register destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthProviderButton), findsOneWidget);
    expect(find.byType(AnimatedAuthBackground), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('continue-with-mail')),
        matching: find.byIcon(Icons.mail_outline),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('continue-with-mail')));
    await tester.pumpAndSettle();
    expect(find.text('login destination'), findsOneWidget);

    Get.back<void>();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-choice-register')));
    await tester.pumpAndSettle();
    expect(find.text('register destination'), findsOneWidget);
  });
}
