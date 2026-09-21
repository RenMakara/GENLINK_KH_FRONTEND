import '../entities/user_settings_entity.dart';

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

  Future<List<NotificationPreferenceEntity>> getNotificationPreferences();

  Future<NotificationPreferenceEntity> updateNotificationPreference({
    required String notificationType,
    required bool enabled,
  });
}
