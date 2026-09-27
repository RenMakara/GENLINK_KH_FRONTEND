import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../storage/genlink_video_cache_manager.dart';
import '../utils/media_url_resolver.dart';

/// Centralized service for video caching in GenLink KH.
///
/// Responsibilities:
/// - Determines whether a video should be played from disk cache or streamed from network.
/// - Implements lazy caching: triggers background caching only when user actually watches
///   the video for at least [watchThreshold] (default 2 seconds) or reaches completion.
/// - Avoids duplicate concurrent downloads for the same URL.
/// - Preserves quick startup on cache miss by streaming immediately without blocking.
/// - Prevents caching of local files (camera, gallery, draft previews).
class VideoCacheService {
  VideoCacheService({BaseCacheManager? cacheManager, Duration? watchThreshold})
      : _cacheManager = cacheManager ?? GenLinkVideoCacheManager(),
        watchThreshold = watchThreshold ?? defaultWatchThreshold;

  static final VideoCacheService instance = VideoCacheService();

  final BaseCacheManager _cacheManager;

  /// Default watch threshold (2 seconds) before background caching is requested.
  static const Duration defaultWatchThreshold = Duration(seconds: 2);

  /// Configurable watch threshold for this service instance.
  final Duration watchThreshold;

  /// Active in-flight downloads mapped by normalized URL to prevent duplicate requests.
  final Map<String, Future<File?>> _activeDownloads = {};

  /// Set of URLs for which background caching has already been triggered in this session.
  final Set<String> _triggeredUrls = {};

  /// Checks if a remote video is already cached on disk and returns its [File].
  ///
  /// - Returns the [File] directly if [rawUrl] is already a valid local file path.
  /// - Returns `null` if [rawUrl] is empty, points to an asset, or is not in cache.
  Future<File?> getCachedFile(String? rawUrl) async {
    final resolved = MediaUrlResolver.resolve(rawUrl);
    if (resolved.isEmpty) return null;

    // Local files are already on disk; do not query cache manager
    if (MediaUrlResolver.isLocalFile(resolved)) {
      final cleanPath = resolved.startsWith('file://')
          ? resolved.replaceFirst('file://', '')
          : resolved;
      try {
        final localFile = File(cleanPath);
        if (localFile.existsSync() && localFile.lengthSync() > 0) {
          return localFile;
        }
      } catch (_) {}
      return null;
    }

    // Remote network URLs only
    if (!MediaUrlResolver.isRemoteUrl(resolved)) {
      return null;
    }

    try {
      final fileInfo = await _cacheManager.getFileFromCache(resolved);
      if (fileInfo != null &&
          fileInfo.file.existsSync() &&
          fileInfo.file.lengthSync() > 0) {
        return fileInfo.file;
      }
    } catch (e) {
      debugPrint('[VideoCacheService] getCachedFile error for $resolved: $e');
    }
    return null;
  }

  /// Downloads and caches the remote video in the background.
  ///
  /// Deduplicates in-flight downloads for the same URL so concurrent callers
  /// share the same download task.
  Future<File?> cacheVideo(String? rawUrl) async {
    final resolved = MediaUrlResolver.resolve(rawUrl);
    if (resolved.isEmpty || !MediaUrlResolver.isRemoteUrl(resolved)) {
      return null;
    }

    // Check if already cached
    final cached = await getCachedFile(resolved);
    if (cached != null) return cached;

    // Check if already downloading (deduplication)
    if (_activeDownloads.containsKey(resolved)) {
      return _activeDownloads[resolved]!;
    }

    final downloadFuture = _performDownload(resolved);
    _activeDownloads[resolved] = downloadFuture;
    return downloadFuture;
  }

  Future<File?> _performDownload(String url) async {
    try {
      final fileInfo = await _cacheManager.downloadFile(url);
      if (fileInfo.file.existsSync() && fileInfo.file.lengthSync() > 0) {
        return fileInfo.file;
      }
      return null;
    } catch (e) {
      debugPrint('[VideoCacheService] Background download failed for $url: $e');
      return null;
    } finally {
      _activeDownloads.remove(url);
    }
  }

  /// Observes actual video playback progress and lazily triggers background
  /// caching once the watch duration reaches [watchThreshold] or the video finishes.
  void trackPlaybackProgress(
    String? rawUrl,
    Duration position,
    Duration duration,
  ) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return;
    final resolved = MediaUrlResolver.resolve(rawUrl);
    if (!MediaUrlResolver.isRemoteUrl(resolved)) return;

    if (_triggeredUrls.contains(resolved)) return;

    final bool reachedThreshold = position >= watchThreshold;
    final bool completed = duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 300);

    if (reachedThreshold || completed) {
      _triggeredUrls.add(resolved);
      unawaited(cacheVideo(resolved));
    }
  }

  /// Helper to create an appropriately configured [VideoPlayerController]:
  /// - If [rawUrl] is cached on disk -> [VideoPlayerController.file]
  /// - If [rawUrl] is a local path -> [VideoPlayerController.file]
  /// - If [rawUrl] is an asset -> [VideoPlayerController.asset]
  /// - If [rawUrl] is a cache-miss remote URL -> [VideoPlayerController.networkUrl]
  Future<VideoPlayerController> createController(
    String rawUrl, {
    VideoPlayerOptions? videoPlayerOptions,
  }) async {
    final resolved = MediaUrlResolver.resolve(rawUrl);
    if (resolved.isEmpty) {
      throw ArgumentError('Video URL cannot be empty');
    }

    if (MediaUrlResolver.isAsset(resolved)) {
      return VideoPlayerController.asset(
        resolved,
        videoPlayerOptions: videoPlayerOptions,
      );
    }

    if (MediaUrlResolver.isLocalFile(resolved)) {
      final cleanPath = resolved.startsWith('file://')
          ? resolved.replaceFirst('file://', '')
          : resolved;
      return VideoPlayerController.file(
        File(cleanPath),
        videoPlayerOptions: videoPlayerOptions,
      );
    }

    // Remote URL: Cache HIT -> File
    final cached = await getCachedFile(resolved);
    if (cached != null) {
      return VideoPlayerController.file(
        cached,
        videoPlayerOptions: videoPlayerOptions,
      );
    }

    // Remote URL: Cache MISS -> Network
    final uri = Uri.tryParse(resolved) ?? Uri.parse(Uri.encodeFull(resolved));
    return VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  /// Clears the video disk cache and in-memory tracking sets.
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      debugPrint('[VideoCacheService] clearCache error: $e');
    }
    _activeDownloads.clear();
    _triggeredUrls.clear();
  }

  /// Removes a single video from the disk cache.
  Future<void> removeFile(String? rawUrl) async {
    final resolved = MediaUrlResolver.resolve(rawUrl);
    if (resolved.isEmpty) return;
    try {
      await _cacheManager.removeFile(resolved);
    } catch (_) {}
    _triggeredUrls.remove(resolved);
  }

  /// Whether a download is currently in flight for the given [rawUrl].
  bool isDownloading(String? rawUrl) {
    final resolved = MediaUrlResolver.resolve(rawUrl);
    return _activeDownloads.containsKey(resolved);
  }

  /// Whether caching has already been triggered for the given [rawUrl].
  bool isTracked(String? rawUrl) {
    final resolved = MediaUrlResolver.resolve(rawUrl);
    return _triggeredUrls.contains(resolved);
  }
}
