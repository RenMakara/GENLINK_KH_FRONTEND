import '../../domain/entities/user_settings_entity.dart';

abstract final class UserSettingsMapper {
  static UserSettingsEntity fromJson(Map<String, dynamic> json) {
    return UserSettingsEntity(
      settingsId: json['settingsId'] as String?,
      language:
          json['language'] as String? ?? UserSettingsEntity.languageEnglish,
      theme: json['theme'] as String? ?? UserSettingsEntity.themeSystem,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      privacyProfile:
          json['privacyProfile'] as String? ?? UserSettingsEntity.privacyPublic,
      allowMessages: json['allowMessages'] as bool? ?? true,
      allowFollowRequest: json['allowFollowRequest'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    );
  }

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
