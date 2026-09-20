import '../../domain/models/short_content_models.dart';
import '../../domain/repositories/short_content_repository.dart';
import '../datasources/short_content_remote_data_source.dart';

class ShortContentRepositoryImpl implements ShortContentRepository {
  const ShortContentRepositoryImpl(this._remoteDataSource);

  final ShortContentRemoteDataSource _remoteDataSource;

  @override
  Future<ShortContentModel> create(ShortContentCreateRequest request) {
    return _remoteDataSource.create(request);
  }

  @override
  Future<void> delete(String contentId) {
    return _remoteDataSource.delete(contentId);
  }

  @override
  Future<ShortContentModel> getById(String contentId) {
    return _remoteDataSource.getById(contentId);
  }

  @override
  Future<ShortContentPage> getFeed({
    int page = 0,
    int size = 20,
    String? category,
  }) {
    return _remoteDataSource.getFeed(
      page: page,
      size: size,
      category: category,
    );
  }

  @override
  Future<ShortContentModel> like(String contentId) {
    return _remoteDataSource.like(contentId);
  }

  @override
  Future<ShortContentModel> unlike(String contentId) {
    return _remoteDataSource.unlike(contentId);
  }

  @override
  Future<ShortContentModel> save(String contentId) {
    return _remoteDataSource.save(contentId);
  }

  @override
  Future<ShortContentModel> unsave(String contentId) {
    return _remoteDataSource.unsave(contentId);
  }

  @override
  Future<ShortContentModel> share(String contentId) {
    return _remoteDataSource.share(contentId);
  }
}
