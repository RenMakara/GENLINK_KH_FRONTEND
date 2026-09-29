import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/settings/domain/entities/user_settings_entity.dart';
import 'package:genlink_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:genlink_frontend/features/settings/presentation/controllers/settings_controller.dart';
import 'package:genlink_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:genlink_frontend/features/settings/presentation/widgets/settings_selection_popups.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockThemeController extends Mock implements ThemeController {}

class _MockLocalizationService extends Mock implements LocalizationService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSettingsRepository settingsRepository;
  late _MockThemeController themeController;
  late _MockLocalizationService localization;
  late _MockAuthRepository authRepository;
  late _MockSecureStorage secureStorage;
  late SettingsController controller;

  setUp(() {
    Get.reset();
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    settingsRepository = _MockSettingsRepository();
    themeController = _MockThemeController();
    localization = _MockLocalizationService();
    authRepository = _MockAuthRepository();
    secureStorage = _MockSecureStorage();

    when(() => themeController.backendTheme)
        .thenReturn(UserSettingsEntity.themeSystem);
    when(() => localization.language)
        .thenReturn(UserSettingsEntity.languageEnglish.obs);
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => const UserSettingsEntity());
    when(
      () => settingsRepository.updateSettings(
        language: any(named: 'language'),
        theme: any(named: 'theme'),
        notificationEnabled: any(named: 'notificationEnabled'),
        privacyProfile: any(named: 'privacyProfile'),
        allowMessages: any(named: 'allowMessages'),
        allowFollowRequest: any(named: 'allowFollowRequest'),
        biometricEnabled: any(named: 'biometricEnabled'),
      ),
    ).thenAnswer((_) async => const UserSettingsEntity());
    when(() => themeController.applyBackendTheme(any()))
        .thenAnswer((_) async {});
    when(() => localization.setLanguage(any())).thenAnswer((_) async {});

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
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 1,
      preferredLanguage: 'ENGLISH',
      role: 'USER',
      active: true,
    );
    Get.put<AuthController>(authController);

    controller = SettingsController(
      repository: settingsRepository,
      themeController: themeController,
      localization: localization,
    )..settings.value = const UserSettingsEntity(
        theme: UserSettingsEntity.themeSystem,
        language: UserSettingsEntity.languageEnglish,
      );
    Get.put<SettingsController>(controller);
  });

  tearDown(Get.reset);

  group('AppearanceSelectionPopup Widget Tests', () {
    testWidgets('renders 3 options in order: System, Light, Dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppearanceSelectionPopup.show(context, controller),
                child: const Text('Open Appearance'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Appearance'));
      await tester.pumpAndSettle();

      // Verify AppearanceSelectionPopup is open
      expect(find.byType(AppearanceSelectionPopup), findsOneWidget);

      // Verify 3 options in popup matching the screenshot
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Verify checkmark appears for active theme (System)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('selecting Dark calls setTheme with DARK', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppearanceSelectionPopup.show(context, controller),
                child: const Text('Open Appearance'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Appearance'));
      await tester.pumpAndSettle();

      // Tap Dark
      await tester.tap(find.text('Dark'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(controller.settings.value.theme, UserSettingsEntity.themeDark);
      verify(() => themeController.applyBackendTheme('DARK')).called(1);
    });

    testWidgets('selecting Light calls setTheme with LIGHT', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppearanceSelectionPopup.show(context, controller),
                child: const Text('Open Appearance'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Appearance'));
      await tester.pumpAndSettle();

      // Tap Light
      await tester.tap(find.text('Light'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(controller.settings.value.theme, UserSettingsEntity.themeLight);
      verify(() => themeController.applyBackendTheme('LIGHT')).called(1);
    });
  });

  group('LanguageSelectionPopup Widget Tests', () {
    testWidgets('renders English and Khmer options', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LanguageSelectionPopup.show(context, controller),
                child: const Text('Open Language'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Language'));
      await tester.pumpAndSettle();

      // Verify LanguageSelectionPopup is open
      expect(find.byType(LanguageSelectionPopup), findsOneWidget);

      // Verify options
      expect(find.text('English'), findsOneWidget);
      expect(find.text('ភាសាខ្មែរ'), findsOneWidget);

      // Verify checkmark appears for active language (English)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('selecting Khmer calls setLanguage with KHMER', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LanguageSelectionPopup.show(context, controller),
                child: const Text('Open Language'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Language'));
      await tester.pumpAndSettle();

      // Tap ភាសាខ្មែរ
      await tester.tap(find.text('ភាសាខ្មែរ'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(controller.settings.value.language, UserSettingsEntity.languageKhmer);
      verify(() => localization.setLanguage(UserSettingsEntity.languageKhmer)).called(1);
    });
  });

  group('SettingsScreen Tap Opens Popovers', () {
    testWidgets('tapping Appearance in SettingsScreen opens AppearanceSelectionPopup', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Appearance row
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      // Verify AppearanceSelectionPopup is open
      expect(find.byType(AppearanceSelectionPopup), findsOneWidget);
      expect(find.text('System'), findsWidgets);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('tapping Language in SettingsScreen opens LanguageSelectionPopup', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Language row
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Verify LanguageSelectionPopup is open
      expect(find.byType(LanguageSelectionPopup), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('ភាសាខ្មែរ'), findsOneWidget);
    });
  });
}
