import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Centralized Image Cache Manager for GenLink KH.
///
/// Configures disk caching parameters:
/// - Key: `genlink_image_cache`
/// - Stale Period: 14 days
/// - Max Objects: 300 images (~150 MB estimated at average 500 KB per image)
/// - Eviction: Least Recently Used (LRU) automatic cleanup managed by CacheManager
class GenLinkImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'genlink_image_cache';

  static final GenLinkImageCacheManager _instance =
      GenLinkImageCacheManager._();
  factory GenLinkImageCacheManager() => _instance;

  GenLinkImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 14),
            maxNrOfCacheObjects: 300,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
