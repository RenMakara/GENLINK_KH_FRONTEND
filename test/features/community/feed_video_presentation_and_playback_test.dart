import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/feed_video_playback_manager.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class _MockRepo implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A controllable mock video client for testing [FeedVideoPlaybackManager] logic directly.
class _FakeVideoClient implements FeedVideoClient {
  _FakeVideoClient({
    required this.videoId,
    required this.clientContext,
    this.isEligible = true,
  });

  @override
  final String videoId;

  @override
  final BuildContext? clientContext;

  @override
  bool isEligible;

  @override
  bool isManuallyPaused = false;

  bool _playing = false;

  @override
  bool get isPlaying => _playing;

  @override
  void playVideo() {
    _playing = true;
  }

  @override
  void pauseVideo() {
    _playing = false;
  }

  @override
  void setManuallyPaused(bool paused) {
    isManuallyPaused = paused;
  }

  @override
  void resetManualPause() {
    isManuallyPaused = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommunityController controller;

  setUp(() {
    Get.reset();
    controller = CommunityController(repository: _MockRepo());
    Get.put<CommunityController>(controller);
    FeedVideoPlaybackManager.instance.pauseAll();
  });

  tearDown(() {
    FeedVideoPlaybackManager.instance.pauseAll();
    Get.reset();
  });

  Widget buildApp(Widget child) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Issue 1: Video Frame / Aspect Ratio & Layout', () {
    testWidgets('Single video post wraps VideoPostMedia without exploding bounds', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'single_vid_post',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Now',
        content: 'Check out this video',
        videoUrl: 'https://example.com/portrait_clip.mp4',
      );

      await tester.pumpWidget(buildApp(SingleChildScrollView(
        child: PostCardWidget(
          post: post,
          controller: controller,
        ),
      )));
      await tester.pump();

      // VideoPostMedia is present
      final videoFinder = find.byType(VideoPostMedia);
      expect(videoFinder, findsOneWidget);

      // Sizing is reasonable (within 100 to 500 px height)
      final size = tester.getSize(videoFinder);
      expect(size.height, greaterThan(150));
      expect(size.height, lessThanOrEqualTo(500));
    });

    testWidgets('Carousel mixed media adapts aspect ratio without fixed-height letterbox collapse', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'mixed_carousel_post',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Now',
        content: 'Mixed media carousel',
        videoUrl: 'https://example.com/clip.mp4',
        imageUrls: const ['https://example.com/photo1.jpg'],
      );

      await tester.pumpWidget(buildApp(SingleChildScrollView(
        child: PostCardWidget(
          post: post,
          controller: controller,
        ),
      )));
      await tester.pump();

      // Aspect ratio aware layout container adapts instead of hardcoded rigid 350 SizedBox
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      final carouselSize = tester.getSize(pageViewFinder);
      expect(carouselSize.height, greaterThan(150));
      expect(carouselSize.height, lessThanOrEqualTo(420));
    });
  });

  group('Issue 2: Feed Video Playback Manager & Visibility Rules', () {
    test('Single active video rule: playing candidate B pauses candidate A', () {
      final manager = FeedVideoPlaybackManager.instance;
      final clientA = _FakeVideoClient(videoId: 'vid_A', clientContext: null);
      final clientB = _FakeVideoClient(videoId: 'vid_B', clientContext: null);

      manager.register(clientA);
      manager.register(clientB);

      // User plays A
      manager.userRequestedPlay(clientA);
      expect(clientA.isPlaying, isTrue);
      expect(clientB.isPlaying, isFalse);
      expect(manager.activeClient, clientA);

      // User plays B -> A pauses immediately
      manager.userRequestedPlay(clientB);
      expect(clientA.isPlaying, isFalse);
      expect(clientB.isPlaying, isTrue);
      expect(manager.activeClient, clientB);

      manager.unregister(clientA);
      manager.unregister(clientB);
    });

    test('Manual pause intent is respected', () {
      final manager = FeedVideoPlaybackManager.instance;
      final client = _FakeVideoClient(videoId: 'vid_1', clientContext: null);

      manager.register(client);
      manager.userRequestedPlay(client);
      expect(client.isPlaying, isTrue);
      expect(client.isManuallyPaused, isFalse);

      // User explicitly taps pause
      manager.userRequestedPause(client);
      expect(client.isPlaying, isFalse);
      expect(client.isManuallyPaused, isTrue);
      expect(manager.activeClient, isNull);

      // Manual pause reset when scrolled off screen
      client.resetManualPause();
      expect(client.isManuallyPaused, isFalse);

      manager.unregister(client);
    });

    test('pauseAll pauses any active playing video', () {
      final manager = FeedVideoPlaybackManager.instance;
      final client = _FakeVideoClient(videoId: 'vid_x', clientContext: null);

      manager.register(client);
      manager.userRequestedPlay(client);
      expect(client.isPlaying, isTrue);

      manager.pauseAll();
      expect(client.isPlaying, isFalse);
      expect(manager.activeClient, isNull);

      manager.unregister(client);
    });

    test('Unregistering active client safely clears active client reference', () {
      final manager = FeedVideoPlaybackManager.instance;
      final client = _FakeVideoClient(videoId: 'vid_leak_check', clientContext: null);

      manager.register(client);
      manager.userRequestedPlay(client);
      expect(manager.activeClient, client);

      manager.unregister(client);
      expect(manager.activeClient, isNull);
    });

    test('Ineligible client (e.g. inactive slide) is not eligible for playback', () {
      final client = _FakeVideoClient(
        videoId: 'ineligible_vid',
        clientContext: null,
        isEligible: false,
      );
      expect(client.isEligible, isFalse);
    });
  });

  group('Issue 2: Carousel Swiping and Playback Interaction', () {
    testWidgets('Swiping from Video slide to Image slide pauses video', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'post_swipe_test',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Now',
        content: 'Carousel playback test',
        videoUrl: 'https://example.com/video.mp4',
        imageUrls: const ['https://example.com/photo.jpg'],
      );

      await tester.pumpWidget(buildApp(SingleChildScrollView(
        child: PostCardWidget(
          post: post,
          controller: controller,
        ),
      )));
      await tester.pump();

      expect(find.byType(VideoPostMedia), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);

      // Swipe to page 2 (Image slide)
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('2/2'), findsOneWidget);

      // Swipe back to page 1 (Video slide)
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);
    });
  });
}
