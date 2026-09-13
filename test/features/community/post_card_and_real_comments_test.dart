import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/data/datasources/demo_community_data_provider.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/media/presentation/media_picker.dart';

class _MockCommunityRepository implements CommunityRepository {
  List<CommentModel> stubComments = [];
  int addCommentCallCount = 0;
  String? lastAddedText;
  String? lastParentCommentId;

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    return List<CommentModel>.from(stubComments);
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    addCommentCallCount++;
    lastAddedText = text;
    lastParentCommentId = parentCommentId;
    final newComment = CommentModel(
      id: 'server_comment_999',
      postId: postId,
      userId: 'user_current',
      userName: 'Current Tester',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );
    return newComment;
  }

  int createPostCallCount = 0;

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    createPostCallCount++;
    return _createPost(content: content, imageUrls: imageUrls, videoUrl: videoUrl);
  }

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CommunityPostModel _createPost({
  String id = 'post_1',
  String content = 'Test post content',
  String? videoUrl,
  List<String> imageUrls = const [],
  int commentsCount = 0,
}) {
  return CommunityPostModel(
    id: id,
    userId: 'user_1',
    authorName: 'Sokny Enat',
    authorTag: 'soknyenat',
    authorAvatar: '',
    timeAgo: '5m ago',
    content: content,
    imageUrls: imageUrls,
    videoUrl: videoUrl,
    commentsCount: commentsCount,
    visibility: 'Public',
    community: 'All GenLink',
  );
}

