import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
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
  bool shouldFailNextAddComment = false;
  bool shouldThrowForbiddenOnUpdate = false;
  bool shouldThrowForbiddenOnDelete = false;

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
      authorId: 'user_tester',
      userName: 'Tester User',
      userAvatar: '',
      text: content,
      timeAgo: 'Just now',
    );

    discussionCommentsStore.putIfAbsent(discussionId, () => []).add(comment);
    return comment;
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

    if (shouldThrowForbiddenOnUpdate) {
      throw const AppError(
        message: 'You do not have permission to modify this comment.',
        errorCode: 'FORBIDDEN',
        statusCode: 403,
      );
    }

    for (final list in discussionCommentsStore.values) {
      final idx = list.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        final existing = list[idx];
        final updated = existing.copyWith(
          text: content,
          updatedAt: DateTime.now().add(const Duration(seconds: 5)),
        );
        list[idx] = updated;
        return updated;
      }
    }

    throw const AppError(
      message: 'Comment not found',
      errorCode: 'NOT_FOUND',
      statusCode: 404,
    );
  }

  @override
  Future<bool> deleteDiscussionComment(String commentId) async {
    recordedDeleteCommentCalls.add(commentId);

    if (shouldThrowForbiddenOnDelete) {
      throw const AppError(
        message: 'You do not have permission to modify this comment.',
        errorCode: 'FORBIDDEN',
        statusCode: 403,
      );
    }

    for (final list in discussionCommentsStore.values) {
      list.removeWhere((c) => c.id == commentId);
    }
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

      expect(find.text('3'), findsOneWidget);
      expect(find.text('No comments yet'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tesy');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedAddCommentCalls.length, 1);
      expect(mockRepo.recordedAddCommentCalls.first['discussionId'], 'disc_101');
      expect(mockRepo.recordedAddCommentCalls.first['content'], 'tesy');

      expect(find.text('tesy'), findsOneWidget);
      expect(find.text('Tester User'), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);

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

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

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

      await tester.enterText(find.byType(TextField), 'My important comment');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'My important comment');

      expect(find.text('My important comment'), findsOneWidget);

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

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedAddCommentCalls.length, 1);
      expect(find.text('6'), findsOneWidget);
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

    testWidgets('TEST 7: Light Mode reply composer has black typed text, black send icon, and gray disabled icon', (tester) async {
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
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initially empty: send icon is disabled gray
      final emptyIconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(emptyIconWidget.color, equals(AppColors.lightTextMuted));

      // 2. TextField decoration & style checks
      final initialTextField = tester.widget<TextField>(find.byType(TextField));
      expect(initialTextField.style?.color, equals(AppColors.lightTextPrimary));
      expect(initialTextField.cursorColor, equals(AppColors.lightTextPrimary));
      expect(initialTextField.decoration?.hintStyle?.color, equals(AppColors.lightTextSecondary));

      // 3. User types text -> send icon becomes black
      await tester.enterText(find.byType(TextField), 'Hello everyone');
      await tester.pump();

      final activeIconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(activeIconWidget.color, equals(AppColors.lightTextPrimary));

      // 4. Send reply -> input clears and send icon returns to disabled gray
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final resetIconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(resetIconWidget.color, equals(AppColors.lightTextMuted));
    });

    testWidgets('TEST 8: Dark Mode reply composer has white typed text, white send icon, and gray disabled icon', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_108',
        title: 'Discussion 108',
        authorName: '@Alice',
        category: 'Dev',
        content: 'Content 108',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '1m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initially empty: send icon is disabled gray
      final emptyIconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(emptyIconWidget.color, equals(AppColors.darkTextMuted));

      // 2. TextField style & cursor checks
      final initialTextField = tester.widget<TextField>(find.byType(TextField));
      expect(initialTextField.style?.color, equals(AppColors.darkTextPrimary));
      expect(initialTextField.cursorColor, equals(AppColors.darkTextPrimary));
      expect(initialTextField.decoration?.hintStyle?.color, equals(AppColors.darkTextSecondary));

      // 3. User types text -> send icon becomes white
      await tester.enterText(find.byType(TextField), 'Hello everyone');
      await tester.pump();

      final activeIconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(activeIconWidget.color, equals(AppColors.darkTextPrimary));
    });

    testWidgets('TEST 9: Send button has mobile touch target of at least 44x44 and visible icon of 21px', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_109',
        title: 'Discussion 109',
        authorName: '@Bob',
        category: 'Product',
        content: 'Content 109',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '2m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // Check send IconButton exists with 44x44 constraints and 44x44 parent box
      final sendButtonFinder = find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(IconButton),
      );
      final iconButton = tester.widget<IconButton>(sendButtonFinder);
      expect(iconButton.constraints?.minWidth, equals(44.0));
      expect(iconButton.constraints?.minHeight, equals(44.0));

      final sizedBoxFinder = find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(SizedBox),
      );
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder.first);
      expect(sizedBox.width, equals(44.0));
      expect(sizedBox.height, equals(44.0));

      // Check visible icon size is 21px
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(iconWidget.size, equals(21.0));
    });

    testWidgets('TEST 10: Khmer localization renders localized placeholder and preserves user input verbatim', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_110',
        title: 'Discussion 110',
        authorName: '@Dara',
        category: 'Technology',
        content: 'Content 110',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '5m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // Check localized placeholder
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, equals('បន្ថែមការឆ្លើយតប...'));

      // Enter Khmer user content
      const khmerInput = 'សួស្តីអ្នកទាំងអស់គ្នា';
      await tester.enterText(find.byType(TextField), khmerInput);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify user content was preserved exactly without translation
      expect(mockRepo.recordedAddCommentCalls.last['content'], equals(khmerInput));
      expect(find.text(khmerInput), findsOneWidget);
    });

    testWidgets('TEST 11: Keyboard inset behavior adapts bottom padding cleanly', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_111',
        title: 'Discussion 111',
        authorName: '@Sophea',
        category: 'General',
        content: 'Content 111',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '10m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
            child: ForumDiscussionScreen(discussion: discussion),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    test('TEST 12: Ownership Verification - Stable ID match determines ownership, never username or avatar', () {
      final myComment = CommentModel(
        id: 'c_own',
        postId: 'd1',
        userId: 'user_auth_123',
        authorId: 'user_auth_123',
        userName: 'Different Display Name',
        userAvatar: 'https://example.com/other.png',
        text: 'My comment',
        timeAgo: '1m ago',
      );

      final otherComment = CommentModel(
        id: 'c_other',
        postId: 'd1',
        userId: 'user_other_456',
        authorId: 'user_other_456',
        userName: 'Dara Sok',
        userAvatar: 'https://example.com/avatar.png',
        text: 'Someone else comment',
        timeAgo: '2m ago',
      );

      expect(myComment.checkIsOwner('user_auth_123'), isTrue);
      expect(otherComment.checkIsOwner('user_auth_123'), isFalse);
    });

    testWidgets('TEST 13: Owner comment shows More (⋯) button opening Edit and Delete options (NO Report)', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_own_menu',
        title: 'Discussion 112',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 112',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_own_menu'] = [
        CommentModel(
          id: 'c_mine',
          postId: 'disc_own_menu',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'My own comment here',
          timeAgo: '2m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My own comment here'), findsOneWidget);
      final moreBtn = find.byKey(const Key('comment_more_c_mine'));
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('comment_option_edit')), findsOneWidget);
      expect(find.byKey(const Key('comment_option_delete')), findsOneWidget);
      expect(find.byKey(const Key('comment_option_report')), findsNothing);
    });

    testWidgets('TEST 14: Non-owner comment shows More (⋯) button opening Report option (NO Edit, NO Delete)', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_other_menu',
        title: 'Discussion 113',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 113',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_other_menu'] = [
        CommentModel(
          id: 'c_other',
          postId: 'disc_other_menu',
          userId: 'user_other_999',
          authorId: 'user_other_999',
          userName: 'Other Person',
          userAvatar: '',
          text: 'Comment from someone else',
          timeAgo: '3m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Comment from someone else'), findsOneWidget);
      final moreBtn = find.byKey(const Key('comment_more_c_other'));
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('comment_option_report')), findsOneWidget);
      expect(find.byKey(const Key('comment_option_edit')), findsNothing);
      expect(find.byKey(const Key('comment_option_delete')), findsNothing);
    });

    testWidgets('TEST 15: Edit UI pre-fills existing text in edit dialog', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_edit_prefill',
        title: 'Discussion 114',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 114',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_edit_prefill'] = [
        CommentModel(
          id: 'c_edit_1',
          postId: 'disc_edit_prefill',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Original initial comment text',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_edit_1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Comment'), findsOneWidget);
      expect(find.text('Original initial comment text'), findsNWidgets(2));
    });

    testWidgets('TEST 16: Edit validation - Empty text displays required warning and prevents API call', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_edit_val',
        title: 'Discussion 115',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 115',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_edit_val'] = [
        CommentModel(
          id: 'c_edit_val',
          postId: 'disc_edit_val',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Text before clear',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_edit_val')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      final editField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(editField, '   ');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('This field is required'), findsOneWidget);
      expect(mockRepo.recordedUpdateCommentCalls, isEmpty);
    });

    testWidgets('TEST 17: Edit save success - calls update API, updates comment immediately, closes dialog, shows success banner', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_edit_success',
        title: 'Discussion 116',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 116',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_edit_success'] = [
        CommentModel(
          id: 'c_edit_ok',
          postId: 'disc_edit_success',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Old comment text',
          timeAgo: '1m ago',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_edit_ok')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      final editField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(editField, 'Newly modified comment text');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedUpdateCommentCalls.length, 1);
      expect(mockRepo.recordedUpdateCommentCalls.first['commentId'], 'c_edit_ok');
      expect(mockRepo.recordedUpdateCommentCalls.first['content'], 'Newly modified comment text');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Newly modified comment text'), findsOneWidget);
      expect(find.text('Comment updated'), findsOneWidget);
    });

    testWidgets('TEST 18: Edited indicator - displays · Edited next to timestamp when comment is edited', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_edited_flag',
        title: 'Discussion 117',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 117',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      final now = DateTime.now();
      mockRepo.discussionCommentsStore['disc_edited_flag'] = [
        CommentModel(
          id: 'c_edited_item',
          postId: 'disc_edited_flag',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'This comment has been edited',
          timeAgo: '10m ago',
          createdAt: now.subtract(const Duration(hours: 1)),
          updatedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This comment has been edited'), findsOneWidget);
      expect(find.text(' · Edited'), findsOneWidget);
    });

    testWidgets('TEST 19: Edit 403 Forbidden rejection - shows permission error banner and keeps dialog open', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_edit_403',
        title: 'Discussion 118',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 118',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_edit_403'] = [
        CommentModel(
          id: 'c_edit_403',
          postId: 'disc_edit_403',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Will fail on save',
          timeAgo: '1m ago',
        ),
      ];
      mockRepo.shouldThrowForbiddenOnUpdate = true;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_edit_403')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      final editField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await tester.enterText(editField, 'Attempted edit text');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('You do not have permission to modify this comment.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Attempted edit text'), findsOneWidget);
    });

    testWidgets('TEST 20: Delete confirmation dialog displays warning message with Cancel and Delete buttons', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_del_dialog',
        title: 'Discussion 119',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 119',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_del_dialog'] = [
        CommentModel(
          id: 'c_del_dlg',
          postId: 'disc_del_dialog',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Comment to verify delete dialog',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_del_dlg')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Comment?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this comment? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('TEST 21: Delete cancel dismisses dialog without deleting comment', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_del_cancel',
        title: 'Discussion 120',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 120',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_del_cancel'] = [
        CommentModel(
          id: 'c_del_canc',
          postId: 'disc_del_cancel',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Will cancel delete',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_del_canc')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Will cancel delete'), findsOneWidget);
      expect(mockRepo.recordedDeleteCommentCalls, isEmpty);
    });

    testWidgets('TEST 22: Delete confirm success - deletes comment, removes from UI immediately, decrements count', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_del_ok',
        title: 'Discussion 121',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 121',
        upvotes: 0,
        repliesCount: 2,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_del_ok'] = [
        CommentModel(
          id: 'c_del_ok',
          postId: 'disc_del_ok',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Comment will be deleted',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('Comment will be deleted'), findsOneWidget);

      await tester.tap(find.byKey(const Key('comment_more_c_del_ok')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_delete')));
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Delete'),
      );
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(mockRepo.recordedDeleteCommentCalls, contains('c_del_ok'));
      expect(find.text('Comment will be deleted'), findsNothing);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Comment deleted'), findsOneWidget);
    });

    testWidgets('TEST 23: Delete 403 Forbidden rejection - shows permission error banner and retains comment in UI', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_del_403',
        title: 'Discussion 122',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 122',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_del_403'] = [
        CommentModel(
          id: 'c_del_forbidden',
          postId: 'disc_del_403',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Comment protected by 403',
          timeAgo: '1m ago',
        ),
      ];
      mockRepo.shouldThrowForbiddenOnDelete = true;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_del_forbidden')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_delete')));
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Delete'),
      );
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('You do not have permission to modify this comment.'), findsOneWidget);
      expect(find.text('Comment protected by 403'), findsOneWidget);
    });

    testWidgets('TEST 24: Report non-owner comment shows report feedback banner', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_report',
        title: 'Discussion 123',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 123',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_report'] = [
        CommentModel(
          id: 'c_report_target',
          postId: 'disc_report',
          userId: 'user_stranger_888',
          authorId: 'user_stranger_888',
          userName: 'Stranger',
          userAvatar: '',
          text: 'Questionable comment text',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_report_target')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_option_report')));
      await tester.pumpAndSettle();

      expect(find.text('Comment reported'), findsOneWidget);
      expect(find.text('Thank you for reporting this comment.'), findsOneWidget);
    });

    testWidgets('TEST 25: Khmer localization - renders Khmer strings and preserves Khmer content verbatim', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_khmer',
        title: 'ពិភាក្សាអំពី Flutter',
        authorName: '@Host',
        category: 'General',
        content: 'ប្រធានបទ',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      const khmerComment = 'នេះជាការបញ្ចេញមតិជាភាសាខ្មែរ';
      final now = DateTime.now();
      mockRepo.discussionCommentsStore['disc_khmer'] = [
        CommentModel(
          id: 'c_khmer',
          postId: 'disc_khmer',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: khmerComment,
          timeAgo: '10m ago',
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(khmerComment), findsOneWidget);
      expect(find.text(' · បានកែប្រែ'), findsOneWidget);

      await tester.tap(find.byKey(const Key('comment_more_c_khmer')));
      await tester.pumpAndSettle();

      expect(find.text('កែសម្រួល'), findsOneWidget);
      expect(find.text('លុប'), findsOneWidget);

      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      expect(find.text('កែប្រែការបញ្ចេញមតិ'), findsOneWidget);
      expect(find.text('បោះបង់'), findsOneWidget);
      expect(find.text('រក្សាទុក'), findsOneWidget);

      await tester.tap(find.text('បោះបង់'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_khmer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_delete')));
      await tester.pumpAndSettle();

      expect(find.text('លុបការបញ្ចេញមតិ?'), findsOneWidget);
      expect(find.text('តើអ្នកប្រាកដថាចង់លុបការបញ្ចេញមតិនេះទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។'), findsOneWidget);
    });

    testWidgets('TEST 26: Light Mode styling tokens - dialogs and sheets respect light theme tokens', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_light_mode',
        title: 'Discussion 125',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 125',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_light_mode'] = [
        CommentModel(
          id: 'c_light',
          postId: 'disc_light_mode',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Light mode comment',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_light')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.backgroundColor, equals(Colors.white));

      final saveButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'));
      expect(saveButton.style?.backgroundColor?.resolve({}), equals(AppColors.lightTextPrimary));
      expect(saveButton.style?.foregroundColor?.resolve({}), equals(Colors.white));
    });

    testWidgets('TEST 27: Dark Mode styling tokens - dialogs and sheets respect dark theme tokens', (tester) async {
      final discussion = ForumTopicModel(
        id: 'disc_dark_mode',
        title: 'Discussion 126',
        authorName: '@Host',
        category: 'General',
        content: 'Topic 126',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '5m ago',
      );

      mockRepo.discussionCommentsStore['disc_dark_mode'] = [
        CommentModel(
          id: 'c_dark',
          postId: 'disc_dark_mode',
          userId: 'user_auth_123',
          authorId: 'user_auth_123',
          userName: 'Dara Sok',
          userAvatar: '',
          text: 'Dark mode comment',
          timeAgo: '1m ago',
        ),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_more_c_dark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('comment_option_edit')));
      await tester.pumpAndSettle();

      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.backgroundColor, equals(AppColors.darkSurfaceSecondary));

      final saveButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'));
      expect(saveButton.style?.backgroundColor?.resolve({}), equals(Colors.white));
      expect(saveButton.style?.foregroundColor?.resolve({}), equals(Colors.black));
    });
  });
}
