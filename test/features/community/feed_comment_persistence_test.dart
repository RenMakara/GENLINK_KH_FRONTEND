import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';

void main() {
  group('Feed Comment Persistence & Contract Verification', () {
    test('1. Feed comment request sends "content" and NOT "text"', () async {
      RequestOptions? capturedOptions;

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 201,
          responseBody: {
            'status': 201,
            'message': 'Comment added',
            'data': {
              'commentId': 'comment-uuid-777',
              'author': {
                'userId': 'user-uuid-1',
                'fullName': 'Sokny Enat',
                'username': 'soknyenat',
                'avatarUrl': 'https://example.com/avatar.png',
              },
              'content': 'This is a real feed comment',
              'parentCommentId': null,
              'language': 'EN',
              'likeCount': 0,
              'likedByMe': false,
              'mine': true,
              'createdAt': '2026-09-17T12:00:00Z',
            },
          },
          onFetch: (opts) => capturedOptions = opts,
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final comment = await dataSource.addComment(
        'post-uuid-101',
        'This is a real feed comment',
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, contains('/posts/post-uuid-101/comments'));
      final data = capturedOptions!.data as Map<String, dynamic>;

      // Must send "content" to match backend CommentCreateRequest
      expect(data['content'], 'This is a real feed comment');
      // Must NOT send "text"
      expect(data.containsKey('text'), isFalse);
      // parentCommentId omitted when null
      expect(data.containsKey('parentCommentId'), isFalse);

      // Verify returned comment has real server ID
      expect(comment.id, 'comment-uuid-777');
      expect(comment.text, 'This is a real feed comment');
      expect(comment.userName, 'Sokny Enat');
      expect(comment.postId, 'post-uuid-101');
    });

    test('2. Feed comment request preserves parentCommentId for replies', () async {
      RequestOptions? capturedOptions;

      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 201,
          responseBody: {
            'status': 201,
            'message': 'Comment added',
            'data': {
              'commentId': 'reply-uuid-888',
              'author': {
                'userId': 'user-uuid-2',
                'fullName': 'Heng Chansela',
                'username': 'hengchansela',
                'avatarUrl': '',
              },
              'content': 'Replying to comment',
              'parentCommentId': 'parent-uuid-555',
              'likeCount': 0,
              'likedByMe': false,
              'mine': true,
              'createdAt': '2026-09-17T12:05:00Z',
            },
          },
          onFetch: (opts) => capturedOptions = opts,
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final reply = await dataSource.addComment(
        'post-uuid-101',
        'Replying to comment',
        parentCommentId: 'parent-uuid-555',
      );

      expect(capturedOptions, isNotNull);
      final data = capturedOptions!.data as Map<String, dynamic>;
      expect(data['content'], 'Replying to comment');
      expect(data['parentCommentId'], 'parent-uuid-555');
      expect(reply.id, 'reply-uuid-888');
      expect(reply.parentCommentId, 'parent-uuid-555');
    });

    test('3. PageResponse comments are correctly parsed from rawData["content"]', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 200,
          responseBody: {
            'status': 200,
            'message': 'Comments retrieved',
            'data': {
              'content': [
                {
                  'commentId': 'c-server-1',
                  'author': {
                    'userId': 'u-1',
                    'fullName': 'Dara Roth',
                    'username': 'dararoth',
                    'avatarUrl': '',
                  },
                  'content': 'Persistent server comment 1',
                  'parentCommentId': null,
                  'likeCount': 5,
                  'likedByMe': true,
                  'mine': false,
                  'createdAt': '2026-09-17T10:00:00Z',
                },
                {
                  'commentId': 'c-server-2',
                  'author': {
                    'userId': 'u-2',
                    'fullName': 'Bopha Chea',
                    'username': 'bophachea',
                    'avatarUrl': '',
                  },
                  'content': 'Persistent server comment 2',
                  'parentCommentId': null,
                  'likeCount': 2,
                  'likedByMe': false,
                  'mine': true,
                  'createdAt': '2026-09-17T11:00:00Z',
                },
              ],
              'pageNumber': 0,
              'pageSize': 20,
              'totalElements': 2,
              'totalPages': 1,
              'last': true,
            },
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final comments = await dataSource.fetchComments('post-uuid-101');

      expect(comments.length, 2);
      expect(comments[0].id, 'c-server-1');
      expect(comments[0].text, 'Persistent server comment 1');
      expect(comments[0].userName, 'Dara Roth');
      expect(comments[0].isLiked, isTrue);
      expect(comments[0].likesCount, 5);

      expect(comments[1].id, 'c-server-2');
      expect(comments[1].text, 'Persistent server comment 2');
      expect(comments[1].userName, 'Bopha Chea');
      expect(comments[1].isOwner, isTrue);
    });

    test('4. Empty PageResponse returns [] without injecting fake mock comments', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 200,
          responseBody: {
            'status': 200,
            'message': 'Comments retrieved',
            'data': {
              'content': <dynamic>[],
              'pageNumber': 0,
              'pageSize': 20,
              'totalElements': 0,
              'totalPages': 0,
              'last': true,
            },
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final comments = await dataSource.fetchComments('post-uuid-101');

      // Crucial: Must be empty list, NOT fake mock comments (c_1, c_2)
      expect(comments, isEmpty);
    });

    test('5. API errors are NOT silently converted into fake comments', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _ErrorAdapter(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/community/posts/p1/comments'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/v1/community/posts/p1/comments'),
              statusCode: 400,
              data: {'message': 'content must not be blank'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);

      // Must throw an AppError, NOT swallow and return fake local comment
      expect(
        () => dataSource.addComment('p1', 'hello'),
        throwsA(isA<AppError>()),
      );
    });

    test('6. CommunityController addComment handles error without corrupting state', () async {
      final mockRepo = _MockFailingCommunityRepository();
      final controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);

      controller.posts.assignAll([
        CommunityPostModel(
          id: 'post-1',
          userId: 'u1',
          authorName: 'User',
          authorTag: '@u1',
          authorAvatar: '',
          isVerified: false,
          timeAgo: '1m ago',
          content: 'Test post',
          likesCount: 0,
          commentsCount: 2,
          sharesCount: 0,
          isLiked: false,
          isBookmarked: false,
          isOwner: false,
          community: 'Campus',
        ),
      ]);

      expect(
        () => controller.addComment('post-1', 'Should fail'),
        throwsA(isA<Exception>()),
      );

      // Post commentsCount must not increment on failure
      expect(controller.posts.first.commentsCount, 2);
      // activeComments must not contain fake comment
      expect(controller.activeComments, isEmpty);

      Get.delete<CommunityController>();
    });

    test('7. fetchComments reconstructs nested reply hierarchy from flat backend list with parentCommentId', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockPathRoutingAdapter(
          routeResponses: {
            '/api/v1/community/posts/post-101/comments': {
              'status': 200,
              'message': 'Comments retrieved',
              'data': {
                'content': [
                  {
                    'commentId': 'parent-1',
                    'author': {'userId': 'u-1', 'fullName': 'Parent User', 'username': 'parent', 'avatarUrl': ''},
                    'content': 'Top-level comment',
                    'parentCommentId': null,
                    'likeCount': 0,
                    'likedByMe': false,
                    'mine': false,
                    'createdAt': '2026-09-17T10:00:00Z',
                  },
                  {
                    'commentId': 'reply-1',
                    'author': {'userId': 'u-2', 'fullName': 'Reply User', 'username': 'replier', 'avatarUrl': ''},
                    'content': 'Nested reply to parent-1',
                    'parentCommentId': 'parent-1',
                    'likeCount': 0,
                    'likedByMe': false,
                    'mine': false,
                    'createdAt': '2026-09-17T10:05:00Z',
                  },
                  {
                    'commentId': 'parent-2',
                    'author': {'userId': 'u-3', 'fullName': 'Another User', 'username': 'another', 'avatarUrl': ''},
                    'content': 'Another top comment',
                    'parentCommentId': null,
                    'likeCount': 1,
                    'likedByMe': false,
                    'mine': false,
                    'createdAt': '2026-09-17T10:10:00Z',
                  },
                ],
                'pageNumber': 0,
                'pageSize': 20,
                'totalElements': 3,
                'totalPages': 1,
                'last': true,
              },
            },
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final comments = await dataSource.fetchComments('post-101');

      // Should return 2 top-level comments
      expect(comments.length, 2);
      expect(comments[0].id, 'parent-1');
      expect(comments[0].replies.length, 1);
      expect(comments[0].replies[0].id, 'reply-1');
      expect(comments[0].replies[0].parentCommentId, 'parent-1');
      expect(comments[0].replies[0].text, 'Nested reply to parent-1');

      expect(comments[1].id, 'parent-2');
      expect(comments[1].replies, isEmpty);
    });

    test('8. fetchComments falls back to fetchCommentReplies if parent has replies on separate endpoint', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockPathRoutingAdapter(
          routeResponses: {
            '/api/v1/community/posts/post-101/comments': {
              'status': 200,
              'data': {
                'content': [
                  {
                    'commentId': 'parent-only',
                    'author': {'userId': 'u-1', 'fullName': 'Parent Only', 'username': 'parent', 'avatarUrl': ''},
                    'content': 'Parent comment alone in post comments',
                    'parentCommentId': null,
                    'likeCount': 0,
                    'likedByMe': false,
                    'mine': false,
                    'createdAt': '2026-09-17T10:00:00Z',
                  },
                ],
              },
            },
            '/api/v1/community/comments/parent-only/replies': {
              'status': 200,
              'data': {
                'content': [
                  {
                    'commentId': 'remote-reply-1',
                    'author': {'userId': 'u-2', 'fullName': 'Remote Replier', 'username': 'replier', 'avatarUrl': ''},
                    'content': 'Reply from separate replies endpoint',
                    'parentCommentId': 'parent-only',
                    'likeCount': 0,
                    'likedByMe': false,
                    'mine': false,
                    'createdAt': '2026-09-17T10:05:00Z',
                  },
                ],
              },
            },
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final comments = await dataSource.fetchComments('post-101');

      expect(comments.length, 1);
      expect(comments[0].id, 'parent-only');
      expect(comments[0].replies.length, 1);
      expect(comments[0].replies[0].id, 'remote-reply-1');
      expect(comments[0].replies[0].text, 'Reply from separate replies endpoint');
    });

    test('9. CommunityController addComment attaches reply to parent.replies immediately in activeComments', () async {
      final mockRepo = _MockWorkingCommunityRepository();
      mockRepo.commentsStore['post-101'] = [
        CommentModel(
          id: 'parent-c1',
          postId: 'post-101',
          userId: 'u1',
          userName: 'Parent User',
          userAvatar: '',
          text: 'Root comment',
          timeAgo: '5m ago',
          replies: [],
        ),
      ];

      final controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);

      controller.posts.assignAll([
        CommunityPostModel(
          id: 'post-101',
          userId: 'u1',
          authorName: 'User',
          authorTag: '@u1',
          authorAvatar: '',
          isVerified: false,
          timeAgo: '10m ago',
          content: 'Test post',
          likesCount: 0,
          commentsCount: 1,
          sharesCount: 0,
          isLiked: false,
          isBookmarked: false,
          isOwner: false,
          community: 'Campus',
        ),
      ]);

      await controller.fetchComments('post-101');
      expect(controller.activeComments.length, 1);
      expect(controller.activeComments.first.replies, isEmpty);

      // Add a reply to parent-c1
      final reply = await controller.addComment(
        'post-101',
        'Immediate reply',
        parentCommentId: 'parent-c1',
      );

      expect(reply, isNotNull);
      expect(reply!.parentCommentId, 'parent-c1');
      // activeComments top level count is still 1
      expect(controller.activeComments.length, 1);
      // reply is attached inside parent.replies
      expect(controller.activeComments.first.replies.length, 1);
      expect(controller.activeComments.first.replies.first.text, 'Immediate reply');
      // Post commentsCount incremented
      expect(controller.posts.first.commentsCount, 2);

      // 10. Reply persists across re-fetch / refresh
      await controller.fetchComments('post-101');
      expect(controller.activeComments.length, 1);
      expect(controller.activeComments.first.replies.length, 1);
      expect(controller.activeComments.first.replies.first.text, 'Immediate reply');

      // 11. Delete nested reply
      final replyId = controller.activeComments.first.replies.first.id;
      final deleted = await controller.deleteComment('post-101', replyId);
      expect(deleted, isTrue);
      expect(controller.activeComments.first.replies, isEmpty);
      expect(controller.posts.first.commentsCount, 1);

      Get.delete<CommunityController>();
    });

    test('12. CommunityController toggleCommentLike works on nested reply', () async {
      final mockRepo = _MockWorkingCommunityRepository();
      final replyModel = CommentModel(
        id: 'reply-like-test',
        postId: 'post-101',
        userId: 'u2',
        userName: 'Replier',
        userAvatar: '',
        text: 'Nested reply to like',
        timeAgo: '2m ago',
        parentCommentId: 'parent-101',
        likesCount: 0,
        isLiked: false,
      );
      mockRepo.commentsStore['post-101'] = [
        CommentModel(
          id: 'parent-101',
          postId: 'post-101',
          userId: 'u1',
          userName: 'Parent User',
          userAvatar: '',
          text: 'Root comment',
          timeAgo: '5m ago',
          replies: [replyModel],
        ),
      ];

      final controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);

      await controller.fetchComments('post-101');
      expect(controller.activeComments.first.replies.first.isLiked, isFalse);
      expect(controller.activeComments.first.replies.first.likesCount, 0);

      controller.toggleCommentLike('post-101', 'reply-like-test');
      expect(controller.activeComments.first.replies.first.isLiked, isTrue);
      expect(controller.activeComments.first.replies.first.likesCount, 1);

      controller.toggleCommentLike('post-101', 'reply-like-test');
      expect(controller.activeComments.first.replies.first.isLiked, isFalse);
      expect(controller.activeComments.first.replies.first.likesCount, 0);

      Get.delete<CommunityController>();
    });
  });

  group('CommentsBottomSheet Widget Integration', () {
    late _MockWorkingCommunityRepository mockRepo;
    late CommunityController controller;

    setUp(() {
      Get.testMode = true;
      Get.reset();
      mockRepo = _MockWorkingCommunityRepository();
      controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Displays real server comments and allows sending new comment', (tester) async {
      mockRepo.commentsStore['post-abc'] = [
        CommentModel(
          id: 'server-comment-1',
          postId: 'post-abc',
          userId: 'u1',
          userName: 'Alice',
          userAvatar: '',
          text: 'Existing server comment',
          timeAgo: '10m ago',
        ),
      ];

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post-abc'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Existing server comment'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);

      // Enter new comment
      await tester.enterText(find.byType(TextField), 'Newly added comment');
      await tester.pump();

      // Tap send
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Input should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Both comments should be visible in UI
      expect(find.text('Newly added comment'), findsOneWidget);
      expect(find.text('Existing server comment'), findsOneWidget);
    });

    testWidgets('Preserves input text on submission error', (tester) async {
      mockRepo.shouldFailNext = true;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post-abc'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Unsaved comment text');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Text must NOT be cleared when request fails
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Unsaved comment text');
    });

    testWidgets('Reply flow: tapping reply shows replying banner and posts reply nested under parent', (tester) async {
      mockRepo.commentsStore['post-abc'] = [
        CommentModel(
          id: 'parent-alice',
          postId: 'post-abc',
          userId: 'u1',
          userName: 'Alice',
          userAvatar: '',
          text: 'Alice root comment',
          timeAgo: '10m ago',
          replies: [],
        ),
      ];

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post-abc'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice root comment'), findsOneWidget);

      // Tap reply button on Alice's comment
      final replyBtn = find.byKey(const Key('comment_reply_parent-alice'));
      expect(replyBtn, findsOneWidget);
      await tester.tap(replyBtn);
      await tester.pumpAndSettle();

      // "Replying to Alice" banner should be visible
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byKey(const Key('cancel_reply_button')), findsOneWidget);

      // Enter reply text
      await tester.enterText(find.byType(TextField), 'I agree with Alice');
      await tester.pump();

      // Tap send
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Replying banner should dismiss
      expect(find.byKey(const Key('cancel_reply_button')), findsNothing);

      // Reply should be visible under Alice
      expect(find.text('I agree with Alice'), findsOneWidget);

      // Persistence test: rebuild / reopen bottom sheet
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post-abc'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both Alice's comment and reply must persist!
      expect(find.text('Alice root comment'), findsOneWidget);
      expect(find.text('I agree with Alice'), findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers & Mocks
// ─────────────────────────────────────────────────────────────────────────────

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter({
    required this.statusCode,
    required this.responseBody,
    this.onFetch,
  });

  final int statusCode;
  final dynamic responseBody;
  final void Function(RequestOptions)? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch?.call(options);
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ErrorAdapter implements HttpClientAdapter {
  _ErrorAdapter(this.error);

  final DioException error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw error;
  }

  @override
  void close({bool force = false}) {}
}

