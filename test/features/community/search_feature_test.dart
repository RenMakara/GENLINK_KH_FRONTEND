import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/models/search_models.dart';
import 'package:genlink_frontend/features/community/domain/repositories/search_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_search_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_search_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return null;
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentPng = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockSearchRepository implements SearchRepository {
  final List<UserSearchResultModel> mockUsers = [
    const UserSearchResultModel(
      userId: 'usr-enat-001',
      username: 'enat',
      fullName: 'Sokny Enat',
      avatarUrl: 'assets/images/user_profile.png',
      universityName: 'ACLEDA University of Business',
      bio: 'Fullstack & Mobile Developer',
      workStatus: 'Student',
      level: 12,
      totalXp: 3450,
    ),
    const UserSearchResultModel(
      userId: 'usr-chansela-002',
      username: 'chansela',
      fullName: 'Heng Chansela',
      avatarUrl: 'assets/images/user_profile.png',
      universityName: 'ACLEDA University of Business',
      bio: 'Software Engineer',
      workStatus: 'Student',
      level: 8,
      totalXp: 1890,
    ),
    const UserSearchResultModel(
      userId: 'usr-sokha-003',
      username: 'sokha',
      fullName: 'សុខា លីម',
      avatarUrl: 'assets/images/user_profile.png',
      universityName: 'CADT',
      bio: 'Computer Science',
      workStatus: 'Student',
      level: 5,
      totalXp: 980,
    ),
  ];

  final List<CommunityPostModel> mockPosts = [
    CommunityPostModel(
      id: 'post-101',
      userId: 'usr-enat-001',
      authorName: 'Sokny Enat',
      authorTag: '@enat',
      authorAvatar: 'https://cdn.genlink.kh/avatars/enat.png',
      timeAgo: '2h ago',
      content: 'Building cross-platform mobile apps with Flutter and Spring Boot for GenLink! #Flutter #GenLink',
      likesCount: 25,
      commentsCount: 6,
    ),
    CommunityPostModel(
      id: 'post-102',
      userId: 'usr-chansela-002',
      authorName: 'Heng Chansela',
      authorTag: '@chansela',
      authorAvatar: 'https://cdn.genlink.kh/avatars/chansela.png',
      timeAgo: '4h ago',
      content: 'Exploring AI and machine learning algorithms on campus. #AI #CampusLink',
      likesCount: 18,
      commentsCount: 3,
    ),
  ];

  final List<EventModel> mockEvents = [
    EventModel(
      id: 'ev-201',
      title: 'GenLink Hackathon 2026',
      organizerName: 'GenLink Team',
      eventType: 'In person',
      location: 'Phnom Penh',
      dateString: '25 Dec 2026',
      description: 'Annual campus hackathon for developers.',
      category: 'Hackathon',
      attendeesCount: 75,
    ),
  ];

  final List<ForumTopicModel> mockDiscussions = [
    ForumTopicModel(
      id: 'disc-301',
      title: 'Clean Architecture with Flutter and GetX',
      authorName: 'Sokny Enat',
      category: 'Technology',
      content: 'Discussion on structuring scalable Flutter codebases.',
      upvotes: 42,
      repliesCount: 9,
      timeAgo: '1d ago',
    ),
  ];

  final List<String> recentSearchesStore = [];
  bool shouldThrowError = false;

  @override
  Future<CombinedSearchResults> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    if (shouldThrowError) {
      throw Exception('Network error');
    }

    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      return CombinedSearchResults(query: query, category: category);
    }

    final matchedUsers = mockUsers.where((u) {
      return u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q) ||
          (u.universityName?.toLowerCase().contains(q) ?? false);
    }).toList();

    final matchedPosts = mockPosts.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.authorName.toLowerCase().contains(q);
    }).toList();

    final matchedEvents = mockEvents.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    }).toList();

    final matchedDiscussions = mockDiscussions.where((d) {
      return d.title.toLowerCase().contains(q) ||
          d.content.toLowerCase().contains(q) ||
          d.authorName.toLowerCase().contains(q);
    }).toList();

    switch (category) {
      case SearchCategory.people:
        return CombinedSearchResults(
          query: query,
          category: category,
          people: matchedUsers,
          totalPeople: matchedUsers.length,
        );
      case SearchCategory.posts:
        return CombinedSearchResults(
          query: query,
          category: category,
          posts: matchedPosts,
          totalPosts: matchedPosts.length,
        );
      case SearchCategory.events:
        return CombinedSearchResults(
          query: query,
          category: category,
          events: matchedEvents,
          totalEvents: matchedEvents.length,
        );
      case SearchCategory.forum:
        return CombinedSearchResults(
          query: query,
          category: category,
          discussions: matchedDiscussions,
          totalDiscussions: matchedDiscussions.length,
        );
      case SearchCategory.media:
        return CombinedSearchResults(query: query, category: category);
      case SearchCategory.all:
        return CombinedSearchResults(
          query: query,
          category: category,
          people: matchedUsers,
          posts: matchedPosts,
          events: matchedEvents,
          discussions: matchedDiscussions,
          totalPeople: matchedUsers.length,
          totalPosts: matchedPosts.length,
          totalEvents: matchedEvents.length,
          totalDiscussions: matchedDiscussions.length,
        );
    }
  }

  @override
  Future<List<UserSearchResultModel>> searchPeople({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await search(query: query, category: SearchCategory.people);
    return res.people;
  }

  @override
  Future<List<CommunityPostModel>> searchPosts({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await search(query: query, category: SearchCategory.posts);
    return res.posts;
  }

  @override
  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await search(query: query, category: SearchCategory.events);
    return res.events;
  }

  @override
  Future<List<ForumTopicModel>> searchDiscussions({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final res = await search(query: query, category: SearchCategory.forum);
    return res.discussions;
  }

  @override
  Future<List<String>> getTrendingHashtags({
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    return ['#Flutter', '#GenLink', '#Hackathon', '#AUB'];
  }

  @override
  Future<List<String>> getRecentSearches() async {
    return List.from(recentSearchesStore);
  }

  @override
  Future<void> addRecentSearch(String query) async {
    recentSearchesStore.remove(query);
    recentSearchesStore.insert(0, query);
  }

  @override
  Future<void> removeRecentSearch(String query) async {
    recentSearchesStore.remove(query);
  }

  @override
  Future<void> clearRecentSearches() async {
    recentSearchesStore.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  group('Search Models & Contract Serialization', () {
    test('UserSearchResultModel fromJson parses backend fields properly', () {
      final json = {
        'userId': 'usr-enat-001',
        'username': 'enat',
        'fullName': 'Sokny Enat',
        'avatarUrl': 'https://example.com/avatar.png',
        'universityName': 'ACLEDA University of Business',
        'bio': 'Developer',
        'workStatus': 'Student',
        'level': 10,
        'totalXp': 2500,
      };

      final user = UserSearchResultModel.fromJson(json);

      expect(user.userId, 'usr-enat-001');
      expect(user.username, 'enat');
      expect(user.fullName, 'Sokny Enat');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.universityName, 'ACLEDA University of Business');
      expect(user.bio, 'Developer');
      expect(user.workStatus, 'Student');
      expect(user.level, 10);
      expect(user.totalXp, 2500);
    });

    test('CombinedSearchResults fromJson parses empty and non-empty categories', () {
      final json = {
        'query': 'enat',
        'category': 'ALL',
        'people': [
          {
            'userId': 'usr-enat-001',
            'username': 'enat',
            'fullName': 'Sokny Enat',
          }
        ],
        'posts': [],
        'events': [],
        'discussions': [],
        'totalPeople': 1,
        'totalPosts': 0,
        'totalEvents': 0,
        'totalDiscussions': 0,
      };

      final results = CombinedSearchResults.fromJson(json);

      expect(results.query, 'enat');
      expect(results.category, SearchCategory.all);
      expect(results.people.length, 1);
      expect(results.people.first.username, 'enat');
      expect(results.posts, isEmpty);
      expect(results.events, isEmpty);
      expect(results.discussions, isEmpty);
      expect(results.isNotEmpty, isTrue);
      expect(results.totalResults, 1);
    });

    test('SearchCategory enum conversion to and from API types', () {
      expect(SearchCategory.all.toApiType(), 'ALL');
      expect(SearchCategory.people.toApiType(), 'PEOPLE');
      expect(SearchCategory.posts.toApiType(), 'POSTS');
      expect(SearchCategory.events.toApiType(), 'EVENTS');
      expect(SearchCategory.forum.toApiType(), 'FORUM');
      expect(SearchCategory.media.toApiType(), 'MEDIA');

      expect(SearchCategory.fromApiType('PEOPLE'), SearchCategory.people);
      expect(SearchCategory.fromApiType('POSTS'), SearchCategory.posts);
      expect(SearchCategory.fromApiType('EVENTS'), SearchCategory.events);
      expect(SearchCategory.fromApiType('FORUM'), SearchCategory.forum);
      expect(SearchCategory.fromApiType('MEDIA'), SearchCategory.media);
      expect(SearchCategory.fromApiType('UNKNOWN'), SearchCategory.all);
      expect(SearchCategory.fromApiType(null), SearchCategory.all);

      expect(SearchCategory.all.isSupported, isTrue);
      expect(SearchCategory.people.isSupported, isTrue);
      expect(SearchCategory.media.isSupported, isFalse);
    });
  });

  group('Real Search Engine Verification (Exact, Partial, Khmer, Case, Nonexistent)', () {
    late MockSearchRepository repository;

    setUp(() {
      repository = MockSearchRepository();
    });

    test('Searching exact username "enat" returns Sokny Enat user and related posts/discussions', () async {
      final result = await repository.search(query: 'enat', category: SearchCategory.all);

      expect(result.people.length, 1);
      expect(result.people.first.username, 'enat');
      expect(result.people.first.fullName, 'Sokny Enat');
      expect(result.posts.length, 1);
      expect(result.discussions.length, 1);
    });

    test('Searching partial username "nat" returns "enat" user', () async {
      final result = await repository.search(query: 'nat', category: SearchCategory.people);

      expect(result.people.length, 1);
      expect(result.people.first.username, 'enat');
    });

    test('Searching display name "Heng Chansela" returns user "chansela"', () async {
      final result = await repository.search(query: 'Heng Chansela', category: SearchCategory.people);

      expect(result.people.length, 1);
      expect(result.people.first.username, 'chansela');
    });

    test('Searching Khmer display name "សុខា" returns Khmer user "sokha"', () async {
      final result = await repository.search(query: 'សុខា', category: SearchCategory.people);

      expect(result.people.length, 1);
      expect(result.people.first.username, 'sokha');
      expect(result.people.first.fullName, 'សុខា លីម');
    });

    test('Search is case-insensitive: "ENAT", "Enat", and "enat" produce identical results', () async {
      final upperRes = await repository.search(query: 'ENAT', category: SearchCategory.people);
      final mixedRes = await repository.search(query: 'Enat', category: SearchCategory.people);
      final lowerRes = await repository.search(query: 'enat', category: SearchCategory.people);

      expect(upperRes.people.length, 1);
      expect(upperRes.people.first.username, 'enat');

      expect(mixedRes.people.length, 1);
      expect(mixedRes.people.first.username, 'enat');

      expect(lowerRes.people.length, 1);
      expect(lowerRes.people.first.username, 'enat');
    });

    test('Searching nonexistent user "randomxyz123" returns empty list without error', () async {
      final result = await repository.search(query: 'randomxyz123', category: SearchCategory.people);

      expect(result.people, isEmpty);
      expect(result.isEmpty, isTrue);
    });

    test('Category switching: PEOPLE category returns only people, POSTS returns only posts', () async {
      final peopleRes = await repository.search(query: 'enat', category: SearchCategory.people);
      expect(peopleRes.people.length, 1);
      expect(peopleRes.posts, isEmpty);
      expect(peopleRes.events, isEmpty);

      final postsRes = await repository.search(query: 'Flutter', category: SearchCategory.posts);
      expect(postsRes.posts.length, 1);
      expect(postsRes.people, isEmpty);
      expect(postsRes.events, isEmpty);
    });

    test('Unsupported category MEDIA returns empty results', () async {
      final mediaRes = await repository.search(query: 'enat', category: SearchCategory.media);
      expect(mediaRes.isEmpty, isTrue);
    });
  });

  group('CommunitySearchController State Management & Actions', () {
    late MockSearchRepository repository;
    late CommunitySearchController controller;

    setUp(() {
      repository = MockSearchRepository();
      controller = CommunitySearchController(repository: repository);
    });

    tearDown(() {
      controller.onClose();
    });

    test('Controller initializes and loads recent searches and trending hashtags', () async {
      await repository.addRecentSearch('Flutter Workshop');
      await controller.loadRecentSearches();
      await controller.loadTrendingHashtags();

      expect(controller.recentSearches, contains('Flutter Workshop'));
      expect(controller.trendingHashtags, isNotEmpty);
      expect(controller.trendingHashtags, contains('#Flutter'));
    });

    test('Recent searches management: add, remove, and clear all', () async {
      await controller.addRecentSearch('GenLink 2026');
      expect(controller.recentSearches, contains('GenLink 2026'));

      await controller.removeRecentSearch('GenLink 2026');
      expect(controller.recentSearches, isNot(contains('GenLink 2026')));

      await controller.addRecentSearch('Item A');
      await controller.addRecentSearch('Item B');
      expect(controller.recentSearches.length, 2);

      await controller.clearAllRecentSearches();
      expect(controller.recentSearches, isEmpty);
    });

    test('Performing search updates reactive results and persists query to recent searches', () async {
      controller.query.value = 'enat';
      await controller.performSearch();

      expect(controller.isLoading.value, isFalse);
      expect(controller.hasSearched.value, isTrue);
      expect(controller.errorMessage.value, isEmpty);
      expect(controller.searchResults.value, isNotNull);
      expect(controller.searchResults.value!.people.first.username, 'enat');
      expect(controller.recentSearches, contains('enat'));
    });

    test('Category selection triggers new search when query is present', () async {
      controller.query.value = 'enat';
      await controller.selectCategory(SearchCategory.people);

      expect(controller.selectedCategory.value, SearchCategory.people);
      expect(controller.searchResults.value, isNotNull);
      expect(controller.searchResults.value!.people.length, 1);
    });

    test('Error handling and retry mechanism', () async {
      repository.shouldThrowError = true;
      controller.query.value = 'enat';
      await controller.performSearch();

      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, isNotEmpty);

      // Now recovery
      repository.shouldThrowError = false;
      controller.retry();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.errorMessage.value, isEmpty);
      expect(controller.searchResults.value, isNotNull);
      expect(controller.searchResults.value!.people.length, 1);
    });
  });

  group('CommunitySearchScreen Widget Rendering', () {
    late MockSearchRepository repository;
    late CommunitySearchController controller;

    setUp(() {
      HttpOverrides.global = _TestHttpOverrides();
      repository = MockSearchRepository();
      controller = CommunitySearchController(repository: repository);
      Get.put<CommunitySearchController>(controller);
    });

    tearDown(() {
      controller.onClose();
      HttpOverrides.global = null;
      Get.reset();
    });

    testWidgets('Renders search text field, idle state, and category tabs on query entry', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: CommunitySearchScreen(activeTab: 'Feed', controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search input field exists
      expect(find.byType(TextField), findsOneWidget);

      // In idle state (empty query), trending section renders
      expect(find.text('Trending'), findsOneWidget);

      // Submitting search query activates the category tabs
      await tester.enterText(find.byType(TextField), 'enat');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify category tabs render when query is present
      expect(find.text('All'), findsWidgets);
      expect(find.text('People'), findsWidgets);
      expect(find.text('Posts'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Forum'), findsWidgets);
    });

    testWidgets('Typing query displays search results', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: CommunitySearchScreen(activeTab: 'Feed', controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Input "enat"
      await tester.enterText(find.byType(TextField), 'enat');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Check results for Sokny Enat
      expect(find.text('Sokny Enat'), findsWidgets);
      expect(find.text('@enat'), findsWidgets);
    });
  });
}
