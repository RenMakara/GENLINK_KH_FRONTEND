// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A robust, crash-proof wrapper around [VideoPlayerPlatform.buildViewWithOptions].
///
/// Flutter's standard [VideoPlayer] widget from the `video_player` package can throw an
/// unhandled [StateError] (`Bad state: No active player with ID $id.`) inside its `build()`
/// method if the underlying native Android/iOS player instance was disposed or invalidated
/// while the widget was still mounted in the tree or during rapid feed scrolling.
///
/// Because Flutter's framework catches exceptions thrown in `Widget.build()`, an uncaught
/// [StateError] results in the red crash screen of death (ErrorWidget) appearing directly in
/// the feed card.
///
/// [SafeVideoPlayer] resolves this by:
/// 1. Verifying that the controller is non-null, initialized, and has a valid playerId (> 0).
/// 2. Invoking [VideoPlayerPlatform.instance.buildViewWithOptions] inside a try/catch block.
/// 3. Intercepting any synchronous [StateError] or [PlatformException] thrown by the platform.
/// 4. Gracefully reporting [onError] so parent widgets render a clean error/retry UI rather
///    than crashing Flutter.
class SafeVideoPlayer extends StatefulWidget {
  const SafeVideoPlayer({
    super.key,
    required this.controller,
    this.onError,
    this.fallbackWidget,
  });

  final VideoPlayerController controller;
  final VoidCallback? onError;
  final Widget? fallbackWidget;

  @override
  State<SafeVideoPlayer> createState() => _SafeVideoPlayerState();
}

class _SafeVideoPlayerState extends State<SafeVideoPlayer> {
  late VoidCallback _listener;
  late int _playerId;
  bool _hasBuildError = false;

  @override
  void initState() {
    super.initState();
    _playerId = widget.controller.playerId;
    _listener = () {
      if (!mounted) return;
      final int newPlayerId = widget.controller.playerId;
      if (newPlayerId != _playerId) {
        setState(() {
          _playerId = newPlayerId;
          _hasBuildError = false;
        });
      }
    };
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(SafeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.controller.playerId != widget.controller.playerId) {
      oldWidget.controller.removeListener(_listener);
      _playerId = widget.controller.playerId;
      _hasBuildError = false;
      widget.controller.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasBuildError ||
        _playerId == VideoPlayerController.kUninitializedPlayerId ||
        !widget.controller.value.isInitialized) {
      return widget.fallbackWidget ?? const SizedBox.shrink();
    }

    try {
      final view = VideoPlayerPlatform.instance.buildViewWithOptions(
        VideoViewOptions(playerId: _playerId),
      );
      final rotation = widget.controller.value.rotationCorrection;
      if (rotation != 0 && rotation % 90 == 0) {
        return RotatedBox(quarterTurns: rotation ~/ 90, child: view);
      }
      return view;
    } catch (e) {
      debugPrint(
          '[SafeVideoPlayer] Intercepted platform build error for player $_playerId: $e');
      _hasBuildError = true;
      scheduleMicrotask(() {
        if (mounted) {
          widget.onError?.call();
        }
      });
      return widget.fallbackWidget ?? const SizedBox.shrink();
    }
  }
}
