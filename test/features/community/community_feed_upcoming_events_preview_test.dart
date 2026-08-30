import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return [
      CommunityPostModel(
        id: 'post_1',
        userId: 'user_1',
        authorName: 'Sokny Enath',
        authorTag: 'sokny',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Excited for the upcoming Flutter workshop this weekend!',
        imageUrls: const [],
        visibility: 'Public',
        community: 'All GenLink',
      ),
    ];
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'post_new',
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
    );
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: 'Sample post',
      imageUrls: const [],
      visibility: 'Public',
      community: 'All GenLink',
    );
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: const [],
      visibility: 'Public',
      community: 'All GenLink',
    );
  }

  @override
  Future<bool> deletePost(String postId) async => true;
  @override
  Future<bool> toggleLike(String postId) async => true;
  @override
  Future<bool> toggleBookmark(String postId) async => true;
  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async => true;
  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;
  @override
  Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'}) async => true;
  @override
  Future<List<CommentModel>> getComments(String postId) async => [];
  @override
  Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async {
    return CommentModel(
      id: 'c1',
      postId: postId,
      userId: 'user_1',
      userName: 'Tester',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
    );
  }
  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;
  @override
  Future<bool> followUser(String userId) async => true;
  @override
  Future<bool> unfollowUser(String userId) async => true;
  @override
  Future<bool> checkIsFollowing(String userId) async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Community Feed Mixed Content & Discovery Previews Tests', () {
    testWidgets('1. Verify Feed renders Post Composer and Stories row without arrows', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Stories row renders
      expect(find.byType(StoryTrayWidget), findsOneWidget);
      // Verify NO right arrow / chevron exists on Stories row
      expect(find.text('Stories >'), findsNothing);

      // Verify Post Composer renders "What's on your mind?" and action buttons
      expect(find.text("What's on your mind?"), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Feeling'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);

      // Tapping composer opens CreatePostScreen
      await tester.tap(find.text("What's on your mind?"));
      await tester.pumpAndSettle();
      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    testWidgets('2. Verify Upcoming Events preview renders 1-2 compact event cards with prominent date and location', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Upcoming Events'), findsOneWidget);
      final seeAllFinders = find.text('See all');
      expect(seeAllFinders, findsWidgets);

      // Verify 1-2 Real Event Titles from controller
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
      expect(find.text('AI in Everyday Life'), findsOneWidget);

      // Verify Date blocks: day & month parsed from dateString
      expect(find.text('25'), findsOneWidget);
      expect(find.text('JUL'), findsWidgets);
      expect(find.text('26'), findsOneWidget);

      // Verify Location and Online indicators
      expect(find.textContaining('ACLEDA University'), findsOneWidget);
      expect(find.text('🌐 Online Event'), findsOneWidget);

      // Verify Join buttons
      expect(find.text('Join'), findsWidgets);
    });

    testWidgets('3. Verify RSVP / Join button toggles state between Join and Joined', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // First event is not RSVPed initially
      expect(controller.events[0].isRsvped, isFalse);

      // Tap first Join button
      final joinButtons = find.text('Join');
      expect(joinButtons, findsWidgets);
      await tester.tap(joinButtons.first);
      await tester.pumpAndSettle();

      // Controller state should now be RSVPed
      expect(controller.events[0].isRsvped, isTrue);
      expect(find.text('Joined'), findsOneWidget);

      // Tap Joined button to un-RSVP
      await tester.tap(find.text('Joined'));
      await tester.pumpAndSettle();

      // Controller state should revert to not RSVPed
      expect(controller.events[0].isRsvped, isFalse);
      expect(find.text('Joined'), findsNothing);
    });

    testWidgets('4. Verify tapping Upcoming Events "See all" navigates directly to Event tab', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));

      // Tap first "See all" (Upcoming Events)
      final seeAllFinders = find.text('See all');
      await tester.tap(seeAllFinders.first);
      await tester.pumpAndSettle();

      // Controller category should now be 'Event'
      expect(controller.selectedCategory.value, equals('Event'));
      // Event tab has FeaturedEventsCarousel and Filter button
      expect(find.byType(FeaturedEventsCarousel), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('5. Verify tapping an Event card opens EventDetailsScreen for that event', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Flutter Workshop event title
      await tester.tap(find.text('Flutter Workshop 2026'));
      await tester.pumpAndSettle();

      // Should open EventDetailsScreen
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Flutter Workshop 2026'), findsWidgets);
      expect(find.text('ACLEDA University, Phnom Penh'), findsWidgets);
    });

    testWidgets('6. Verify Trending Discussions preview renders and tapping "See all" navigates to Forum tab', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Trending Discussions header
      expect(find.text('Trending Discussions'), findsOneWidget);

      // Verify discussion preview title
      expect(
        find.text('Best practices for GetX state management in Flutter Community App'),
        findsOneWidget,
      );

      // Tap second "See all" (Trending Discussions)
      final seeAllFinders = find.text('See all');
      await tester.tap(seeAllFinders.last);
      await tester.pumpAndSettle();

      // Controller category should now be 'Forum'
      expect(controller.selectedCategory.value, equals('Forum'));
      expect(find.text('Latest Discussions'), findsOneWidget);
    });

    testWidgets('7. Verify tapping a Discussion card opens ForumDiscussionScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on discussion title
      await tester.tap(
        find.text('Best practices for GetX state management in Flutter Community App'),
      );
      await tester.pumpAndSettle();

      // Should open ForumDiscussionScreen
      expect(find.byType(ForumDiscussionScreen), findsOneWidget);
    });

    testWidgets('8. Verify Empty State cleanly hides preview when controller has no events or discussions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      controller.events.clear();
      controller.forumPinnedDiscussions.clear();
      controller.forumLatestDiscussions.clear();
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Upcoming Events & Trending Discussions sections should not render
      expect(find.text('Upcoming Events'), findsNothing);
      expect(find.text('Trending Discussions'), findsNothing);
    });

    testWidgets('9. Verify Feed composer renders in Khmer without redundant Post label', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify localized Khmer composer placeholder
      expect(find.text('តើអ្នកកំពុងគិតអ្វី?'), findsOneWidget);
      expect(find.text('រូបថត'), findsOneWidget);
      expect(find.text('វីដេអូ'), findsOneWidget);
      expect(find.text('អារម្មណ៍'), findsOneWidget);
      expect(find.text('ទីតាំង'), findsOneWidget);
    });

    testWidgets('10. Verify Upcoming Events preview in Khmer renders localized strings', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Upcoming Events header in Khmer
      expect(find.text('ព្រឹត្តិការណ៍នាពេលខាងមុខ'), findsOneWidget);
      expect(find.text('មើលទាំងអស់'), findsWidgets);
      expect(find.text('ចូលរួម'), findsWidgets);
      expect(find.text('🌐 ព្រឹត្តិការណ៍អនឡាញ'), findsOneWidget);
    });

    testWidgets('11. Verify Feed and compact event cards adapt responsively to small screens (320px)', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
    });

    testWidgets('12. Verify Feed renders correctly in Light Mode and Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // 1. Light Mode
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Upcoming Events'), findsOneWidget);

      // 2. Dark Mode
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Upcoming Events'), findsOneWidget);
    });
  });
}
