import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interface for any feed video player client registered with [FeedVideoPlaybackManager].
abstract class FeedVideoClient {
  /// Unique identifier for this video instance (e.g. post ID + url + slide index).
  String get videoId;

  /// The BuildContext of the video widget to compute visibility relative to the viewport.
  BuildContext? get clientContext;

  /// Whether this client is eligible for playback (e.g. is current page in carousel, initialized, mounted).
  bool get isEligible;

  /// Whether the user has explicitly tapped pause on this video.
  bool get isManuallyPaused;

  /// Whether the video is currently playing.
  bool get isPlaying;

  /// Play this video.
  void playVideo();

  /// Pause this video.
  void pauseVideo();

  /// Set the manual pause state when user taps pause or play.
  void setManuallyPaused(bool paused);

  /// Resets manual pause flag (e.g. when video scrolls completely out of view).
  void resetManualPause();
}

/// Central manager for feed video playback behavior:
/// 1. Visibility-based auto-play: videos >= 50% visible auto-play; < 40% auto-pause.
/// 2. Single active video rule: only ONE video can auto-play in the feed at any given time.
/// 3. Mixed-media carousel awareness: swiping away pauses; swiping back resumes.
/// 4. Manual controls: explicit tap-to-pause is respected until scrolled out of view.
/// 5. Resource safe: no controller leaks, no continuous reinitialization, smooth scrolling.
class FeedVideoPlaybackManager {
  FeedVideoPlaybackManager._internal();
  static final FeedVideoPlaybackManager instance = FeedVideoPlaybackManager._internal();

  /// Registered clients currently mounted in the feed.
  final Set<FeedVideoClient> _clients = <FeedVideoClient>{};

  /// The single video client that is currently playing.
  FeedVideoClient? _activeClient;
  FeedVideoClient? get activeClient => _activeClient;

  Timer? _scrollThrottleTimer;
  bool _isEvaluating = false;

  /// Registers a video client when mounted.
  void register(FeedVideoClient client) {
    _clients.add(client);
  }

  /// Unregisters a video client when unmounted.
  void unregister(FeedVideoClient client) {
    _clients.remove(client);
    if (_activeClient == client) {
      _activeClient = null;
    }
  }

  /// Clears the active client if it matches [client].
  void clearActiveClient(FeedVideoClient client) {
    if (_activeClient == client) {
      _activeClient = null;
    }
  }

  /// Handles scroll notifications from the feed viewport.
  void onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification ||
        notification is UserScrollNotification) {
      _scrollThrottleTimer?.cancel();
      _scrollThrottleTimer = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        evaluateVisibility();
      });
      return;
    }

    if (notification is ScrollUpdateNotification) {
      if (_scrollThrottleTimer == null || !_scrollThrottleTimer!.isActive) {
        _scrollThrottleTimer = Timer(const Duration(milliseconds: 100), () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            evaluateVisibility();
          });
        });
      }
    }
  }

  /// Evaluates the visibility of all registered video clients and ensures
  /// only the single most visible video (>= 50% visible) plays.
  void evaluateVisibility() {
    if (_isEvaluating || _clients.isEmpty) return;
    _isEvaluating = true;

    try {
      FeedVideoClient? bestCandidate;
      double bestScore = -1.0;

      for (final client in _clients) {
        final ctx = client.clientContext;
        if (ctx == null || !ctx.mounted) continue;

        final renderBox = ctx.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) continue;

        // Position of the video widget in global coordinate space
        final position = renderBox.localToGlobal(Offset.zero);
        final widgetTop = position.dy;
        final widgetHeight = renderBox.size.height;
        if (widgetHeight <= 0) continue;
        final widgetBottom = widgetTop + widgetHeight;

        // Determine viewport bounds
        final mediaQuery = MediaQuery.maybeOf(ctx);
        final viewportHeight = mediaQuery?.size.height ?? 800.0;
        final viewportTop = mediaQuery?.padding.top ?? 0.0;
        final viewportBottom =
            viewportHeight - (mediaQuery?.padding.bottom ?? 0.0);

        // Visible vertical overlap
        final visibleTop = math.max(widgetTop, viewportTop);
        final visibleBottom = math.min(widgetBottom, viewportBottom);
        final visibleHeight = math.max(0.0, visibleBottom - visibleTop);
        final visibleFraction = visibleHeight / widgetHeight;

        // If video is scrolled far away, reset user's manual pause so it can autoplay next time
        if (visibleFraction < 0.15 && client.isManuallyPaused) {
          client.resetManualPause();
        }

        // Candidate must be eligible (e.g. current slide) and not manually paused
        if (!client.isEligible || client.isManuallyPaused) {
          continue;
        }

        // Must be at least 50% visible in the viewport
        if (visibleFraction >= 0.5) {
          final viewportCenter = (viewportTop + viewportBottom) / 2;
          final widgetCenter = widgetTop + (widgetHeight / 2);
          final distanceFromCenter = (widgetCenter - viewportCenter).abs();

          // Scoring: prefer higher visibility, break ties with closeness to center
          final score = (visibleFraction * 1000) - distanceFromCenter;

          if (score > bestScore) {
            bestScore = score;
            bestCandidate = client;
          }
        }
      }

      if (bestCandidate != null) {
        if (_activeClient != bestCandidate) {
          _activeClient?.pauseVideo();
          _activeClient = bestCandidate;
          bestCandidate.playVideo();
        } else if (!bestCandidate.isPlaying && !bestCandidate.isManuallyPaused) {
          bestCandidate.playVideo();
        }
      } else {
        // No client meets >= 50% threshold.
        // If current active client is now < 40% visible, pause it.
        final current = _activeClient;
        if (current != null) {
          final ctx = current.clientContext;
          if (ctx != null && ctx.mounted) {
            final renderBox = ctx.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final position = renderBox.localToGlobal(Offset.zero);
              final widgetTop = position.dy;
              final widgetHeight = renderBox.size.height;
              final widgetBottom = widgetTop + widgetHeight;

              final mediaQuery = MediaQuery.maybeOf(ctx);
              final viewportHeight = mediaQuery?.size.height ?? 800.0;
              final viewportTop = mediaQuery?.padding.top ?? 0.0;
              final viewportBottom =
                  viewportHeight - (mediaQuery?.padding.bottom ?? 0.0);

              final visibleTop = math.max(widgetTop, viewportTop);
              final visibleBottom = math.min(widgetBottom, viewportBottom);
              final visibleHeight = math.max(0.0, visibleBottom - visibleTop);
              final visibleFraction =
                  widgetHeight > 0 ? (visibleHeight / widgetHeight) : 0.0;

              if (visibleFraction < 0.4) {
                current.pauseVideo();
                _activeClient = null;
              }
            } else {
              current.pauseVideo();
              _activeClient = null;
            }
          } else {
            _activeClient = null;
          }
        }
      }
    } finally {
      _isEvaluating = false;
    }
  }

  /// Called when user explicitly taps play on a video client.
  void userRequestedPlay(FeedVideoClient client) {
    client.setManuallyPaused(false);
    if (_activeClient != null && _activeClient != client) {
      _activeClient?.pauseVideo();
    }
    _activeClient = client;
    client.playVideo();
  }

  /// Called when user explicitly taps pause on a video client.
  void userRequestedPause(FeedVideoClient client) {
    client.setManuallyPaused(true);
    client.pauseVideo();
    if (_activeClient == client) {
      _activeClient = null;
    }
  }

  /// Pauses all videos (e.g. when leaving the feed screen or switching tabs).
  void pauseAll() {
    _activeClient?.pauseVideo();
    _activeClient = null;
  }
}
