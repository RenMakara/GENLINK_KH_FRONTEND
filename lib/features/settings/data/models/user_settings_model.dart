import '../../domain/entities/user_settings_entity.dart';

/// Wire model for `UserSettingResponse` / `UserSettingUpdateRequest`.
abstract final class UserSettingsMapper {
  static UserSettingsEntity fromJson(Map<String, dynamic> json) {
    return UserSettingsEntity(
      settingsId: json['settingsId'] as String?,
      language: json['language'] as String? ?? UserSettingsEntity.languageKhmer,
      theme: json['theme'] as String? ?? UserSettingsEntity.themeSystem,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      privacyProfile:
          json['privacyProfile'] as String? ?? UserSettingsEntity.privacyPublic,
      allowMessages: json['allowMessages'] as bool? ?? true,
      allowFollowRequest: json['allowFollowRequest'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    );
  }

  /// The update request is a partial patch — only send what changed so an
  /// unrelated field can never be clobbered by a stale local value.
  static Map<String, dynamic> updateBody({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  }) {
    return <String, dynamic>{
      'language': language,
      'theme': theme,
      'notificationEnabled': notificationEnabled,
      'privacyProfile': privacyProfile,
      'allowMessages': allowMessages,
      'allowFollowRequest': allowFollowRequest,
      'biometricEnabled': biometricEnabled,
    }..removeWhere((_, value) => value == null);
  }
}
