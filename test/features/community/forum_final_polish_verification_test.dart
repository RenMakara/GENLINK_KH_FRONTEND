import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/widgets/community_widgets.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/forum_liked_by_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/forum_share_to_chat_sheet.dart';

class _MockChatRepository implements ChatRepositoryImpl {
  final List<ChatConversationModel> conversations = [
    ChatConversationModel(
      id: 'conv_1',
      name: 'Vireak Roth',
      avatar: '',
      lastMessage: 'Hello there',
      lastMessageTime: '5m',
    ),
  ];
  final List<Map<String, dynamic>> sentMessages = [];

  @override
  Future<List<ChatConversationModel>> getConversations() async => conversations;

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async => [];

  @override
  Future<bool> markConversationRead(String conversationId) async => true;

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
    String? localId,
    SharedContentModel? sharedContent,
    StoryReference? storyReference,
  }) async {
    sentMessages.add({
      'conversationId': conversationId,
      'content': content.isNotEmpty ? content : (sharedContent != null ? '${sharedContent.title}\n\n${sharedContent.previewText ?? ""}'.trim() : ''),
      'messageType': messageType,
    });
    return ChatMessageModel(
      id: 'msg_1',
      conversationId: conversationId,
      senderId: 'current_user',
      senderName: 'Me',
      content: content,
      timestamp: DateTime.now(),
      timeAgo: 'Just now',
      isMine: true,
      messageType: messageType,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCommunityRepository implements CommunityRepository {
  final Map<String, List<CommentModel>> discussionCommentsStore = {};
  final Map<String, List<ForumLikerModel>> discussionLikersStore = {};
  final List<Map<String, dynamic>> recordedAddCommentCalls = [];
  final List<String> recordedRepostCalls = [];
  final Set<String> bookmarkedDiscussionIds = {};
  final List<ForumTopicModel> discussions = [];

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async {
    return List<CommentModel>.from(discussionCommentsStore[discussionId] ?? []);
  }

  @override
  Future<List<ForumLikerModel>> getDiscussionLikers(
    String discussionId, {
    int page = 0,
    int size = 20,
  }) async {
    return List<ForumLikerModel>.from(discussionLikersStore[discussionId] ?? []);
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
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: discussionId,
      userId: 'user_tester',
      userName: 'Tester User',
      userAvatar: '',
      text: content,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
    );

    if (parentCommentId != null) {
      final comments = discussionCommentsStore[discussionId] ?? [];
      final parentIdx = comments.indexWhere((c) => c.id == parentCommentId);
      if (parentIdx != -1) {
        final parent = comments[parentIdx];
        final updatedReplies = List<CommentModel>.from(parent.replies)..add(comment);
        comments[parentIdx] = parent.copyWith(replies: updatedReplies);
      }
    } else {
      discussionCommentsStore.putIfAbsent(discussionId, () => []).add(comment);
    }
    return comment;
  }

  @override
  Future<bool> toggleDiscussionLike(String discussionId, {bool isCurrentlyLiked = false}) async {
    return true;
  }

  @override
  Future<bool> toggleDiscussionBookmark(String discussionId, {required bool isCurrentlyBookmarked}) async {
    if (bookmarkedDiscussionIds.contains(discussionId)) {
      bookmarkedDiscussionIds.remove(discussionId);
    } else {
      bookmarkedDiscussionIds.add(discussionId);
    }
    return true;
  }

  @override
  Future<bool> isDiscussionBookmarked(String discussionId) async {
    return bookmarkedDiscussionIds.contains(discussionId);
  }

  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async {
    recordedRepostCalls.add(postId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockCommunityRepository mockRepo;
  late _MockChatRepository mockChatRepo;
  late CommunityController controller;
  late ChatController chatController;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    mockRepo = _MockCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);

    mockChatRepo = _MockChatRepository();
    chatController = ChatController(repository: mockChatRepo);
    chatController.conversations.assignAll(mockChatRepo.conversations);
    Get.put<ChatController>(chatController);
  });

  tearDown(() {
    Get.reset();
  });

  group('Forum Final Pass Verification (12 Criteria)', () {
    testWidgets('CRITERION 1: "Liked by" preview row is HIDDEN when likes == 0', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              title: 'Discussion Zero Likes',
              author: '@Tester',
              timeAgo: '5m ago',
              category: 'General',
              replies: 0,
              likes: 0,
              likers: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forum_liked_by_preview')), findsNothing);
      expect(find.textContaining('Liked by'), findsNothing);
    });

    testWidgets('CRITERION 2: "Liked by" preview displays real likers when likes > 0', (tester) async {
      final likers = [
        ForumLikerModel(id: 'u1', fullName: 'Enat', username: '@enat', avatarUrl: ''),
        ForumLikerModel(id: 'u2', fullName: 'Makara', username: '@makara', avatarUrl: ''),
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              title: 'Discussion With Likers',
              author: '@Author',
              timeAgo: '10m ago',
              category: 'Tech',
              replies: 2,
              likes: 3,
              likers: likers,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forum_liked_by_preview')), findsOneWidget);
      expect(find.textContaining('Liked by Enat, Makara +1'), findsOneWidget);
    });

    testWidgets('CRITERION 3: Tapping "Liked by" preview opens ForumLikedBySheet modal', (tester) async {
      final likers = [
        ForumLikerModel(id: 'u1', fullName: 'Enat', username: '@enat', avatarUrl: ''),
      ];
      mockRepo.discussionLikersStore['disc_sheet_1'] = likers;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              discussionId: 'disc_sheet_1',
              title: 'Discussion For Sheet',
              author: '@Author',
              timeAgo: '10m ago',
              category: 'Tech',
              replies: 1,
              likes: 1,
              likers: likers,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forum_liked_by_preview')));
      await tester.pumpAndSettle();

      expect(find.byType(ForumLikedBySheet), findsOneWidget);
      expect(find.text('Enat'), findsWidgets);
    });

    testWidgets('CRITERION 4 & 5: ForumThreadCard engagement row order: LIKE -> COMMENT -> REPOST -> SAVE -> SHARE TO CHAT', (tester) async {
      bool saveTapped = false;
      bool shareTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              title: 'Engagement Row Verification',
              author: '@Enat',
              timeAgo: '1h ago',
              category: 'Design',
              replies: 5,
              likes: 12,
              likers: const [],
              onSaveTap: () => saveTapped = true,
              onShareToChatTap: () => shareTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final likeFinder = find.byIcon(Icons.favorite_border_rounded);
      final commentFinder = find.byIcon(Icons.chat_bubble_outline_rounded);
      final repostFinder = find.byKey(const Key('forum_card_repost_button'));
      final saveFinder = find.byKey(const Key('forum_card_save_button'));
      final shareFinder = find.byKey(const Key('forum_card_share_to_chat_button'));

      expect(likeFinder, findsOneWidget);
      expect(commentFinder, findsOneWidget);
      expect(repostFinder, findsOneWidget);
      expect(saveFinder, findsOneWidget);
      expect(shareFinder, findsOneWidget);

      // Verify strict horizontal left-to-right ordering
      final likePos = tester.getCenter(likeFinder);
      final commentPos = tester.getCenter(commentFinder);
      final repostPos = tester.getCenter(repostFinder);
      final savePos = tester.getCenter(saveFinder);
      final sharePos = tester.getCenter(shareFinder);

      expect(likePos.dx < commentPos.dx, isTrue);
      expect(commentPos.dx < repostPos.dx, isTrue);
      expect(repostPos.dx < savePos.dx, isTrue);
      expect(savePos.dx < sharePos.dx, isTrue);

      // Test tapping save and share
      await tester.tap(saveFinder);
      await tester.pump();
      expect(saveTapped, isTrue);

      await tester.tap(shareFinder);
      await tester.pump();
      expect(shareTapped, isTrue);
    });

    testWidgets('CRITERION 6: ForumDiscussionScreen engagement row order: LIKE -> COMMENT -> REPOST -> SAVE -> SHARE TO CHAT', (tester) async {
      final topic = ForumTopicModel(
        id: 'disc_det_1',
        title: 'Discussion Detail Engagement',
        authorName: '@OtherUser',
        category: 'General',
        content: 'Content detail here',
        upvotes: 4,
        repliesCount: 2,
        timeAgo: '20m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      final likeFinder = find.byIcon(Icons.favorite_border_rounded);
      final commentFinder = find.byIcon(Icons.chat_bubble_outline_rounded);
      final repostFinder = find.byKey(const Key('forum_discussion_repost_button'));
      final saveFinder = find.byKey(const Key('forum_discussion_save_button'));
      final shareFinder = find.byKey(const Key('forum_discussion_share_to_chat_button'));

      expect(likeFinder, findsOneWidget);
      expect(commentFinder, findsWidgets);
      expect(repostFinder, findsOneWidget);
      expect(saveFinder, findsOneWidget);
      expect(shareFinder, findsOneWidget);

      // Verify strict horizontal left-to-right ordering
      final likePos = tester.getCenter(likeFinder);
      final commentPos = tester.getCenter(commentFinder.first);
      final repostPos = tester.getCenter(repostFinder);
      final savePos = tester.getCenter(saveFinder);
      final sharePos = tester.getCenter(shareFinder);

      expect(likePos.dx < commentPos.dx, isTrue);
      expect(commentPos.dx < repostPos.dx, isTrue);
      expect(repostPos.dx < savePos.dx, isTrue);
      expect(savePos.dx < sharePos.dx, isTrue);

      // Tap save in ForumDiscussionScreen: changes to bookmarked
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('CRITERION 7: Nested replies render hierarchically under parent comment', (tester) async {
      final childReply = CommentModel(
        id: 'reply_1',
        postId: 'disc_nest',
        userId: 'user_reply',
        userName: 'Reply Author',
        userAvatar: '',
        text: 'This is a nested reply',
        timeAgo: '5m ago',
        parentCommentId: 'parent_1',
      );
      final parentComment = CommentModel(
        id: 'parent_1',
        postId: 'disc_nest',
        userId: 'user_parent',
        userName: 'Parent Author',
        userAvatar: '',
        text: 'This is a parent comment',
        timeAgo: '15m ago',
        replies: [childReply],
      );

      mockRepo.discussionCommentsStore['disc_nest'] = [parentComment];

      final topic = ForumTopicModel(
        id: 'disc_nest',
        title: 'Nested Discussion',
        authorName: '@Author',
        category: 'Tech',
        content: 'Content',
        upvotes: 1,
        repliesCount: 2,
        timeAgo: '1h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This is a parent comment'), findsOneWidget);
      expect(find.text('Parent Author'), findsOneWidget);
      expect(find.text('This is a nested reply'), findsOneWidget);
      expect(find.text('Reply Author'), findsOneWidget);
    });

    testWidgets('CRITERION 8: Tapping reply sets reply context and submits with parentCommentId', (tester) async {
      final parentComment = CommentModel(
        id: 'parent_99',
        postId: 'disc_reply_test',
        userId: 'user_p',
        userName: 'Sophea',
        userAvatar: '',
        text: 'Main comment',
        timeAgo: '10m ago',
      );
      mockRepo.discussionCommentsStore['disc_reply_test'] = [parentComment];

      final topic = ForumTopicModel(
        id: 'disc_reply_test',
        title: 'Reply Test Discussion',
        authorName: '@Owner',
        category: 'Tech',
        content: 'Content',
        upvotes: 0,
        repliesCount: 1,
        timeAgo: '10m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('comment_reply_parent_99')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cancel_reply_button')), findsOneWidget);
      expect(find.text('Sophea'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'My nested response');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedAddCommentCalls.isNotEmpty, isTrue);
      expect(mockRepo.recordedAddCommentCalls.first['parentCommentId'], 'parent_99');
      expect(mockRepo.recordedAddCommentCalls.first['content'], 'My nested response');
    });

    testWidgets('CRITERION 9: Active Send button icon color is pure WHITE', (tester) async {
      final topic = ForumTopicModel(
        id: 'disc_white_icon',
        title: 'Send Icon Color Test',
        authorName: '@Owner',
        category: 'Tech',
        content: 'Content',
        upvotes: 0,
        repliesCount: 0,
        timeAgo: '10m ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Testing active send button');
      await tester.pump();

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.send_rounded));
      expect(iconWidget.color, Colors.white);
    });

    testWidgets('CRITERION 10: Repost discussion prompts dialog and executes repost', (tester) async {
      final topic = ForumTopicModel(
        id: 'disc_repost_test',
        title: 'Repost Test',
        authorName: '@OtherUser',
        category: 'General',
        content: 'Discussion to repost',
        upvotes: 5,
        repliesCount: 1,
        timeAgo: '1h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forum_discussion_repost_button')));
      await tester.pumpAndSettle();

      expect(find.text('Repost'), findsWidgets);
      expect(find.textContaining('Reposting content originally by @OtherUser'), findsOneWidget);

      // Tap confirm repost
      await tester.tap(find.widgetWithText(ElevatedButton, 'Repost'));
      await tester.pumpAndSettle();

      expect(mockRepo.recordedRepostCalls.contains('disc_repost_test'), isTrue);
    });

    testWidgets('CRITERION 11: Light and Dark mode renders cleanly without errors', (tester) async {
      final topic = ForumTopicModel(
        id: 'disc_theme',
        title: 'Theme Verification Discussion',
        authorName: '@Themer',
        category: 'Design',
        content: 'Verifying dark and light themes render correctly',
        upvotes: 3,
        repliesCount: 1,
        timeAgo: '30m ago',
        likers: [
          ForumLikerModel(id: 'u1', fullName: 'Sokha', username: '@sokha', avatarUrl: ''),
        ],
      );

      // Test Dark Mode
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Theme Verification Discussion'), findsOneWidget);

      // Test Light Mode
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Theme Verification Discussion'), findsOneWidget);
    });

    testWidgets('CRITERION 12: Khmer localization renders cleanly on narrow screen (320px)', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final topic = ForumTopicModel(
        id: 'disc_km_narrow',
        title: 'ការពិភាក្សាអំពីបច្ចេកវិទ្យា',
        authorName: 'វិសាល',
        category: 'Technology',
        content: 'ខ្លឹមសារនៃការពិភាក្សា',
        upvotes: 2,
        repliesCount: 0,
        timeAgo: '1h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ការពិភាក្សាអំពីបច្ចេកវិទ្យា'), findsOneWidget);
      expect(find.byType(ForumDiscussionScreen), findsOneWidget);
    });

    testWidgets('CRITERION 13: Real save/bookmark functionality backed by repository', (tester) async {
      final topic = ForumTopicModel(
        id: 'disc_bookmark_real',
        title: 'Bookmark Discussion Test',
        authorName: '@Author',
        category: 'Tech',
        content: 'Test content',
        timeAgo: '1h ago',
      );
      controller.forumLatestDiscussions.assignAll([topic]);

      expect(controller.isDiscussionBookmarked('disc_bookmark_real'), isFalse);

      final result = await controller.toggleDiscussionBookmark('disc_bookmark_real');
      expect(result, isTrue);
      expect(controller.isDiscussionBookmarked('disc_bookmark_real'), isTrue);
      expect(mockRepo.bookmarkedDiscussionIds.contains('disc_bookmark_real'), isTrue);

      final unbookmarkResult = await controller.toggleDiscussionBookmark('disc_bookmark_real');
      expect(unbookmarkResult, isTrue);
      expect(controller.isDiscussionBookmarked('disc_bookmark_real'), isFalse);
      expect(mockRepo.bookmarkedDiscussionIds.contains('disc_bookmark_real'), isFalse);
    });

    testWidgets('CRITERION 14: Real "Share to Chat" flow opens ForumShareToChatSheet and sends a text message', (tester) async {
      final topic = ForumTopicModel(
        id: 'disc_share_test',
        title: 'Learn Flutter in Cambodia',
        authorName: '@Instructor',
        category: 'Education',
        content: 'Flutter tutorial discussion',
        timeAgo: '2h ago',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ForumShareToChatSheet.show(ctx, topic: topic),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(ForumShareToChatSheet), findsOneWidget);
      expect(find.text('Learn Flutter in Cambodia'), findsOneWidget);
      expect(find.text('Vireak Roth'), findsOneWidget);

      // Tap conversation to send
      await tester.tap(find.text('Vireak Roth'));
      await tester.pumpAndSettle();

      final mockChat = Get.find<ChatController>().repository as _MockChatRepository;
      expect(mockChat.sentMessages.isNotEmpty, isTrue);
      expect(mockChat.sentMessages.first['conversationId'], 'conv_1');
      expect(mockChat.sentMessages.first['messageType'], 'text');
      expect(mockChat.sentMessages.first['content'], 'Learn Flutter in Cambodia\n\nFlutter tutorial discussion');
    });
  });
}
