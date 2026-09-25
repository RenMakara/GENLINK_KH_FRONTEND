import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/short_content_models.dart';

abstract class ShortContentRemoteDataSource {
  Future<ShortContentModel> create(ShortContentCreateRequest request);

  Future<void> delete(String contentId);

  Future<ShortContentModel> getById(String contentId);

  Future<ShortContentPage> getFeed({
    int page = 0,
    int size = 20,
    String? category,
  });

  Future<ShortContentModel> like(String contentId);

  Future<ShortContentModel> unlike(String contentId);

  Future<ShortContentModel> save(String contentId);

  Future<ShortContentModel> unsave(String contentId);

  Future<ShortContentModel> share(String contentId);
}

class ShortContentRemoteDataSourceImpl implements ShortContentRemoteDataSource {
  const ShortContentRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ShortContentModel> create(ShortContentCreateRequest request) {
    return _apiClient.post(
      ApiEndpoints.shortContent,
      body: request.toJson(),
      parse: _parseContent,
    );
  }

  @override
  Future<ShortContentPage> getFeed({
    int page = 0,
    int size = 20,
    String? category,
  }) {
    final query = <String, dynamic>{'page': page, 'size': size};
    final normalizedCategory = category?.trim();
    if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
      query['category'] = normalizedCategory;
    }

    return _apiClient.get(
      ApiEndpoints.shortContent,
      query: query,
      parse: (data) => ShortContentPage.fromJson(ApiClient.asMap(data)),
    );
  }

  @override
  Future<ShortContentModel> like(String contentId) {
    return _apiClient.post(
      ApiEndpoints.shortContentLike(contentId),
      parse: _parseContent,
    );
  }

  @override
  Future<ShortContentModel> unlike(String contentId) {
    return _apiClient.deleteWithResult(
      ApiEndpoints.shortContentLike(contentId),
      parse: _parseContent,
    );
  }

  @override
  Future<ShortContentModel> save(String contentId) {
    return _apiClient.post(
      ApiEndpoints.shortContentSave(contentId),
      parse: _parseContent,
    );
  }

  @override
  Future<ShortContentModel> unsave(String contentId) {
    return _apiClient.deleteWithResult(
      ApiEndpoints.shortContentSave(contentId),
      parse: _parseContent,
    );
  }

  @override
  Future<ShortContentModel> share(String contentId) {
    return _apiClient.post(
      ApiEndpoints.shortContentShare(contentId),
      parse: _parseContent,
    );
  }

  @override
  Future<void> delete(String contentId) {
    return _apiClient.delete(ApiEndpoints.shortContentItem(contentId));
  }

  @override
  Future<ShortContentModel> getById(String contentId) {
    return _apiClient.get(
      ApiEndpoints.shortContentItem(contentId),
      parse: _parseContent,
    );
  }

  ShortContentModel _parseContent(dynamic data) =>
      ShortContentModel.fromJson(ApiClient.asMap(data));
}
