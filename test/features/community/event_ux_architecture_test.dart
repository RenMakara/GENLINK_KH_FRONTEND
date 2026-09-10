import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_register_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_featured_events_carousel.dart';

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return [
      CommunityPostModel(
        id: 'post_1',
        userId: 'user_1',
        authorName: 'Sokny Enat',
        authorTag: '@soknyenat',
        authorAvatar: '',
        timeAgo: '15m ago',
        content: 'Excited for learning Flutter architecture!',
        imageUrls: const [],
        visibility: 'Public',
        community: 'All GenLink',
      ),
      CommunityPostModel(
        id: 'post_event_workshop',
        userId: 'user_aub',
        authorName: 'AUB Digital Academy',
        authorTag: '@aub_academy',
        authorAvatar: '',
        isVerified: true,
        timeAgo: '2h ago',
        content: '🚀 Don\'t miss our upcoming Flutter Workshop 2026!',
        likesCount: 88,
        commentsCount: 16,
        sharesCount: 12,
        postType: 'event',
        attachedEvent: EventModel(
          id: 'ev1',
          title: 'Flutter Workshop 2026',
          subtitle: 'Build real-world mobile apps with Flutter from scratch.',
          organizerName: 'AUB Digital Academy',
          eventType: 'In person',
          location: 'ACLEDA University, Phnom Penh',
          dateString: '25 Jul 2026',
          timeString: '9:00 AM – 4:00 PM',
          description: 'Join us for an intensive hands-on workshop on Flutter.',
          category: 'Workshop',
          imageUrl: '',
          attendeesCount: 120,
        ),
        community: 'ACLEDA University of Business (AUB)',
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
      authorName: 'Sokny Enat',
      authorTag: '@soknyenat',
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
    final posts = await getPosts();
    return posts.firstWhere((p) => p.id == postId, orElse: () => posts.first);
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    final posts = await getPosts();
    final post = posts.firstWhere((p) => p.id == postId);
    return post.copyWith(content: content);
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

  group('GenLink Event UX Architecture Full Verification Tests', () {
    testWidgets('1. Home Screen — Featured Events Carousel renders big card with category, title, date, location, attendees', (tester) async {
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Section title
      expect(find.textContaining('FEATURED EVENTS'), findsOneWidget);

      // Top event title and subtitle
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
      expect(find.text('Build real-world mobile apps with Flutter from scratch.'), findsOneWidget);

      // Category badge
      expect(find.text('WORKSHOP'), findsOneWidget);

      // Date & Time
      expect(find.textContaining('25 Jul 2026 · 9:00 AM – 4:00 PM'), findsOneWidget);

      // Location
      expect(find.textContaining('ACLEDA University, Phnom Penh'), findsOneWidget);

      // Attendees count
      expect(find.textContaining('120'), findsOneWidget);

      // View details CTA
      expect(find.text('View details'), findsOneWidget);

      // Tapping card navigates to EventDetailsScreen
      await tester.tap(find.text('Flutter Workshop 2026'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
    });

    testWidgets('2. Community Feed — Event Post renders organizer header, caption, preview card, and social actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final eventPost = CommunityPostModel(
        id: 'post_event_workshop',
        userId: 'user_aub',
        authorName: 'AUB Digital Academy',
        authorTag: '@aub_academy',
        authorAvatar: '',
        isVerified: true,
        timeAgo: '2h ago',
        content: '🚀 Excited to host our upcoming workshop! Check out details 👇',
        likesCount: 88,
        commentsCount: 16,
        sharesCount: 12,
        postType: 'event',
        attachedEvent: EventModel(
          id: 'ev1',
          title: 'Flutter Workshop 2026',
          subtitle: 'Build real-world mobile apps with Flutter from scratch.',
          organizerName: 'AUB Digital Academy',
          eventType: 'In person',
          location: 'ACLEDA University, Phnom Penh',
          dateString: '25 Jul 2026',
          timeString: '9:00 AM – 4:00 PM',
          description: 'Join us for an intensive hands-on workshop on Flutter.',
          category: 'Workshop',
          imageUrl: '',
          attendeesCount: 120,
        ),
        community: 'ACLEDA University of Business (AUB)',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: eventPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Post Author & Caption
      expect(find.text('AUB Digital Academy'), findsOneWidget);
      expect(find.text('🚀 Excited to host our upcoming workshop! Check out details 👇'), findsOneWidget);

      // Event Preview Card
      expect(find.text('WORKSHOP'), findsOneWidget);
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
      expect(find.textContaining('25 Jul 2026 · 9:00 AM – 4:00 PM'), findsOneWidget);
      expect(find.textContaining('ACLEDA University, Phnom Penh'), findsOneWidget);
      expect(find.textContaining('120'), findsOneWidget);
      expect(find.text('View Event'), findsOneWidget);

      // Social interaction actions (likes, comments, shares, bookmark)
      expect(find.text('88'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Tapping preview card navigates to EventDetailsScreen
      await tester.tap(find.text('View Event'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
    });

    testWidgets('3. Event Screen (Event Tab) — Renders simple "Upcoming Events" title and compact horizontal cards without duplicate featured carousel or filters', (tester) async {
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

      // Switch to Event Tab (index 2)
      controller.setCategory('Event');
      await tester.pumpAndSettle();

      // Header is a simple section title "Upcoming Events"
      expect(find.text('Upcoming Events'), findsOneWidget);

      // NO large Featured Events carousel or duplicate header on Event screen
      expect(find.byType(HomeFeaturedEventsCarousel), findsNothing);
      expect(find.text('Featured Events'), findsNothing);

      // NO filter buttons / sorting buttons on Event screen
      expect(find.text('Filter'), findsNothing);
      expect(find.text('Filter Events'), findsNothing);

      // Compact cards rendered
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
      expect(find.text('AI in Everyday Life'), findsOneWidget);

      // Distinct Online indicator for online event vs physical location for in-person event
      expect(find.textContaining('ACLEDA University, Phnom Penh'), findsOneWidget);
      expect(find.text('🌐 Online Event'), findsWidgets);

      // Independent Bookmark button on card toggles state without navigating
      expect(controller.events[0].isBookmarked, isFalse);
      final bookmarkButtons = find.byIcon(Icons.bookmark_border_rounded);
      expect(bookmarkButtons, findsWidgets);
      await tester.tap(bookmarkButtons.first);
      await tester.pumpAndSettle();
      expect(controller.events[0].isBookmarked, isTrue);

      // Tapping card navigates to EventDetailsScreen
      await tester.tap(find.text('Flutter Workshop 2026'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
    });

    testWidgets('4. Event Details Screen — Displays full info and "Register Now" opens EventRegisterScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final event = controller.events.first;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();

      // Full event details rendered
      expect(find.text(event.title), findsOneWidget);
      expect(find.text(event.subtitle), findsOneWidget);
      expect(find.text('Register Now'), findsOneWidget);

      // Tap Register Now
      await tester.tap(find.text('Register Now'));
      await tester.pumpAndSettle();

      // Opens EventRegisterScreen
      expect(find.byType(EventRegisterScreen), findsOneWidget);
    });

    testWidgets('5. Khmer Localization — Event experience displays correctly in Khmer', (tester) async {
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

      // Switch to Event Tab in Khmer
      controller.setCategory('Event');
      await tester.pumpAndSettle();

      // Upcoming Events in Khmer
      expect(find.text('ព្រឹត្តិការណ៍នាពេលខាងមុខ'), findsOneWidget);

      // Online Event in Khmer
      expect(find.text('🌐 ព្រឹត្តិការណ៍អនឡាញ'), findsWidgets);
    });
  });
}
