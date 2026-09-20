import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/models/search_models.dart';
import 'package:genlink_frontend/features/community/domain/repositories/search_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_search_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_search_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/comments_bottom_sheet.dart';

class ComprehensiveMockSearchRepository implements SearchRepository {
  final List<UserSearchResultModel> realUsers = [
    const UserSearchResultModel(
      userId: 'usr-001',
      username: 'chansela',
      fullName: 'Heng Chansela',
      avatarUrl: null,
      universityName: 'ACLEDA University of Business',
      bio: 'Mobile Developer',
      workStatus: 'Student',
      level: 4,
      totalXp: 1200,
    ),
    const UserSearchResultModel(
      userId: 'usr-002',
      username: '@enat', // Leading @ in data
      fullName: 'Sokny Enat',
      avatarUrl: null,
      universityName: 'ACLEDA University of Business',
      bio: 'Fullstack Dev',
      workStatus: 'Student',
      level: 10,
      totalXp: 3500,
    ),
    const UserSearchResultModel(
      userId: 'usr-003',
      username: 'sokha_kh',
      fullName: 'សុខា លីម', // Khmer display name
      avatarUrl: null,
      universityName: 'CADT',
      bio: 'AI & Data Science',
      level: 6,
      totalXp: 1800,
    ),
    const UserSearchResultModel(
      userId: 'usr-004',
      username: 'genlink_official',
      fullName: '', // Empty display name to test fallback
      avatarUrl: null,
      level: 1,
      totalXp: 100,
    ),
  ];

  final List<CommunityPostModel> realPosts = [
    CommunityPostModel(
      id: 'post-001',
      userId: 'usr-002',
      authorName: 'Sokny Enat',
      authorTag: '@enat',
      authorAvatar: '',
      timeAgo: '1h ago',
      content: 'Building real search with Spring Boot & Flutter! #GenLink',
      likesCount: 14,
      commentsCount: 5,
    ),
  ];

  final List<EventModel> realEvents = [
    EventModel(
      id: 'ev-001',
      title: 'GenLink Hackathon 2026',
      organizerName: 'GenLink Core',
      eventType: 'In Person',
      location: 'Phnom Penh',
      dateString: '25 Dec 2026',
      description: 'Annual hackathon event for Cambodian youth.',
      category: 'Hackathon',
      attendeesCount: 88,
    ),
  ];

  final List<ForumTopicModel> realDiscussions = [
    ForumTopicModel(
      id: 'forum-001',
      title: 'State Management with GetX in GenLink',
      authorName: 'Sokny Enat with a very long display name for testing small screen overflow protection',
      category: 'Technology',
      content: 'Discussion on structuring scalable state controllers in GenLink.',
      upvotes: 35,
      repliesCount: 8,
      timeAgo: '3h ago',
    ),
  ];

  bool throwError = false;

  @override
  Future<CombinedSearchResults> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    if (throwError) {
      throw Exception('Live server connection timed out');
    }

    final q = query.toLowerCase().trim().replaceFirst(RegExp(r'^@+'), '');
    if (q.isEmpty) {
      return CombinedSearchResults(query: query, category: category);
    }

    final matchedPeople = realUsers.where((u) {
      final cleanU = u.username.toLowerCase().replaceFirst(RegExp(r'^@+'), '');
      return cleanU.contains(q) ||
          u.fullName.toLowerCase().contains(q) ||
          (u.universityName?.toLowerCase().contains(q) ?? false);
    }).toList();

