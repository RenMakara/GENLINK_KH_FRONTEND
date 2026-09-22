import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_video_player_widget.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _FakeVideoPlayerController extends VideoPlayerController {
  _FakeVideoPlayerController() : super.file(File('dummy.mp4'));

  bool playCalled = false;
  bool pauseCalled = false;
  bool loopingSet = false;
  double? volumeSet;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 12),
      size: const Size(1080, 1920),
    );
  }

  @override
  Future<void> play() async {
    playCalled = true;
    value = value.copyWith(isPlaying: true);
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    value = value.copyWith(isPlaying: false);
    notifyListeners();
  }

  @override
  Future<void> setLooping(bool looping) async {
    loopingSet = looping;
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumeSet = volume;
    value = value.copyWith(volume: volume);
  }

  void triggerEnd() {
    value = value.copyWith(
      position: const Duration(seconds: 12),
    );
    notifyListeners();
  }

  void triggerError(String desc) {
    value = value.copyWith(
      errorDescription: desc,
    );
    notifyListeners();
  }
}

class _MockLocalStorage extends LocalStorage {
  _MockLocalStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> readStoryDraft() async => null;

  @override
  Future<void> saveStoryDraft(String draftJson) async {}

  @override
  Future<void> deleteStoryDraft() async {}
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('StoryVideoPlayerWidget Playback Regression Tests', () {
    testWidgets('1. StoryVideoPlayerWidget initializes with external controller and plays', (tester) async {
      final fakeCtrl = _FakeVideoPlayerController();
      await fakeCtrl.initialize();

      bool initializedCallbackCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryVideoPlayerWidget(
              videoUrl: 'https://cdn.genlink.com/sample.mp4',
              controller: fakeCtrl,
              isPlaying: true,
              onControllerInitialized: (c) {
                initializedCallbackCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(fakeCtrl.playCalled, isTrue);
      expect(fakeCtrl.value.isPlaying, isTrue);
    });

    testWidgets('2. StoryVideoPlayerWidget syncs pause and play states when isPlaying changes', (tester) async {
      final fakeCtrl = _FakeVideoPlayerController();
      await fakeCtrl.initialize();

      bool isPlaying = true;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: StoryVideoPlayerWidget(
                        videoUrl: 'https://cdn.genlink.com/sample.mp4',
                        controller: fakeCtrl,
                        isPlaying: isPlaying,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isPlaying = false),
                      child: const Text('Pause'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(fakeCtrl.value.isPlaying, isTrue);

      await tester.tap(find.text('Pause'));
      await tester.pump();

      expect(fakeCtrl.pauseCalled, isTrue);
      expect(fakeCtrl.value.isPlaying, isFalse);
    });

    testWidgets('3. StoryVideoPlayerWidget detects video completion and invokes onVideoEnd', (tester) async {
      final fakeCtrl = _FakeVideoPlayerController();
      await fakeCtrl.initialize();

      bool ended = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryVideoPlayerWidget(
              videoUrl: 'https://cdn.genlink.com/sample.mp4',
              controller: fakeCtrl,
              isPlaying: true,
              isLooping: false,
              onVideoEnd: () {
                ended = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(ended, isFalse);
      fakeCtrl.triggerEnd();
      await tester.pump();

      expect(ended, isTrue);
    });

    testWidgets('4. StoryVideoPlayerWidget shows error message and retry button when playback fails', (tester) async {
      final fakeCtrl = _FakeVideoPlayerController();
      await fakeCtrl.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryVideoPlayerWidget(
              videoUrl: 'https://cdn.genlink.com/bad_video.mp4',
              controller: fakeCtrl,
            ),
          ),
        ),
      );
      await tester.pump();

      fakeCtrl.triggerError('Corrupt video stream');
      await tester.pump();

      expect(find.text('Corrupt video stream'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('5. StoryViewerScreen renders VideoPlayer for StoryType.video instead of static card', (tester) async {
      final story = StoryItemModel(
        id: 'vid_viewer_story_01',
        type: StoryType.video,
        mediaUrl: 'https://cdn.genlink.com/stories/test_video.mp4',
        textContent: 'Test video post',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      );
      final group = StoryGroupModel(
        userId: 'user_01',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [story],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.byType(StoryVideoPlayerWidget), findsOneWidget);
      expect(find.byKey(const ValueKey('story_video_vid_viewer_story_01')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('6. Remote viewer (Account B, isOwner: false) plays Account A video story without UnimplementedError', (tester) async {
      final storyAccountA = StoryItemModel(
        id: 'story_account_a_vid_99',
        type: StoryType.video,
        mediaUrl: 'https://cdn.genlink.com/stories/account_a_video.mp4',
        textContent: 'Story from Account A',
        timeAgo: '2h ago',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      final groupAccountA = StoryGroupModel(
        userId: 'account_a_id',
        userName: 'Account A Creator',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false, // Account B is viewing
        stories: [storyAccountA],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [groupAccountA],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.byType(StoryVideoPlayerWidget), findsOneWidget);
      expect(find.text('Story from Account A'), findsOneWidget);

      // Verify that "UnimplementedError: init() has not been implemented." is NEVER displayed
      expect(find.textContaining('UnimplementedError'), findsNothing);
      expect(find.textContaining('init() has not been implemented'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('7. StoryVideoPlayerWidget internal initialization renders without throwing UnimplementedError', (tester) async {
      VideoPlayerController? capturedCtrl;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryVideoPlayerWidget(
              videoUrl: 'https://cdn.genlink.com/stories/stream_test.mp4',
              onControllerInitialized: (ctrl) {
                capturedCtrl = ctrl;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(StoryVideoPlayerWidget), findsOneWidget);
      expect(find.textContaining('UnimplementedError'), findsNothing);
      expect(capturedCtrl, isNotNull);
      expect(capturedCtrl!.value.isInitialized, isTrue);
    });

    testWidgets('8. ensureVideoPlayerPlatformRegistered guarantees platform interface is functional', (tester) async {
      ensureVideoPlayerPlatformRegistered();
      expect(VideoPlayerPlatform.instance, isNotNull);
      expect(VideoPlayerPlatform.instance.runtimeType.toString(), isNot(contains('Placeholder')));

      // Initializing should not throw UnimplementedError
      await expectLater(VideoPlayerPlatform.instance.init(), completes);
    });
  });
}
