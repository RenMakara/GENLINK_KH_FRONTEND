import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../models/user_settings_model.dart';

/// Remote data source for `/api/v1/profile/settings`.
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
}