class _MockPathRoutingAdapter implements HttpClientAdapter {
  _MockPathRoutingAdapter({
    required this.routeResponses,
  });

  final Map<String, dynamic> routeResponses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in routeResponses.entries) {
      if (options.path.contains(entry.key) || entry.key.contains(options.path)) {
        return ResponseBody.fromString(
          jsonEncode(entry.value),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
    }
    return ResponseBody.fromString(
      jsonEncode({'status': 404, 'message': 'Not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockFailingCommunityRepository implements CommunityRepository {
  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    throw Exception('Server rejected comment');
  }

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockWorkingCommunityRepository implements CommunityRepository {
  final Map<String, List<CommentModel>> commentsStore = {};
  bool shouldFailNext = false;

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    return List<CommentModel>.from(commentsStore[postId] ?? []);
  }

  @override
  Future<List<CommentModel>> getCommentReplies(String commentId) async {
    for (final list in commentsStore.values) {
      for (final comment in list) {
        if (comment.id == commentId) {
          return comment.replies;
        }
      }
    }
    return [];
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async {
    final list = commentsStore[postId];
    if (list != null) {
      list.removeWhere((c) => c.id == commentId);
      for (int i = 0; i < list.length; i++) {
        final p = list[i];
        list[i] = p.copyWith(
          replies: p.replies.where((r) => r.id != commentId).toList(),
        );
      }
    }
    return true;
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    if (shouldFailNext) {
      throw const AppError(message: 'Server error', errorCode: 'COMMENT_FAIL');
    }

    final comment = CommentModel(
      id: 'comment_${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      userId: 'user_tester',
      userName: 'Tester User',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );

    if (parentCommentId != null && parentCommentId.isNotEmpty) {
      final list = commentsStore[postId] ?? [];
      final parentIdx = list.indexWhere((c) => c.id == parentCommentId);
      if (parentIdx != -1) {
        final parent = list[parentIdx];
        list[parentIdx] = parent.copyWith(
          replies: [...parent.replies, comment],
        );
      } else {
        list.add(comment);
      }
      commentsStore[postId] = list;
    } else {
      commentsStore.putIfAbsent(postId, () => []).add(comment);
    }
    return comment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
