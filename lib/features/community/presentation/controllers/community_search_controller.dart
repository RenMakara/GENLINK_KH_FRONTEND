import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../profile/presentation/utils/profile_navigation.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/search_models.dart';
import '../../domain/repositories/search_repository.dart';
import '../screens/event_details_screen.dart';
import '../screens/forum_discussion_screen.dart';
import '../widgets/comments_bottom_sheet.dart';

class CommunitySearchController extends GetxController {
  final SearchRepository searchRepository;

  CommunitySearchController({SearchRepository? repository})
      : searchRepository = repository ??
            SearchRepositoryImpl(
              remoteDataSource: SearchRemoteDataSource(
                dio: Get.isRegistered<Dio>()
                    ? Get.find<Dio>()
                    : DioProvider.create(),
              ),
            );

  final RxString query = ''.obs;
  final Rx<SearchCategory> selectedCategory = SearchCategory.all.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasSearched = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<CombinedSearchResults?> searchResults = Rx<CombinedSearchResults?>(null);

  final RxList<String> recentSearches = <String>[].obs;
  final RxList<String> trendingHashtags = <String>[].obs;
  final RxBool isLoadingTrending = false.obs;

  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  int _requestSeq = 0;

  @override
  void onInit() {
    super.onInit();
    loadRecentSearches();
    loadTrendingHashtags();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    super.onClose();
  }

  void onQueryChanged(String text) {
    query.value = text;
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
      isLoading.value = false;
      hasSearched.value = false;
      errorMessage.value = '';
      searchResults.value = null;
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      performSearch();
    });
  }

  Future<void> selectCategory(SearchCategory category) async {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;

    if (query.value.trim().isNotEmpty) {
      _debounceTimer?.cancel();
      await performSearch();
    }
  }

  Future<void> performSearch({bool isRetry = false}) async {
    final currentQuery = query.value.trim();
    if (currentQuery.isEmpty) {
      isLoading.value = false;
      hasSearched.value = false;
      searchResults.value = null;
      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    _requestSeq++;
    final localSeq = _requestSeq;

    isLoading.value = true;
    errorMessage.value = '';
    hasSearched.value = true;

    try {
      final results = await searchRepository.search(
        query: currentQuery,
        category: selectedCategory.value,
        cancelToken: _cancelToken,
      );

      if (localSeq != _requestSeq) return;

      searchResults.value = results;
      isLoading.value = false;

      // Persist to recent searches
      await addRecentSearch(currentQuery);
    } catch (e) {
      if (localSeq != _requestSeq) return;
      if ((e is DioException && CancelToken.isCancel(e)) ||
          _cancelToken?.isCancelled == true) {
        return;
      }
      isLoading.value = false;
      errorMessage.value = 'community.searchError'.tr;
    }
  }

  Future<void> loadRecentSearches() async {
    try {
      final items = await searchRepository.getRecentSearches();
      recentSearches.assignAll(items);
    } catch (_) {}
  }

  Future<void> addRecentSearch(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await searchRepository.addRecentSearch(trimmed);
      await loadRecentSearches();
    } catch (_) {}
  }

  Future<void> removeRecentSearch(String text) async {
    try {
      await searchRepository.removeRecentSearch(text);
      await loadRecentSearches();
    } catch (_) {}
  }

  Future<void> clearAllRecentSearches() async {
    try {
      await searchRepository.clearRecentSearches();
      recentSearches.clear();
    } catch (_) {}
  }

  Future<void> loadTrendingHashtags() async {
    isLoadingTrending.value = true;
    try {
      final tags = await searchRepository.getTrendingHashtags(limit: 10);
      if (tags.isNotEmpty) {
        trendingHashtags.assignAll(tags);
      } else {
        // Safe fallback hashtags if none recorded yet in DB
        trendingHashtags.assignAll([
          '#Flutter',
          '#Internship',
          '#Hackathon',
          '#AI',
          '#Community',
          '#CADT',
          '#AUB',
        ]);
      }
    } catch (_) {
      trendingHashtags.assignAll([
        '#Flutter',
        '#Internship',
        '#Hackathon',
        '#AI',
        '#Community',
        '#CADT',
        '#AUB',
      ]);
    } finally {
      isLoadingTrending.value = false;
    }
  }

  void retry() {
    performSearch(isRetry: true);
  }

  Future<void> openUserProfile(UserSearchResultModel user) async {
    addRecentSearch(user.fullName.isNotEmpty ? user.fullName : user.username);
    final cleanUsername = user.username.trim().replaceFirst(RegExp(r'^@+'), '');
    await ProfileNavigation.open(
      username: cleanUsername.isNotEmpty ? cleanUsername : user.username,
      userId: user.userId,
    );
  }

  Future<void> openEvent(EventModel event) async {
    addRecentSearch(event.title);
    await Get.to<void>(() => EventDetailsScreen(event: event));
  }

  Future<void> openDiscussion(ForumTopicModel discussion) async {
    addRecentSearch(discussion.title);
    await Get.to<void>(() => ForumDiscussionScreen(discussion: discussion));
  }

  void openPostComments(BuildContext context, CommunityPostModel post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(postId: post.id),
    );
  }
}
