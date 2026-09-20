import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';

class _MockFeedRepo implements CommunityRepository {
  final List<CommentModel> comments;
  final List<Map<String, dynamic>> addCommentCalls = [];

  _MockFeedRepo({required this.comments});

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    return List<CommentModel>.from(comments);
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    addCommentCalls.add({
      'postId': postId,
      'text': text,
      'parentCommentId': parentCommentId,
    });
    return CommentModel(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: 'usr_me',
      userName: 'Current User',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );
  }

  final List<Map<String, dynamic>> deleteCommentCalls = [];

  @override
  Future<bool> deleteComment(String postId, String commentId) async {
    deleteCommentCalls.add({
      'postId': postId,
      'commentId': commentId,
    });
    comments.removeWhere((c) => c.id == commentId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  final sampleComment = CommentModel(
    id: 'parent_1',
    postId: 'post_1',
    userId: 'user_1',
    userName: 'Sokny Enat',
    userAvatar: '',
    text: 'This is a top-level parent comment.',
    timeAgo: '5m ago',
    likesCount: 2,
    isLiked: false,
    replies: [
      CommentModel(
        id: 'reply_1',
        postId: 'post_1',
        userId: 'user_2',
        userName: 'Bopha Pich',
        userAvatar: '',
        text: 'This is a nested reply.',
        timeAgo: '2m ago',
        likesCount: 1,
        isLiked: true,
        parentCommentId: 'parent_1',
      ),
    ],
  );

  group('Feed Comment/Reply UI Match with Forum Comment UI', () {
    testWidgets('1. Comments render with avatar sizing 15 and reply avatar sizing 12', (tester) async {
      final repo = _MockFeedRepo(comments: [sampleComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top level comment avatar radius is 15
      final parentAvatar = tester.widget<CircleAvatar>(
        find.ancestor(
          of: find.text('S'),
          matching: find.byType(CircleAvatar),
        ),
      );
      expect(parentAvatar.radius, 15);

      // Nested reply avatar radius is 12
      final replyAvatar = tester.widget<CircleAvatar>(
        find.ancestor(
          of: find.text('B'),
          matching: find.byType(CircleAvatar),
        ),
      );
      expect(replyAvatar.radius, 12);
    });

    testWidgets('2. Comment container has AppRadius.md and subtle border', (tester) async {
      final repo = _MockFeedRepo(comments: [sampleComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify comment and reply content
      expect(find.text('This is a top-level parent comment.'), findsOneWidget);
      expect(find.text('This is a nested reply.'), findsOneWidget);

      // Reply button inside comment bubble
      expect(find.byKey(const Key('comment_reply_parent_1')), findsOneWidget);
      expect(find.byKey(const Key('comment_reply_reply_1')), findsOneWidget);
    });

    testWidgets('3. Tapping Reply displays pill reply-to banner with reply icon and bold username', (tester) async {
      final repo = _MockFeedRepo(comments: [sampleComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reply on the parent comment
      await tester.tap(find.byKey(const Key('comment_reply_parent_1')));
      await tester.pumpAndSettle();

      // Reply banner should be visible
      expect(find.byKey(const Key('cancel_reply_button')), findsOneWidget);
      expect(find.textContaining('Sokny Enat'), findsAtLeastNWidgets(2)); // in comment + in banner

      // Input field hint changes to reply hint
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, contains('Sokny Enat'));

      // Tap cancel reply
      await tester.tap(find.byKey(const Key('cancel_reply_button')));
      await tester.pumpAndSettle();

      // Reply banner dismissed
      expect(find.byKey(const Key('cancel_reply_button')), findsNothing);
    });

    testWidgets('4. Send button uses Icons.send_rounded (size 21) and enables only when text entered', (tester) async {
      final repo = _MockFeedRepo(comments: [sampleComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sendIconFinder = find.byIcon(Icons.send_rounded);
      expect(sendIconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(sendIconFinder);
      expect(icon.size, 21);

      // Initially empty: tapping send button should not trigger API call
      await tester.tap(sendIconFinder);
      await tester.pumpAndSettle();
      expect(repo.addCommentCalls, isEmpty);

      // Type text: send button activates
      await tester.enterText(find.byType(TextField), 'My new feedback');
      await tester.pump();

      await tester.tap(sendIconFinder);
      await tester.pumpAndSettle();

      expect(repo.addCommentCalls.length, 1);
      expect(repo.addCommentCalls.first['text'], 'My new feedback');
      expect(repo.addCommentCalls.first['parentCommentId'], isNull);
    });

    testWidgets('5. Replying to a comment passes parentCommentId on submit', (tester) async {
      final repo = _MockFeedRepo(comments: [sampleComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reply on parent
      await tester.tap(find.byKey(const Key('comment_reply_parent_1')));
      await tester.pumpAndSettle();

      // Type reply
      await tester.enterText(find.byType(TextField), 'Great point Sokny!');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(repo.addCommentCalls.length, 1);
      expect(repo.addCommentCalls.first['text'], 'Great point Sokny!');
      expect(repo.addCommentCalls.first['parentCommentId'], 'parent_1');
    });

    testWidgets('6. Own comment options show Delete, confirm dialog deletes comment and calls API', (tester) async {
      final ownComment = CommentModel(
        id: 'parent_own',
        postId: 'post_1',
        userId: 'user_own',
        userName: 'Myself',
        userAvatar: '',
        text: 'This is my own comment.',
        timeAgo: '1m ago',
        isOwner: true,
      );

      final repo = _MockFeedRepo(comments: [ownComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This is my own comment.'), findsOneWidget);

      // Tap more options button on own comment
      final moreBtnFinder = find.byKey(const Key('comment_more_parent_own'));
      expect(moreBtnFinder, findsOneWidget);
      await tester.tap(moreBtnFinder);
      await tester.pumpAndSettle();

      // Delete option is displayed for owner
      final deleteOption = find.byKey(const Key('comment_option_delete'));
      expect(deleteOption, findsOneWidget);
      expect(find.byKey(const Key('comment_option_report')), findsNothing);

      // Tap delete option to open confirmation dialog
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap the confirm delete button (ElevatedButton)
      final confirmDeleteBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(ElevatedButton),
      );
      expect(confirmDeleteBtn, findsOneWidget);
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // API was called with correct postId and commentId
      expect(repo.deleteCommentCalls.length, 1);
      expect(repo.deleteCommentCalls.first['postId'], 'post_1');
      expect(repo.deleteCommentCalls.first['commentId'], 'parent_own');

      // Comment is removed from the list immediately
      expect(find.text('This is my own comment.'), findsNothing);
    });

    testWidgets('7. Other user comment options show Report instead of Delete', (tester) async {
      final otherComment = CommentModel(
        id: 'parent_other',
        postId: 'post_1',
        userId: 'user_other',
        userName: 'Other User',
        userAvatar: '',
        text: 'This is someone elses comment.',
        timeAgo: '10m ago',
        isOwner: false,
      );

      final repo = _MockFeedRepo(comments: [otherComment]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap more options on other comment
      final moreBtnFinder = find.byKey(const Key('comment_more_parent_other'));
      expect(moreBtnFinder, findsOneWidget);
      await tester.tap(moreBtnFinder);
      await tester.pumpAndSettle();

      // Report option should be present, Delete option must NOT be present
      expect(find.byKey(const Key('comment_option_report')), findsOneWidget);
      expect(find.byKey(const Key('comment_option_delete')), findsNothing);
    });

    testWidgets('8. Own nested reply options show Delete and confirms deletion', (tester) async {
      final parentWithOwnReply = CommentModel(
        id: 'parent_2',
        postId: 'post_1',
        userId: 'user_other',
        userName: 'Other User',
        userAvatar: '',
        text: 'Parent comment',
        timeAgo: '10m ago',
        isOwner: false,
        replies: [
          CommentModel(
            id: 'reply_own',
            postId: 'post_1',
            userId: 'user_own',
            userName: 'Myself',
            userAvatar: '',
            text: 'My reply to you',
            timeAgo: '1m ago',
            isOwner: true,
            parentCommentId: 'parent_2',
          ),
        ],
      );

      final repo = _MockFeedRepo(comments: [parentWithOwnReply]);
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CommentsBottomSheet(postId: 'post_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My reply to you'), findsOneWidget);

      // Tap more options on own reply
      final moreReplyBtn = find.byKey(const Key('comment_more_reply_own'));
      expect(moreReplyBtn, findsOneWidget);
      await tester.tap(moreReplyBtn);
      await tester.pumpAndSettle();

      // Delete option is present
      final deleteOption = find.byKey(const Key('comment_option_delete'));
      expect(deleteOption, findsOneWidget);

      // Tap delete and confirm
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(ElevatedButton),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(repo.deleteCommentCalls.length, 1);
      expect(repo.deleteCommentCalls.first['commentId'], 'reply_own');
      expect(find.text('My reply to you'), findsNothing);
    });
  });
}
