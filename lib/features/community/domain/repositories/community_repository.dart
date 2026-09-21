import '../models/community_models.dart';
import '../models/community_post_model.dart';

abstract class CommunityRepository {
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10});

  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  });

  /// Optional video-aware extension. Existing repository fakes can continue
  /// implementing [createPost] while production uses the media-aware path.
  Future<CommunityPostModel> createPostWithVideo({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) => createPost(
    content: content,
    imageUrls: imageUrls,
    visibility: visibility,
    community: community,
  );

  Future<CommunityPostModel> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
  }) => throw UnimplementedError();

  Future<CommunityPostModel> votePoll({
    required String postId,
    required String optionId,
  }) => throw UnimplementedError();

  Future<CommunityPostModel> getPostDetails(String postId);

  Future<CommunityPostModel> updatePost(
    String postId, {
    required String content,
  });

  Future<bool> deletePost(String postId);

  Future<bool> toggleLike(String postId);

  Future<bool> unlikePost(String postId) => toggleLike(postId);

  Future<List<PostLikerModel>> getPostLikers(
    String postId, {
    int page = 0,
    int size = 20,
  }) => Future.value([]);

  Future<bool> toggleBookmark(String postId);
  Future<bool> repostPost(String postId, {String? caption, String? reposterId});
  Future<bool> unrepostPost(String postId, {String? reposterId});
  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  });

  Future<List<CommentModel>> getComments(String postId);

  Future<List<CommentModel>> getCommentReplies(String commentId) =>
      Future.value([]);

  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  });

  Future<bool> deleteComment(String postId, String commentId);

  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  });

  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  });

  Future<ForumTopicModel> getDiscussionDetails(String discussionId);

  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
    bool? anonymous,
  });

  Future<bool> deleteDiscussion(String discussionId);

  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  });

  Future<bool> toggleDiscussionBookmark(
    String discussionId, {
    required bool isCurrentlyBookmarked,
  }) => Future.value(!isCurrentlyBookmarked);

  Future<bool> isDiscussionBookmarked(String discussionId) =>
      Future.value(false);

  Future<bool> reportDiscussion(
    String discussionId, {
    String reason = 'INAPPROPRIATE_CONTENT',
    String? details,
  });

  Future<List<CommentModel>> getDiscussionComments(String discussionId);

  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  });

  Future<List<CommentModel>> getDiscussionCommentReplies(String commentId) =>
      Future.value([]);

  Future<List<ForumLikerModel>> getDiscussionLikers(
    String discussionId, {
    int page = 0,
    int size = 20,
  }) => Future.value([]);

  Future<CommentModel> updateDiscussionComment(
    String commentId,
    String content,
  ) => throw UnimplementedError();

  Future<bool> toggleDiscussionCommentLike(
    String commentId, {
    required bool isCurrentlyLiked,
  });

  Future<bool> deleteDiscussionComment(String commentId);

  Future<bool> followUser(String userId);
  Future<bool> unfollowUser(String userId);
  Future<bool> checkIsFollowing(String userId);

  Future<RsvpResponseModel> rsvpEvent(
    String eventId, {
    EventRegistrationRequest? request,
  });

  Future<bool> cancelRsvpEvent(String eventId) async => true;

  Future<EventModel> createEvent(EventCreateRequest request) =>
      throw UnimplementedError();

  Future<EventModel> updateEvent(String eventId, EventCreateRequest request) =>
      throw UnimplementedError();

  Future<bool> deleteEvent(String eventId) async => true;

  Future<List<EventAttendeeModel>> getEventAttendees(
    String eventId, {
    int page = 1,
    int limit = 50,
  }) async => const [];

  Future<EventPageModel<EventAttendeeModel>> getEventAttendeesPage(
    String eventId, {
    int page = 1,
    int limit = 50,
  }) async {
    final content = await getEventAttendees(eventId, page: page, limit: limit);
    return EventPageModel<EventAttendeeModel>.fromContent(
      content,
      page: page - 1,
      size: limit,
    );
  }

  Future<bool> toggleEventBookmark(
    String eventId, {
    required bool isCurrentlyBookmarked,
  }) async => true;

  Future<Set<String>> getSavedEventIds() async => const {};

  Future<List<EventModel>> getEvents({
    int page = 1,
    int limit = 20,
    String? category,
  }) async => const [];

  Future<EventPageModel<EventModel>> getEventsPage({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final content = await getEvents(
      page: page,
      limit: limit,
      category: category,
    );
    return EventPageModel<EventModel>.fromContent(
      content,
      page: page - 1,
      size: limit,
    );
  }

  Future<List<EventModel>> getMyEvents({int page = 1, int limit = 20}) async =>
      const [];

  Future<EventPageModel<EventModel>> getMyEventsPage({
    int page = 1,
    int limit = 20,
  }) async {
    final content = await getMyEvents(page: page, limit: limit);
    return EventPageModel<EventModel>.fromContent(
      content,
      page: page - 1,
      size: limit,
    );
  }

  Future<EventModel> getEventDetails(String eventId);
}
