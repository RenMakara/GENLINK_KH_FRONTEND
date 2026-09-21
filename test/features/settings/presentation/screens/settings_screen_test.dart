import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/settings/domain/entities/user_settings_entity.dart';
import 'package:genlink_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:genlink_frontend/features/settings/presentation/controllers/settings_controller.dart';
import 'package:genlink_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockThemeController extends Mock implements ThemeController {}

class _MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSettingsRepository settingsRepository;
  late _MockAuthRepository authRepository;
  late _MockSecureStorage secureStorage;
  late _MockThemeController themeController;
  late _MockLocalizationService localization;

  setUp(() {
    settingsRepository = _MockSettingsRepository();
    authRepository = _MockAuthRepository();
    secureStorage = _MockSecureStorage();
    themeController = _MockThemeController();
    localization = _MockLocalizationService();

    when(
      () => themeController.backendTheme,
    ).thenReturn(UserSettingsEntity.themeSystem);
    when(
      () => localization.language,
    ).thenReturn(UserSettingsEntity.languageEnglish.obs);
    when(
      settingsRepository.getSettings,
    ).thenAnswer((_) async => const UserSettingsEntity());

    final authController = AuthController(
      authRepository: authRepository,
      secureStorage: secureStorage,
      localization: LocalizationService(localStorage: LocalStorage()),
    );
    authController.currentUser.value = const UserEntity(
      id: 'u1',
      fullName: 'Ren Makara',
      username: 'makara.it.official',
      email: 'makara.it.official@gmail.com',
      workStatus: 'ENTREPRENEUR',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 1240,
      level: 13,
      preferredLanguage: 'ENGLISH',
      role: 'USER',
      active: true,
    );
    Get.put<AuthController>(authController);

    final settingsController = SettingsController(
      repository: settingsRepository,
      themeController: themeController,
      localization: localization,
    )..settings.value = const UserSettingsEntity();
    Get.put<SettingsController>(settingsController);
  });

  tearDown(Get.reset);

  testWidgets('renders profile summary with long role without overflow', (
    tester,
  ) async {
    // Test on a narrow screen size (360x780) matching Android viewport in screenshot
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.darkFor('en'),
        home: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ren Makara'), findsOneWidget);
    expect(find.text('ENTREPRENEUR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders profile summary with extremely long role without overflow on 320px width', (
    tester,
  ) async {
    final authController = Get.find<AuthController>();
    authController.currentUser.value = const UserEntity(
      id: 'u1',
      fullName: 'Ren Makara With A Very Long Name',
      username: 'makara.it.official.very.long.username',
      email: 'makara.it.official.very.long.email@example.com',
      workStatus: 'SENIOR SOFTWARE ARCHITECT & ENTREPRENEUR',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 1240,
      level: 13,
      preferredLanguage: 'ENGLISH',
      role: 'USER',
      active: true,
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: LocalizationService.englishLocale,
        fallbackLocale: LocalizationService.englishLocale,
        theme: AppTheme.darkFor('en'),
        home: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // No RenderFlex overflow exception
    expect(tester.takeException(), isNull);
  });
}
