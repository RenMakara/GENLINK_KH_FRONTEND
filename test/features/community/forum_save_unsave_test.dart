import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/widgets/community_widgets.dart';

class _MockSaveUnsaveCommunityRepository implements CommunityRepository {
  final Set<String> savedDiscussionIds = {};
  final List<Map<String, dynamic>> recordedCalls = [];
  bool failNextToggle = false;

  @override
  Future<bool> toggleDiscussionBookmark(
    String discussionId, {
    required bool isCurrentlyBookmarked,
  }) async {
    recordedCalls.add({
      'action': isCurrentlyBookmarked ? 'unsave' : 'save',
      'discussionId': discussionId,
      'isCurrentlyBookmarked': isCurrentlyBookmarked,
    });

    if (failNextToggle) {
      throw Exception('Network error during bookmark toggle');
    }

    if (isCurrentlyBookmarked) {
      savedDiscussionIds.remove(discussionId);
    } else {
      savedDiscussionIds.add(discussionId);
    }
    return true;
  }

  @override
  Future<bool> isDiscussionBookmarked(String discussionId) async {
    return savedDiscussionIds.contains(discussionId);
  }

  @override
  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    return [
      ForumTopicModel(
        id: 'disc_1',
        title: 'Discussion 1',
        authorName: 'User A',
        category: 'Tech',
        content: 'Content 1',
        timeAgo: '1m ago',
        isBookmarked: savedDiscussionIds.contains('disc_1'),
      ),
      ForumTopicModel(
        id: 'disc_2',
        title: 'Discussion 2',
        authorName: 'User B',
        category: 'General',
        content: 'Content 2',
        timeAgo: '2m ago',
        isBookmarked: savedDiscussionIds.contains('disc_2'),
      ),
    ];
  }

  @override
  Future<EventPageModel<ForumTopicModel>> getDiscussionsPage({
    String? category,
    int page = 1,
    int limit = 20,
  }) async => EventPageModel<ForumTopicModel>.fromContent(
    await getDiscussions(category: category, page: page, limit: limit),
    page: page - 1,
    size: limit,
  );

  @override
  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async {
    return ForumTopicModel(
      id: discussionId,
      title: 'Discussion Detail $discussionId',
      authorName: 'Author',
      category: 'General',
      content: 'Detailed content',
      timeAgo: 'Just now',
      isBookmarked: savedDiscussionIds.contains(discussionId),
    );
  }

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async =>
      [];

  @override
  Future<List<ForumLikerModel>> getDiscussionLikers(
    String discussionId, {
    int page = 0,
    int size = 20,
  }) async => [];

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockSaveUnsaveCommunityRepository repository;
  late CommunityController controller;

  setUp(() {
    Get.reset();
    repository = _MockSaveUnsaveCommunityRepository();
    controller = CommunityController(repository: repository);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('Forum Discussion Save / Unsave Functionality Tests', () {
    testWidgets(
      '1. Initial State: Unsaved discussion displays bookmark_border_rounded',
      (tester) async {
        final topic = ForumTopicModel(
          id: 'disc_101',
          title: 'Fresh Discussion',
          authorName: 'Student',
          category: 'General',
          content: 'Hello everyone',
          timeAgo: 'Just now',
          isBookmarked: false,
        );

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: ForumThreadCard(
                discussionId: topic.id,
                title: topic.title,
                author: topic.authorName,
                timeAgo: topic.timeAgo,
                category: topic.category,
                replies: 0,
                likes: 0,
                isBookmarked: controller.isDiscussionBookmarked(topic.id),
                onSaveTap: () => controller.toggleDiscussionBookmark(topic.id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.isDiscussionBookmarked('disc_101'), isFalse);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
      },
    );

    testWidgets(
      '2. Save: Tapping unsaved bookmark saves discussion and changes icon to bookmark_rounded',
      (tester) async {
        final topic = ForumTopicModel(
          id: 'disc_102',
          title: 'Saveable Discussion',
          authorName: 'Student',
          category: 'General',
          content: 'Testing Save',
          timeAgo: 'Just now',
          isBookmarked: false,
        );
        controller.forumLatestDiscussions.assignAll([topic]);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: Obx(
                () => ForumThreadCard(
                  discussionId: topic.id,
                  title: topic.title,
                  author: topic.authorName,
                  timeAgo: topic.timeAgo,
                  category: topic.category,
                  replies: 0,
                  likes: 0,
                  isBookmarked: controller.isDiscussionBookmarked(topic.id),
                  onSaveTap: () =>
                      controller.toggleDiscussionBookmark(topic.id),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial check
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

        // Tap Save
        await tester.tap(find.byKey(const Key('forum_card_save_button')));
        await tester.pumpAndSettle();

        expect(controller.isDiscussionBookmarked('disc_102'), isTrue);
        expect(repository.savedDiscussionIds.contains('disc_102'), isTrue);
        expect(repository.recordedCalls.last['action'], 'save');
        expect(repository.recordedCalls.last['isCurrentlyBookmarked'], isFalse);

        // Icon updated to filled bookmark
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
      },
    );

    testWidgets(
      '3. Unsave: Tapping saved bookmark unsaves discussion and reverts icon to bookmark_border_rounded',
      (tester) async {
        // Pre-saved in repository and controller
        repository.savedDiscussionIds.add('disc_103');
        controller.discussionBookmarks['disc_103'] = true;

        final topic = ForumTopicModel(
          id: 'disc_103',
          title: 'Already Saved Discussion',
          authorName: 'Student',
          category: 'General',
          content: 'Testing Unsave',
          timeAgo: 'Just now',
          isBookmarked: true,
        );
        controller.forumLatestDiscussions.assignAll([topic]);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: Obx(
                () => ForumThreadCard(
                  discussionId: topic.id,
                  title: topic.title,
                  author: topic.authorName,
                  timeAgo: topic.timeAgo,
                  category: topic.category,
                  replies: 0,
                  likes: 0,
                  isBookmarked: controller.isDiscussionBookmarked(topic.id),
                  onSaveTap: () =>
                      controller.toggleDiscussionBookmark(topic.id),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

        // Tap to Unsave
        await tester.tap(find.byKey(const Key('forum_card_save_button')));
        await tester.pumpAndSettle();

        expect(controller.isDiscussionBookmarked('disc_103'), isFalse);
        expect(repository.savedDiscussionIds.contains('disc_103'), isFalse);
        expect(repository.recordedCalls.last['action'], 'unsave');
        expect(repository.recordedCalls.last['isCurrentlyBookmarked'], isTrue);

        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
      },
    );

    testWidgets(
      '4. Repeated Toggle: Save -> Unsave -> Save -> Unsave behaves as a true toggle',
      (tester) async {
        final topic = ForumTopicModel(
          id: 'disc_104',
          title: 'Multi Toggle Discussion',
          authorName: 'Student',
          category: 'General',
          content: 'Testing Repeated Toggle',
          timeAgo: 'Just now',
          isBookmarked: false,
        );
        controller.forumLatestDiscussions.assignAll([topic]);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: Obx(
                () => ForumThreadCard(
                  discussionId: topic.id,
                  title: topic.title,
                  author: topic.authorName,
                  timeAgo: topic.timeAgo,
                  category: topic.category,
                  replies: 0,
                  likes: 0,
                  isBookmarked: controller.isDiscussionBookmarked(topic.id),
                  onSaveTap: () =>
                      controller.toggleDiscussionBookmark(topic.id),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final saveButton = find.byKey(const Key('forum_card_save_button'));

        // 1st tap: Save
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(controller.isDiscussionBookmarked('disc_104'), isTrue);
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(repository.recordedCalls.last['action'], 'save');

        // 2nd tap: Unsave
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(controller.isDiscussionBookmarked('disc_104'), isFalse);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(repository.recordedCalls.last['action'], 'unsave');

        // 3rd tap: Save again
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(controller.isDiscussionBookmarked('disc_104'), isTrue);
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(repository.recordedCalls.last['action'], 'save');

        // 4th tap: Unsave again
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(controller.isDiscussionBookmarked('disc_104'), isFalse);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(repository.recordedCalls.last['action'], 'unsave');

        // 4 total calls: save, unsave, save, unsave
        expect(repository.recordedCalls.length, 4);
        expect(repository.recordedCalls.map((c) => c['action']).toList(), [
          'save',
          'unsave',
          'save',
          'unsave',
        ]);
      },
    );

    testWidgets(
      '5. Detail Screen: Bookmark state and toggle sync correctly with controller',
      (tester) async {
        final topic = ForumTopicModel(
          id: 'disc_detail_1',
          title: 'Detail Discussion Test',
          authorName: 'Author',
          category: 'Academics',
          content: 'Full body content',
          timeAgo: '10m ago',
          isBookmarked: false,
        );

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: ForumDiscussionScreen(discussion: topic),
          ),
        );
        await tester.pumpAndSettle();

        final detailSaveBtn = find.byKey(
          const Key('forum_discussion_save_button'),
        );
        expect(detailSaveBtn, findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

        // Tap Save on detail screen
        await tester.tap(detailSaveBtn);
        await tester.pumpAndSettle();

        expect(controller.isDiscussionBookmarked('disc_detail_1'), isTrue);
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

        // Tap Unsave on detail screen
        await tester.tap(detailSaveBtn);
        await tester.pumpAndSettle();

        expect(controller.isDiscussionBookmarked('disc_detail_1'), isFalse);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '6. Discussion action row omits repost and keeps Save before Share',
      (tester) async {
        final topic = ForumTopicModel(
          id: 'disc_order_test',
          title: 'Action Order Test',
          authorName: 'Author',
          category: 'Academics',
          content: 'Testing Action Row Order',
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

        // Find all engagement action widgets by their icons
        final likeFinder = find.byIcon(Icons.favorite_border_rounded);
        final commentFinder = find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              w.icon == Icons.chat_bubble_outline_rounded &&
              w.size == 20.0,
        );
        final saveFinder = find.byKey(
          const Key('forum_discussion_save_button'),
        );
        final shareFinder = find.byKey(
          const Key('forum_discussion_share_to_chat_button'),
        );

        expect(likeFinder, findsOneWidget);
        expect(commentFinder, findsOneWidget);
        expect(
          find.byKey(const Key('forum_discussion_repost_button')),
          findsNothing,
        );
        expect(saveFinder, findsOneWidget);
        expect(shareFinder, findsOneWidget);

        // Verify horizontal coordinates: Like.dx < Comment.dx < Repost.dx < Save.dx < Share.dx
        final likeDx = tester.getCenter(likeFinder).dx;
        final commentDx = tester.getCenter(commentFinder).dx;
        final saveDx = tester.getCenter(saveFinder).dx;
        final shareDx = tester.getCenter(shareFinder).dx;

        expect(
          likeDx < commentDx,
          isTrue,
          reason: 'Like must be before Comment',
        );
        expect(
          commentDx < saveDx,
          isTrue,
          reason: 'Comment must be before Save',
        );
        expect(
          saveDx < shareDx,
          isTrue,
          reason: 'Save must be before Share to Chat',
        );
      },
    );

    testWidgets(
      '7. Backend Persistence: fetchDiscussions hydrates savedByMe into controller discussionBookmarks',
      (tester) async {
        // Disc_1 is bookmarked on backend, Disc_2 is not
        repository.savedDiscussionIds.add('disc_1');

        // onInit already starts an initial load; force this assertion's own
        // request instead of racing that in-flight request.
        await controller.fetchDiscussions(isRefresh: true);

        expect(controller.isDiscussionBookmarked('disc_1'), isTrue);
        expect(controller.isDiscussionBookmarked('disc_2'), isFalse);
      },
    );

    testWidgets(
      '8. Multi-Discussion Isolation: saving discussion A does not affect discussion B',
      (tester) async {
        await controller.toggleDiscussionBookmark('disc_A');

        expect(controller.isDiscussionBookmarked('disc_A'), isTrue);
        expect(controller.isDiscussionBookmarked('disc_B'), isFalse);

        await controller.toggleDiscussionBookmark('disc_B');

        expect(controller.isDiscussionBookmarked('disc_A'), isTrue);
        expect(controller.isDiscussionBookmarked('disc_B'), isTrue);

        await controller.toggleDiscussionBookmark('disc_A');

        expect(controller.isDiscussionBookmarked('disc_A'), isFalse);
        expect(controller.isDiscussionBookmarked('disc_B'), isTrue);
      },
    );

    testWidgets(
      '9. Session Isolation: clearBookmarkCache resets cache on account switch/logout',
      (tester) async {
        await controller.toggleDiscussionBookmark('disc_user1');
        expect(controller.isDiscussionBookmarked('disc_user1'), isTrue);

        controller.clearBookmarkCache();

        expect(controller.discussionBookmarks.isEmpty, isTrue);
        expect(controller.isDiscussionBookmarked('disc_user1'), isFalse);
      },
    );

    testWidgets(
      '10. Failure Rollback: network error reverts optimistic bookmark update',
      (tester) async {
        final topic = ForumTopicModel(
          id: 'disc_fail',
          title: 'Failing Discussion',
          authorName: 'Author',
          category: 'General',
          content: 'Fails on toggle',
          timeAgo: 'Just now',
          isBookmarked: false,
        );
        controller.forumLatestDiscussions.assignAll([topic]);

        repository.failNextToggle = true;

        final success = await controller.toggleDiscussionBookmark('disc_fail');

        expect(success, isFalse);
        // Reverted to original false state
        expect(controller.isDiscussionBookmarked('disc_fail'), isFalse);
        expect(controller.forumLatestDiscussions.first.isBookmarked, isFalse);
      },
    );
  });
}
