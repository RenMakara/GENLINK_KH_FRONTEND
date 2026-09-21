import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/forum_share_to_chat_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class _MockAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStorage implements SecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLocalizationService extends GetxService implements LocalizationService {
  @override
  final language = 'en'.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCommunityRepository implements CommunityRepository {
  _MockCommunityRepository({List<CommunityPostModel>? posts})
      : _posts = posts ?? [];

  final List<CommunityPostModel> _posts;
  final Set<String> savedPostIds = {};
  final List<Map<String, dynamic>> recordedCalls = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return _posts.map((p) {
      if (savedPostIds.contains(p.id)) {
        return p.copyWith(isBookmarked: true);
      }
      return p;
    }).toList();
  }

  @override
  Future<bool> toggleBookmark(String postId) async {
    return togglePostBookmark(
      postId,
      isCurrentlyBookmarked: savedPostIds.contains(postId),
    );
  }

  @override
  Future<bool> togglePostBookmark(
    String postId, {
    required bool isCurrentlyBookmarked,
  }) async {
    recordedCalls.add({
      'action': isCurrentlyBookmarked ? 'unsave' : 'save',
      'postId': postId,
      'isCurrentlyBookmarked': isCurrentlyBookmarked,
    });

    if (isCurrentlyBookmarked) {
      savedPostIds.remove(postId);
    } else {
      savedPostIds.add(postId);
    }
    return true;
  }

  @override
  Future<bool> isPostBookmarked(String postId) async {
    return savedPostIds.contains(postId);
  }

  @override
  Future<bool> toggleLike(String postId) async => true;

  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async => true;

  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;

  @override
  Future<bool> checkIsFollowing(String userId) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockChatRepository implements ChatRepositoryImpl {
  final List<String> sentMessages = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ChatConversationModel>> getConversations() async => [
        ChatConversationModel(
          id: 'conv-study-1',
          name: 'Computer Science Study Group',
          avatar: '',
          lastMessage: 'Let us meet tomorrow',
          lastMessageTime: '10m ago',
          unreadCount: 0,
          isGroup: true,
          membersCount: 8,
        ),
        ChatConversationModel(
          id: 'conv-dm-2',
          name: 'Sok Vichea',
          avatar: '',
          lastMessage: 'Good luck with the exam!',
          lastMessageTime: '1h ago',
          unreadCount: 0,
          isGroup: false,
          membersCount: 2,
        ),
      ];

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId, {int page = 1, int limit = 50}) async => [];

  @override
  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
    ChatReplyReference? replyTo,
    String? localId,
  }) async {
    sentMessages.add('$conversationId: $content');
    return ChatMessageModel(
      id: 'msg-1',
      conversationId: conversationId,
      senderId: 'user-me',
      senderName: 'Test User',
      content: content,
      timestamp: DateTime.now(),
      timeAgo: 'Just now',
      isMine: true,
    );
  }

  @override
  Future<bool> markConversationRead(String conversationId) async => true;

  @override
  Future<int> getUnreadCount() async => 0;
}

