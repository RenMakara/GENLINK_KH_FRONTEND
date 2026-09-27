import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import '../../../../core/services/video_cache_service.dart';
import 'safe_video_player.dart';

/// A resilient fallback implementation of [VideoPlayerPlatform] that satisfies the
/// platform interface contract on platforms/environments where native video_player
/// registrant is not available (such as desktop, test runners, or background isolates).
class SafeVideoPlayerPlatform extends VideoPlayerPlatform {
  static int _nextPlayerId = 1;
  final Map<int, StreamController<VideoEvent>> _streamControllers = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, bool> _isLooping = {};
  final Map<int, double> _volume = {};
  final Map<int, Duration> _position = {};

  @override
  Future<void> init() async {
    // Graceful no-op on platforms where native plugin is not registered
  }

  @override
  Future<void> dispose(int playerId) async {
    _isPlaying.remove(playerId);
    _isLooping.remove(playerId);
    _volume.remove(playerId);
    _position.remove(playerId);
    final controller = _streamControllers.remove(playerId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextPlayerId++;
    _setupPlayer(id);
    return id;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextPlayerId++;
    _setupPlayer(id);
    return id;
  }

  void _setupPlayer(int id) {
    _isPlaying[id] = false;
    _isLooping[id] = false;
    _volume[id] = 1.0;
    _position[id] = Duration.zero;

    _streamControllers.putIfAbsent(
      id,
      () => StreamController<VideoEvent>.broadcast(
        onListen: () {
          final ctrl = _streamControllers[id];
          if (ctrl != null && !ctrl.isClosed) {
            scheduleMicrotask(() {
              if (!ctrl.isClosed) {
                ctrl.add(VideoEvent(
                  eventType: VideoEventType.initialized,
                  duration: const Duration(seconds: 15),
                  size: const Size(1080, 1920),
                ));
              }
            });
          }
        },
      ),
    );
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = _streamControllers.putIfAbsent(
      playerId,
      () => StreamController<VideoEvent>.broadcast(),
    );
    return controller.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    _isLooping[playerId] = looping;
  }

  @override
  Future<void> play(int playerId) async {
    _isPlaying[playerId] = true;
    final controller = _streamControllers[playerId];
    if (controller != null && !controller.isClosed) {
      controller.add(VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ));
    }
  }

  @override
  Future<void> pause(int playerId) async {
    _isPlaying[playerId] = false;
    final controller = _streamControllers[playerId];
    if (controller != null && !controller.isClosed) {
      controller.add(VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ));
    }
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    _volume[playerId] = volume;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _position[playerId] = position;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async {
    return _position[playerId] ?? Duration.zero;
  }

  @override
  Widget buildView(int playerId) {
    return const SizedBox.expand();
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return const SizedBox.expand();
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setAllowBackgroundPlayback(bool allowBackgroundPlayback) async {}
}

/// Ensures that the video player platform is properly registered across all platforms.
void ensureVideoPlayerPlatformRegistered() {
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (e) {
    debugPrint('[StoryVideoPlayer] DartPluginRegistrant note: $e');
  }

  if (VideoPlayerPlatform.instance.runtimeType.toString().contains('Placeholder')) {
    debugPrint('[StoryVideoPlayer] Registering SafeVideoPlayerPlatform fallback');
    VideoPlayerPlatform.instance = SafeVideoPlayerPlatform();
  }
}

/// Normalizes file path/URI string across Android, iOS, and Windows.
File _resolveVideoFile(String rawPath) {
  String clean = rawPath.trim();
  if (clean.startsWith('file:')) {
    final normalized = clean.replaceAll('\\', '/');
    try {
      clean = Uri.parse(normalized).toFilePath();
    } catch (_) {
      clean = normalized.replaceFirst(RegExp(r'^file:/{1,3}'), '');
    }
  }
  clean = clean.replaceAll('\\', '/');
  if (clean.startsWith('/') && clean.length > 2 && clean[2] == ':') {
    clean = clean.substring(1);
  }
  return File(clean);
}

/// A dedicated, robust video player widget designed for Story viewer and canvas.
class StoryVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VideoPlayerController? controller;
  final bool isPlaying;
  final bool isLooping;
  final bool isMuted;
  final BoxFit fit;
  final VoidCallback? onVideoEnd;
  final void Function(VideoPlayerController controller)? onControllerInitialized;
  final void Function(String error)? onError;
  final VoidCallback? onTap;
  final bool showControls;

