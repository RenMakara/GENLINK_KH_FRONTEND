import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/features/settings/domain/entities/user_settings_entity.dart';
import 'package:genlink_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:genlink_frontend/features/settings/presentation/controllers/settings_controller.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockThemeController extends Mock implements ThemeController {}

class _MockLocalizationService extends Mock implements LocalizationService {}

const _initialSettings = UserSettingsEntity(
  language: UserSettingsEntity.languageEnglish,
  theme: UserSettingsEntity.themeLight,
);

const _persistenceError = AppError(
  message: 'Unable to save settings',
  errorCode: 'SETTINGS_UPDATE_FAILED',
  statusCode: 500,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSettingsRepository repository;
  late _MockThemeController themeController;
  late _MockLocalizationService localization;
  late SettingsController controller;

  setUp(() {
    repository = _MockSettingsRepository();
    themeController = _MockThemeController();
    localization = _MockLocalizationService();
    when(
      () => themeController.backendTheme,
    ).thenReturn(UserSettingsEntity.themeSystem);
    when(
      () => localization.language,
    ).thenReturn(UserSettingsEntity.languageEnglish.obs);
    controller = SettingsController(
      repository: repository,
      themeController: themeController,
      localization: localization,
    )..settings.value = _initialSettings;
  });

  tearDown(Get.reset);

  test('failed theme persistence restores entity and applied theme', () async {
    when(
      () => themeController.applyBackendTheme(any()),
    ).thenAnswer((_) async {});
    when(
      () => repository.updateSettings(theme: UserSettingsEntity.themeDark),
    ).thenThrow(_persistenceError);

    await controller.setTheme(UserSettingsEntity.themeDark);

    expect(controller.settings.value.theme, UserSettingsEntity.themeLight);
    expect(controller.errorMessage.value, _persistenceError.message);
    verifyInOrder([
      () => themeController.applyBackendTheme(UserSettingsEntity.themeDark),
      () => themeController.applyBackendTheme(UserSettingsEntity.themeLight),
    ]);
  });

  test('failed language persistence restores entity and locale', () async {
    when(() => localization.setLanguage(any())).thenAnswer((_) async {});
    when(
      () =>
          repository.updateSettings(language: UserSettingsEntity.languageKhmer),
    ).thenThrow(_persistenceError);

    await controller.setLanguage(UserSettingsEntity.languageKhmer);

    expect(
      controller.settings.value.language,
      UserSettingsEntity.languageEnglish,
    );
    expect(controller.errorMessage.value, _persistenceError.message);
    verifyInOrder([
      () => localization.setLanguage(UserSettingsEntity.languageKhmer),
      () => localization.setLanguage(UserSettingsEntity.languageEnglish),
    ]);
  });

  test(
    'uses backend English instead of treating it as a missing value',
    () async {
      controller.settings.value = const UserSettingsEntity(
        language: UserSettingsEntity.languageKhmer,
        theme: UserSettingsEntity.themeLight,
      );
      when(
        () => repository.getSettings(),
      ).thenAnswer((_) async => _initialSettings);

      await controller.load();

      expect(
        controller.settings.value.language,
        UserSettingsEntity.languageEnglish,
      );
    },
  );

  test('applies backend SYSTEM_DEFAULT instead of stale local theme', () async {
    controller.settings.value = const UserSettingsEntity(
      language: UserSettingsEntity.languageEnglish,
      theme: UserSettingsEntity.themeDark,
    );
    when(() => repository.getSettings()).thenAnswer(
      (_) async => const UserSettingsEntity(
        language: UserSettingsEntity.languageEnglish,
        theme: UserSettingsEntity.themeSystem,
      ),
    );
    when(
      () => themeController.applyBackendTheme(UserSettingsEntity.themeSystem),
    ).thenAnswer((_) async {});

    await controller.load();

    expect(controller.settings.value.theme, UserSettingsEntity.themeSystem);
    verify(
      () => themeController.applyBackendTheme(UserSettingsEntity.themeSystem),
    ).called(1);
  });

  test('successful theme persistence keeps server response', () async {
    const saved = UserSettingsEntity(
      language: UserSettingsEntity.languageEnglish,
      theme: UserSettingsEntity.themeDark,
      notificationEnabled: false,
    );
    when(
      () => themeController.applyBackendTheme(any()),
    ).thenAnswer((_) async {});
    when(
      () => repository.updateSettings(theme: UserSettingsEntity.themeDark),
    ).thenAnswer((_) async => saved);

    await controller.setTheme(UserSettingsEntity.themeDark);

    expect(controller.settings.value, saved);
    verify(
      () => themeController.applyBackendTheme(UserSettingsEntity.themeDark),
    ).called(1);
    verify(() => themeController.backendTheme).called(1);
    verifyNoMoreInteractions(themeController);
  });

  test('loads the backend productivity notification preferences', () async {
    when(() => repository.getNotificationPreferences()).thenAnswer(
      (_) async => const [
        NotificationPreferenceEntity(
          notificationType: 'PRODUCTIVITY_TASK',
          enabled: false,
        ),
      ],
    );

    await controller.loadNotificationPreferences();

    expect(
      controller.notificationPreferenceEnabled('PRODUCTIVITY_TASK'),
      isFalse,
    );
    // The backend stores only explicit overrides; absent types remain enabled.
    expect(
      controller.notificationPreferenceEnabled('PRODUCTIVITY_HABIT'),
      isTrue,
    );
  });

  test(
    'duplicate preference updates are ignored while the first is pending',
    () async {
      final response = Completer<NotificationPreferenceEntity>();
      when(
        () => repository.updateNotificationPreference(
          notificationType: 'PRODUCTIVITY_TASK',
          enabled: false,
        ),
      ).thenAnswer((_) => response.future);

      final first = controller.setNotificationPreference(
        'PRODUCTIVITY_TASK',
        false,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.setNotificationPreference('PRODUCTIVITY_TASK', true);

      verify(
        () => repository.updateNotificationPreference(
          notificationType: 'PRODUCTIVITY_TASK',
          enabled: false,
        ),
      ).called(1);
      expect(
        controller.notificationPreferenceEnabled('PRODUCTIVITY_TASK'),
        isFalse,
      );

      response.complete(
        const NotificationPreferenceEntity(
          notificationType: 'PRODUCTIVITY_TASK',
          enabled: false,
        ),
      );
      await first;
      expect(
        controller.isNotificationPreferenceBusy('PRODUCTIVITY_TASK'),
        isFalse,
      );
    },
  );

  test('failed preference update restores the previous value', () async {
    when(
      () => repository.updateNotificationPreference(
        notificationType: 'PRODUCTIVITY_HABIT',
        enabled: false,
      ),
    ).thenThrow(_persistenceError);

    await controller.setNotificationPreference('PRODUCTIVITY_HABIT', false);

    expect(
      controller.notificationPreferenceEnabled('PRODUCTIVITY_HABIT'),
      isTrue,
    );
    expect(
      controller.notificationPreferencesError.value,
      _persistenceError.message,
    );
  });
}
