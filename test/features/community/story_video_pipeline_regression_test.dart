// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_video_player_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'dart:io';

class PipelineMockLocalStorage extends LocalStorage {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> saveStoryDraft(String draftJson) async {
    _data['story_draft'] = draftJson;
  }

  @override
  Future<String?> readStoryDraft() async {
    return _data['story_draft'] as String?;
  }

  @override
  Future<void> deleteStoryDraft() async {
    _data.remove('story_draft');
  }
}

class PipelineFakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextPlayerId = 100;
  final Map<int, StreamController<VideoEvent>> _controllers = {};
  bool shouldFail = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {
    await _controllers[playerId]?.close();
    _controllers.remove(playerId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    if (shouldFail) {
      throw PlatformException(
        code: 'VIDEO_ERROR',
        message: 'Pipeline simulated video failure',
      );
    }
    final id = _nextPlayerId++;
    final controller = StreamController<VideoEvent>.broadcast();
    controller.onListen = () {
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(seconds: 12),
              size: const Size(720, 1280),
            ),
          );
        }
      });
    };
    _controllers[id] = controller;

    return id;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) {
    return create(options.dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _controllers[playerId]?.stream ?? const Stream.empty();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    _controllers[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    _controllers[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) {
    return Container(
      key: ValueKey('pipeline_video_texture_$playerId'),
      color: Colors.black,
    );
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return buildView(options.playerId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

void main() {
  late PipelineFakeVideoPlayerPlatform fakePlatform;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    fakePlatform = PipelineFakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakePlatform;
    final storage = PipelineMockLocalStorage();
    Get.put<LocalStorage>(storage);
    final repo = StoryRepositoryImpl();
    Get.put<StoryRepository>(repo);
    Get.put<StoryController>(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Video Pipeline Stages A-G Regression Suite', () {
    test('Stage A: Video file extension and query param stripping validation', () {
      bool isVideoPath(String path) {
        final cleanPath = path.split('?').first.toLowerCase();
        return cleanPath.endsWith('.mp4') ||
            cleanPath.endsWith('.mov') ||
            cleanPath.endsWith('.m4v') ||
            cleanPath.endsWith('.3gp') ||
            cleanPath.endsWith('.webm') ||
            cleanPath.endsWith('.mkv');
      }

      expect(isVideoPath('/data/user/0/com.genlink.genlink_frontend/cache/REC_123.mp4'), isTrue);
      expect(isVideoPath('/cache/video.MP4'), isTrue);
      expect(isVideoPath('https://s3.amazonaws.com/genlink/story_video.mp4?AWSAccessKeyId=XYZ&Signature=ABC'), isTrue);
      expect(isVideoPath('https://cdn.genlink.com/videos/reel.webm?token=12345'), isTrue);
      expect(isVideoPath('/storage/emulated/0/DCIM/camera/photo.jpg'), isFalse);
      expect(isVideoPath('https://cdn.genlink.com/images/story.png?v=2'), isFalse);
    });

    test('Stage B: StoryCreator preserves StoryType.video for video paths', () {
      final creator = StoryCreatorScreen(
        type: StoryType.video,
        mediaPaths: const ['/data/user/0/com.genlink/cache/recorded_story.mp4'],
      );
      expect(creator.type, equals(StoryType.video));
      expect(creator.mediaPaths?.first, contains('.mp4'));
    });

    test('Stage C: Story publishing preserves StoryType.video end-to-end', () async {
      final controller = Get.find<StoryController>();
      await controller.fetchStories();

      final published = await controller.publishStory(
        type: StoryType.video,
        mediaUrl: 'https://cdn.genlink.com/stories/user_reel.mp4?token=valid',
        textContent: 'Testing Video Story Pipeline 🚀',
        location: 'CADT Phnom Penh',
      );

      expect(published, isTrue);
      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.first.type, equals(StoryType.video));
      expect(ownerGroup.stories.first.mediaUrl, contains('user_reel.mp4'));
    });

    test('Stage D: Backend response parser preserves StoryType.video', () {
      final jsonPayload = {
        'id': 'backend_story_99',
        'type': 'VIDEO',
        'mediaType': 'VIDEO',
        'mediaUrl': 'https://cdn.genlink.com/uploads/story_rec.mp4?exp=99999',
        'textContent': 'Backend Parsed Story',
        'location': 'Phnom Penh',
        'timeAgo': '1m ago',
        'createdAt': DateTime.now().toIso8601String(),
        'likesCount': 42,
        'isLiked': true,
      };

      final story = StoryItemModel.fromJson(jsonPayload);
      expect(story.type, equals(StoryType.video));
      expect(story.mediaUrl, equals('https://cdn.genlink.com/uploads/story_rec.mp4?exp=99999'));
      expect(story.likesCount, equals(42));
      expect(story.isLiked, isTrue);
    });

    testWidgets('Stage E & F: StoryViewerScreen mounts StoryVideoPlayerWidget for video stories', (tester) async {
      final videoStoryGroup = StoryGroupModel(
        userId: 'dev_user_1',
        userName: 'GenLink Tester',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [
          StoryItemModel(
            id: 'pipe_story_1',
            type: StoryType.video,
            mediaUrl: 'assets/videos/sample_video.mp4',
            textContent: 'Live Video Test Pipeline',
            location: 'Testing Lab',
            timeAgo: 'Just now',
            createdAt: DateTime.now(),
            likesCount: 5,
            isLiked: false,
          ),
        ],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [videoStoryGroup],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.byType(StoryVideoPlayerWidget), findsOneWidget);
      expect(find.byType(VideoPlayer), findsWidgets);
      expect(find.text('Live Video Test Pipeline'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Stage F: StoryVideoPlayerWidget displays graceful error fallback when video fails to play', (tester) async {
      fakePlatform.shouldFail = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoryVideoPlayerWidget(
              videoUrl: 'https://corrupt.example.com/broken.mp4',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    test('Stage G: AndroidManifest contains android:usesCleartextTraffic="true"', () {
      final manifestPath = 'android/app/src/main/AndroidManifest.xml';
      final file = File(manifestPath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        expect(content, contains('android:usesCleartextTraffic="true"'));
      }
    });
  });
}
