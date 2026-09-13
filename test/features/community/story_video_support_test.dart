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
import 'package:genlink_frontend/features/community/presentation/controllers/story_gallery_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_video_player_widget.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class MockLocalStorage extends LocalStorage {
  final Map<String, dynamic> _memory = {};

  @override
  Future<void> saveStoryDraft(String draftJson) async {
    _memory['story_draft'] = draftJson;
  }

  @override
  Future<String?> readStoryDraft() async {
    return _memory['story_draft'] as String?;
  }

  @override
  Future<void> deleteStoryDraft() async {
    _memory.remove('story_draft');
  }
}

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextPlayerId = 1;
  final Map<int, StreamController<VideoEvent>> _controllers = {};
  final Map<int, bool> _isPlaying = {};
  bool shouldFail = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {
    await _controllers[playerId]?.close();
    _controllers.remove(playerId);
    _isPlaying.remove(playerId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    if (shouldFail) {
      throw PlatformException(
        code: 'VIDEO_ERROR',
        message: 'Simulated video initialization error',
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
              duration: const Duration(seconds: 15),
              size: const Size(1080, 1920),
            ),
          );
        }
      });
    };
    _controllers[id] = controller;
    _isPlaying[id] = false;

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
    _isPlaying[playerId] = true;
    _controllers[playerId]?.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause(int playerId) async {
    _isPlaying[playerId] = false;
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
      key: ValueKey('fake_video_texture_$playerId'),
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
  late FakeVideoPlayerPlatform fakeVideoPlatform;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    fakeVideoPlatform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakeVideoPlatform;
    final storage = MockLocalStorage();
    Get.put<LocalStorage>(storage);
    final repo = StoryRepositoryImpl();
    Get.put<StoryRepository>(repo);
    Get.put<StoryController>(StoryController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Video Support Feature Tests', () {
    test('Test 1: StoryType.video exists and StoryItemModel constructs properly with video media', () {
      final videoStory = StoryItemModel(
        id: 'video_story_1',
        type: StoryType.video,
        mediaUrl: 'assets/videos/sample_campus_tour.mp4',
        textContent: 'Campus Tour Video 🎥',
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
        location: 'CADT Innovation Center',
      );

      expect(videoStory.type, equals(StoryType.video));
      expect(videoStory.mediaUrl, equals('assets/videos/sample_campus_tour.mp4'));
      expect(videoStory.textContent, equals('Campus Tour Video 🎥'));
      expect(videoStory.location, equals('CADT Innovation Center'));
      expect(videoStory.likesCount, equals(0));
      expect(videoStory.isLiked, isFalse);
    });

    test('Test 2: StoryController publishes Video Story successfully and inserts into owner story group', () async {
      final controller = Get.find<StoryController>();
      await controller.fetchStories();

      final published = await controller.publishStory(
        type: StoryType.video,
        mediaUrl: 'assets/videos/tech_demo.mp4',
        textContent: 'Building with Flutter & AI 🚀',
        location: 'Phnom Penh',
      );

      expect(published, isTrue);
      expect(controller.storyGroups.isNotEmpty, isTrue);

      final ownerGroup = controller.storyGroups.firstWhere((g) => g.isOwner);
      expect(ownerGroup.stories.isNotEmpty, isTrue);

      final latestStory = ownerGroup.stories.first;
      expect(latestStory.type, equals(StoryType.video));
      expect(latestStory.mediaUrl, equals('assets/videos/tech_demo.mp4'));
      expect(latestStory.textContent, equals('Building with Flutter & AI 🚀'));
    });

    testWidgets('Test 3: StoryViewerScreen renders Video Story with play/pause and video metadata', (tester) async {
      final videoGroup = StoryGroupModel(
        userId: 'user_dev',
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: true,
        stories: [
          StoryItemModel(
            id: 'video_test_1',
            type: StoryType.video,
            mediaUrl: 'assets/videos/flutter_web.mp4',
            textContent: 'Check out the video preview!',
            location: 'Phnom Penh',
            timeAgo: '10m ago',
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
            likesCount: 15,
            isLiked: false,
          ),
        ],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [videoGroup],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StoryViewerScreen), findsOneWidget);
      expect(find.text('Check out the video preview!'), findsOneWidget);
      expect(find.text('Phnom Penh'), findsOneWidget);
      expect(find.byType(StoryVideoPlayerWidget), findsOneWidget);
      expect(find.byType(VideoPlayer), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Test 4: StoryCreatorScreen supports StoryType.video with media paths', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const StoryCreatorScreen(
            type: StoryType.video,
            mediaPaths: ['assets/videos/demo_reel.mp4'],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StoryCreatorScreen), findsOneWidget);
      expect(find.byIcon(Icons.videocam_rounded), findsWidgets);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('00:15'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });

    test('Test 5: StoryGalleryController configures photo vs common request type correctly', () {
      final galleryController = Get.put(StoryGalleryController());

      expect(galleryController.requiredPhotosCount.value, equals(0));
      expect(galleryController.selectedTemplate.value, isNull);

      galleryController.configureForTemplate(
        requiredPhotos: 3,
        isMultiSelect: true,
      );
      expect(galleryController.requiredPhotosCount.value, equals(3));
      expect(galleryController.isMultiSelectMode.value, isTrue);
    });

    testWidgets('Test 6: StoryCreatorScreen displays error and retry button when video fails to load', (tester) async {
      fakeVideoPlatform.shouldFail = true;

      await tester.pumpWidget(
        GetMaterialApp(
          home: const StoryCreatorScreen(
            type: StoryType.video,
            mediaPaths: ['assets/videos/corrupted_video.mp4'],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StoryCreatorScreen), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Choose Video'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
