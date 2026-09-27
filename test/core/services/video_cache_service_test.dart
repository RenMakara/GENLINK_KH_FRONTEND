import 'dart:io' as io;

// ignore: depend_on_referenced_packages
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/services/video_cache_service.dart';

/// Test implementation of [BaseCacheManager] backed by real temporary files.
class FakeVideoCacheManager implements BaseCacheManager {
  FakeVideoCacheManager({required this.tempDir});

  final io.Directory tempDir;
  final Map<String, FileInfo> cache = {};
  final List<String> downloadCalls = [];
  bool shouldFailDownloads = false;
  int downloadDelayMs = 0;
  final LocalFileSystem _fs = const LocalFileSystem();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async {
    return cache[key];
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    downloadCalls.add(url);
    if (downloadDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: downloadDelayMs));
    }
    if (shouldFailDownloads) {
      throw Exception('Simulated network failure for download: $url');
    }

    final cacheKey = key ?? url;
    final filePath = '${tempDir.path}/video_${cacheKey.hashCode}.mp4';
    final file = _fs.file(filePath);
    if (!file.existsSync()) {
      file.writeAsBytesSync([0, 0, 0, 32, 102, 116, 121, 112]); // Mock MP4 header
    }

    final fileInfo = FileInfo(
      file,
      FileSource.Online,
      DateTime.now().add(const Duration(days: 7)),
      url,
    );
    cache[cacheKey] = fileInfo;
    return fileInfo;
  }

  @override
  Future<void> emptyCache() async {
    cache.clear();
    downloadCalls.clear();
  }

  @override
  Future<void> removeFile(String key) async {
    cache.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late io.Directory tempDir;
  late FakeVideoCacheManager fakeCacheManager;
  late VideoCacheService service;

  setUp(() {
    tempDir = io.Directory.systemTemp.createTempSync('genlink_video_cache_test_');
    fakeCacheManager = FakeVideoCacheManager(tempDir: tempDir);
    service = VideoCacheService(
      cacheManager: fakeCacheManager,
      watchThreshold: const Duration(seconds: 2),
    );
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('VideoCacheService Unit Tests', () {
    test('returns null for empty or null URL', () async {
      expect(await service.getCachedFile(null), isNull);
      expect(await service.getCachedFile(''), isNull);
      expect(await service.getCachedFile('   '), isNull);
    });

    test('returns null on cache miss for un-cached remote video', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/test.mp4';
      final file = await service.getCachedFile(remoteUrl);
      expect(file, isNull);
    });

    test('downloads and caches remote video on demand', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/test.mp4';

      final file = await service.cacheVideo(remoteUrl);
      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);
      expect(fakeCacheManager.downloadCalls.length, 1);

      // Subsequent getCachedFile should now hit the disk cache
      final cachedFile = await service.getCachedFile(remoteUrl);
      expect(cachedFile, isNotNull);
      expect(cachedFile!.path, file.path);
    });

    test('deduplicates concurrent download requests for the same URL', () async {
      fakeCacheManager.downloadDelayMs = 25;
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/concurrent.mp4';

      // Launch 3 simultaneous download requests
      final future1 = service.cacheVideo(remoteUrl);
      final future2 = service.cacheVideo(remoteUrl);
      final future3 = service.cacheVideo(remoteUrl);

      final results = await Future.wait([future1, future2, future3]);

      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(results[2], isNotNull);
      expect(results[0]!.path, results[1]!.path);
      expect(results[1]!.path, results[2]!.path);

      // Only ONE download should have been executed by the cache manager
      expect(fakeCacheManager.downloadCalls.length, 1);
    });

    test('handles download errors gracefully without throwing', () async {
      fakeCacheManager.shouldFailDownloads = true;
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/broken.mp4';

      final file = await service.cacheVideo(remoteUrl);
      expect(file, isNull);
      expect(await service.getCachedFile(remoteUrl), isNull);
    });

    test('normalizes legacy digitaloceanspaces.com URLs before querying cache', () async {
      const legacyUrl =
          'https://genlink-media.sgp1.cdn.digitaloceanspaces.com/posts/video.mp4';
      const expectedNormalized =
          'https://genlink-media.sgp1.digitaloceanspaces.com/posts/video.mp4';

      await service.cacheVideo(legacyUrl);

      // Cache should store under normalized key
      expect(fakeCacheManager.cache.containsKey(expectedNormalized), isTrue);

      // Querying with legacy URL should hit the normalized cache
      final cached = await service.getCachedFile(legacyUrl);
      expect(cached, isNotNull);
    });

    test('does not cache local filesystem paths into remote cache', () async {
      final localFile = io.File('${tempDir.path}/local_camera_video.mp4')
        ..writeAsBytesSync([1, 2, 3]);

      // Should return local file directly without calling cache manager
      final result = await service.getCachedFile(localFile.path);
      expect(result, isNotNull);
      expect(result!.path, localFile.path);

      // Cache manager should NOT have downloaded or stored anything
      expect(fakeCacheManager.downloadCalls, isEmpty);
      expect(fakeCacheManager.cache, isEmpty);
    });

    test('clearCache empties the cache manager and clears in-memory tracking', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/to_clear.mp4';
      await service.cacheVideo(remoteUrl);
      expect(await service.getCachedFile(remoteUrl), isNotNull);

      await service.clearCache();
      expect(await service.getCachedFile(remoteUrl), isNull);
      expect(fakeCacheManager.cache, isEmpty);
    });

    test('removeFile removes only the targeted video from cache', () async {
      const url1 = 'https://d123456abcdef.cloudfront.net/posts/v1.mp4';
      const url2 = 'https://d123456abcdef.cloudfront.net/posts/v2.mp4';

      await service.cacheVideo(url1);
      await service.cacheVideo(url2);

      await service.removeFile(url1);

      expect(await service.getCachedFile(url1), isNull);
      expect(await service.getCachedFile(url2), isNotNull);
    });
  });

  group('VideoCacheService Lazy Caching Policy Tests', () {
    test('does NOT trigger caching if playback duration is under 2 seconds', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/short_watch.mp4';

      // Watch for 1.2 seconds of a 15 second video
      service.trackPlaybackProgress(
        remoteUrl,
        const Duration(milliseconds: 1200),
        const Duration(seconds: 15),
      );

      // Give microtasks a moment to run
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.isTracked(remoteUrl), isFalse);
      expect(fakeCacheManager.downloadCalls, isEmpty);
    });

    test('triggers background caching when watch duration reaches 2 seconds', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/watched_2s.mp4';

      service.trackPlaybackProgress(
        remoteUrl,
        const Duration(seconds: 2),
        const Duration(seconds: 20),
      );

      expect(service.isTracked(remoteUrl), isTrue);

      // Wait for background download to complete
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeCacheManager.downloadCalls.contains(remoteUrl), isTrue);
      expect(await service.getCachedFile(remoteUrl), isNotNull);
    });

    test('triggers background caching when video reaches completion even if < 2s', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/quick_clip.mp4';

      // 1.5 second clip watched to 1.4 seconds (within 300ms of end)
      service.trackPlaybackProgress(
        remoteUrl,
        const Duration(milliseconds: 1400),
        const Duration(milliseconds: 1500),
      );

      expect(service.isTracked(remoteUrl), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeCacheManager.downloadCalls.contains(remoteUrl), isTrue);
    });
  });

  group('VideoCacheService Controller Resolution Tests', () {
    test('creates network controller on cache miss', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/miss.mp4';

      final ctrl = await service.createController(remoteUrl);
      expect(ctrl.dataSourceType.name, 'network');
      expect(ctrl.dataSource, remoteUrl);
      await ctrl.dispose();
    });

    test('creates file controller on cache hit', () async {
      const remoteUrl = 'https://d123456abcdef.cloudfront.net/posts/hit.mp4';
      final cachedFile = await service.cacheVideo(remoteUrl);

      final ctrl = await service.createController(remoteUrl);
      expect(ctrl.dataSourceType.name, 'file');
      expect(ctrl.dataSource, cachedFile!.uri.toString());
      await ctrl.dispose();
    });

    test('creates file controller for local file paths', () async {
      final localFile = io.File('${tempDir.path}/local_test.mp4')
        ..writeAsBytesSync([1, 2, 3]);

      final ctrl = await service.createController(localFile.path);
      expect(ctrl.dataSourceType.name, 'file');
      expect(ctrl.dataSource, localFile.uri.toString());
      await ctrl.dispose();
    });
  });
}
