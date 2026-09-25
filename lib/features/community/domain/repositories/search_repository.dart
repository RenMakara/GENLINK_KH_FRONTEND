import 'package:dio/dio.dart';
import '../models/community_models.dart';
import '../models/community_post_model.dart';
import '../models/search_models.dart';

abstract class SearchRepository {
  Future<CombinedSearchResults> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });

  Future<List<UserSearchResultModel>> searchPeople({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });

  Future<List<CommunityPostModel>> searchPosts({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });

  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });

  Future<List<ForumTopicModel>> searchDiscussions({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });

  Future<List<String>> getTrendingHashtags({
    int limit = 10,
    CancelToken? cancelToken,
  });

  Future<List<String>> getRecentSearches();
  Future<void> addRecentSearch(String query);
  Future<void> removeRecentSearch(String query);
  Future<void> clearRecentSearches();
}
