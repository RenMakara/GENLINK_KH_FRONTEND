import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

/// Owns `/api/v1/profile/settings`.
///
/// Theme and language are applied locally *first* so the UI responds
/// immediately, then persisted. If the server rejects the change the local
/// value is rolled back, so the two never silently disagree.
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

      // Merge: prefer backend if it's NOT the default, otherwise stay with 
      // current local state. This prevents backend defaults from 
      // clobbering a user's manual choice when opening the settings page.
      final merged = loaded.copyWith(
        theme: loaded.theme == UserSettingsEntity.themeSystem
            ? current.theme
            : loaded.theme,
        language: loaded.language == UserSettingsEntity.languageEnglish
            ? current.language
            : loaded.language,
      );

      settings.value = merged;

      // Only apply to the app if it actually changed from current local state.
      if (merged.theme != current.theme) {
        await _theme.applyBackendTheme(merged.theme);
      }
      if (merged.language != current.language) {
        _localization.syncFromAccount(merged.language);
      }
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Appearance ────────────────────────────────────────────────────────

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

  // ── Toggles ───────────────────────────────────────────────────────────

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

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Optimistic update: apply locally, then roll back if the save fails.
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

      // If the backend returns defaults for fields we just tried to set,
      // keep our local value for now to avoid the UI "flickering" or
      // ticking the wrong box while the backend catches up.
      settings.value = updated.copyWith(
        language: language,
        theme: theme,
        notificationEnabled: notificationEnabled,
        privacyProfile: privacyProfile,
        allowMessages: allowMessages,
        allowFollowRequest: allowFollowRequest,
        biometricEnabled: biometricEnabled,
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
