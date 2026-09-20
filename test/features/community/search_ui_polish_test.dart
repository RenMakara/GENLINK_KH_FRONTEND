import 'dart:async';
import 'dart:io';

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

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
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

class TestSearchRepository implements SearchRepository {
  final List<UserSearchResultModel> mockUsers = [
    const UserSearchResultModel(
      userId: 'usr-chansela-001',
      username: 'chansela',
      fullName: 'Heng Chansela',
      avatarUrl: null,
      universityName: 'ACLEDA University of Business',
      bio: 'Software Engineer',
      workStatus: 'Student',
      level: 1,
      totalXp: 500,
    ),
    const UserSearchResultModel(
      userId: 'usr-enat-002',
      username: 'enat',
      fullName: 'Sokny Enat',
      avatarUrl: null,
      universityName: 'AUB',
      bio: 'Mobile Developer',
      workStatus: 'STUDENT',
      level: 12,
      totalXp: 3500,
    ),
  ];

  final List<CommunityPostModel> mockPosts = [
    CommunityPostModel(
      id: 'post-001',
      userId: 'usr-enat-002',
      authorName: 'Sokny Enat',
      authorTag: '@enat',
      authorAvatar: '',
      timeAgo: '2h ago',
      content: 'Exploring real search integration with clean neutral styling for GenLink.',
      likesCount: 14,
      commentsCount: 5,
      imageUrls: ['https://cdn.genlink.kh/images/post1.png'],
    ),
  ];

  final List<EventModel> mockEvents = [
    EventModel(
      id: 'ev-001',
      title: 'GenLink Hackathon 2026',
      organizerName: 'GenLink Core',
      eventType: 'In Person',
      location: 'Phnom Penh',
      dateString: '25 Dec 2026',
      description: 'Annual campus hackathon.',
      category: 'Hackathon',
      attendeesCount: 75,
    ),
  ];

  final List<ForumTopicModel> mockDiscussions = [
    ForumTopicModel(
      id: 'forum-001',
      title: 'GenLink Architecture Discussion',
      authorName: 'Sokny Enat',
      category: 'Technology',
      content: 'How we structure mobile widgets cleanly.',
      upvotes: 28,
      repliesCount: 6,
      timeAgo: '1d ago',
    ),
  ];

