import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCommunityRepository implements CommunityRepository {
  final Map<String, List<CommentModel>> discussionCommentsStore = {};
  final List<Map<String, dynamic>> recordedAddCommentCalls = [];
  final List<Map<String, dynamic>> recordedUpdateCommentCalls = [];
  final List<String> recordedDeleteCommentCalls = [];
  final List<String> recordedLikeCommentCalls = [];

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async {
    return List<CommentModel>.from(discussionCommentsStore[discussionId] ?? []);
  }

  @override
  Future<List<CommentModel>> getDiscussionCommentReplies(String commentId) async {
    return [];
  }

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    recordedAddCommentCalls.add({
      'discussionId': discussionId,
      'content': content,
      'parentCommentId': parentCommentId,
    });

    final comment = CommentModel(
      id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
      postId: discussionId,
      userId: 'user_auth_123',
      authorId: 'user_auth_123',
      userName: 'Dara Sok',
      userAvatar: '',
      text: content,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
      isOwner: true,
    );

    return comment;
  }

  @override
  Future<bool> toggleDiscussionCommentLike(
    String commentId, {
    required bool isCurrentlyLiked,
  }) async {
    recordedLikeCommentCalls.add(commentId);
    return true;
  }

  @override
  Future<CommentModel> updateDiscussionComment(
    String commentId,
    String content,
  ) async {
    recordedUpdateCommentCalls.add({
      'commentId': commentId,
      'content': content,
    });
    return CommentModel(
      id: commentId,
      postId: 'disc_1',
      userId: 'user_auth_123',
      authorId: 'user_auth_123',
      userName: 'Dara Sok',
      userAvatar: '',
      text: content,
      timeAgo: 'Just now',
      updatedAt: DateTime.now(),
      isOwner: true,
    );
  }

  @override
  Future<bool> deleteDiscussionComment(String commentId) async {
    recordedDeleteCommentCalls.add(commentId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockCommunityRepository mockRepo;
  late CommunityController controller;
  late _FakeAuthController authController;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    mockRepo = _MockCommunityRepository();
    authController = _FakeAuthController();
    authController.currentUser.value = const UserEntity(
      id: 'user_auth_123',
      fullName: 'Dara Sok',
      username: 'darasok',
      email: 'dara@example.com',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 1,
      preferredLanguage: 'en',
      role: 'USER',
      active: true,
    );
    Get.put<AuthController>(authController);
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  final testDiscussion = ForumTopicModel(
    id: 'disc_1',
    title: 'Discussion on Modern Mobile Architecture',
    content: 'Let us discuss scalable Clean Architecture patterns.',
    category: 'Technology',
    authorId: 'author_456',
    authorName: 'Tech Lead',
    authorAvatar: '',
    timeAgo: '2h ago',
    upvotes: 12,
    repliesCount: 2,
    isLiked: false,
  );

  Widget createWidget({Locale locale = const Locale('en', 'US')}) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      home: ForumDiscussionScreen(discussion: testDiscussion),
    );
  }

  testWidgets('1. Reply button exists on comment, tapping sets reply mode and banner', (tester) async {
    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'This is a great point about Clean Architecture!',
      timeAgo: '1h ago',
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Verify parent comment rendered
    expect(find.text('This is a great point about Clean Architecture!'), findsOneWidget);

    // Verify Reply button exists
    final replyBtnFinder = find.byKey(const Key('comment_reply_comment_top_1'));
    expect(replyBtnFinder, findsOneWidget);

    // Initially no "Replying to" banner
    expect(find.byKey(const Key('cancel_reply_button')), findsNothing);

    // Tap Reply button
    await tester.tap(replyBtnFinder);
    await tester.pumpAndSettle();

    // Verify reply banner appears with parent user's name
    expect(find.byKey(const Key('cancel_reply_button')), findsOneWidget);
    expect(find.text('Sophea Chem'), findsWidgets);
    expect(find.textContaining('Replying to'), findsOneWidget);
  });

  testWidgets('2. Cancel button in reply banner dismisses reply mode', (tester) async {
    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'This is a great point about Clean Architecture!',
      timeAgo: '1h ago',
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Enter reply mode
    await tester.tap(find.byKey(const Key('comment_reply_comment_top_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cancel_reply_button')), findsOneWidget);

    // Tap cancel reply
    await tester.tap(find.byKey(const Key('cancel_reply_button')));
    await tester.pumpAndSettle();

    // Banner is dismissed
    expect(find.byKey(const Key('cancel_reply_button')), findsNothing);
  });

  testWidgets('3. Submitting reply sends parentCommentId and attaches beneath parent', (tester) async {
    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Top level question about GetX state',
      timeAgo: '2h ago',
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap reply on the comment
    await tester.tap(find.byKey(const Key('comment_reply_comment_top_1')));
    await tester.pumpAndSettle();

    // Type reply text
    await tester.enterText(find.byType(TextField), 'I recommend using GetX controllers with Obx.');
    await tester.pumpAndSettle();

    // Tap Send
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    // Verify repository received parentCommentId
    expect(mockRepo.recordedAddCommentCalls.length, 1);
    expect(mockRepo.recordedAddCommentCalls.first['parentCommentId'], 'comment_top_1');
    expect(mockRepo.recordedAddCommentCalls.first['content'], 'I recommend using GetX controllers with Obx.');

    // Verify reply banner is dismissed
    expect(find.byKey(const Key('cancel_reply_button')), findsNothing);

    // Verify reply rendered on screen
    expect(find.text('I recommend using GetX controllers with Obx.'), findsOneWidget);
  });

  testWidgets('4. Nested replies render indented with author and text', (tester) async {
    final nestedReply = CommentModel(
      id: 'reply_child_1',
      postId: 'disc_1',
      userId: 'user_nested',
      authorId: 'user_nested',
      userName: 'Chanda Keo',
      userAvatar: '',
      text: 'Thanks for the helpful tip!',
      timeAgo: '30m ago',
      parentCommentId: 'comment_top_1',
      likesCount: 7,
      isLiked: false,
    );

    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Top level question about GetX state',
      timeAgo: '2h ago',
      replies: [nestedReply],
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Both top-level comment and nested reply render
    expect(find.text('Top level question about GetX state'), findsOneWidget);
    expect(find.text('Thanks for the helpful tip!'), findsOneWidget);
    expect(find.text('Chanda Keo'), findsOneWidget);
    expect(find.text('7'), findsOneWidget); // like count on reply
  });

  testWidgets('5. Liking a reply toggles like count and status', (tester) async {
    final nestedReply = CommentModel(
      id: 'reply_child_1',
      postId: 'disc_1',
      userId: 'user_nested',
      authorId: 'user_nested',
      userName: 'Chanda Keo',
      userAvatar: '',
      text: 'Great tip!',
      timeAgo: '30m ago',
      parentCommentId: 'comment_top_1',
      likesCount: 1,
      isLiked: false,
    );

    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Top level question',
      timeAgo: '2h ago',
      replies: [nestedReply],
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap like on the nested reply
    final likeHeart = find.byIcon(Icons.favorite_border_rounded).last;
    await tester.tap(likeHeart);
    await tester.pumpAndSettle();

    // Verify repo called
    expect(mockRepo.recordedLikeCommentCalls.contains('reply_child_1'), isTrue);

    // Verify count increased to 2
    expect(nestedReply.likesCount, 2);
    expect(nestedReply.isLiked, isTrue);
  });

  testWidgets('6. Owner of reply can edit and delete reply', (tester) async {
    final myReply = CommentModel(
      id: 'my_reply_1',
      postId: 'disc_1',
      userId: 'user_auth_123',
      authorId: 'user_auth_123',
      userName: 'Dara Sok',
      userAvatar: '',
      text: 'My reply that I can edit or delete',
      timeAgo: '10m ago',
      parentCommentId: 'comment_top_1',
      isOwner: true,
    );

    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Parent comment',
      timeAgo: '1h ago',
      replies: [myReply],
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Open options for the reply
    final moreBtn = find.byKey(const Key('comment_more_my_reply_1'));
    expect(moreBtn, findsOneWidget);
    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    // Verify Edit and Delete options are available for owner
    expect(find.byKey(const Key('comment_option_edit')), findsOneWidget);
    expect(find.byKey(const Key('comment_option_delete')), findsOneWidget);
  });

  testWidgets('7. Bilingual Khmer mode displays Khmer translations for reply and replying to', (tester) async {
    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Parent comment in Khmer mode',
      timeAgo: '1h ago',
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget(locale: const Locale('km', 'KH')));
    await tester.pumpAndSettle();

    // Verify Khmer 'ឆ្លើយតប' appears on the reply button
    expect(find.text('ឆ្លើយតប'), findsWidgets);

    // Tap reply button
    await tester.tap(find.byKey(const Key('comment_reply_comment_top_1')));
    await tester.pumpAndSettle();

    // Verify Khmer 'កំពុងឆ្លើយតបទៅ' appears in the banner
    expect(find.textContaining('កំពុងឆ្លើយតបទៅ'), findsOneWidget);
  });

  testWidgets('8. Tapping reply on a child reply targets the parent comment', (tester) async {
    final childReply = CommentModel(
      id: 'reply_child_1',
      postId: 'disc_1',
      userId: 'user_nested',
      authorId: 'user_nested',
      userName: 'Chanda Keo',
      userAvatar: '',
      text: 'First nested response',
      timeAgo: '15m ago',
      parentCommentId: 'comment_top_1',
    );

    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Parent comment thread',
      timeAgo: '1h ago',
      replies: [childReply],
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap reply on the CHILD reply
    final childReplyBtn = find.byKey(const Key('comment_reply_reply_child_1'));
    expect(childReplyBtn, findsOneWidget);
    await tester.tap(childReplyBtn);
    await tester.pumpAndSettle();

    // Verify reply banner appears targeting the parent comment's user
    expect(find.byKey(const Key('cancel_reply_button')), findsOneWidget);
    expect(find.text('Sophea Chem'), findsWidgets);

    // Type a response
    await tester.enterText(find.byType(TextField), 'Second nested response attached to thread');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    // Verify parentCommentId is the top-level parent
    expect(mockRepo.recordedAddCommentCalls.length, 1);
    expect(mockRepo.recordedAddCommentCalls.first['parentCommentId'], 'comment_top_1');
  });

  test('9. CommunityRemoteDataSource.fetchComments returns empty list and NEVER returns mock comments', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = _TestMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': 'Comments retrieved',
            'data': <dynamic>[],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

    final dataSource = CommunityRemoteDataSource(dio: dio);
    final comments = await dataSource.fetchComments('post_123');

    // Must be strictly empty, never c_1 or c_2
    expect(comments, isEmpty);
    expect(comments.any((c) => c.id == 'c_1' || c.id == 'c_2'), isFalse);
    expect(comments.any((c) => c.text.contains('Awesome post')), isFalse);
  });

  test('10. CommunityRemoteDataSource.fetchDiscussionComments hydrates nested replies from backend', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = _TestMockAdapter((options) async {
        final path = options.path;
        if (path.contains('/comments/top_1/replies')) {
          return ResponseBody.fromString(
            jsonEncode({
              'success': true,
              'message': 'Replies retrieved',
              'data': {
                'content': [
                  {
                    'id': 'reply_100',
                    'discussionId': 'disc_1',
                    'content': 'Persisted nested reply retrieved from backend',
                    'parentCommentId': 'top_1',
                    'author': {
                      'id': 'user_persisted',
                      'fullName': 'Backend Replier',
                      'username': 'backendreplier',
                    },
                    'likeCount': 3,
                    'likedByMe': true,
                    'mine': false,
                    'createdAt': '2026-09-12T10:00:00Z',
                  }
                ],
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        // Top level comments endpoint
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': 'Comments retrieved',
            'data': {
              'content': [
                {
                  'id': 'top_1',
                  'discussionId': 'disc_1',
                  'content': 'Top level comment from backend',
                  'author': {
                    'id': 'user_top',
                    'fullName': 'Backend Author',
                    'username': 'backendauthor',
                  },
                  'likeCount': 5,
                  'likedByMe': false,
                  'mine': false,
                  'createdAt': '2026-09-12T09:00:00Z',
                }
              ],
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

    final dataSource = CommunityRemoteDataSource(dio: dio);
    final comments = await dataSource.fetchDiscussionComments('disc_1');

    expect(comments.length, 1);
    final topComment = comments.first;
    expect(topComment.id, 'top_1');
    expect(topComment.text, 'Top level comment from backend');
    // Verify nested replies were fetched and populated
    expect(topComment.replies.length, 1);
    final reply = topComment.replies.first;
    expect(reply.id, 'reply_100');
    expect(reply.text, 'Persisted nested reply retrieved from backend');
    expect(reply.userName, 'Backend Replier');
    expect(reply.parentCommentId, 'top_1');
    expect(reply.isLiked, isTrue);
    expect(reply.likesCount, 3);
  });

  testWidgets('11. Deleting a child reply updates controller and UI replies count', (tester) async {
    final myReply = CommentModel(
      id: 'my_reply_1',
      postId: 'disc_1',
      userId: 'user_auth_123',
      authorId: 'user_auth_123',
      userName: 'Dara Sok',
      userAvatar: '',
      text: 'My reply to be deleted',
      timeAgo: '5m ago',
      parentCommentId: 'comment_top_1',
      isOwner: true,
    );

    final parentComment = CommentModel(
      id: 'comment_top_1',
      postId: 'disc_1',
      userId: 'user_other',
      authorId: 'user_other',
      userName: 'Sophea Chem',
      userAvatar: '',
      text: 'Parent comment thread',
      timeAgo: '1h ago',
      replies: [myReply],
    );
    mockRepo.discussionCommentsStore['disc_1'] = [parentComment];

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('My reply to be deleted'), findsOneWidget);

    // Open options menu for the reply
    await tester.tap(find.byKey(const Key('comment_more_my_reply_1')));
    await tester.pumpAndSettle();

    // Tap Delete in options sheet
    await tester.tap(find.byKey(const Key('comment_option_delete')));
    await tester.pumpAndSettle();

    // Confirm Delete dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    // Verify repo received delete call
    expect(mockRepo.recordedDeleteCommentCalls.contains('my_reply_1'), isTrue);

    // Verify reply removed from UI
    expect(find.text('My reply to be deleted'), findsNothing);
  });
}

class _TestMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onHandle;
  _TestMockAdapter(this.onHandle);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onHandle(options);
  }

  @override
  void close({bool force = false}) {}
}
