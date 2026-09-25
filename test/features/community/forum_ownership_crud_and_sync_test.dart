import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';

class _MockTestCommunityRepository implements CommunityRepository {
  final List<CommunityPostModel> posts = [];
  final List<ForumTopicModel> discussions = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => List.from(posts);

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async => CommunityPostModel(
    id: 'post_${DateTime.now().millisecondsSinceEpoch}',
    userId: 'user_current',
    authorName: 'Current User',
    authorTag: 'current',
    authorAvatar: '',
    timeAgo: 'Just now',
    content: content,
  );

  @override
  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async => List.from(discussions);

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    final newTopic = ForumTopicModel(
      id: 'disc_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'user_current',
      authorName: 'Current User',
      authorAvatar: '',
      title: title,
      content: content,
      category: category,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
    );
    discussions.add(newTopic);
    return newTopic;
  }

  @override
  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
    bool? anonymous,
  }) async {
    final index = discussions.indexWhere((d) => d.id == discussionId);
    if (index != -1) {
      final updated = discussions[index].copyWith(
        title: title,
        content: content,
        category: category,
      );
      discussions[index] = updated;
      return updated;
    }
    final created = ForumTopicModel(
      id: discussionId,
      authorId: 'user_current',
      authorName: 'Current User',
      authorAvatar: '',
      title: title,
      content: content,
      category: category,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
    );
    discussions.add(created);
    return created;
  }

  @override
  Future<bool> deleteDiscussion(String discussionId) async {
    discussions.removeWhere((d) => d.id == discussionId);
    return true;
  }

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

  @override
  Future<bool> toggleLike(String postId) async => true;

  @override
  Future<bool> toggleBookmark(String postId) async => true;

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async => [];

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async => CommentModel(
    id: 'comment_1',
    postId: discussionId,
    userId: 'user_current',
    userName: 'Current User',
    userAvatar: '',
    text: content,
    timeAgo: 'Just now',
  );
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Forum Ownership, CRUD & Sync Comprehensive Tests', () {
    test('1. ForumTopicModel ownership is strictly ID-based, not display name matching', () {
      final topic = ForumTopicModel(
        id: 'disc_1',
        authorId: 'user_123',
        authorName: 'John Doe',
        authorAvatar: '',
        title: 'Title',
        content: 'Content',
        category: 'Technology',
        timeAgo: 'now',
        upvotes: 5,
        repliesCount: 2,
      );

      expect(topic.checkIsOwner('user_123'), isTrue);

      expect(topic.checkIsOwner('user_456'), isFalse);
      expect(topic.checkIsOwner(null), isFalse);
      expect(topic.checkIsOwner(''), isFalse);
    });

    test('2. Forum discussion lifecycle: Creating discussion updates Forum list and keeps Feed posts isolated', () async {
      final repo = _MockTestCommunityRepository();
      final controller = CommunityController(repository: repo);

      expect(controller.forumLatestDiscussions.isEmpty, isTrue);
      expect(controller.forumPinnedDiscussions.isEmpty, isTrue);

      final initialFeedCount = controller.posts.length;

      final created = await controller.addDiscussion(
        title: 'New AI Architecture in Flutter',
        content: 'Discussing GetX and clean state handling.',
        category: 'Technology',
      );

      expect(created, isNotNull);
      expect(controller.forumLatestDiscussions.first.title, equals('New AI Architecture in Flutter'));
      expect(controller.forumLatestDiscussions.first.id, equals(created.id));

      // Forum discussions belong to forumLatestDiscussions, NOT synthetic posts in Feed
      expect(controller.posts.length, equals(initialFeedCount));
      expect(controller.posts.any((p) => p.id == created.id), isFalse);
    });

    test('3. Forum discussion lifecycle: Editing discussion updates Forum topic without polluting Feed', () async {
      final repo = _MockTestCommunityRepository();
      final controller = CommunityController(repository: repo);

      final created = await controller.addDiscussion(
        title: 'Original Title',
        content: 'Original Content',
        category: 'Technology',
      );

      expect(created, isNotNull);

      final updated = await controller.updateDiscussion(
        discussionId: created.id,
        title: 'Updated Title',
        content: 'Updated Content Body',
        category: 'Career',
      );

      expect(updated, isTrue);
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == created.id).title, equals('Updated Title'));
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == created.id).category, equals('Career'));
      expect(controller.posts.any((p) => p.id == created.id), isFalse);
    });

    test('4. Forum discussion lifecycle: Deleting discussion removes from Forum list', () async {
      final repo = _MockTestCommunityRepository();
      final controller = CommunityController(repository: repo);

      final created = await controller.addDiscussion(
        title: 'To Be Deleted',
        content: 'Temporary content',
        category: 'Study & Education',
      );

      expect(created, isNotNull);
      expect(controller.forumLatestDiscussions.any((d) => d.id == created.id), isTrue);

      final success = await controller.deleteDiscussion(created.id);
      expect(success, isTrue);

      expect(controller.forumLatestDiscussions.any((d) => d.id == created.id), isFalse);
    });

    test('5. Forum discussion reactions: Toggling like updates Forum discussion independently without post cross-talk', () async {
      final repo = _MockTestCommunityRepository();
      final controller = CommunityController(repository: repo);

      final created = await controller.addDiscussion(
        title: 'Sync Like Test',
        content: 'Content',
        category: 'Technology',
      );

      final topicId = created.id;
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == topicId).upvotes, equals(0));

      await controller.toggleDiscussionLike(topicId);
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == topicId).isLiked, isTrue);
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == topicId).upvotes, equals(1));

      await controller.toggleDiscussionLike(topicId);
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == topicId).isLiked, isFalse);
      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == topicId).upvotes, equals(0));
    });

    testWidgets('6. Forum UI starts with Latest Discussions and has zero pinned sections', (tester) async {
      final repo = _MockTestCommunityRepository();
      repo.discussions.add(ForumTopicModel(
        id: 'disc_sample_1',
        title: 'Sample Discussion Title',
        content: 'Sample Content',
        category: 'Technology',
        authorName: 'Test Author',
        authorAvatar: '',
        timeAgo: 'now',
        upvotes: 0,
        repliesCount: 0,
      ));
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.text('📌 Pinned Discussions'), findsNothing);
      expect(find.textContaining('📌'), findsNothing);

      expect(find.text('Latest Discussions'), findsOneWidget);
    });

    testWidgets('7. CreateDiscussionScreen in edit mode pre-fills fields and updates on submit', (tester) async {
      final repo = _MockTestCommunityRepository();
      final initialTopic = ForumTopicModel(
        id: 'disc_edit_1',
        authorId: 'user_current',
        authorName: 'Current User',
        authorAvatar: '',
        title: 'Original Title To Edit',
        content: 'Original Content Body To Edit',
        category: 'Technology',
        timeAgo: 'now',
        upvotes: 0,
        repliesCount: 0,
      );
      repo.discussions.insert(0, initialTopic);
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);
      controller.forumLatestDiscussions.insert(0, initialTopic);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CreateDiscussionScreen(initialDiscussion: initialTopic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('Original Title To Edit'), findsOneWidget);
      expect(find.text('Original Content Body To Edit'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Original Title To Edit'), 'Brand New Edited Title');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(controller.forumLatestDiscussions.first.title, equals('Brand New Edited Title'));
    });
  });
}
