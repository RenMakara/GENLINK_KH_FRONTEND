import '../entities/user_settings_entity.dart';

/// Contract for the signed-in user's app preferences.
abstract interface class SettingsRepository {
  Future<UserSettingsEntity> getSettings();

  Future<UserSettingsEntity> updateSettings({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  });
}
