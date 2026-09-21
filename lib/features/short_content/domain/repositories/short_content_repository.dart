import '../models/short_content_models.dart';

abstract class ShortContentRepository {
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
