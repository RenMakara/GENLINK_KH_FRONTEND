import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../models/user_settings_model.dart';

class SettingsRemoteDatasource {
  const SettingsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<UserSettingsEntity> getSettings() {
    return _client.get(
      ApiEndpoints.profileSettings,
      parse: (data) => UserSettingsMapper.fromJson(ApiClient.asMap(data)),
    );
  }

  Future<UserSettingsEntity> updateSettings(Map<String, dynamic> body) {
    return _client.put(
      ApiEndpoints.profileSettings,
      body: body,
      parse: (data) => UserSettingsMapper.fromJson(ApiClient.asMap(data)),
    );
  }

  Future<List<NotificationPreferenceEntity>> getNotificationPreferences() {
    return _client.get(
      ApiEndpoints.notificationPreferences,
      parse: (data) =>
          ApiClient.asList(data, NotificationPreferenceMapper.fromJson),
    );
  }

  Future<NotificationPreferenceEntity> updateNotificationPreference({
    required String notificationType,
    required bool enabled,
  }) {
    return _client.put(
      ApiEndpoints.notificationPreference(notificationType),
      body: NotificationPreferenceMapper.updateBody(enabled: enabled),
      parse: (data) =>
          NotificationPreferenceMapper.fromJson(ApiClient.asMap(data)),
    );
  }
}
