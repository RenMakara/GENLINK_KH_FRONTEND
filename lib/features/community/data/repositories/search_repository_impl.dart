import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/utils/current_user.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/search_models.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final LocalStorage localStorage;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    LocalStorage? localStorage,
  }) : localStorage = localStorage ??
            (Get.isRegistered<LocalStorage>()
                ? Get.find<LocalStorage>()
                : LocalStorage());

  String get _currentUserId {
    final uid = CurrentUser.id;
    return uid.isNotEmpty ? uid : 'guest';
  }

  @override
  Future<CombinedSearchResults> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.search(
      query: query,
      category: category,
      page: page,
      size: size,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<UserSearchResultModel>> searchPeople({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.searchPeople(
      query: query,
      page: page,
      size: size,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<CommunityPostModel>> searchPosts({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.searchPosts(
      query: query,
      page: page,
      size: size,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.searchEvents(
      query: query,
      page: page,
      size: size,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ForumTopicModel>> searchDiscussions({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.searchDiscussions(
      query: query,
      page: page,
      size: size,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<String>> getTrendingHashtags({
    int limit = 10,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.getTrendingHashtags(
      limit: limit,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<String>> getRecentSearches() async {
    try {
      final raw = await localStorage.readRecentSearches(_currentUserId);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    try {
      final list = await getRecentSearches();
      // Remove any existing case-insensitive match
      list.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
      // Insert at front
      list.insert(0, trimmed);
      // Keep up to 15 items
      if (list.length > 15) {
        list.removeRange(15, list.length);
      }
      await localStorage.saveRecentSearches(_currentUserId, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Future<void> removeRecentSearch(String query) async {
    try {
      final list = await getRecentSearches();
      list.removeWhere((item) => item.toLowerCase() == query.toLowerCase().trim());
      await localStorage.saveRecentSearches(_currentUserId, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Future<void> clearRecentSearches() async {
    try {
      await localStorage.clearRecentSearches(_currentUserId);
    } catch (_) {}
  }
}
