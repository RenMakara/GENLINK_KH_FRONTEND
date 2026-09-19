import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityRemoteDataSource remoteDataSource;

  CommunityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) {
    return remoteDataSource.fetchPosts(page: page, limit: limit);
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) {
    return remoteDataSource.createPost(
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
    );
  }

  @override
  Future<CommunityPostModel> createPostWithVideo({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) {
    return remoteDataSource.createPost(
      content: content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      visibility: visibility,
      community: community,
    );
  }

  @override
  Future<CommunityPostModel> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
  }) {
    return remoteDataSource.createPollPost(
      question: question,
      options: options,
      caption: caption,
      visibility: visibility,
      communityId: communityId,
    );
  }

  @override
  Future<CommunityPostModel> votePoll({
    required String postId,
    required String optionId,
  }) {
    return remoteDataSource.votePoll(postId: postId, optionId: optionId);
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    final posts = await remoteDataSource.fetchPosts();
    return posts.firstWhere((p) => p.id == postId, orElse: () => posts.first);
  }

  @override
  Future<CommunityPostModel> updatePost(
    String postId, {
    required String content,
  }) async {
    final posts = await remoteDataSource.fetchPosts();
    final post = posts.firstWhere((p) => p.id == postId);
    return post.copyWith(content: content);
  }

  @override
  Future<bool> deletePost(String postId) {
    return remoteDataSource.deletePost(postId);
  }

  @override
  Future<bool> toggleLike(String postId) {
    return remoteDataSource.toggleLike(
      postId,
      isCurrentlyLiked: false,
    );
  }

  @override
  Future<bool> unlikePost(String postId) {
    return remoteDataSource.toggleLike(
      postId,
      isCurrentlyLiked: true,
    );
  }

  @override
  Future<List<PostLikerModel>> getPostLikers(
    String postId, {
    int page = 0,
    int size = 20,
  }) {
    return remoteDataSource.fetchPostLikers(
      postId,
      page: page,
      size: size,
    );
  }

  @override
  Future<bool> toggleBookmark(String postId) {
    return remoteDataSource.toggleBookmark(postId);
  }

  @override
  Future<bool> repostPost(
    String postId, {
    String? caption,
    String? reposterId,
  }) {
    return remoteDataSource.repostPost(
      postId,
      caption: caption,
      reposterId: reposterId,
    );
  }

  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) {
    return remoteDataSource.unrepostPost(postId, reposterId: reposterId);
  }

  @override
  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  }) {
    return remoteDataSource.reportPost(postId, reason: reason);
  }

  @override
  Future<List<CommentModel>> getComments(String postId) {
    return remoteDataSource.fetchComments(postId);
  }

  @override
  Future<List<CommentModel>> getCommentReplies(String commentId) {
    return remoteDataSource.fetchCommentReplies(commentId);
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) {
    return remoteDataSource.addComment(
      postId,
      text,
      parentCommentId: parentCommentId,
    );
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) {
    return remoteDataSource.deleteComment(commentId);
  }

  @override
  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.fetchDiscussions(
      category: category,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) {
    return remoteDataSource.createDiscussion(
      title: title,
      content: content,
      category: category,
      anonymous: anonymous,
    );
  }

  @override
  Future<ForumTopicModel> getDiscussionDetails(String discussionId) {
    return remoteDataSource.getDiscussionDetails(discussionId);
  }

  @override
  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
  }) {
    return remoteDataSource.updateDiscussion(
      discussionId,
      title: title,
      content: content,
      category: category,
    );
  }

  @override
  Future<bool> deleteDiscussion(String discussionId) {
    return remoteDataSource.deleteDiscussion(discussionId);
  }

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) {
    return remoteDataSource.toggleDiscussionLike(
      discussionId,
      isCurrentlyLiked: isCurrentlyLiked,
    );
  }

  @override
  Future<bool> toggleDiscussionBookmark(
    String discussionId, {
    required bool isCurrentlyBookmarked,
  }) {
    return remoteDataSource.toggleDiscussionBookmark(
      discussionId,
      isCurrentlyBookmarked: isCurrentlyBookmarked,
    );
  }

  @override
  Future<bool> isDiscussionBookmarked(String discussionId) {
    return remoteDataSource.isDiscussionBookmarked(discussionId);
  }

  @override
  Future<bool> reportDiscussion(
    String discussionId, {
    String reason = 'INAPPROPRIATE_CONTENT',
    String? details,
  }) {
    return remoteDataSource.reportDiscussion(
      discussionId,
      reason: reason,
      details: details,
    );
  }

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) {
    return remoteDataSource.fetchDiscussionComments(discussionId);
  }

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) {
    return remoteDataSource.addDiscussionComment(
      discussionId,
      content,
      parentCommentId: parentCommentId,
    );
  }

  @override
  Future<List<CommentModel>> getDiscussionCommentReplies(String commentId) {
    return remoteDataSource.fetchDiscussionCommentReplies(commentId);
  }

  @override
  Future<List<ForumLikerModel>> getDiscussionLikers(
    String discussionId, {
    int page = 0,
    int size = 20,
  }) {
    return remoteDataSource.fetchDiscussionLikers(
      discussionId,
      page: page,
      size: size,
    );
  }

  @override
  Future<CommentModel> updateDiscussionComment(
    String commentId,
    String content,
  ) {
    return remoteDataSource.updateDiscussionComment(commentId, content);
  }

  @override
  Future<bool> toggleDiscussionCommentLike(
    String commentId, {
    required bool isCurrentlyLiked,
  }) {
    return remoteDataSource.toggleDiscussionCommentLike(
      commentId,
      isCurrentlyLiked: isCurrentlyLiked,
    );
  }

  @override
  Future<bool> deleteDiscussionComment(String commentId) {
    return remoteDataSource.deleteDiscussionComment(commentId);
  }

  @override
  Future<bool> followUser(String userId) {
    return remoteDataSource.followUser(userId);
  }

  @override
  Future<bool> unfollowUser(String userId) {
    return remoteDataSource.unfollowUser(userId);
  }

  @override
  Future<bool> checkIsFollowing(String userId) {
    return remoteDataSource.checkIsFollowing(userId);
  }

  @override
  Future<RsvpResponseModel> rsvpEvent(
    String eventId, {
    EventRegistrationRequest? request,
  }) {
    return remoteDataSource.rsvpEvent(eventId, request: request);
  }

  @override
  Future<bool> cancelRsvpEvent(String eventId) {
    return remoteDataSource.cancelRsvpEvent(eventId);
  }

  @override
  Future<EventModel> createEvent(EventCreateRequest request) {
    return remoteDataSource.createEvent(request);
  }

  @override
  Future<List<EventModel>> getEvents({
    int page = 1,
    int limit = 20,
    String? category,
    String? status,
  }) {
    return remoteDataSource.fetchEvents(
      page: page,
      limit: limit,
      category: category,
      status: status,
    );
  }
}
