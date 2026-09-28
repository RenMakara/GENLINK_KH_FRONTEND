import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';

void main() {
  test('feed refresh wins over an older in-flight page response', () async {
    final oldPage = Completer<List<CommunityPostModel>>();
    final repository = _Phase2Repository()
      ..postPageTwo = oldPage
      ..postPageOne = [_post('refreshed')];
    final controller = CommunityController(repository: repository)
      ..currentPage.value = 1
      ..hasMorePosts.value = true;
    controller.posts.add(_post('old-page-one'));

    final loadMore = controller.loadMorePosts();
    expect(repository.requestedPostPages, [2]);

    await controller.fetchPosts(isRefresh: true);
    expect(controller.posts.map((post) => post.id), ['refreshed']);

    oldPage.complete([_post('stale-page-two')]);
    await loadMore;

    expect(controller.posts.map((post) => post.id), ['refreshed']);
    expect(controller.currentPage.value, 1);
    expect(controller.hasMorePosts.value, isFalse);
    expect(controller.isLoadingMore.value, isFalse);
  });

  test(
    'feed page failure keeps current content and exposes a retryable error',
    () async {
      final repository = _Phase2Repository()
        ..postPageTwoError = StateError('temporary network failure')
        ..postPageOne = [_post('page-two')];
      final controller = CommunityController(repository: repository)
        ..currentPage.value = 1
        ..hasMorePosts.value = true;
      controller.posts.add(_post('page-one'));

      await controller.loadMorePosts();

      expect(controller.posts.map((post) => post.id), ['page-one']);
      expect(controller.currentPage.value, 1);
      expect(controller.hasMorePosts.value, isTrue);
      expect(controller.hasMorePostsError.value, isTrue);
      expect(
        controller.morePostsErrorMessage.value,
        contains('load more posts'),
      );

      repository.postPageTwoError = null;
      await controller.loadMorePosts();

      expect(controller.posts.map((post) => post.id), ['page-one', 'page-two']);
      expect(controller.currentPage.value, 2);
      expect(controller.hasMorePostsError.value, isFalse);
    },
  );

  test(
    'comment request failure does not replace loaded comments with empty state',
    () async {
      final repository = _Phase2Repository()
        ..comments = [_comment('existing-comment', 'post-1')];
      final controller = CommunityController(repository: repository);

      await controller.fetchComments('post-1');
      repository.commentsError = StateError('offline');
      await controller.fetchComments('post-1');

      expect(controller.activeComments.map((comment) => comment.id), [
        'existing-comment',
      ]);
      expect(controller.commentsErrorMessage.value, isNotEmpty);
      expect(controller.isLoadingComments.value, isFalse);
    },
  );

  test(
    'discussion pagination preserves hasNext and avoids duplicate rows',
    () async {
      final repository = _Phase2Repository()
        ..discussionPages = {
          1: _page([_discussion('discussion-1')], page: 0, hasNext: true),
          2: _page(
            [_discussion('discussion-1'), _discussion('discussion-2')],
            page: 1,
            hasNext: true,
          ),
          3: _page([_discussion('discussion-3')], page: 2, hasNext: false),
        };
      final controller = CommunityController(repository: repository);

      await controller.fetchDiscussions(isRefresh: true);
      await controller.loadMoreDiscussions();
      await controller.loadMoreDiscussions();

      expect(repository.requestedDiscussionPages, [1, 2, 3]);
      expect(controller.currentForumDiscussionsPage.value, 3);
      expect(controller.hasMoreForumDiscussions.value, isFalse);
      expect(controller.forumLatestDiscussions.map((topic) => topic.id), [
        'discussion-1',
        'discussion-2',
        'discussion-3',
      ]);
    },
  );

  test('opportunity pagination keeps server page metadata', () async {
    final repository = _Phase2Repository()
      ..opportunityPages = {
        1: _page([_opportunity('opportunity-1')], page: 0, hasNext: true),
        2: _page([_opportunity('opportunity-2')], page: 1, hasNext: false),
      };
    final controller = CommunityController(repository: repository);

    await controller.fetchOpportunities(isRefresh: true);
    await controller.loadMoreOpportunities();

    expect(repository.requestedOpportunityPages, [1, 2]);
    expect(controller.currentOpportunitiesPage.value, 2);
    expect(controller.hasMoreOpportunities.value, isFalse);
    expect(controller.opportunities.map((opportunity) => opportunity.id), [
      'opportunity-1',
      'opportunity-2',
    ]);
  });
}

class _Phase2Repository implements CommunityRepository {
  List<CommunityPostModel> postPageOne = const [];
  Completer<List<CommunityPostModel>>? postPageTwo;
  Object? postPageTwoError;
  List<CommentModel> comments = const [];
  Object? commentsError;
  Map<int, EventPageModel<ForumTopicModel>> discussionPages = const {};
  Map<int, EventPageModel<OpportunityModel>> opportunityPages = const {};
  final requestedPostPages = <int>[];
  final requestedDiscussionPages = <int>[];
  final requestedOpportunityPages = <int>[];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) {
    requestedPostPages.add(page);
    if (page == 2 && postPageTwoError != null) {
      return Future.error(postPageTwoError!);
    }
    if (page == 2 && postPageTwo != null) return postPageTwo!.future;
    return Future.value(postPageOne);
  }

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    if (commentsError != null) throw commentsError!;
    return comments;
  }

  @override
  Future<EventPageModel<ForumTopicModel>> getDiscussionsPage({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    requestedDiscussionPages.add(page);
    return discussionPages[page] ?? const EventPageModel<ForumTopicModel>();
  }

  @override
  Future<EventPageModel<OpportunityModel>> getOpportunitiesPage({
    String? type,
    bool includeExpired = false,
    int page = 1,
    int limit = 20,
  }) async {
    requestedOpportunityPages.add(page);
    return opportunityPages[page] ?? const EventPageModel<OpportunityModel>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventPageModel<T> _page<T>(
  List<T> content, {
  required int page,
  required bool hasNext,
}) => EventPageModel<T>(
  content: content,
  page: page,
  size: 20,
  totalElements: content.length,
  totalPages: hasNext ? page + 2 : page + 1,
  hasNext: hasNext,
);

CommunityPostModel _post(String id) => CommunityPostModel(
  id: id,
  userId: '',
  authorName: '',
  authorTag: '',
  authorAvatar: '',
  timeAgo: '',
  content: id,
);

ForumTopicModel _discussion(String id) => ForumTopicModel(
  id: id,
  title: id,
  authorName: 'Author',
  category: 'General',
  content: id,
  timeAgo: 'now',
);

OpportunityModel _opportunity(String id) => OpportunityModel(id: id, title: id);

CommentModel _comment(String id, String postId) => CommentModel(
  id: id,
  postId: postId,
  userId: 'user-1',
  userName: 'User',
  userAvatar: '',
  text: 'Comment',
  timeAgo: 'now',
);