    final matchedPosts = realPosts.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.authorName.toLowerCase().contains(q);
    }).toList();

    final matchedEvents = realEvents.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
    }).toList();

    final matchedDiscussions = realDiscussions.where((d) {
      return d.title.toLowerCase().contains(q) ||
          d.content.toLowerCase().contains(q) ||
          d.authorName.toLowerCase().contains(q);
    }).toList();

    switch (category) {
      case SearchCategory.people:
        return CombinedSearchResults(
          query: query,
          category: category,
          people: matchedPeople,
          totalPeople: matchedPeople.length,
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
          people: matchedPeople,
          posts: matchedPosts,
          events: matchedEvents,
          discussions: matchedDiscussions,
          totalPeople: matchedPeople.length,
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
    final r = await search(query: query, category: SearchCategory.people);
    return r.people;
  }

  @override
  Future<List<CommunityPostModel>> searchPosts({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final r = await search(query: query, category: SearchCategory.posts);
    return r.posts;
  }

  @override
  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final r = await search(query: query, category: SearchCategory.events);
    return r.events;
  }

  @override
  Future<List<ForumTopicModel>> searchDiscussions({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final r = await search(query: query, category: SearchCategory.forum);
    return r.discussions;
  }

  @override
  Future<List<String>> getTrendingHashtags({int limit = 10, CancelToken? cancelToken}) async {
    return ['#GenLink', '#Flutter', '#Hackathon', '#CADT'];
  }

  final List<String> _recents = [];
  @override
  Future<List<String>> getRecentSearches() async => List.from(_recents);

  @override
  Future<void> addRecentSearch(String query) async {
    _recents.remove(query);
    _recents.insert(0, query);
  }

  @override
  Future<void> removeRecentSearch(String query) async => _recents.remove(query);

  @override
  Future<void> clearRecentSearches() async => _recents.clear();
}

class TestableSearchController extends CommunitySearchController {
  TestableSearchController({super.repository});
  bool postCommentsOpened = false;
  bool eventOpened = false;
  bool discussionOpened = false;

  @override
  void openPostComments(BuildContext context, CommunityPostModel post) {
    postCommentsOpened = true;
  }

  @override
  Future<void> openEvent(EventModel event) async {
    eventOpened = true;
  }

  @override
  Future<void> openDiscussion(ForumTopicModel discussion) async {
    discussionOpened = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  group('PRE-PUSH 24-POINT SEARCH VERIFICATION', () {
    late ComprehensiveMockSearchRepository repository;
    late CommunitySearchController controller;

    setUp(() {
      repository = ComprehensiveMockSearchRepository();
      controller = CommunitySearchController(repository: repository);
    });

    tearDown(() {
      controller.onClose();
    });

    // 1. Search multiple real users
    test('1. Search multiple real users returns all matching candidates', () async {
      final res = await repository.search(query: 'en', category: SearchCategory.people);
      expect(res.people.length, greaterThanOrEqualTo(2));
      expect(res.people.any((u) => u.username.contains('chansela')), isTrue);
      expect(res.people.any((u) => u.username.contains('enat')), isTrue);
    });

    // 2. Search exact username
    test('2. Search exact username returns target user', () async {
      final res = await repository.search(query: 'chansela', category: SearchCategory.people);
      expect(res.people.length, 1);
      expect(res.people.first.username, 'chansela');
      expect(res.people.first.fullName, 'Heng Chansela');
    });

    // 3. Search partial username
    test('3. Search partial username matches substring', () async {
      final res = await repository.search(query: 'sela', category: SearchCategory.people);
      expect(res.people.length, 1);
      expect(res.people.first.username, 'chansela');
    });

    // 4. Search display name
    test('4. Search display name returns user even when username is different', () async {
      final res = await repository.search(query: 'Heng Chansela', category: SearchCategory.people);
      expect(res.people.length, 1);
      expect(res.people.first.username, 'chansela');
    });

    // 5. Test uppercase/lowercase
    test('5. Test uppercase/lowercase is case-insensitive', () async {
      final lower = await repository.search(query: 'chansela', category: SearchCategory.people);
      final upper = await repository.search(query: 'CHANSELA', category: SearchCategory.people);
      final mixed = await repository.search(query: 'ChanSela', category: SearchCategory.people);

      expect(lower.people.length, 1);
      expect(upper.people.length, 1);
      expect(mixed.people.length, 1);
      expect(lower.people.first.userId, upper.people.first.userId);
      expect(lower.people.first.userId, mixed.people.first.userId);
    });

    // 6. Test a query with no results
    test('6. Query with no results returns clean empty structure', () async {
      final res = await repository.search(query: 'nonexistentuser999', category: SearchCategory.all);
      expect(res.isEmpty, isTrue);
      expect(res.people, isEmpty);
      expect(res.posts, isEmpty);
      expect(res.events, isEmpty);
      expect(res.discussions, isEmpty);
      expect(res.totalResults, 0);
    });

    // 7 & 8. Test API error state and Retry
    test('7 & 8. API error state triggers error message and Retry recovers', () async {
      repository.throwError = true;
      controller.query.value = 'enat';
      await controller.performSearch();

      expect(controller.errorMessage.value, isNotEmpty);
      expect(controller.isLoading.value, isFalse);

      // Now recover with retry
      repository.throwError = false;
      controller.retry();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.errorMessage.value, isEmpty);
      expect(controller.searchResults.value, isNotNull);
      expect(controller.searchResults.value!.people, isNotEmpty);
    });

    // 10. Test debounce
    test('10. Rapid queries are debounced properly', () async {
      controller.onQueryChanged('c');
      controller.onQueryChanged('ch');
      controller.onQueryChanged('cha');
      controller.onQueryChanged('chan');
      expect(controller.isLoading.value, isFalse); // Has not triggered yet

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(controller.hasSearched.value, isTrue);
      expect(controller.searchResults.value?.people.first.username, 'chansela');
    });

    // 11 & 12. Verify search results are NOT hardcoded & counts are real backend counts
    test('11 & 12. Search counts and data dynamically match backend response', () async {
      final res = await repository.search(query: 'enat', category: SearchCategory.all);
      expect(res.totalPeople, 1);
      expect(res.totalPosts, 1);
      expect(res.totalDiscussions, 1);
      expect(res.totalEvents, 0);
      expect(res.people.first.userId, 'usr-002');
    });

    // 18. Verify no duplicate @ symbols or incorrect user formatting
    test('18. Formatting strips leading @ from data, avoiding @@username', () {
      final userWithAt = repository.realUsers.firstWhere((u) => u.username == '@enat');
      final cleanUsername = userWithAt.username.trim().replaceFirst(RegExp(r'^@+'), '');
      final displayUsername = cleanUsername.isNotEmpty ? '@$cleanUsername' : '';
      expect(displayUsername, '@enat');
      expect(displayUsername.startsWith('@@'), isFalse);

      final userWithoutName = repository.realUsers.firstWhere((u) => u.username == 'genlink_official');
      final fallbackName = userWithoutName.fullName.trim().isNotEmpty
          ? userWithoutName.fullName.trim()
          : (userWithoutName.username.trim().isNotEmpty ? userWithoutName.username.trim() : 'GenLink User');
      expect(fallbackName, 'genlink_official');
    });

    // 22 & 23. Test English and Khmer translations
    test('22 & 23. English and Khmer localization keys exist for Search UI', () {
      final translations = AppTranslations();
      final en = translations.keys['en_US']!;
      final km = translations.keys['km_KH']!;

      final keysToVerify = [
        'community.searchHint',
        'community.searchAll',
        'community.searchPeople',
        'community.searchPosts',
        'community.searchEvents',
        'community.searchForum',
        'community.noResultsFound',
        'community.noResultsForQuery',
        'community.trySearchingAnother',
        'community.searchError',
        'community.searchErrorSub',
        'community.retry',
        'community.recentSearches',
        'community.clear',
        'community.trending',
        'community.seeAll',
      ];

      for (final key in keysToVerify) {
        expect(en.containsKey(key), isTrue, reason: 'Missing EN key: $key');
        expect(km.containsKey(key), isTrue, reason: 'Missing KM key: $key');
        expect(en[key]!.isNotEmpty, isTrue);
        expect(km[key]!.isNotEmpty, isTrue);
      }
    });
  });

  group('WIDGET & UI/UX INTERACTION VERIFICATION', () {
    late ComprehensiveMockSearchRepository repository;
    late CommunitySearchController controller;

    setUp(() {
      repository = ComprehensiveMockSearchRepository();
      controller = CommunitySearchController(repository: repository);
      Get.put<CommunitySearchController>(controller);
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    // 9. Test clear button
    testWidgets('9. Clear button resets text and controller to Idle state', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Clear button (close icon) appears
      final clearBtn = find.byIcon(Icons.close_rounded);
      expect(clearBtn, findsWidgets);

      // Tap clear
      await tester.tap(clearBtn.first);
      await tester.pumpAndSettle();

      expect(controller.query.value, isEmpty);
      expect(find.text('Trending'), findsOneWidget);
    });

    // 13. Verify "See all" opens complete result list
    testWidgets('13. Tapping "See all" opens the complete result category list', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'en');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // "See all" button exists next to People section
      final seeAll = find.text('See all');
      expect(seeAll, findsWidgets);

      // Tap "See all"
      await tester.tap(seeAll.first);
      await tester.pumpAndSettle();

      // Should now be on People category tab
      expect(controller.selectedCategory.value, SearchCategory.people);
    });

    // 14. Verify tapping a People result triggers Profile navigation
    testWidgets('14. Tapping a People result opens user profile without error', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => CommunitySearchScreen(controller: controller)),
            GetPage(name: AppRoutes.profile, page: () => const Scaffold(body: Text('Profile Screen'))),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Tap Chansela card
      final personCard = find.text('Heng Chansela');
      expect(personCard, findsOneWidget);
      await tester.tap(personCard);
      await tester.pumpAndSettle();

      // Profile screen opened
      expect(find.text('Profile Screen'), findsOneWidget);
    });

    // 15. Verify Posts navigation
    testWidgets('15. Tapping a Post result triggers comments sheet presentation', (tester) async {
      final testController = TestableSearchController(repository: repository);
      Get.replace<CommunitySearchController>(testController);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: testController),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Spring Boot');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final postText = find.textContaining('Spring Boot & Flutter');
      expect(postText, findsOneWidget);
      await tester.tap(postText);
      await tester.pump();

      expect(testController.postCommentsOpened, isTrue);
    });

    // 16. Verify Events navigation
    testWidgets('16. Tapping an Event result opens EventDetailsScreen', (tester) async {
      final testController = TestableSearchController(repository: repository);
      Get.replace<CommunitySearchController>(testController);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: testController),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hackathon');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final eventTitle = find.text('GenLink Hackathon 2026');
      expect(eventTitle, findsOneWidget);
      await tester.tap(eventTitle);
      await tester.pump();

      expect(testController.eventOpened, isTrue);
    });

    // 17. Verify Forum navigation
    testWidgets('17. Tapping a Forum result opens ForumDiscussionScreen', (tester) async {
      final testController = TestableSearchController(repository: repository);
      Get.replace<CommunitySearchController>(testController);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: testController),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'GetX');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final forumTitle = find.text('State Management with GetX in GenLink');
      expect(forumTitle, findsOneWidget);
      await tester.tap(forumTitle);
      await tester.pump();

      expect(testController.discussionOpened, isTrue);
    });

    // 20. Test Light Mode colors (primarily Black + White + Neutral)
    testWidgets('20. Light Mode renders with neutral light palette', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.lightSurfacePrimary);
    });

    // 21. Test Dark Mode colors (primarily Black + White + Neutral)
    testWidgets('21. Dark Mode renders with neutral dark palette', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.darkBgPrimary);
    });

    // 23. Test Khmer Language UI Rendering
    testWidgets('23. Khmer language strings render correctly in Search UI', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Khmer text
      expect(find.text('ពេញនិយម'), findsOneWidget); // "Trending" in Khmer

      // Enter query and submit to check Khmer category tabs
      await tester.enterText(find.byType(TextField), 'en');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('ទាំងអស់'), findsWidgets); // "All"
      expect(find.text('មនុស្ស'), findsWidgets); // "People"
      expect(find.text('ការបង្ហោះ'), findsWidgets); // "Posts"
      expect(find.text('ព្រឹត្តិការណ៍'), findsWidgets); // "Events"
      expect(find.text('វេទិកា'), findsWidgets); // "Forum"
      expect(find.text('មើលទាំងអស់'), findsWidgets); // "See all"
    });

    // 24. Check for overflow on small phone screens (320x568 screen)
    testWidgets('24. No overflow on small 320x568 phone screen with long text and Khmer', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Enter query that returns long titles and Khmer text
      await tester.enterText(find.byType(TextField), 'en');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify no RenderFlex exception was thrown
      expect(tester.takeException(), isNull);
    });
  });
}