  const StoryVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.controller,
    this.isPlaying = true,
    this.isLooping = false,
    this.isMuted = false,
    this.fit = BoxFit.contain,
    this.onVideoEnd,
    this.onControllerInitialized,
    this.onError,
    this.onTap,
    this.showControls = true,
  });

  @override
  State<StoryVideoPlayerWidget> createState() => _StoryVideoPlayerWidgetState();
}

class _StoryVideoPlayerWidgetState extends State<StoryVideoPlayerWidget> {
  VideoPlayerController? _internalController;
  bool _isInitializing = false;
  bool _hasError = false;
  bool _hasEnded = false;
  String? _errorMessage;

  VideoPlayerController? get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    ensureVideoPlayerPlatformRegistered();
    if (widget.controller != null) {
      _attachControllerListeners(widget.controller!);
      final ctrl = widget.controller!;
      if (ctrl.value.isInitialized) {
        ctrl.setLooping(widget.isLooping);
        ctrl.setVolume(widget.isMuted ? 0.0 : 1.0);
        if (widget.isPlaying && !ctrl.value.isPlaying) {
          ctrl.play();
        }
        widget.onControllerInitialized?.call(ctrl);
      }
    } else {
      _initInternalController();
    }
  }

  @override
  void didUpdateWidget(covariant StoryVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller != null) {
        _removeControllerListeners(oldWidget.controller!);
      }
      if (widget.controller != null) {
        _disposeInternalController();
        _attachControllerListeners(widget.controller!);
        final ctrl = widget.controller!;
        if (ctrl.value.isInitialized) {
          ctrl.setLooping(widget.isLooping);
          ctrl.setVolume(widget.isMuted ? 0.0 : 1.0);
          if (widget.isPlaying && !ctrl.value.isPlaying) {
            ctrl.play();
          }
          widget.onControllerInitialized?.call(ctrl);
        }
      } else {
        _hasEnded = false;
        _initInternalController();
      }
    } else if (widget.controller == null && widget.videoUrl != oldWidget.videoUrl) {
      _hasEnded = false;
      _initInternalController();
    }

    // Sync play/pause, looping, volume
    final ctrl = _effectiveController;
    if (ctrl != null && ctrl.value.isInitialized) {
      if (widget.isPlaying && !ctrl.value.isPlaying) {
        ctrl.play();
      } else if (!widget.isPlaying && ctrl.value.isPlaying) {
        ctrl.pause();
      }
      if (widget.isLooping != oldWidget.isLooping) {
        ctrl.setLooping(widget.isLooping);
      }
      if (widget.isMuted != oldWidget.isMuted) {
        ctrl.setVolume(widget.isMuted ? 0.0 : 1.0);
      }
    }
  }

  void _attachControllerListeners(VideoPlayerController ctrl) {
    ctrl.addListener(_onControllerTick);
  }

  void _removeControllerListeners(VideoPlayerController ctrl) {
    ctrl.removeListener(_onControllerTick);
  }

  void _onControllerTick() {
    if (!mounted) return;
    final ctrl = _effectiveController;
    if (ctrl == null) return;

    if (ctrl.value.hasError && !_hasError) {
      final desc = ctrl.value.errorDescription ?? 'Unknown playback error';
      debugPrint('[StoryVideoPlayer] Controller error: $desc');
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = desc;
      });
      widget.onError?.call(desc);
      return;
    }

    // Detect video end
    if (ctrl.value.isInitialized &&
        !widget.isLooping &&
        !_hasEnded &&
        ctrl.value.duration > Duration.zero &&
        ctrl.value.position >= ctrl.value.duration) {
      _hasEnded = true;
      widget.onVideoEnd?.call();
    }

    if (ctrl.value.isPlaying) {
      VideoCacheService.instance.trackPlaybackProgress(
        widget.videoUrl,
        ctrl.value.position,
        ctrl.value.duration,
      );
    }

    setState(() {});
  }

  Future<void> _initInternalController() async {
    _disposeInternalController();

    if (widget.videoUrl.trim().isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Empty video URL';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _hasError = false;
      _hasEnded = false;
      _errorMessage = null;
    });

    final url = widget.videoUrl.trim();
    debugPrint('[StoryVideoPlayer] Initializing video: $url');

    try {
      ensureVideoPlayerPlatformRegistered();

      VideoPlayerController ctrl;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final cached = await VideoCacheService.instance.getCachedFile(url);
        if (!mounted) return;
        if (cached != null) {
          ctrl = VideoPlayerController.file(
            cached,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          final uri = Uri.tryParse(url) ?? Uri.parse(Uri.encodeFull(url));
          ctrl = VideoPlayerController.networkUrl(
            uri,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        }
      } else if (url.startsWith('assets/')) {
        ctrl = VideoPlayerController.asset(
          url,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else if (url.startsWith('content://')) {
        final uri = Uri.tryParse(url) ?? Uri.parse(url);
        ctrl = VideoPlayerController.contentUri(
          uri,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        final file = _resolveVideoFile(url);
        if (!file.existsSync()) {
          throw Exception('Local video file does not exist: ${file.path}');
        }
        ctrl = VideoPlayerController.file(
          file,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      _internalController = ctrl;
      _attachControllerListeners(ctrl);

      await ctrl.initialize();

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      await ctrl.setLooping(widget.isLooping);
      await ctrl.setVolume(widget.isMuted ? 0.0 : 1.0);

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      if (widget.isPlaying) {
        try {
          await ctrl.play();
        } catch (playErr) {
          debugPrint('[StoryVideoPlayer] Initial ctrl.play() warning: $playErr');
        }
      }

      debugPrint('[StoryVideoPlayer] Initialized successfully: isInitialized=${ctrl.value.isInitialized}, isPlaying=${ctrl.value.isPlaying}, hasError=${ctrl.value.hasError}, size=${ctrl.value.size}, duration=${ctrl.value.duration}, aspectRatio=${ctrl.value.aspectRatio}');

      widget.onControllerInitialized?.call(ctrl);
    } catch (e) {
      debugPrint('[StoryVideoPlayer] Video initialization failed: $e, hasError=${_internalController?.value.hasError}, errorDescription=${_internalController?.value.errorDescription}');
      _disposeInternalController();
      if (mounted) {
        final rawError = e.toString();
        String userFriendlyError;
        if (rawError.contains('UnimplementedError') ||
            rawError.contains('init()') ||
            rawError.contains('MissingPluginException')) {
          userFriendlyError = 'Unable to play video on this device.';
        } else if (rawError.contains('Local video file does not exist')) {
          userFriendlyError = 'Video file not found.';
        } else if (rawError.contains('SocketException') ||
            rawError.contains('HttpDataSourceException') ||
            rawError.contains('Failed to load video')) {
          userFriendlyError = 'Unable to stream video. Please check your connection.';
        } else {
          userFriendlyError = 'Unable to play video. Tap Retry to reload.';
        }

        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = userFriendlyError;
        });
        widget.onError?.call(rawError);
      }
    }
  }

  void _disposeInternalController() {
    if (_internalController != null) {
      _removeControllerListeners(_internalController!);
      _internalController!.pause();
      _internalController!.dispose();
      _internalController = null;
    }
  }

  @override
  void dispose() {
    final ctrl = widget.controller;
    if (ctrl != null) {
      _removeControllerListeners(ctrl);
    }
    _disposeInternalController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _effectiveController;

    if (_hasError || (ctrl != null && ctrl.value.hasError)) {
      final errorText = _errorMessage ??
          ctrl?.value.errorDescription ??
          'Unable to play video';
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_rounded,
                  color: Colors.white70,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  if (widget.controller == null) {
                    _initInternalController();
                  }
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitializing || ctrl == null || !ctrl.value.isInitialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final size = ctrl.value.size;
    final aspect = ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : (9.0 / 16.0);
    final width = size.width > 0 ? size.width : 720.0;
    final height = size.height > 0 ? size.height : (720.0 / aspect);
    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: SafeVideoPlayer(
                    key: ValueKey('safe_story_vp_${identityHashCode(ctrl)}_${widget.videoUrl}'),
                    controller: ctrl,
                  ),
                ),
              ),
            ),
            if (widget.showControls && !widget.isPlaying && !isPlaying)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: 0.9,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
