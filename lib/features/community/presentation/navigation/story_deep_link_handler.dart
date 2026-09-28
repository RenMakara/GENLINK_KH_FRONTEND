import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Handles the canonical story URL on cold launch and while the app is active.
class StoryDeepLinkHandler {
  StoryDeepLinkHandler({required this._onOpenStory, AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final Future<bool> Function(String storyId) _onOpenStory;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _lastUri;
  DateTime? _lastHandledAt;

  Future<void> initialize() async {
    _subscription ??= _appLinks.uriLinkStream.listen(
      (uri) => unawaited(handleUri(uri)),
      onError: (Object error) {
        debugPrint('[StoryDeepLink] Link stream error: $error');
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        unawaited(handleUri(initialUri));
      }
    } catch (error) {
      debugPrint('[StoryDeepLink] Initial link unavailable: $error');
    }
  }

  Future<bool> handleUri(Uri uri) async {
    final storyId = storyIdFromUri(uri);
    if (storyId == null) return false;

    final now = DateTime.now();
    if (_lastUri == uri.toString() &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastUri = uri.toString();
    _lastHandledAt = now;
    return _onOpenStory(storyId);
  }

  static String? storyIdFromUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'https' ||
        uri.host.toLowerCase() != 'genlink.app' ||
        (uri.port != 443 && uri.hasPort)) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'story') return null;
    final storyId = segments[1];
    if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(storyId)) return null;
    return storyId;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
