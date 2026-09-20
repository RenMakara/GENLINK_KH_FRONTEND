import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/short_content/presentation/widgets/short_content_video_player.dart';

class _FakeVideoController implements ShortContentVideoController {
  bool initialized = false;
  bool playing = false;
  bool looping = false;
  bool disposed = false;
  int initializeCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  VoidCallback? _listener;

  @override
  bool get isInitialized => initialized;

  @override
  bool get isPlaying => playing;

  @override
  bool get isBuffering => false;

  @override
  bool get hasError => false;

  @override
  String? get errorDescription => null;

  @override
  double get aspectRatio => 16 / 9;

  @override
  void addListener(VoidCallback listener) => _listener = listener;

  @override
  void removeListener(VoidCallback listener) {
    if (_listener == listener) _listener = null;
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
    initialized = true;
    _listener?.call();
  }

  @override
  Future<void> setLooping(bool value) async => looping = value;

  @override
  Future<void> play() async {
    playCalls++;
    playing = true;
    _listener?.call();
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    playing = false;
    _listener?.call();
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    playing = false;
  }

  @override
  Widget buildView() => const SizedBox.expand();
}

void main() {
  testWidgets('initializes only when active and disposes when inactive', (
    tester,
  ) async {
    final controllers = <_FakeVideoController>[];

    ShortContentVideoController factory(Uri _) {
      final controller = _FakeVideoController();
      controllers.add(controller);
      return controller;
    }

    Future<void> pumpPlayer(bool active) {
      return tester.pumpWidget(
        MaterialApp(
          home: ShortContentVideoPlayer(
            videoUrl: 'https://cdn.example.com/video.mp4',
            thumbnailUrl: null,
            isActive: active,
            controllerFactory: factory,
          ),
        ),
      );
    }

    await pumpPlayer(false);
    expect(controllers, isEmpty);

    await pumpPlayer(true);
    await tester.pump();
    await tester.pump();

    expect(controllers, hasLength(1));
    expect(controllers.single.initializeCalls, 1);
    expect(controllers.single.looping, isTrue);
    expect(controllers.single.playCalls, 1);

    await pumpPlayer(false);
    await tester.pump();
    expect(controllers.single.disposed, isTrue);
  });

  testWidgets('renders a media error when initialization fails', (
    tester,
  ) async {
    final controller = _FailingVideoController();

    await tester.pumpWidget(
      MaterialApp(
        home: ShortContentVideoPlayer(
          videoUrl: 'https://cdn.example.com/video.mp4',
          thumbnailUrl: null,
          isActive: true,
          controllerFactory: (_) => controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Unable to play this video'), findsOneWidget);
    expect(controller.disposed, isTrue);
  });
}

class _FailingVideoController extends _FakeVideoController {
  @override
  Future<void> initialize() async {
    initializeCalls++;
    throw StateError('network unavailable');
  }
}
