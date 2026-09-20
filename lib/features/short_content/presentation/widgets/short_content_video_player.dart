import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

typedef ShortContentVideoControllerFactory =
    ShortContentVideoController Function(Uri url);

abstract interface class ShortContentVideoController {
  bool get isInitialized;
  bool get isPlaying;
  bool get isBuffering;
  bool get hasError;
  String? get errorDescription;
  double get aspectRatio;

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);

  Future<void> initialize();

  Future<void> setLooping(bool looping);

  Future<void> play();

  Future<void> pause();

  Future<void> dispose();

  Widget buildView();
}

ShortContentVideoController createShortContentVideoController(Uri url) =>
    _VideoPlayerControllerAdapter(VideoPlayerController.networkUrl(url));

class _VideoPlayerControllerAdapter implements ShortContentVideoController {
  _VideoPlayerControllerAdapter(this._controller);

  final VideoPlayerController _controller;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  bool get isBuffering => _controller.value.isBuffering;

  @override
  bool get hasError => _controller.value.hasError;

  @override
  String? get errorDescription => _controller.value.errorDescription;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> setLooping(bool looping) => _controller.setLooping(looping);

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> dispose() => _controller.dispose();

  @override
  Widget buildView() => VideoPlayer(_controller);
}

class ShortContentVideoPlayer extends StatefulWidget {
  const ShortContentVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.isActive,
    this.controllerFactory = createShortContentVideoController,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final bool isActive;
  final ShortContentVideoControllerFactory controllerFactory;

  @override
  State<ShortContentVideoPlayer> createState() =>
      _ShortContentVideoPlayerState();
}

class _ShortContentVideoPlayerState extends State<ShortContentVideoPlayer>
    with WidgetsBindingObserver {
  ShortContentVideoController? _controller;
  bool _isLoading = false;
  bool _hasError = false;
  int _generation = 0;
  Future<void>? _disposeInFlight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) unawaited(_activate());
  }

  @override
  void didUpdateWidget(covariant ShortContentVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _deactivate();
      if (widget.isActive) unawaited(_activate());
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        unawaited(_activate());
      } else {
        _deactivate();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.isActive) unawaited(_resume());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_pause());
    }
  }

  Future<void> _activate() async {
    final token = ++_generation;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Wait for the previous native player to release its resources before
      // creating the next one. This prevents two pages playing during a fast
      // swipe while the old controller is still disposing.
      await _disposeController();
    } catch (_) {
      // Continue with a fresh controller even if native disposal reports an
      // error during a route or app lifecycle transition.
    }
    if (!_isCurrentGeneration(token)) return;

    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null || !_isSupportedUri(uri)) {
      if (mounted && token == _generation) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    late final ShortContentVideoController nextController;
    try {
      nextController = widget.controllerFactory(uri);
    } catch (_) {
      if (mounted && token == _generation) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    _controller = nextController;
    nextController.addListener(_onControllerChanged);

    try {
      await nextController.initialize();
      if (!_isCurrent(token)) return;
      await nextController.setLooping(true);
      await nextController.play();
      if (!_isCurrent(token)) return;

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!_isCurrent(token)) return;
      unawaited(_disposeController());
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _resume() async {
    final controller = _controller;
    if (controller == null || !controller.isInitialized) {
      if (widget.isActive) await _activate();
      return;
    }
    try {
      await controller.play();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _pause() async {
    final controller = _controller;
    if (controller == null || !controller.isPlaying) return;
    try {
      await controller.pause();
    } catch (_) {
      // The controller may already be disposed during a route transition.
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.isInitialized) return;
    try {
      if (controller.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    if (controller.hasError) {
      if (!_hasError) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }
    setState(() {});
  }

  bool _isCurrent(int token) =>
      mounted && token == _generation && widget.isActive && _controller != null;

  bool _isCurrentGeneration(int token) =>
      mounted && token == _generation && widget.isActive;

  void _deactivate() {
    _generation++;
    unawaited(_disposeController());
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  Future<void> _disposeController() {
    final oldController = _controller;
    _controller = null;
    if (oldController == null) {
      return _disposeInFlight ?? Future<void>.value();
    }
    oldController.removeListener(_onControllerChanged);
    final disposal = oldController.dispose();
    _disposeInFlight = disposal;
    return disposal;
  }

  static bool _isSupportedUri(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canRenderVideo =
        controller != null && controller.isInitialized && !_hasError;
    final aspectRatio = canRenderVideo && controller.aspectRatio > 0
        ? controller.aspectRatio
        : 9 / 16;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          _ShortContentThumbnail(url: widget.thumbnailUrl),
          if (canRenderVideo)
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: controller.buildView(),
              ),
            ),
          if (_isLoading && !_hasError)
            const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          if (_hasError) _mediaError(),
          if (canRenderVideo)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayback,
                child: AnimatedOpacity(
                  opacity: controller.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          controller.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaError() {
    final translated = 'shortContent.mediaError'.tr;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_library_outlined,
                color: Colors.white70,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                translated == 'shortContent.mediaError'
                    ? 'Unable to play this video'
                    : translated,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortContentThumbnail extends StatelessWidget {
  const _ShortContentThumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final thumbnail = url?.trim();
    if (thumbnail == null || thumbnail.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }

    return Image.network(
      thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: Colors.black),
    );
  }
}
