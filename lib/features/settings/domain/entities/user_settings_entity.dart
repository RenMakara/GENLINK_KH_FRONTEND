/// User settings, from `GET /api/v1/profile/settings`.
///
/// One row per user, created on first read. Every field is nullable on the
/// wire (the update request is a partial patch), so defaults are applied
/// here rather than forcing every caller to null-check.
class UserSettingsEntity {
  const UserSettingsEntity({
    this.settingsId,
    this.language = languageEnglish,
    this.theme = themeSystem,
    this.notificationEnabled = true,
    this.privacyProfile = privacyPublic,
    this.allowMessages = true,
    this.allowFollowRequest = true,
    this.biometricEnabled = false,
  });

  static const languageEnglish = 'ENGLISH';
  static const languageKhmer = 'KHMER';

  static const themeLight = 'LIGHT';
  static const themeDark = 'DARK';
  static const themeSystem = 'SYSTEM_DEFAULT';

  static const privacyPublic = 'PUBLIC';
  static const privacyFriends = 'FRIENDS';
  static const privacyPrivate = 'PRIVATE';

  static const privacyOptions = <String>[
    privacyPublic,
    privacyFriends,
    privacyPrivate,
  ];

  final String? settingsId;
  final String language;
  final String theme;
  final bool notificationEnabled;
  final String privacyProfile;
  final bool allowMessages;
  final bool allowFollowRequest;
  final bool biometricEnabled;

  UserSettingsEntity copyWith({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  }) {
    return UserSettingsEntity(
      settingsId: settingsId,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      privacyProfile: privacyProfile ?? this.privacyProfile,
      allowMessages: allowMessages ?? this.allowMessages,
      allowFollowRequest: allowFollowRequest ?? this.allowFollowRequest,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
