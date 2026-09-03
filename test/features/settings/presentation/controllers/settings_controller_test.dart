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
}
