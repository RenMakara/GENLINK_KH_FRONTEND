import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/post_gallery_screen.dart';

class MockCommunityRepository implements CommunityRepository {
  CommunityPostModel? lastCreatedPost;
  List<String> lastImageUrls = [];
  String? lastVideoUrl;

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    lastImageUrls = List.from(imageUrls);
    lastVideoUrl = null;
    lastCreatedPost = CommunityPostModel(
      id: 'post_img_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
      isOwner: true,
      postType: imageUrls.isNotEmpty ? 'IMAGE' : 'TEXT',
    );
    return lastCreatedPost!;
  }

  @override
  Future<CommunityPostModel> createPostWithVideo({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    lastImageUrls = List.from(imageUrls);
    lastVideoUrl = videoUrl;
    lastCreatedPost = CommunityPostModel(
      id: 'post_mixed_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_1',
      authorName: 'Tester',
      authorTag: '@tester',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      visibility: visibility,
      community: community,
      isOwner: true,
      postType: 'VIDEO',
    );
    return lastCreatedPost!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCommunityRepository mockRepo;
  late CommunityController controller;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    mockRepo = MockCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget(Widget child) {
    return GetMaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('Post Media Unified Selection & Carousel Comprehensive Test Suite', () {
    // 1. Select one image
    testWidgets('1. Select one image in gallery session', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      galleryKey.currentState!.togglePathForTesting('/storage/emulated/0/DCIM/photo1.jpg', isVideo: false);
      await tester.pumpAndSettle();

      expect(find.text('Add (1)'), findsWidgets);
      expect(find.text('1 photo'), findsOneWidget);
    });

    // 2. Select multiple images in one gallery session
    testWidgets('2. Select multiple images in one gallery session', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      galleryKey.currentState!.togglePathForTesting('/path/photo1.jpg', isVideo: false);
      galleryKey.currentState!.togglePathForTesting('/path/photo2.jpg', isVideo: false);
      galleryKey.currentState!.togglePathForTesting('/path/photo3.jpg', isVideo: false);
      await tester.pumpAndSettle();

      expect(find.text('Add (3)'), findsWidgets);
      expect(find.text('3 photos'), findsOneWidget);
    });

    // 3. Select one video
    testWidgets('3. Select one video in gallery session', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      galleryKey.currentState!.togglePathForTesting('/path/video1.mp4', isVideo: true);
      await tester.pumpAndSettle();

      expect(find.text('Add (1)'), findsWidgets);
      expect(find.text('1 video'), findsOneWidget);
    });

    // 4. Select image + video if backend supports it
    testWidgets('4. Select image + video together (mixed media)', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      galleryKey.currentState!.togglePathForTesting('/path/photo1.jpg', isVideo: false);
      galleryKey.currentState!.togglePathForTesting('/path/video1.mp4', isVideo: true);
      await tester.pumpAndSettle();

      expect(find.text('Add (2)'), findsWidgets);
      expect(find.text('1 photo, 1 video'), findsOneWidget);
    });

    // 5. Select multiple images + one video if supported
    testWidgets('5. Select multiple images + one video together', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      galleryKey.currentState!.togglePathForTesting('/path/img1.jpg', isVideo: false);
      galleryKey.currentState!.togglePathForTesting('/path/img2.jpg', isVideo: false);
      galleryKey.currentState!.togglePathForTesting('/path/video.mp4', isVideo: true);
      await tester.pumpAndSettle();

      expect(find.text('Add (3)'), findsWidgets);
      expect(find.text('2 photos, 1 video'), findsOneWidget);
    });

    // 6. Add more media without losing existing selection
    testWidgets('6. Add more media without losing existing selection', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
            initialSelectedImages: const ['/path/img1.jpg'],
            initialSelectedVideo: '/path/video.mp4',
            initialMediaOrder: const ['/path/img1.jpg', '/path/video.mp4'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pre-existing selections: 1 image + 1 video = 2
      expect(find.text('Add (2)'), findsWidgets);
      expect(find.text('1 photo, 1 video'), findsOneWidget);

      // Add another image
      galleryKey.currentState!.togglePathForTesting('/path/img2.jpg', isVideo: false);
      await tester.pumpAndSettle();

      // Now 2 images + 1 video = 3
      expect(find.text('Add (3)'), findsWidgets);
      expect(find.text('2 photos, 1 video'), findsOneWidget);
    });

    // 7. Remove one image in Post Composer
    testWidgets('7. Remove one image in Post Composer preserves remaining image and video', (tester) async {
      final screenKey = GlobalKey<CreatePostScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          CreatePostScreen(key: screenKey),
        ),
      );
      await tester.pumpAndSettle();

      // Set 2 images and 1 video
      await screenKey.currentState!.applyGalleryResultForTesting(
        const PostGalleryResult(
          images: ['/path/img1.jpg', '/path/img2.jpg'],
          video: '/path/video.mp4',
          orderedMedia: ['/path/img1.jpg', '/path/img2.jpg', '/path/video.mp4'],
        ),
      );
      await tester.pumpAndSettle();

      expect(screenKey.currentState!.attachedImages, ['/path/img1.jpg', '/path/img2.jpg']);
      expect(screenKey.currentState!.attachedVideo, '/path/video.mp4');

      // Remove img1
      screenKey.currentState!.removeImageForTesting('/path/img1.jpg');
      await tester.pumpAndSettle();

      // Verify img2 and video remain
      expect(screenKey.currentState!.attachedImages, ['/path/img2.jpg']);
      expect(screenKey.currentState!.attachedVideo, '/path/video.mp4');
      expect(screenKey.currentState!.attachedMediaOrder, ['/path/img2.jpg', '/path/video.mp4']);
    });

    // 8. Remove video in Post Composer
    testWidgets('8. Remove video in Post Composer preserves attached images', (tester) async {
      final screenKey = GlobalKey<CreatePostScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          CreatePostScreen(key: screenKey),
        ),
      );
      await tester.pumpAndSettle();

      // Set 2 images and 1 video
      await screenKey.currentState!.applyGalleryResultForTesting(
        const PostGalleryResult(
          images: ['/path/img1.jpg', '/path/img2.jpg'],
          video: '/path/video.mp4',
          orderedMedia: ['/path/img1.jpg', '/path/img2.jpg', '/path/video.mp4'],
        ),
      );
      await tester.pumpAndSettle();

      expect(screenKey.currentState!.attachedVideo, '/path/video.mp4');

      // Clear video
      await screenKey.currentState!.clearVideoForTesting();
      await tester.pumpAndSettle();

      // Verify video is removed but images are strictly preserved
      expect(screenKey.currentState!.attachedVideo, isNull);
      expect(screenKey.currentState!.attachedImages, ['/path/img1.jpg', '/path/img2.jpg']);
      expect(screenKey.currentState!.attachedMediaOrder, ['/path/img1.jpg', '/path/img2.jpg']);
    });

    // 9. Attempt to add second video
    testWidgets('9. Attempt to add second video shows compact validation message and keeps existing video', (tester) async {
      final screenKey = GlobalKey<CreatePostScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          CreatePostScreen(key: screenKey),
        ),
      );
      await tester.pumpAndSettle();

      // Attach first video
      await screenKey.currentState!.handleSelectedMediaPathsForTesting(['/path/first_video.mp4']);
      await tester.pumpAndSettle();

      expect(screenKey.currentState!.attachedVideo, '/path/first_video.mp4');

      // Attempt to attach second video
      await screenKey.currentState!.handleSelectedMediaPathsForTesting(['/path/second_video.mp4']);
      await tester.pumpAndSettle();

      // Verification message shown, NO dialog
      expect(find.text('Only one video can be added to a post.'), findsOneWidget);
      // Existing video strictly kept!
      expect(screenKey.currentState!.attachedVideo, '/path/first_video.mp4');
    });

    // 10. Publish selected media
    testWidgets('10. Publish selected media with mixed images and video', (tester) async {
      final success = await controller.addNewPost(
        content: 'Testing mixed media post publication',
        imageUrls: ['https://cdn.example.com/photo1.jpg', 'https://cdn.example.com/photo2.jpg'],
        videoUrl: 'https://cdn.example.com/sample_video.mp4',
      );

      expect(success, isTrue);
      expect(mockRepo.lastCreatedPost, isNotNull);
      expect(mockRepo.lastImageUrls, ['https://cdn.example.com/photo1.jpg', 'https://cdn.example.com/photo2.jpg']);
      expect(mockRepo.lastVideoUrl, 'https://cdn.example.com/sample_video.mp4');
    });

    // 11. Verify published post contains exactly the selected media
    testWidgets('11. Verify published post contains exactly the selected media', (tester) async {
      const img1 = 'https://cdn.example.com/shot1.jpg';
      const img2 = 'https://cdn.example.com/shot2.jpg';
      const vid = 'https://cdn.example.com/clip.mp4';

      await controller.addNewPost(
        content: 'Check out our 2 photos and 1 video!',
        imageUrls: [img1, img2],
        videoUrl: vid,
      );

      final published = mockRepo.lastCreatedPost!;
      expect(published.content, 'Check out our 2 photos and 1 video!');
      expect(published.imageUrls, hasLength(2));
      expect(published.imageUrls, containsAllInOrder([img1, img2]));
      expect(published.videoUrl, vid);
      expect(published.isVideoPost, isTrue);
      expect(published.postType, 'VIDEO');
    });
  });

  group('Post Composer Carousel UI Rendering', () {
    testWidgets('Carousel renders [IMG 1] [IMG 2] [VIDEO] [+ Add] in horizontal strip', (tester) async {
      final screenKey = GlobalKey<CreatePostScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          CreatePostScreen(key: screenKey),
        ),
      );
      await tester.pumpAndSettle();

      await screenKey.currentState!.applyGalleryResultForTesting(
        const PostGalleryResult(
          images: ['/path/img1.jpg', '/path/img2.jpg'],
          video: '/path/video.mp4',
          orderedMedia: ['/path/img1.jpg', '/path/img2.jpg', '/path/video.mp4'],
        ),
      );
      await tester.pumpAndSettle();

      // Verify carousel is rendered
      expect(find.byKey(const Key('unified_media_carousel')), findsOneWidget);

      // Verify video badge is visible
      expect(find.text('VIDEO'), findsOneWidget);

      // Verify [+ Add] button is visible
      expect(find.byKey(const Key('add_more_media_btn')), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);

      // Verify remove video button is present
      expect(find.byKey(const Key('remove_video_btn')), findsOneWidget);
    });
  });
}
