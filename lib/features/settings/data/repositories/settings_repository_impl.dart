import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';
import '../models/user_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDatasource _remote;

  @override
  Future<UserSettingsEntity> getSettings() => _remote.getSettings();

  @override
  Future<UserSettingsEntity> updateSettings({
    String? language,
    String? theme,
    bool? notificationEnabled,
    String? privacyProfile,
    bool? allowMessages,
    bool? allowFollowRequest,
    bool? biometricEnabled,
  }) {
    return _remote.updateSettings(
      UserSettingsMapper.updateBody(
        language: language,
        theme: theme,
        notificationEnabled: notificationEnabled,
        privacyProfile: privacyProfile,
        allowMessages: allowMessages,
        allowFollowRequest: allowFollowRequest,
        biometricEnabled: biometricEnabled,
      ),
    );
  }
}
