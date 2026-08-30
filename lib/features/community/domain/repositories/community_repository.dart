import '../models/community_post_model.dart';

abstract class CommunityRepository {
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10});

  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  });

  Future<CommunityPostModel> getPostDetails(String postId);

  Future<CommunityPostModel> updatePost(
    String postId, {
    required String content,
  });

  Future<bool> deletePost(String postId);

  Future<bool> toggleLike(String postId);

  Future<bool> toggleBookmark(String postId);
  Future<bool> repostPost(String postId, {String? caption, String? reposterId});
  Future<bool> unrepostPost(String postId, {String? reposterId});
  Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'});

  Future<List<CommentModel>> getComments(String postId);

  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  });

  Future<bool> deleteComment(String postId, String commentId);

  Future<List<CommentModel>> getDiscussionComments(String discussionId);

  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  });

  Future<bool> followUser(String userId);
  Future<bool> unfollowUser(String userId);
  Future<bool> checkIsFollowing(String userId);
}
