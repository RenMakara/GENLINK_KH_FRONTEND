import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/safe_video_player.dart';

class FailingVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {
    _controllers.remove(playerId);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async => 2;

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 2;

  final Map<int, StreamController<VideoEvent>> _controllers = {};

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _controllers.putIfAbsent(
      playerId,
      () => StreamController<VideoEvent>.broadcast(
        onListen: () {
          scheduleMicrotask(() {
            _controllers[playerId]?.add(
              VideoEvent(
                eventType: VideoEventType.initialized,
                duration: const Duration(seconds: 10),
                size: const Size(1920, 1080),
              ),
            );
          });
        },
      ),
    ).stream;
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    if (options.playerId == 2) {
      throw StateError('No active player with ID ${options.playerId}.');
    }
    return Container();
  }
}

class WorkingVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> create(DataSource dataSource) async => 1;

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => const Stream.empty();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return const KeyedSubtree(
      key: ValueKey('working_platform_video_view'),
      child: SizedBox(width: 320, height: 180),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafeVideoPlayer Widget Tests', () {
    testWidgets('renders fallback without crashing when controller is uninitialized', (tester) async {
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/test.mp4'),
      );

      bool errorTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeVideoPlayer(
              controller: ctrl,
              fallbackWidget: const Text('Fallback Placeholder'),
              onError: () {
                errorTriggered = true;
              },
            ),
          ),
        ),
      );

      // Uninitialized controller has textureId == -1 and isInitialized == false
      expect(find.text('Fallback Placeholder'), findsOneWidget);
      expect(errorTriggered, isFalse);

      await ctrl.dispose();
    });

    testWidgets('intercepts StateError: No active player with ID without throwing red screen', (tester) async {
      // Mock platform that throws "No active player with ID 2."
      VideoPlayerPlatform.instance = FailingVideoPlayerPlatform();

      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/test.mp4'),
      );
      await ctrl.initialize();

      bool errorTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeVideoPlayer(
              controller: ctrl,
              fallbackWidget: const Text('Recovered Fallback'),
              onError: () {
                errorTriggered = true;
              },
            ),
          ),
        ),
      );

      // Should safely render fallback without causing ErrorWidget / red screen
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.text('Recovered Fallback'), findsOneWidget);
      await tester.pump();
      expect(errorTriggered, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
