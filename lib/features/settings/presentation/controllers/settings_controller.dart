import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/localization/localization_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/user_settings_entity.dart';

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
  })  : _theme = themeController;

  final ProfileRepository _repository;
  final ThemeController _theme;
  final LocalizationService _localization;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final settings = UserSettingsEntity().obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await _repository.getSettings();
      settings.value = loaded;
      // The server is authoritative for a signed-in user. Language is a
      // sync (not an explicit choice) so device-following stays alive for
      // users who never picked one themselves.
      await _theme.applyBackendTheme(loaded.theme);
      _localization.syncFromAccount(loaded.language);
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
    final previous = settings.value.theme;
    if (previous == theme) return;

    settings.value = settings.value.copyWith(theme: theme);
    await _theme.applyBackendTheme(theme);

    await _patch(theme: theme);
  }

  Future<void> setLanguage(String language) async {
    final previous = settings.value.language;
    if (previous == language) return;

    settings.value = settings.value.copyWith(language: language);
    await _localization.setLanguage(language);

    await _patch(language: language);
  }

  // ── Toggles ───────────────────────────────────────────────────────────

  Future<void> setNotificationEnabled(bool value) =>
      _toggle((s) => s.copyWith(notificationEnabled: value),
          () => _patch(notificationEnabled: value));

  Future<void> setAllowMessages(bool value) => _toggle(
      (s) => s.copyWith(allowMessages: value),
      () => _patch(allowMessages: value));

  Future<void> setAllowFollowRequest(bool value) => _toggle(
      (s) => s.copyWith(allowFollowRequest: value),
      () => _patch(allowFollowRequest: value));

  Future<void> setBiometricEnabled(bool value) => _toggle(
      (s) => s.copyWith(biometricEnabled: value),
      () => _patch(biometricEnabled: value));

  Future<void> setPrivacyProfile(String value) => _toggle(
      (s) => s.copyWith(privacyProfile: value),
      () => _patch(privacyProfile: value));

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
      settings.value = await _repository.updateSettings(
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