void main() {
  late _MockCommunityRepository mockRepo;
  late CommunityController controller;

  setUp(() {
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');

    mockRepo = _MockCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestWidget({
    required Widget child,
    Locale locale = const Locale('en', 'US'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    Get.locale = locale;
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(body: child),
    );
  }

  group('STEP 4: PART A — POST CARD / VIDEO PREPARATION', () {
    testWidgets('Text post: isVideoPost is false, no VideoPostMedia rendered', (tester) async {
      final post = _createPost(content: 'Just text content', videoUrl: null);
      expect(post.isVideoPost, isFalse);

      await tester.pumpWidget(
        createTestWidget(
          child: PostCardWidget(post: post, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VideoPostMedia), findsNothing);
      expect(find.text('Just text content'), findsOneWidget);
    });

    testWidgets('Image post: isVideoPost is false, no VideoPostMedia rendered', (tester) async {
      final post = _createPost(
        content: 'Photo update',
        imageUrls: ['https://example.com/photo.png'],
        videoUrl: null,
      );
      expect(post.isVideoPost, isFalse);

      await tester.pumpWidget(
        createTestWidget(
          child: PostCardWidget(post: post, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VideoPostMedia), findsNothing);
    });

    test('VideoPostModel: isVideoPost is true ONLY when videoUrl is non-null and non-empty', () {
      final nullVideo = _createPost(videoUrl: null);
      expect(nullVideo.isVideoPost, isFalse);

      final emptyVideo = _createPost(videoUrl: '');
      expect(emptyVideo.isVideoPost, isFalse);

      final validVideo = _createPost(videoUrl: 'https://cdn.genlink.kh/video1.mp4');
      expect(validVideo.isVideoPost, isTrue);
      expect(validVideo.videoUrl, equals('https://cdn.genlink.kh/video1.mp4'));
    });

    testWidgets('1. Video can be selected from Create Post', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final mediaBtn = find.byTooltip('Media / Image');
      expect(mediaBtn, findsOneWidget);
      await tester.tap(mediaBtn);
      await tester.pumpAndSettle();

      expect(find.text('Select Video'), findsOneWidget);
      expect(find.text('Choose a video from your gallery'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsWidgets);
    });

    testWidgets('2. Video preview appears when video is attached', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedVideoForTesting('/data/user/0/com.genlink.kh/cache/sample_video.mp4');
      state.setVideoInitializedForTesting(true);
      await tester.pumpAndSettle();

      expect(find.text('Video ready to post'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsWidgets);
    });

    testWidgets('3. Video can be removed cleanly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedVideoForTesting('/data/user/0/com.genlink.kh/cache/sample_video.mp4');
      state.setVideoInitializedForTesting(true);
      await tester.pumpAndSettle();
      expect(find.text('Video ready to post'), findsOneWidget);

      final removeIconFinder = find.byIcon(Icons.close);
      await tester.ensureVisible(removeIconFinder);
      await tester.tap(removeIconFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Video ready to post'), findsNothing);
      expect(state.attachedVideo, isNull);
    });

    testWidgets('4. Image + video combination is prevented (mutual exclusivity)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedImagesForTesting(['image1.jpg', 'image2.jpg']);
      await tester.pumpAndSettle();
      expect(state.attachedImages.length, equals(2));

      // Trigger video pick via media sheet while images are attached
      await tester.tap(find.byTooltip('Media / Image'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select Video'));
      await tester.pumpAndSettle();

      // Expect conflict dialog
      expect(find.text('Replace photos with video?'), findsOneWidget);
      expect(find.text('Selecting a video will remove your selected photos. Continue?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Cancel keeps existing images
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(state.attachedImages.length, equals(2));
      expect(state.attachedVideo, isNull);
    });

    testWidgets('5. Existing image-only post flow still works', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedImagesForTesting(['https://example.com/sample.jpg']);
      await tester.pumpAndSettle();

      expect(find.text('Video ready to post'), findsNothing);
      expect(state.attachedImages.length, equals(1));
      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('6. Video preview failure is handled gracefully', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedVideoForTesting('/corrupt/video.mp4');
      state.setVideoInitErrorForTesting(true);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Unable to play video'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('MediaPicker: PickedMedia holds bytes, contentType, and path', () {
      final picked = PickedMedia(
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'video/mp4',
        path: '/data/user/sample.mp4',
      );
      expect(picked.path, equals('/data/user/sample.mp4'));
      expect(picked.contentType, equals('video/mp4'));
      expect(picked.bytes.length, equals(3));
    });

    testWidgets('7. Video post submission connects to backend in Step 4B', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedVideoForTesting('https://cdn.genlink.kh/test_video.mp4');
      state.setVideoInitializedForTesting(true);
      await tester.pumpAndSettle();

      final postButton = find.text('Post');
      expect(postButton, findsOneWidget);
      await tester.tap(postButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(mockRepo.createPostCallCount, equals(1));
    });

    testWidgets('8. Camera photo selection triggers conflict dialog if video is attached', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedVideoForTesting('/test/video.mp4');
      state.setVideoInitializedForTesting(true);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Media / Image'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Replace video with photos?'), findsOneWidget);
      expect(find.text('Selecting photos will remove your selected video. Continue?'), findsOneWidget);

      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(state.attachedVideo, equals('/test/video.mp4'));
      expect(state.attachedImages, isEmpty);
    });

    testWidgets('9. GIF selection triggers conflict dialog if video is attached', (tester) async {
      await tester.pumpWidget(
        createTestWidget(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      final state = tester.state<CreatePostScreenState>(find.byType(CreatePostScreen));
      state.setAttachedVideoForTesting('/test/video.mp4');
      state.setVideoInitializedForTesting(true);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('GIF'));
      await tester.pumpAndSettle();

      expect(find.text('Replace video with photos?'), findsOneWidget);
      expect(find.text('Selecting photos will remove your selected video. Continue?'), findsOneWidget);

      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(state.attachedVideo, equals('/test/video.mp4'));
      expect(state.attachedImages, isEmpty);
    });
  });

  group('STEP 4: PART B — REMOVE AUTOMATIC / MOCK COMMENTS & REAL BACKEND ONLY', () {
    test('DemoCommunityDataProvider posts all have commentsCount == 0 (no manufactured counts)', () {
      final demoPosts = DemoCommunityDataProvider.getDay15DemoPosts();
      for (final post in demoPosts) {
        expect(
          post.commentsCount,
          equals(0),
          reason: 'Post ${post.id} should have zero manufactured comments',
        );
      }
    });

    testWidgets('Empty comment list: Displays localized "No comments yet" and "Be the first to comment" (English)', (tester) async {
      mockRepo.stubComments = [];

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_test_empty'),
          locale: const Locale('en', 'US'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.textContaining('Be the first to comment'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(controller.activeComments.isEmpty, isTrue);
    });

    testWidgets('Empty comment list: Displays localized Khmer empty state (Khmer)', (tester) async {
      mockRepo.stubComments = [];

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_test_khmer'),
          locale: const Locale('km', 'KH'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('មិនទាន់មានមតិយោបល់ទេ'), findsOneWidget);
      expect(find.textContaining('សូមធ្វើជាអ្នកដំបូងដែលបញ្ចេញមតិ'), findsOneWidget);
      expect(controller.activeComments.isEmpty, isTrue);
    });

    testWidgets('Empty comment list: Respects Dark Mode', (tester) async {
      mockRepo.stubComments = [];

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_test_dark'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.textContaining('Be the first to comment'), findsOneWidget);
    });

    testWidgets('Real backend comments: Rendered accurately when returned from server', (tester) async {
      mockRepo.stubComments = [
        CommentModel(
          id: 'comm_1',
          postId: 'post_1',
          userId: 'user_heng',
          userName: 'Heng Chansela',
          userAvatar: '',
          text: 'Great post about Flutter!',
          timeAgo: '10m ago',
        ),
        CommentModel(
          id: 'comm_2',
          postId: 'post_1',
          userId: 'user_makara',
          userName: 'Ren Makara',
          userAvatar: '',
          text: 'Impressive progress!',
          timeAgo: '5m ago',
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsNothing);
      expect(find.textContaining('Heng Chansela'), findsOneWidget);
      expect(find.text('Great post about Flutter!'), findsOneWidget);
      expect(find.textContaining('Ren Makara'), findsOneWidget);
      expect(find.text('Impressive progress!'), findsOneWidget);
      expect(controller.activeComments.length, equals(2));
    });

    testWidgets('Explicit user submission: Typing and tapping Send adds comment via backend', (tester) async {
      mockRepo.stubComments = [];
      final post = _createPost(id: 'post_target', commentsCount: 0);
      controller.posts.assignAll([post]);

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_target'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
      expect(mockRepo.addCommentCallCount, equals(0));

      // Enter comment text
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Real user comment from input');
      await tester.pump();

      // Tap Send icon
      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verified: Real backend addComment called
      expect(mockRepo.addCommentCallCount, equals(1));
      expect(mockRepo.lastAddedText, equals('Real user comment from input'));
      expect(mockRepo.lastParentCommentId, isNull);

      // UI updated from real response
      expect(controller.activeComments.length, equals(1));
      expect(controller.activeComments.first.text, equals('Real user comment from input'));
      expect(controller.posts.first.commentsCount, equals(1));
      expect(find.text('Real user comment from input'), findsOneWidget);
      expect(find.text('No comments yet'), findsNothing);
    });

    testWidgets('Reply behavior: Tapping reply sets @UserName and forwards parentCommentId on submit', (tester) async {
      mockRepo.stubComments = [
        CommentModel(
          id: 'comm_root',
          postId: 'post_reply_target',
          userId: 'user_heng',
          userName: 'Heng Chansela',
          userAvatar: '',
          text: 'Original message',
          timeAgo: '10m ago',
        ),
      ];
      final post = _createPost(id: 'post_reply_target', commentsCount: 1);
      controller.posts.assignAll([post]);

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_reply_target'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Reply
      final replyButton = find.text('Reply');
      expect(replyButton, findsOneWidget);
      await tester.tap(replyButton);
      await tester.pumpAndSettle();

      // Expect replying banner and text prefilled
      expect(find.text('Replying to Heng Chansela'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('@Heng Chansela '));

      // Type reply text
      await tester.enterText(find.byType(TextField), '@Heng Chansela Absolutely agree!');
      await tester.pump();

      // Send reply
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify backend was called with parentCommentId
      expect(mockRepo.addCommentCallCount, equals(1));
      expect(mockRepo.lastAddedText, equals('@Heng Chansela Absolutely agree!'));
      expect(mockRepo.lastParentCommentId, equals('comm_root'));
      expect(find.text('Replying to Heng Chansela'), findsNothing);
    });

    testWidgets('Reply cancel: Tapping close on replying banner cancels reply state', (tester) async {
      mockRepo.stubComments = [
        CommentModel(
          id: 'comm_root',
          postId: 'post_reply_target',
          userId: 'user_heng',
          userName: 'Heng Chansela',
          userAvatar: '',
          text: 'Original message',
          timeAgo: '10m ago',
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          child: const CommentsBottomSheet(postId: 'post_reply_target'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Reply
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();
      expect(find.text('Replying to Heng Chansela'), findsOneWidget);

      // Tap cancel icon on replying banner
      final cancelIcon = find.byIcon(Icons.close_rounded);
      expect(cancelIcon, findsOneWidget);
      await tester.tap(cancelIcon);
      await tester.pumpAndSettle();

      // Replying banner dismissed and input cleared
      expect(find.text('Replying to Heng Chansela'), findsNothing);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('Opening comments bottom sheet does NOT artificially increment post commentCount', (tester) async {
      mockRepo.stubComments = [];
      final post = _createPost(id: 'post_count_check', commentsCount: 0);
      controller.posts.assignAll([post]);

      await tester.pumpWidget(
        createTestWidget(
          child: PostCardWidget(post: post, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);

      final commentBtn = find.byIcon(Icons.chat_bubble_outline_rounded);
      await tester.tap(commentBtn);
      await tester.pumpAndSettle();

      expect(find.text('No comments yet'), findsOneWidget);
      expect(controller.posts.first.commentsCount, equals(0));
    });
  });
}
