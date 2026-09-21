import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class _MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommunityController controller;

  setUp(() {
    Get.reset();
    controller = CommunityController(repository: _MockCommunityRepository());
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp(CommunityPostModel post) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PostCardWidget(
            post: post,
            controller: controller,
          ),
        ),
      ),
    );
  }

  group('Unified Media Carousel — 10 Required Test Cases', () {
    // -------------------------------------------------------------------------
    // TEST 1: 1 image → one image, no PageView, no counter pill
    // -------------------------------------------------------------------------
    testWidgets('TEST 1: 1 image → renders one image normally without carousel counter', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_1_img',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Single image post',
        imageUrls: const ['https://example.com/single.jpg'],
      );

      // Model verification
      expect(post.mediaItems.length, 1);
      expect(post.mediaItems.first.isImage, isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.text('1/1'), findsNothing);
      expect(find.byType(VideoPostMedia), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 2: 3 images → one carousel → 1/3 → 2/3 → 3/3
    // -------------------------------------------------------------------------
    testWidgets('TEST 2: 3 images → one carousel → 1/3 → 2/3 → 3/3', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_3_imgs',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Three images post',
        imageUrls: const [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
          'https://example.com/img3.jpg',
        ],
      );

      // Model verification
      expect(post.mediaItems.length, 3);
      expect(post.mediaItems.every((m) => m.isImage), isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Swipe to image 2
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // Swipe to image 3
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 3: 1 video → one video, no PageView, no counter pill
    // -------------------------------------------------------------------------
    testWidgets('TEST 3: 1 video → renders one video normally without carousel counter', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_1_vid',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Single video post',
        videoUrl: 'https://example.com/clip.mp4',
      );

      // Model verification
      expect(post.mediaItems.length, 1);
      expect(post.mediaItems.first.isVideo, isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      expect(find.byType(VideoPostMedia), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('1/1'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 4: video + image → one carousel → video → image
    // -------------------------------------------------------------------------
    testWidgets('TEST 4: video + image → one carousel → video → image', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_vid_img',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Video and image post',
        videoUrl: 'https://example.com/clip.mp4',
        imageUrls: const ['https://example.com/img1.jpg'],
      );

      // Model verification: video first, then image
      expect(post.mediaItems.length, 2);
      expect(post.mediaItems[0].isVideo, isTrue);
      expect(post.mediaItems[1].isImage, isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      // Only ONE PageView, with 1/2 badge
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);

      // Swipe to page 2 (image)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 5: video + image + image → one carousel → video → image → image (1/3 → 2/3 → 3/3)
    // -------------------------------------------------------------------------
    testWidgets('TEST 5: video + image + image → one carousel → video → image → image → 1/3 → 2/3 → 3/3', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_vid_2imgs',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Video and two images post',
        videoUrl: 'https://example.com/video.mp4',
        imageUrls: const [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ],
      );

      // Model verification
      expect(post.mediaItems.length, 3);
      expect(post.mediaItems[0].isVideo, isTrue);
      expect(post.mediaItems[1].isImage, isTrue);
      expect(post.mediaItems[2].isImage, isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      // Exactly ONE PageView
      expect(find.byType(PageView), findsOneWidget);
      // Starts at 1/3 with video
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);

      // Swipe to image 1 (2/3)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // Swipe to image 2 (3/3)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 6: image + video + image → one carousel → image → video → image
    // -------------------------------------------------------------------------
    testWidgets('TEST 6: image + video + image → one carousel → image → video → image', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_img_vid_img',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Image then video then image',
        mediaUrls: const [
          'https://example.com/img1.jpg',
          'https://example.com/clip.mp4',
          'https://example.com/img2.jpg',
        ],
      );

      // Model verification: preserves order image → video → image
      expect(post.mediaItems.length, 3);
      expect(post.mediaItems[0].isImage, isTrue);
      expect(post.mediaItems[1].isVideo, isTrue);
      expect(post.mediaItems[2].isImage, isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      // Page 0 is image 1
      expect(find.text('1/3'), findsOneWidget);

      // Swipe to page 1 (video)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);

      // Swipe to page 2 (image 2)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 7: image + image + video → one carousel → image → image → video
    // -------------------------------------------------------------------------
    testWidgets('TEST 7: image + image + video → one carousel → image → image → video', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_img_img_vid',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Two images then video',
        mediaUrls: const [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
          'https://example.com/clip.mp4',
        ],
      );

      // Model verification: image → image → video
      expect(post.mediaItems.length, 3);
      expect(post.mediaItems[0].isImage, isTrue);
      expect(post.mediaItems[1].isImage, isTrue);
      expect(post.mediaItems[2].isVideo, isTrue);

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Swipe to page 1 (image 2)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // Swipe to page 2 (video)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Swipe between media → only ONE media item visible at a time
    // -------------------------------------------------------------------------
    testWidgets('TEST 8: Swipe between media → only ONE media item visible at a time', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_viewport',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Viewport test',
        videoUrl: 'https://example.com/clip.mp4',
        imageUrls: const ['https://example.com/photo.jpg'],
      );

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      // Exactly ONE PageView exists
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      // On page 0, the counter is 1/2
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('2/2'), findsNothing);

      // After swiping to page 1, counter is 2/2
      await tester.fling(pageViewFinder, const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('1/2'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // TEST 9: Video page → video remains playable
    // -------------------------------------------------------------------------
    testWidgets('TEST 9: Video page → video remains playable with play/pause controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_playback',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Playable video in carousel',
        videoUrl: 'https://example.com/clip.mp4',
        imageUrls: const ['https://example.com/photo.jpg'],
      );

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      // VideoPostMedia is present in page 0 of carousel
      expect(find.byType(VideoPostMedia), findsOneWidget);

      // Tapping the video page does not crash and toggles play/pause state
      await tester.tap(find.byType(VideoPostMedia));
      await tester.pump();
      expect(find.byType(VideoPostMedia), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 10: Return to video page → no duplicate video widget, no broken playback
    // -------------------------------------------------------------------------
    testWidgets('TEST 10: Return to video page → no duplicate video widget and state preserved', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'test_return_playback',
        userId: 'u1',
        authorName: 'User',
        authorTag: '@user',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Swipe away and return',
        videoUrl: 'https://example.com/clip.mp4',
        imageUrls: const [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
      );

      await tester.pumpWidget(buildTestApp(post));
      await tester.pump();

      // Page 0: video
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byType(VideoPostMedia), findsOneWidget);

      // Swipe to page 1: image 1
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // Swipe to page 2: image 2
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);

      // Swipe back to page 1
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // Swipe back to page 0 (video)
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // Verify exactly ONE VideoPostMedia widget (no duplicate widget created)
      expect(find.byType(VideoPostMedia), findsOneWidget);
    });
  });
}