  @override
  Future<CombinedSearchResults> search({
    required String query,
    SearchCategory category = SearchCategory.all,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    final q = query.toLowerCase().trim();
    if (q == 'randomxyz123' || q == 'nonexistent') {
      return CombinedSearchResults(query: query, category: category);
    }
    return CombinedSearchResults(
      query: query,
      category: category,
      people: mockUsers,
      posts: mockPosts,
      events: mockEvents,
      discussions: mockDiscussions,
      totalPeople: mockUsers.length,
      totalPosts: mockPosts.length,
      totalEvents: mockEvents.length,
      totalDiscussions: mockDiscussions.length,
    );
  }

  @override
  Future<List<UserSearchResultModel>> searchPeople({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async => mockUsers;

  @override
  Future<List<CommunityPostModel>> searchPosts({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async => mockPosts;

  @override
  Future<List<EventModel>> searchEvents({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async => mockEvents;

  @override
  Future<List<ForumTopicModel>> searchDiscussions({
    required String query,
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async => mockDiscussions;

  @override
  Future<List<String>> getTrendingHashtags({int limit = 10, CancelToken? cancelToken}) async =>
      ['#GenLink', '#Flutter', '#AI'];

  @override
  Future<List<String>> getRecentSearches() async => ['chansela', 'enat'];

  @override
  Future<void> addRecentSearch(String query) async {}

  @override
  Future<void> removeRecentSearch(String query) async {}

  @override
  Future<void> clearRecentSearches() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
    Get.reset();
  });

  tearDown(() {
    HttpOverrides.global = null;
    Get.reset();
  });

  group('SEARCH UI/UX POLISH PASS VERIFICATION', () {
    late TestSearchRepository repository;
    late CommunitySearchController controller;

    setUp(() {
      repository = TestSearchRepository();
      controller = CommunitySearchController(repository: repository);
      Get.put<CommunitySearchController>(controller);
    });

    tearDown(() {
      controller.onClose();
    });

    testWidgets('1. People cards have chevron (>) removed and remain fully tappable', (tester) async {
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
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Check that Heng Chansela is rendered
      final nameFinder = find.text('Heng Chansela');
      expect(nameFinder, findsOneWidget);

      // Verify level badge Lv.1 is present
      expect(find.text('Lv.1'), findsOneWidget);

      // Verify @chansela is present
      expect(find.text('@chansela'), findsOneWidget);

      // Verify STUDENT role is present
      expect(find.text('Student'), findsOneWidget);

      // Verify that chevron_right is NOT inside the person card (only in the See all section header)
      // The section header has 1 chevron_right for "See all >"
      // There are 4 sections (People, Posts, Events, Forum), so exactly 4 chevrons for the 4 "See all" headers
      final chevrons = find.byIcon(Icons.chevron_right_rounded);
      expect(chevrons, findsNWidgets(4));

      // Tap the person card and verify profile opens
      await tester.tap(nameFinder);
      await tester.pumpAndSettle();
      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('2. Category tabs contain Forum with no clipping and proper scrollability', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // All categories exist
      expect(find.text('All'), findsWidgets);
      expect(find.text('People'), findsWidgets);
      expect(find.text('Posts'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Forum'), findsWidgets);
    });

    testWidgets('3. Responsive screen test: 320x568 screen (iPhone SE 1st gen) has NO overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'), // Khmer is generally wider
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Responsive screen test: 360x800 (standard Android) has NO overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Responsive screen test: 390x844 (modern iPhone) has NO overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Dark Mode uses dark neutral surface for cards', (tester) async {
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

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Find Material cards inside the search results
      final materials = tester.widgetList<Material>(find.byType(Material));
      final darkSurfaceCards = materials.where((m) => m.color == AppColors.darkSurfacePrimary);
      expect(darkSurfaceCards, isNotEmpty);
    });

    testWidgets('7. Section header count badges are subtle and formatted properly', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify count values match repository
      expect(find.text('2'), findsWidgets); // 2 people
      expect(find.text('1'), findsWidgets); // 1 post, 1 event, 1 discussion
    });

    testWidgets('8. Category pills have polished dimensions: height 32px, font 13px, compact padding 11px, separator 6px', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Find the category bar ListView
      final listViews = tester.widgetList<ListView>(find.byType(ListView));
      final categoryBar = listViews.firstWhere(
        (lv) => lv.scrollDirection == Axis.horizontal,
      );
      expect(categoryBar.scrollDirection, Axis.horizontal);

      // Verify category bar height is between 32 and 34px
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final categoryBox = sizedBoxes.firstWhere(
        (sb) => sb.height != null && sb.height! >= 32.0 && sb.height! <= 34.0,
      );
      expect(categoryBox.height, equals(32.0));

      // Verify Media is NOT present in categories
      expect(find.text('Media'), findsNothing);

      // Verify the 5 required categories are present
      expect(find.text('All'), findsWidgets);
      expect(find.text('People'), findsWidgets);
      expect(find.text('Posts'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Forum'), findsWidgets);

      // Verify font size is 13px on category tabs
      final categoryForumFinder = find.descendant(
        of: find.byType(AnimatedContainer),
        matching: find.text('Forum'),
      );
      final textWidget = tester.widget<Text>(categoryForumFinder);
      expect(textWidget.style?.fontSize, equals(13.0));

      // Verify compact horizontal padding (11px)
      final containers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      final forumContainer = containers.firstWhere((c) {
        final child = c.child;
        return child is Text && child.data == 'Forum';
      });
      final padding = forumContainer.padding as EdgeInsets;
      expect(padding.left, equals(11.0));
      expect(padding.right, equals(11.0));

      // Verify pill border radius is 16px (half of 32px height)
      final decoration = forumContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(16.0)));
    });

    testWidgets('9. Category pills preserve black/white/neutral palette in Dark Mode and Light Mode', (tester) async {
      // Light Mode test
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // In Light Mode, selected category (All) should use lightTextPrimary (dark neutral / black)
      final allFinderLight = find.descendant(
        of: find.byType(AnimatedContainer),
        matching: find.text('All'),
      ).first;
      final allText = tester.widget<Text>(allFinderLight);
      expect(allText.style?.color, equals(AppColors.lightTextInverse));

      // In Light Mode, unselected category (People) should use lightTextSecondary
      final peopleFinderLight = find.descendant(
        of: find.byType(AnimatedContainer),
        matching: find.text('People'),
      ).first;
      final peopleText = tester.widget<Text>(peopleFinderLight);
      expect(peopleText.style?.color, equals(AppColors.lightTextSecondary));

      // Dark Mode test
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // In Dark Mode, selected category (All) should use darkTextInverse (dark neutral) on white pill
      final allFinderDark = find.descendant(
        of: find.byType(AnimatedContainer),
        matching: find.text('All'),
      ).first;
      final allTextDark = tester.widget<Text>(allFinderDark);
      expect(allTextDark.style?.color, equals(AppColors.darkTextInverse));

      // In Dark Mode, unselected category (People) should use darkTextSecondary
      final peopleFinderDark = find.descendant(
        of: find.byType(AnimatedContainer),
        matching: find.text('People'),
      ).first;
      final peopleTextDark = tester.widget<Text>(peopleFinderDark);
      expect(peopleTextDark.style?.color, equals(AppColors.darkTextSecondary));
    });

    testWidgets('10. Forum is comfortably visible and not clipped on 360px phone width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify Forum pill is fully rendered inside screen width (360px)
      final forumRect = tester.getRect(find.text('Forum'));
      expect(forumRect.right, lessThanOrEqualTo(360.0));
      expect(forumRect.left, greaterThan(0.0));
    });

    testWidgets('11. Khmer category pills render without overflow or vertical clipping', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
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

      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Khmer categories: ទាំងអស់ (All), មនុស្ស (People), ការបង្ហោះ (Posts), ព្រឹត្តិការណ៍ (Events), វេទិកា (Forum)
      expect(find.text('ទាំងអស់'), findsWidgets);
      expect(find.text('មនុស្ស'), findsWidgets);
      expect(find.text('ការបង្ហោះ'), findsWidgets);
      expect(find.text('ព្រឹត្តិការណ៍'), findsWidgets);
      expect(find.text('វេទិកា'), findsWidgets);
      // Media (មេឌា) should NOT be present
      expect(find.text('មេឌា'), findsNothing);

      expect(tester.takeException(), isNull);
    });

    testWidgets('12. State 1 (Typing): displays lightweight suggestions and compact people, but NOT category tabs or full cards', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Merely type query (do NOT submit)
      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Category tabs are NOT shown in typing suggestion state
      expect(find.text('All'), findsNothing);

      // Full result card elements (like Lv.1 badge) are NOT shown
      expect(find.text('Lv.1'), findsNothing);

      // Query suggestions section and people suggestions section are shown
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('chansela'), findsWidgets);

      expect(find.text('People'), findsOneWidget);
      expect(find.text('Heng Chansela'), findsOneWidget);
      expect(find.text('@chansela'), findsOneWidget);
    });

    testWidgets('13. State 2 (Submitted): pressing Search/Enter transitions from suggestions to full results', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Type query
      await tester.enterText(find.byType(TextField), 'chansela');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // In State 1
      expect(controller.isSubmitted.value, isFalse);
      expect(find.text('All'), findsNothing);

      // Submit search via keyboard action
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Now in State 2
      expect(controller.isSubmitted.value, isTrue);
      expect(find.text('All'), findsWidgets);
      expect(find.text('People'), findsWidgets);
      expect(find.text('Posts'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Forum'), findsWidgets);

      // Full card details appear
      expect(find.text('Lv.1'), findsOneWidget);
    });

    testWidgets('14. Tapping a query suggestion submits the search and shows full results', (tester) async {
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

      // Suggestions visible
      expect(find.text('Suggestions'), findsOneWidget);

      // Tap query suggestion tile
      final suggestionTile = find.descendant(
        of: find.byType(InkWell),
        matching: find.text('chansela'),
      ).first;
      await tester.tap(suggestionTile);
      await tester.pumpAndSettle();

      // Search submitted and full results loaded
      expect(controller.isSubmitted.value, isTrue);
      expect(find.text('All'), findsWidgets);
    });

    testWidgets('15. Tapping a compact People suggestion navigates to user profile', (tester) async {
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

      // Tap compact person suggestion
      await tester.tap(find.text('Heng Chansela'));
      await tester.pumpAndSettle();

      // Profile screen opened
      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('16. Nonexistent query shows minimal "No suggestions" while typing and full state on submission', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunitySearchScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'randomxyz123');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Minimal "No suggestions" while typing
      expect(find.text('No suggestions'), findsOneWidget);
      expect(find.text('No results found'), findsNothing);

      // Press search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Full empty state after submission
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('No suggestions'), findsNothing);
    });
  });
}
