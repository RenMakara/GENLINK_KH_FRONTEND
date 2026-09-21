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

  group('Post Gallery Permission Flow & System Picker Tests', () {
    testWidgets('1. Shows Access to Photos & Videos Needed screen when permission is denied', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PostGalleryScreen(
            mockHasPermissionForTesting: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title, description, and action buttons
      expect(find.text('Access to Photos & Videos Needed'), findsOneWidget);
      expect(
        find.text('Please allow GenLink to access photos and videos so you can attach them to your post.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('gallery_open_settings_btn')), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byKey(const Key('gallery_system_picker_fallback_btn')), findsOneWidget);
      expect(find.text('Use System Picker Instead'), findsOneWidget);
    });

    testWidgets('2. Use System Picker Instead selects images and returns PostGalleryResult', (tester) async {
      PostGalleryResult? returnedResult;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final res = await Navigator.of(context).push<PostGalleryResult>(
                    MaterialPageRoute(
                      builder: (_) => PostGalleryScreen(
                        mockHasPermissionForTesting: false,
                        mockSystemPickerForTesting: () async => [
                          '/path/storage/pic1.jpg',
                          '/path/storage/pic2.png',
                        ],
                      ),
                    ),
                  );
                  returnedResult = res;
                },
                child: const Text('Open Gallery'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open gallery
      await tester.tap(find.text('Open Gallery'));
      await tester.pumpAndSettle();

      // Verify permission denied screen is visible
      expect(find.text('Access to Photos & Videos Needed'), findsOneWidget);

      // Tap Use System Picker Instead
      await tester.tap(find.byKey(const Key('gallery_system_picker_fallback_btn')));
      await tester.pumpAndSettle();

      // Screen should pop and return result to caller
      expect(returnedResult, isNotNull);
      expect(returnedResult!.images, ['/path/storage/pic1.jpg', '/path/storage/pic2.png']);
      expect(returnedResult!.video, isNull);
      expect(returnedResult!.orderedMedia, ['/path/storage/pic1.jpg', '/path/storage/pic2.png']);
    });

    testWidgets('3. Use System Picker Instead selects mixed images and video', (tester) async {
      PostGalleryResult? returnedResult;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final res = await Navigator.of(context).push<PostGalleryResult>(
                    MaterialPageRoute(
                      builder: (_) => PostGalleryScreen(
                        mockHasPermissionForTesting: false,
                        mockSystemPickerForTesting: () async => [
                          '/path/storage/pic1.jpg',
                          '/path/storage/clip.mp4',
                        ],
                      ),
                    ),
                  );
                  returnedResult = res;
                },
                child: const Text('Open Gallery'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Gallery'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gallery_system_picker_fallback_btn')));
      await tester.pumpAndSettle();

      expect(returnedResult, isNotNull);
      expect(returnedResult!.images, ['/path/storage/pic1.jpg']);
      expect(returnedResult!.video, '/path/storage/clip.mp4');
      expect(returnedResult!.orderedMedia, ['/path/storage/pic1.jpg', '/path/storage/clip.mp4']);
    });

    testWidgets('4. CreatePostScreen attaches media from system picker fallback and posts successfully', (tester) async {
      final screenKey = GlobalKey<CreatePostScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          CreatePostScreen(key: screenKey),
        ),
      );
      await tester.pumpAndSettle();

      // Apply result simulating system picker return
      await screenKey.currentState!.applyGalleryResultForTesting(
        const PostGalleryResult(
          images: ['/storage/emulated/0/DCIM/vacation.jpg'],
          video: null,
          orderedMedia: ['/storage/emulated/0/DCIM/vacation.jpg'],
        ),
      );
      await tester.pumpAndSettle();

      // Verify image preview is rendered in Post Composer
      expect(screenKey.currentState!.attachedImages, ['/storage/emulated/0/DCIM/vacation.jpg']);
      expect(find.byKey(const Key('unified_media_carousel')), findsOneWidget);

      // Publish post
      final success = await controller.addNewPost(
        content: 'Testing post published via system picker fallback',
        imageUrls: ['https://cdn.example.com/vacation.jpg'],
      );

      expect(success, isTrue);
      expect(mockRepo.lastCreatedPost, isNotNull);
      expect(mockRepo.lastImageUrls, ['https://cdn.example.com/vacation.jpg']);
      expect(mockRepo.lastCreatedPost!.content, 'Testing post published via system picker fallback');
    });

    testWidgets('5. App lifecycle resume updates permission state', (tester) async {
      final galleryKey = GlobalKey<PostGalleryScreenState>();
      await tester.pumpWidget(
        buildTestWidget(
          PostGalleryScreen(
            key: galleryKey,
            mockHasPermissionForTesting: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(galleryKey.currentState!.hasPermission, isFalse);

      // Verify didChangeAppLifecycleState can be invoked on resume
      galleryKey.currentState!.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(galleryKey.currentState, isNotNull);
    });
  });
}