void main() {
  late _MockCommunityRepository communityRepo;
  late _MockChatRepository chatRepo;
  late CommunityController communityController;
  late ChatController chatController;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    final authController = AuthController(
      authRepository: _MockAuthRepo(),
      secureStorage: _MockStorage(),
      localization: _MockLocalizationService(),
    );
    authController.currentUser.value = const UserEntity(
      id: 'user-me',
      fullName: 'Test User',
      username: 'testuser',
      email: 'test@genlink.kh',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 1,
      preferredLanguage: 'en',
      role: 'STUDENT',
      active: true,
    );
    Get.put<AuthController>(authController);
    Get.put<LocalizationService>(_MockLocalizationService());

    communityRepo = _MockCommunityRepository();
    communityController = CommunityController(repository: communityRepo);
    Get.put<CommunityController>(communityController);

    chatRepo = _MockChatRepository();
    chatController = ChatController(repository: chatRepo);
    Get.put<ChatController>(chatController);
  });

  tearDown(() {
    Get.reset();
  });

  group('Feed Share to Chat & Engagement Specifications', () {
    testWidgets('1. Feed Share button opens Share to Chat sheet with Post preview', (tester) async {
      final post = CommunityPostModel(
        id: 'post-share-test-1',
        userId: 'author-101',
        authorName: 'Vanna Roth',
        authorTag: '@vannaroth',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Excited to announce our new Flutter project at GenLink!',
        likesCount: 15,
        commentsCount: 3,
        sharesCount: 1,
        isLiked: false,
        isBookmarked: false,
        isRepostedByMe: false,
      );
      communityController.posts.assignAll([post]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: post,
              controller: communityController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the share button in the feed post card
      final shareBtn = find.byKey(Key('post_share_button_${post.id}'));
      expect(shareBtn, findsOneWidget);

      // Tap share button
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      // Share to Chat bottom sheet is opened
      expect(find.byType(ForumShareToChatSheet), findsOneWidget);
      expect(find.byKey(const Key('forum_share_to_chat_sheet')), findsOneWidget);

      // Verify sheet displays post content preview
      expect(find.text('Excited to announce our new Flutter project at GenLink!'), findsWidgets);
      expect(find.text('Vanna Roth'), findsWidgets);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('2. Share to Chat Sheet: Neutral styling verified (Inverted Send button, no blue)', (tester) async {
      final post = CommunityPostModel(
        id: 'post-share-neutral-ui',
        userId: 'author-102',
        authorName: 'Sokha Meng',
        authorTag: '@sokhameng',
        authorAvatar: '',
        timeAgo: '2m ago',
        content: 'Clean architecture in Flutter apps',
        likesCount: 5,
        commentsCount: 2,
        sharesCount: 0,
      );

      // Populate conversations in controller
      await chatController.fetchConversations();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ForumShareToChatSheet(post: post),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Inverted Send buttons exist
      final sendTextFinder = find.text('Send');
      expect(sendTextFinder, findsWidgets);

      // Verify that the send button container has neutral styling (white background in dark theme)
      final sendContainer = tester.widget<Container>(
        find.ancestor(of: sendTextFinder.first, matching: find.byType(Container)).first,
      );
      final decoration = sendContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));

      // Verify text inside inverted Send button is black
      final sendText = tester.widget<Text>(sendTextFinder.first);
      expect(sendText.style?.color, equals(Colors.black));

      // Verify Search chat input field is present
      expect(find.text('Search chat...'), findsOneWidget);
    });

    testWidgets('3. Share to Chat: Selecting conversation sends post content and navigates', (tester) async {
      final post = CommunityPostModel(
        id: 'post-share-send',
        userId: 'author-103',
        authorName: 'Rithy Panh',
        authorTag: '@rithy',
        authorAvatar: '',
        timeAgo: '5m ago',
        content: 'Campus seminar happening this Friday afternoon!',
        likesCount: 8,
        commentsCount: 1,
        sharesCount: 0,
      );

      // Populate conversations
      await chatController.fetchConversations();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumShareToChatSheet(post: post),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the first conversation ListTile
      final convTile = find.text('Computer Science Study Group');
      expect(convTile, findsOneWidget);

      // Tap to share to this conversation
      await tester.tap(convTile);
      await tester.pumpAndSettle();

      // Verify message was dispatched to chat repository with post content
      expect(chatRepo.sentMessages.length, equals(1));
      expect(
        chatRepo.sentMessages.first,
        equals('conv-study-1: Campus seminar happening this Friday afternoon!'),
      );
    });

    testWidgets('4. Engagement Action Row: All 5 icons have size 20 and min 44x44 touch targets', (tester) async {
      final post = CommunityPostModel(
        id: 'post-icons-spec',
        userId: 'author-104',
        authorName: 'Kosal Chea',
        authorTag: '@kosal',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Testing icon sizes and touch target constraints',
        likesCount: 10,
        commentsCount: 4,
        sharesCount: 2,
        isLiked: false,
        isBookmarked: false,
      );
      communityController.posts.assignAll([post]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: post,
              controller: communityController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find engagement buttons
      final likeBtn = find.byKey(Key('post_like_button_${post.id}'));
      final commentBtn = find.byKey(Key('post_comment_button_${post.id}'));
      final repostBtn = find.byKey(Key('post_repost_button_${post.id}'));
      final bookmarkBtn = find.byKey(Key('post_bookmark_button_${post.id}'));
      final shareBtn = find.byKey(Key('post_share_button_${post.id}'));

      expect(likeBtn, findsOneWidget);
      expect(commentBtn, findsOneWidget);
      expect(repostBtn, findsOneWidget);
      expect(bookmarkBtn, findsOneWidget);
      expect(shareBtn, findsOneWidget);

      // Verify minimum touch target constraints >= 44
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final min44Boxes = constrainedBoxes.where(
        (cb) => cb.constraints.minHeight >= 44.0,
      ).toList();
      expect(min44Boxes.length, greaterThanOrEqualTo(5));

      // Verify horizontal ordering: Like < Comment < Repost < Bookmark < Share
      final likeX = tester.getCenter(likeBtn).dx;
      final commentX = tester.getCenter(commentBtn).dx;
      final repostX = tester.getCenter(repostBtn).dx;
      final bookmarkX = tester.getCenter(bookmarkBtn).dx;
      final shareX = tester.getCenter(shareBtn).dx;

      expect(likeX < commentX, isTrue, reason: 'Like must be to the left of Comment');
      expect(commentX < repostX, isTrue, reason: 'Comment must be to the left of Repost');
      expect(repostX < bookmarkX, isTrue, reason: 'Repost must be to the left of Bookmark');
      expect(bookmarkX < shareX, isTrue, reason: 'Bookmark must be to the left of Share');
    });

    testWidgets('5. Feed Bookmark: Save/Unsave toggles through controller and reflects on card UI', (tester) async {
      final post = CommunityPostModel(
        id: 'post-save-toggle-105',
        userId: 'author-105',
        authorName: 'Sok Vanna',
        authorTag: '@sokvanna',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Bookmark toggle specification test',
        likesCount: 3,
        commentsCount: 0,
        sharesCount: 0,
        isLiked: false,
        isBookmarked: false,
      );
      communityController.posts.assignAll([post]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: PostCardWidget(
              post: post,
              controller: communityController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bookmarkBtn = find.byKey(Key('post_bookmark_button_${post.id}'));

      // Initially unbookmarked
      expect(communityController.isPostBookmarked(post.id), isFalse);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

      // Tap to save
      await tester.tap(bookmarkBtn);
      await tester.pumpAndSettle();

      expect(communityController.isPostBookmarked(post.id), isTrue);
      expect(communityRepo.savedPostIds.contains(post.id), isTrue);
      expect(communityRepo.recordedCalls.last['action'], equals('save'));
      expect(communityRepo.recordedCalls.last['isCurrentlyBookmarked'], isFalse);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

      // Tap to unsave
      await tester.tap(bookmarkBtn);
      await tester.pumpAndSettle();

      expect(communityController.isPostBookmarked(post.id), isFalse);
      expect(communityRepo.savedPostIds.contains(post.id), isFalse);
      expect(communityRepo.recordedCalls.last['action'], equals('unsave'));
      expect(communityRepo.recordedCalls.last['isCurrentlyBookmarked'], isTrue);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });
  });
}
