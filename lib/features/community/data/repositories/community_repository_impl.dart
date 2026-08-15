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
  Future<CommunityPostModel> getPostDetails(String postId) async {
    final posts = await remoteDataSource.fetchPosts();
    return posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => posts.first,
    );
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    final posts = await remoteDataSource.fetchPosts();
    final post = posts.firstWhere((p) => p.id == postId);
    return post.copyWith(content: content);
  }

  @override
  Future<bool> deletePost(String postId) {
    return remoteDataSource.deletePost(postId);
  }

  @override
  Future<bool> toggleLike(String postId, {required bool isCurrentlyLiked}) {
    return remoteDataSource.toggleLike(postId, isCurrentlyLiked: isCurrentlyLiked);
  }

  @override
  Future<bool> toggleBookmark(String postId) {
    return remoteDataSource.toggleBookmark(postId);
  }

  @override
  Future<List<CommentModel>> getComments(String postId) {
    return remoteDataSource.fetchComments(postId);
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) {
    return remoteDataSource.addComment(postId, text, parentCommentId: parentCommentId);
  }

  @override
  Future<bool> deleteComment(String postId, String commentId) async {
    return true;
  }
}
