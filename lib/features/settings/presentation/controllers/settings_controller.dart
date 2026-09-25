import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsController extends GetxController {
  SettingsController({
    required this._repository,
    required ThemeController themeController,
    required this._localization,
  }) : _theme = themeController;

  final SettingsRepository _repository;
  final ThemeController _theme;
  final LocalizationService _localization;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final isNotificationPreferencesLoading = false.obs;
  final notificationPreferencesError = RxnString();
  final notificationPreferences = <String, bool>{}.obs;
  final notificationPreferenceBusyTypes = <String>{}.obs;

  late final settings = UserSettingsEntity(
    theme: _theme.backendTheme,
    language: _localization.language.value,
  ).obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await _repository.getSettings();
      final current = settings.value;

      // The backend owns the account preference. In particular, SYSTEM_DEFAULT
      // must not be replaced with the stale locally cached theme.
      settings.value = loaded;

      if (loaded.theme != current.theme) {
        await _theme.applyBackendTheme(loaded.theme);
      }
      if (loaded.language != current.language) {
        _localization.syncFromAccount(loaded.language);
      }
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setTheme(String theme) async {
    final previous = settings.value;
    if (previous.theme == theme) return;

    settings.value = previous.copyWith(theme: theme);
    await _theme.applyBackendTheme(theme);

    if (!await _patch(theme: theme)) {
      settings.value = previous;
      await _theme.applyBackendTheme(previous.theme);
    }
  }

  Future<void> setLanguage(String language) async {
    final previous = settings.value;
    if (previous.language == language) return;

    settings.value = previous.copyWith(language: language);
    await _localization.setLanguage(language);

    if (!await _patch(language: language)) {
      settings.value = previous;
      await _localization.setLanguage(previous.language);
    }
  }

  Future<void> setNotificationEnabled(bool value) => _toggle(
    (s) => s.copyWith(notificationEnabled: value),
    () => _patch(notificationEnabled: value),
  );

  Future<void> setAllowMessages(bool value) => _toggle(
    (s) => s.copyWith(allowMessages: value),
    () => _patch(allowMessages: value),
  );

  Future<void> setAllowFollowRequest(bool value) => _toggle(
    (s) => s.copyWith(allowFollowRequest: value),
    () => _patch(allowFollowRequest: value),
  );

  Future<void> setBiometricEnabled(bool value) => _toggle(
    (s) => s.copyWith(biometricEnabled: value),
    () => _patch(biometricEnabled: value),
  );

  Future<void> setPrivacyProfile(String value) => _toggle(
    (s) => s.copyWith(privacyProfile: value),
    () => _patch(privacyProfile: value),
  );

  bool notificationPreferenceEnabled(String notificationType) =>
      notificationPreferences[notificationType] ?? true;

  bool isNotificationPreferenceBusy(String notificationType) =>
      notificationPreferenceBusyTypes.contains(notificationType);

  Future<void> loadNotificationPreferences() async {
    if (isNotificationPreferencesLoading.value) return;
    isNotificationPreferencesLoading.value = true;
    notificationPreferencesError.value = null;
    try {
      final loaded = await _repository.getNotificationPreferences();
      notificationPreferences.assignAll({
        for (final preference in loaded)
          preference.notificationType: preference.enabled,
      });
    } on AppError catch (e) {
      notificationPreferencesError.value = e.message;
    } catch (_) {
      notificationPreferencesError.value = 'common.error'.tr;
    } finally {
      isNotificationPreferencesLoading.value = false;
    }
  }

  Future<void> setNotificationPreference(
    String notificationType,
    bool enabled,
  ) async {
    if (notificationPreferenceBusyTypes.contains(notificationType)) return;

    final hadPrevious = notificationPreferences.containsKey(notificationType);
    final previous = notificationPreferenceEnabled(notificationType);
    notificationPreferences[notificationType] = enabled;
    notificationPreferenceBusyTypes.add(notificationType);
    notificationPreferencesError.value = null;

    try {
      final saved = await _repository.updateNotificationPreference(
        notificationType: notificationType,
        enabled: enabled,
      );
      notificationPreferences[notificationType] = saved.enabled;
    } on AppError catch (e) {
      _restoreNotificationPreference(
        notificationType,
        previous,
        hadPrevious: hadPrevious,
      );
      notificationPreferencesError.value = e.message;
      AppSnackbar.error(e.message);
    } catch (_) {
      _restoreNotificationPreference(
        notificationType,
        previous,
        hadPrevious: hadPrevious,
      );
      notificationPreferencesError.value = 'common.error'.tr;
      AppSnackbar.error('common.error'.tr);
    } finally {
      notificationPreferenceBusyTypes.remove(notificationType);
    }
  }

  void _restoreNotificationPreference(
    String notificationType,
    bool previous, {
    required bool hadPrevious,
  }) {
    if (hadPrevious) {
      notificationPreferences[notificationType] = previous;
    } else {
      notificationPreferences.remove(notificationType);
    }
  }

  Future<void> _toggle(
    UserSettingsEntity Function(UserSettingsEntity) apply,
    Future<bool> Function() save,
  ) async {
    final previous = settings.value;
    settings.value = apply(previous);
    if (!await save()) settings.value = previous;
  }

  Future<bool> _patch({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;
    try {
      final updated = await _repository.updateSettings(
        language: language,
        theme: theme,
        notificationEnabled: notificationEnabled,
        privacyProfile: privacyProfile,
        allowMessages: allowMessages,
        allowFollowRequest: allowFollowRequest,
        biometricEnabled: biometricEnabled,
      );

      final mergedLanguage = language != null && updated.language != language
          ? language
          : updated.language;
      final mergedTheme = theme != null && updated.theme != theme
          ? theme
          : updated.theme;
      final mergedNotificationEnabled =
          notificationEnabled ?? updated.notificationEnabled;
      final mergedPrivacyProfile = privacyProfile ?? updated.privacyProfile;
      final mergedAllowMessages = allowMessages ?? updated.allowMessages;
      final mergedAllowFollowRequest =
          allowFollowRequest ?? updated.allowFollowRequest;
      final mergedBiometricEnabled =
          biometricEnabled ?? updated.biometricEnabled;

      final responseMatches =
          mergedLanguage == updated.language &&
          mergedTheme == updated.theme &&
          mergedNotificationEnabled == updated.notificationEnabled &&
          mergedPrivacyProfile == updated.privacyProfile &&
          mergedAllowMessages == updated.allowMessages &&
          mergedAllowFollowRequest == updated.allowFollowRequest &&
          mergedBiometricEnabled == updated.biometricEnabled;
      settings.value = responseMatches
          ? updated
          : updated.copyWith(
              language: mergedLanguage,
              theme: mergedTheme,
              notificationEnabled: mergedNotificationEnabled,
              privacyProfile: mergedPrivacyProfile,
              allowMessages: mergedAllowMessages,
              allowFollowRequest: mergedAllowFollowRequest,
              biometricEnabled: mergedBiometricEnabled,
            );
      return true;
    } on AppError catch (e) {
      errorMessage.value = e.message;
      AppSnackbar.error(e.message);
      return false;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
      AppSnackbar.error('common.error'.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
