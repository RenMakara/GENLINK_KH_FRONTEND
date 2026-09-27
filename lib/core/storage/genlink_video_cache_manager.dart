import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Dedicated Video Cache Manager for GenLink KH.
///
/// Configures disk caching parameters for video files:
/// - Key: `genlink_video_cache`
/// - Stale Period: 7 days
/// - Max Objects: 25 video files (~250 MB budget assuming ~10 MB average per video)
/// - Eviction: Least Recently Used (LRU) automatic cleanup managed by CacheManager
class GenLinkVideoCacheManager extends CacheManager {
  static const key = 'genlink_video_cache';
  static const int maxObjects = 25;
  static const Duration staleDuration = Duration(days: 7);

  static final GenLinkVideoCacheManager _instance =
      GenLinkVideoCacheManager._();
  factory GenLinkVideoCacheManager() => _instance;

  GenLinkVideoCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: staleDuration,
            maxNrOfCacheObjects: maxObjects,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
