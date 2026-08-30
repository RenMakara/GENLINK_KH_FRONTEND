import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';

class _MockCommunityRepository implements CommunityRepository {
  final Map<String, List<CommentModel>> discussionCommentsStore = {};
  final List<Map<String, dynamic>> recordedAddCommentCalls = [];
  bool shouldFailNextAddComment = false;

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async {
    return List<CommentModel>.from(discussionCommentsStore[discussionId] ?? []);
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

    if (shouldFailNextAddComment) {
      throw Exception('Network error occurred');
    }

    final comment = CommentModel(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: discussionId,
      userId: 'user_tester',
      userName: 'Tester User',
      userAvatar: '',
      text: content,
      timeAgo: 'Just now',
    );

    discussionCommentsStore.putIfAbsent(discussionId, () => []).add(comment);
    return comment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockCommunityRepository mockRepo;
  late CommunityController controller;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    mockRepo = _MockCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('Forum Discussion Comment Send Verification Tests', () {
    testWidgets('TEST 1: Type text and tap Send -> API succeeds, comment appears, input clears, count increments', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_101',
        title: 'How to learn Flutter fast?',
        authorName: '@Rathana',
        category: 'Development',
        content: 'Any tips for junior developers?',
        upvotes: 15,
        repliesCount: 3,
        timeAgo: '1h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state
      expect(find.text('3'), findsOneWidget); // Replies count
      expect(find.text('No comments yet'), findsOneWidget);

      // Type "tesy"
      await tester.enterText(find.byType(TextField), 'tesy');
      await tester.pump();

      // Tap Send
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verified API call
      expect(mockRepo.recordedAddCommentCalls.length, 1);
      expect(mockRepo.recordedAddCommentCalls.first['discussionId'], 'disc_101');
      expect(mockRepo.recordedAddCommentCalls.first['content'], 'tesy');

      // Comment appears in the UI
      expect(find.text('tesy'), findsOneWidget);
      expect(find.text('Tester User'), findsOneWidget);

      // Input is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

      // Replies count updated from 3 to 4
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('TEST 2: Empty input -> Send button disabled and no API call is triggered', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_102',
        title: 'Discussion 102',
        authorName: '@Dev',
        category: 'Design',
        content: 'Content 102',
        upvotes: 2,
        repliesCount: 0,
        timeAgo: '2h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Send while input is empty
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Zero API calls
      expect(mockRepo.recordedAddCommentCalls, isEmpty);
    });

    testWidgets('TEST 3: API failure -> Comment text preserved, no fake comment, count unchanged', (tester) async {
      mockRepo.shouldFailNextAddComment = true;

      final discussion = ForumTopicModel(
        id: 'disc_103',
        title: 'Discussion 103',
        authorName: '@Sokchea',
        category: 'Career',
        content: 'Content 103',
        upvotes: 5,
        repliesCount: 2,
        timeAgo: '3h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // Type comment
      await tester.enterText(find.byType(TextField), 'My important comment');
      await tester.pump();

      // Tap Send
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Text is preserved in the TextField
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'My important comment');

      // No comment displayed in list
      expect(find.text('My important comment'), findsOneWidget); // only in textfield

      // Replies count remains 2
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('TEST 4: Rapid Send taps -> exactly one API call executed', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_104',
        title: 'Discussion 104',
        authorName: '@Alice',
        category: 'General',
        content: 'Content 104',
        upvotes: 10,
        repliesCount: 5,
        timeAgo: '1d ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Rapid tap test');
      await tester.pump();

      // Rapidly tap 3 times
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Exactly 1 comment added
      expect(mockRepo.recordedAddCommentCalls.length, 1);
      expect(find.text('6'), findsOneWidget); // 5 + 1
    });

    testWidgets('TEST 5: Long comment submits correctly with trimmed whitespace', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_105',
        title: 'Discussion 105',
        authorName: '@Bob',
        category: 'Tech',
        content: 'Content 105',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '4h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      const longComment = '   This is a very detailed and thoughtful response discussing the nuances of state management architecture in modern Dart & Flutter applications.   ';
      await tester.enterText(find.byType(TextField), longComment);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedAddCommentCalls.first['content'], longComment.trim());
      expect(find.text(longComment.trim()), findsOneWidget);
    });

    testWidgets('TEST 6: Correct discussion ID is sent, NOT author or current user ID', (tester) async {
      final discussionA = ForumTopicModel(
        id: 'discussion_uuid_9999',
        title: 'Discussion A',
        authorName: '@AuthorA',
        category: 'News',
        content: 'Content A',
        upvotes: 1,
        repliesCount: 0,
        timeAgo: '5m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussionA),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Testing ID routing');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedAddCommentCalls.first['discussionId'], 'discussion_uuid_9999');
    });

    testWidgets('TEST 7: Send icon color is pure WHITE', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_107',
        title: 'Discussion 107',
        authorName: '@Charlie',
        category: 'Design',
        content: 'Content 107',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '1m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // When text entered, icon is Colors.white
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(iconWidget.color, Colors.white);
    });
  });
}
