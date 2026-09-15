import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/network/api_endpoints.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class _FakeCommunityRepository implements CommunityRepository {
  final Map<String, List<CommentModel>> postComments = {};
  final List<CommunityPostModel> serverPosts = [];
  int addCommentCallCount = 0;
  String? lastAddedText;
  String? lastParentCommentId;

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    return List.from(postComments[postId] ?? []);
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

    final comment = CommentModel(
      id: 'server_comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: 'user_tester',
      authorId: 'user_tester',
      userName: 'Tester User',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );

    final currentList = postComments[postId] ?? [];
    if (parentCommentId != null && parentCommentId.isNotEmpty) {
      final parentIdx = currentList.indexWhere((c) => c.id == parentCommentId);
      if (parentIdx != -1) {
        final parent = currentList[parentIdx];
        final updatedReplies = List<CommentModel>.from(parent.replies)..add(comment);
        currentList[parentIdx] = parent.copyWith(replies: updatedReplies);
      } else {
        currentList.add(comment);
      }
    } else {
      currentList.add(comment);
    }
    postComments[postId] = currentList;
    return comment;
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async {
    final list = postComments[postId] ?? [];
    final topIdx = list.indexWhere((c) => c.id == commentId);
    if (topIdx != -1) {
      list.removeAt(topIdx);
      postComments[postId] = list;
      return true;
    }
    for (int i = 0; i < list.length; i++) {
      final parent = list[i];
      if (parent.replies.any((r) => r.id == commentId)) {
        final updatedReplies = List<CommentModel>.from(parent.replies)
          ..removeWhere((r) => r.id == commentId);
        list[i] = parent.copyWith(replies: updatedReplies);
        postComments[postId] = list;
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> toggleCommentLike(
    String commentId, {
    required bool isCurrentlyLiked,
  }) async =>
      true;

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    final post = CommunityPostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_creator',
      authorName: 'Creator',
      authorTag: '@creator',
      authorAvatar: '',
      content: content,
      timeAgo: 'Just now',
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      postType: videoUrl != null && videoUrl.isNotEmpty ? 'VIDEO' : 'TEXT',
      visibility: visibility,
    );
    serverPosts.insert(0, post);
    return post;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 1 Issue 1 — Feed Comment Persistence & Threading', () {
    late _FakeCommunityRepository repo;
    late CommunityController controller;

    setUp(() {
      Get.reset();
      repo = _FakeCommunityRepository();
      controller = Get.put(CommunityController(repository: repo));
    });

    tearDown(() {
      Get.reset();
    });

    test('addComment persists to repository, updates count, and survives reload', () async {
      const postId = 'post_100';
      final initialPost = CommunityPostModel(
        id: postId,
        userId: 'user_owner',
        authorName: 'Owner',
        authorTag: '@owner',
        authorAvatar: '',
        content: 'Original Post',
        timeAgo: '1h ago',
        commentsCount: 0,
      );
      controller.posts.assignAll([initialPost]);

      // 1. Initially empty comments
      await controller.fetchComments(postId);
      expect(controller.activeComments.isEmpty, isTrue);

      // 2. Add top-level comment
      await controller.addComment(postId, 'First persistent comment');
      expect(repo.addCommentCallCount, equals(1));
      expect(repo.lastAddedText, equals('First persistent comment'));
      expect(repo.lastParentCommentId, isNull);
      expect(controller.activeComments.length, equals(1));
      expect(controller.activeComments.first.text, equals('First persistent comment'));
      expect(controller.posts.first.commentsCount, equals(1));

      // 3. Add reply to first comment
      final parentId = controller.activeComments.first.id;
      await controller.addComment(postId, 'First reply to comment', parentCommentId: parentId);
      expect(repo.addCommentCallCount, equals(2));
      expect(repo.lastParentCommentId, equals(parentId));
      expect(controller.activeComments.first.replies.length, equals(1));
      expect(controller.activeComments.first.replies.first.text, equals('First reply to comment'));
      expect(controller.posts.first.commentsCount, equals(2));

      // 4. Reload from backend persistence (simulates refresh/reopen)
      await controller.fetchComments(postId);
      expect(controller.activeComments.length, equals(1));
      expect(controller.activeComments.first.text, equals('First persistent comment'));
      expect(controller.activeComments.first.replies.length, equals(1));
      expect(controller.activeComments.first.replies.first.text, equals('First reply to comment'));
    });

    testWidgets('CommentsBottomSheet renders comments and nested replies properly', (tester) async {
      const postId = 'post_sheet_test';
      final parentComment = CommentModel(
        id: 'c_parent',
        postId: postId,
        userId: 'u_alice',
        userName: 'Alice',
        userAvatar: '',
        text: 'This is the parent comment',
        timeAgo: '5m ago',
        replies: [
          CommentModel(
            id: 'c_reply_1',
            postId: postId,
            userId: 'u_bob',
            userName: 'Bob',
            userAvatar: '',
            text: 'Nested reply text content',
            timeAgo: '2m ago',
            parentCommentId: 'c_parent',
          ),
        ],
      );

      repo.postComments[postId] = [parentComment];
      final post = CommunityPostModel(
        id: postId,
        userId: 'u_author',
        authorName: 'Author',
        authorTag: '@author',
        authorAvatar: '',
        content: 'Post Content',
        timeAgo: '10m ago',
        commentsCount: 2,
      );
      controller.posts.assignAll([post]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: CommentsBottomSheet(postId: postId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify parent comment is visible
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.text('This is the parent comment'), findsOneWidget);

      // Verify nested reply is rendered
      expect(find.textContaining('Bob'), findsOneWidget);
      expect(find.text('Nested reply text content'), findsOneWidget);

      // Verify typing a reply pre-fills username
      final replyButtons = find.text('Reply');
      expect(replyButtons, findsNWidgets(2)); // parent + reply
      await tester.tap(replyButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Replying to Alice'), findsOneWidget);
    });

    test('deleteComment removes comment from activeComments and updates count', () async {
      const postId = 'post_del_test';
      final comment = CommentModel(
        id: 'c_to_delete',
        postId: postId,
        userId: 'u_me',
        userName: 'Me',
        userAvatar: '',
        text: 'To be deleted',
        timeAgo: 'Just now',
      );
      repo.postComments[postId] = [comment];
      controller.posts.assignAll([
        CommunityPostModel(
          id: postId,
          userId: 'u_me',
          authorName: 'Me',
          authorTag: '@me',
          authorAvatar: '',
          content: 'Post',
          timeAgo: '1h ago',
          commentsCount: 1,
        ),
      ]);

      await controller.fetchComments(postId);
      expect(controller.activeComments.length, equals(1));

      final deleted = await controller.deleteComment(postId, 'c_to_delete');
      expect(deleted, isTrue);
      expect(controller.activeComments.isEmpty, isTrue);
      expect(controller.posts.first.commentsCount, equals(0));
    });
  });

  group('Batch 1 Issue 3 — Feed Video Posting & Playback Data Flow', () {
    test('CommunityPostModel serializes and deserializes videoUrl from backend response', () {
      final backendPostJson = {
        'postId': '00000000-0000-0000-0000-000000000123',
        'author': {
          'userId': '00000000-0000-0000-0000-000000000456',
          'fullName': 'Sokny Enat',
          'username': 'soknyenat',
          'avatarUrl': 'https://cdn.example.com/avatar.png',
        },
        'contentText': 'Check out this awesome campus tour video! #campus #tour',
        'imageUrl': null,
        'videoUrl': 'https://cdn.example.com/posts/campus_tour.mp4',
        'postType': 'VIDEO',
        'visibility': 'PUBLIC',
        'likeCount': 15,
        'commentCount': 3,
        'likedByMe': false,
        'savedByMe': false,
        'hashtags': ['#campus', '#tour'],
        'createdAt': '2026-09-15T10:00:00Z',
      };

      final post = CommunityPostModel.fromJson(backendPostJson);

      expect(post.id, equals('00000000-0000-0000-0000-000000000123'));
      expect(post.authorName, equals('Sokny Enat'));
      expect(post.videoUrl, equals('https://cdn.example.com/posts/campus_tour.mp4'));
      expect(post.isVideoPost, isTrue);
      expect(post.postType, equals('VIDEO'));
      expect(post.likesCount, equals(15));
      expect(post.commentsCount, equals(3));
    });

    test('Non-video posts have isVideoPost == false', () {
      final textPostJson = {
        'postId': 'post_text_only',
        'contentText': 'Just a text post',
        'postType': 'TEXT',
        'videoUrl': null,
      };
      final post = CommunityPostModel.fromJson(textPostJson);
      expect(post.isVideoPost, isFalse);
      expect(post.videoUrl, isNull);
    });

    testWidgets('PostCardWidget renders VideoPostMedia when isVideoPost is true', (tester) async {
      Get.reset();
      final repo = _FakeCommunityRepository();
      final controller = Get.put(CommunityController(repository: repo));

      final videoPost = CommunityPostModel(
        id: 'post_video_render',
        userId: 'u_1',
        authorName: 'Video Creator',
        authorTag: '@video',
        authorAvatar: '',
        content: 'Watch this clip!',
        timeAgo: '1m ago',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        postType: 'VIDEO',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: videoPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // VideoPostMedia widget is rendered in widget tree
      expect(find.byType(VideoPostMedia), findsOneWidget);
    });
  });

  group('Batch 1 Backend Contract Check Verification', () {
    test('Backend Comment API endpoints are correctly defined', () {
      expect(
        ApiEndpoints.communityPostComments('123'),
        contains('/community/posts/123/comments'),
      );
      expect(
        ApiEndpoints.communityPostCommentReplies('456'),
        contains('/community/comments/456/replies'),
      );
      expect(
        ApiEndpoints.communityCommentLike('789'),
        contains('/community/comments/789/like'),
      );
      expect(
        ApiEndpoints.communityComment('789'),
        contains('/community/comments/789'),
      );
    });
  });
}
