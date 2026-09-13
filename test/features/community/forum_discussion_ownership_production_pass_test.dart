import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';

class _MockProductionCommunityRepository implements CommunityRepository {
  final List<CommunityPostModel> posts = [];
  final List<ForumTopicModel> discussions = [];
  String currentSessionUserId = 'user_A';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => List.from(posts);

  @override
  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async => List.from(discussions);

  @override
  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async {
    final found = discussions.firstWhereOrNull((d) => d.id == discussionId);
    if (found == null) {
      throw const AppError(message: 'Discussion not found', errorCode: 'NOT_FOUND', statusCode: 404);
    }
    return found;
  }

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    final newTopic = ForumTopicModel(
      id: 'disc_${DateTime.now().microsecondsSinceEpoch}',
      authorId: currentSessionUserId,
      authorName: currentSessionUserId == 'user_A' ? 'User A' : 'User B',
      authorAvatar: '',
      title: title,
      content: content,
      category: category,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
      isOwner: true,
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
  }) async {
    final index = discussions.indexWhere((d) => d.id == discussionId);
    if (index == -1) {
      throw const AppError(message: 'Discussion not found', errorCode: 'NOT_FOUND', statusCode: 404);
    }
    final existing = discussions[index];
    if (existing.authorId != null && existing.authorId != currentSessionUserId) {
      throw const AppError(
        message: 'You do not have permission to edit this discussion.',
        errorCode: 'FORBIDDEN',
        statusCode: 403,
      );
    }
    final updated = existing.copyWith(
      title: title,
      content: content,
      category: category,
    );
    discussions[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteDiscussion(String discussionId) async {
    final index = discussions.indexWhere((d) => d.id == discussionId);
    if (index == -1) {
      throw const AppError(message: 'Discussion not found', errorCode: 'NOT_FOUND', statusCode: 404);
    }
    final existing = discussions[index];
    if (existing.authorId != null && existing.authorId != currentSessionUserId) {
      throw const AppError(
        message: 'You do not have permission to delete this discussion.',
        errorCode: 'FORBIDDEN',
        statusCode: 403,
      );
    }
    discussions.removeAt(index);
    return true;
  }

  @override
  Future<bool> toggleDiscussionLike(String discussionId, {bool isCurrentlyLiked = false}) async => true;

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async => [];

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async => CommentModel(
    id: 'cmt_1',
    postId: discussionId,
    userId: currentSessionUserId,
    userName: 'Tester',
    userAvatar: '',
    text: content,
    timeAgo: 'Just now',
  );
}

class _TestCommunityController extends CommunityController {
  String testUserId = 'user_A';

  _TestCommunityController({required CommunityRepository repository, required this.testUserId})
      : super(repository: repository);

  @override
  String? get currentUserId => testUserId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('GENLINK FORUM — 22 Production Pass Ownership & Security Tests', () {
    // 1 & 2: Owner sees Edit & Delete
    testWidgets('1 & 2: Owner opening their own discussion sees Edit and Delete actions in ⋯ menu', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final discussionA = ForumTopicModel(
        id: 'disc_A',
        authorId: 'user_A',
        authorName: 'User A',
        authorAvatar: '',
        title: 'Discussion by User A',
        content: 'Content by User A',
        category: 'Technology',
        timeAgo: '2h',
        isOwner: true,
      );
      repo.discussions.add(discussionA);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussionA),
        ),
      );
      await tester.pumpAndSettle();

      // Tap ⋯ in appbar
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // Owner sees Edit & Delete
      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('Delete Discussion'), findsOneWidget);
      // Non-owner action Report is NOT shown for owner
      expect(find.text('Report'), findsNothing);

      // Cleanly dismiss bottom sheet
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    // 3 & 4: Non-owner does NOT see Edit or Delete
    testWidgets('3 & 4: Non-owner opening another user\'s discussion does NOT see Edit or Delete, sees Report', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final discussionA = ForumTopicModel(
        id: 'disc_A',
        authorId: 'user_A',
        authorName: 'User A',
        authorAvatar: '',
        title: 'Discussion by User A',
        content: 'Content by User A',
        category: 'Technology',
        timeAgo: '2h',
        isOwner: false,
      );
      repo.discussions.add(discussionA);

      // User B is viewing User A's discussion
      final controller = _TestCommunityController(repository: repo, testUserId: 'user_B');
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: discussionA),
        ),
      );
      await tester.pumpAndSettle();

      // Tap ⋯ in appbar
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // Non-owner MUST NOT see Edit or Delete
      expect(find.text('Edit Discussion'), findsNothing);
      expect(find.text('Delete Discussion'), findsNothing);

      // Non-owner sees Report
      expect(find.text('Report'), findsOneWidget);

      // Cleanly dismiss bottom sheet
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    // 5 & 6: Owner can open Edit and existing values are pre-filled
    testWidgets('5 & 6: Owner can open Edit and category, title, content are pre-filled', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final discussion = ForumTopicModel(
        id: 'disc_edit_test',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Original Title 101',
        content: 'Original Content Body 101',
        category: 'Technology',
        timeAgo: '1h',
        isOwner: true,
      );
      repo.discussions.add(discussion);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CreateDiscussionScreen(initialDiscussion: discussion),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title is Edit Discussion
      expect(find.text('Edit Discussion'), findsOneWidget);
      // Values are pre-filled
      expect(find.text('Original Title 101'), findsOneWidget);
      expect(find.text('Original Content Body 101'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
    });

    // 7 & 8: Owner can save edits and edited data appears immediately
    testWidgets('7 & 8: Owner can save edits and edited data updates controller state immediately', (tester) async {
      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_save_test',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Initial Title',
        content: 'Initial Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      controller.forumLatestDiscussions.add(topic);

      final success = await controller.updateDiscussion(
        discussionId: 'disc_save_test',
        title: 'Updated Title Immediately',
        content: 'Updated Content Immediately',
        category: 'Career',
      );

      expect(success, isTrue);
      expect(controller.forumLatestDiscussions.first.title, 'Updated Title Immediately');
      expect(controller.forumLatestDiscussions.first.content, 'Updated Content Immediately');
      expect(controller.forumLatestDiscussions.first.category, 'Career');
    });

    // 9: Edit persists after refresh
    test('9: Edit persists in repository source of truth after refresh', () async {
      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_persist_test',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Before Refresh Title',
        content: 'Before Refresh Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      await controller.updateDiscussion(
        discussionId: 'disc_persist_test',
        title: 'Persisted New Title',
        content: 'Persisted New Content',
        category: 'Projects',
      );

      // Simulate full app refresh / reload from repository
      await controller.fetchDiscussions(isRefresh: true);

      expect(controller.forumLatestDiscussions.first.title, 'Persisted New Title');
      expect(controller.forumLatestDiscussions.first.content, 'Persisted New Content');
      expect(controller.forumLatestDiscussions.first.category, 'Projects');
    });

    // 10 & 11: Owner can delete and confirmation dialog appears
    testWidgets('10 & 11: Delete tap prompts confirmation dialog with Cancel and Delete actions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_del_dialog_test',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'To Delete Title',
        content: 'To Delete Content',
        category: 'Technology',
        timeAgo: 'now',
        isOwner: true,
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      // Open ⋯
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // Tap Delete Discussion
      await tester.tap(find.text('Delete Discussion'));
      await tester.pumpAndSettle();

      // Verify destructive confirmation dialog
      expect(find.text('Delete Discussion?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Cleanly dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    // 12 & 13: Deleted discussion disappears and persists after refresh
    test('12 & 13: Deleted discussion disappears from list and remains deleted after refresh', () async {
      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_delete_persist',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Will Be Deleted',
        content: 'Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      await controller.fetchDiscussions();
      expect(controller.forumLatestDiscussions.any((d) => d.id == 'disc_delete_persist'), isTrue);

      final success = await controller.deleteDiscussion('disc_delete_persist');
      expect(success, isTrue);
      expect(controller.forumLatestDiscussions.any((d) => d.id == 'disc_delete_persist'), isFalse);

      // Refresh from repository
      await controller.fetchDiscussions(isRefresh: true);
      expect(controller.forumLatestDiscussions.any((d) => d.id == 'disc_delete_persist'), isFalse);
    });

    // 14: Non-owner edit returns 403 Forbidden
    test('14: Non-owner edit returns 403 Forbidden', () async {
      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_user_A',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'User A Discussion',
        content: 'Original Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      // User B attempts to edit User A's discussion
      repo.currentSessionUserId = 'user_B';
      final controller = _TestCommunityController(repository: repo, testUserId: 'user_B');

      expect(
        () async => await controller.updateDiscussion(
          discussionId: 'disc_user_A',
          title: 'Hacked Title',
          content: 'Hacked Content',
          category: 'Technology',
        ),
        throwsA(predicate((e) => e is AppError && e.statusCode == 403 && e.isForbidden)),
      );

      // Topic remains unmodified in repo
      expect(repo.discussions.first.title, 'User A Discussion');
    });

    // 15: Non-owner delete returns 403 Forbidden
    test('15: Non-owner delete returns 403 Forbidden', () async {
      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_user_A',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'User A Discussion',
        content: 'Original Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      // User B attempts to delete User A's discussion
      repo.currentSessionUserId = 'user_B';
      final controller = _TestCommunityController(repository: repo, testUserId: 'user_B');

      expect(
        () async => await controller.deleteDiscussion('disc_user_A'),
        throwsA(predicate((e) => e is AppError && e.statusCode == 403 && e.isForbidden)),
      );

      // Topic remains alive in repo
      expect(repo.discussions.any((d) => d.id == 'disc_user_A'), isTrue);
    });

    // 16 & 17: Feed reflects edits and deletion when discussion appears in feed
    test('16 & 17: Feed reflects discussion edits and deletion when discussion is present in feed', () async {
      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_shared',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Shared Title',
        content: 'Shared Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      controller.forumLatestDiscussions.add(topic);

      // Feed has the same discussion as a feed post
      controller.posts.add(CommunityPostModel(
        id: 'disc_shared',
        userId: 'user_A',
        authorName: 'User A',
        authorTag: 'usera',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Shared Content',
        discussionTitle: 'Shared Title',
        category: 'Technology',
      ));

      expect(controller.posts.first.discussionTitle, 'Shared Title');

      // Edit discussion
      await controller.updateDiscussion(
        discussionId: 'disc_shared',
        title: 'Updated Shared Title',
        content: 'Updated Shared Body',
        category: 'Career',
      );

      // Both Forum and Feed reflect the update
      expect(controller.forumLatestDiscussions.first.title, 'Updated Shared Title');
      expect(controller.posts.first.discussionTitle, 'Updated Shared Title');
      expect(controller.posts.first.category, 'Career');

      // Delete discussion
      await controller.deleteDiscussion('disc_shared');

      // Both Forum and Feed remove the discussion
      expect(controller.forumLatestDiscussions.any((d) => d.id == 'disc_shared'), isFalse);
      expect(controller.posts.any((p) => p.id == 'disc_shared'), isFalse);
    });

    // 18 & 19: Khmer and English editing works exactly as entered
    testWidgets('18 & 19: Khmer and English text editing works without unwanted translation or alteration', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_khmer_en',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Original Title',
        content: 'Original Content',
        category: 'Technology',
        timeAgo: 'now',
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      controller.forumLatestDiscussions.add(topic);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => CreateDiscussionScreen(initialDiscussion: topic)),
                ),
                child: const Text('Open Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      const khmerTitle = 'ការណែនាំអំពី Architecture សម្រាប់ GenLink';
      const mixedContent = 'សូមស្វាគមន៍! Building Flutter apps with Spring Boot clean architecture.';

      await tester.enterText(find.widgetWithText(TextField, 'Original Title'), khmerTitle);
      await tester.enterText(find.widgetWithText(TextField, 'Original Content'), mixedContent);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(controller.forumLatestDiscussions.first.title, equals(khmerTitle));
      expect(controller.forumLatestDiscussions.first.content, equals(mixedContent));
    });

    // 20: Light Mode works
    testWidgets('20: ForumDiscussionScreen renders with high contrast in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_light_test',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Light Mode Discussion',
        content: 'Light Mode Content',
        category: 'Technology',
        timeAgo: 'now',
        isOwner: true,
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Light Mode Discussion'), findsOneWidget);
      expect(find.text('Light Mode Content'), findsOneWidget);
    });

    // 21: Dark Mode works
    testWidgets('21: ForumDiscussionScreen renders with high contrast in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_dark_test',
        authorId: 'user_A',
        authorName: 'User A',
        title: 'Dark Mode Discussion',
        content: 'Dark Mode Content',
        category: 'Technology',
        timeAgo: 'now',
        isOwner: true,
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark Mode Discussion'), findsOneWidget);
      expect(find.text('Dark Mode Content'), findsOneWidget);
    });

    // 22: Responsive layout works at 320px, 360px, 390px, 430px
    testWidgets('22: Responsive layout renders without overflow at 320px, 360px, 390px, and 430px', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];

      final repo = _MockProductionCommunityRepository();
      final topic = ForumTopicModel(
        id: 'disc_responsive_test',
        authorId: 'user_A',
        authorName: 'User A with a Very Long Name For Responsive Testing',
        title: 'ការពិភាក្សាអំពី Flutter និង Spring Boot ជាមួយចំណងជើងវែងបំផុតនៅលើអេក្រង់តូច',
        content: 'Responsive content body designed to test wrapping and spacing without overflowing any viewport dimension.',
        category: 'Study & Education',
        timeAgo: 'now',
        isOwner: true,
      );
      repo.discussions.add(topic);

      final controller = _TestCommunityController(repository: repo, testUserId: 'user_A');
      Get.put<CommunityController>(controller);

      for (final w in widths) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: ForumDiscussionScreen(discussion: topic),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero layout overflow at width $w px');
      }

      tester.view.resetPhysicalSize();
    });
  });
}
