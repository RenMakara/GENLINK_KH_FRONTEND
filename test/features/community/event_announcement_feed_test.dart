import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class MockCommunityRepository implements CommunityRepository {
  List<CommunityPostModel> remotePosts = [];
  List<EventModel> remoteEvents = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => remotePosts;

  @override
  Future<List<EventModel>> getEvents({int page = 1, int limit = 10, String? category, String? status}) async => remoteEvents;

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async => CommunityPostModel(
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

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async => CommunityPostModel(
    id: postId,
    userId: 'u1',
    authorName: 'A',
    authorTag: '@a',
    authorAvatar: '',
    timeAgo: '',
    content: '',
  );

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async => CommunityPostModel(
    id: postId,
    userId: 'u1',
    authorName: 'A',
    authorTag: '@a',
    authorAvatar: '',
    timeAgo: '',
    content: content,
  );

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
  Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async => CommentModel(
    id: 'c1',
    postId: postId,
    userId: 'user_1',
    userName: 'Tester',
    userAvatar: '',
    text: text,
    timeAgo: 'Just now',
  );
  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;
  @override
  Future<bool> followUser(String userId) async => true;
  @override
  Future<bool> unfollowUser(String userId) async => true;
  @override
  Future<bool> checkIsFollowing(String userId) async => false;
  @override
  Future<EventModel> createEvent(EventCreateRequest request) async => EventModel(
    id: 'ev_created_101',
    title: request.title,
    description: request.description ?? '',
    category: request.category ?? '',
    eventType: request.mode == 'ONLINE' ? 'Online' : 'In person',
    location: request.locationName ?? '',
    organizerName: 'Organizer',
  );
  @override
  Future<RsvpResponseModel> rsvpEvent(String eventId, {EventRegistrationRequest? request}) async => const RsvpResponseModel(
    eventId: 'ev_1',
    status: 'JOINED',
    attendeeCount: 10,
    xpAwarded: 50,
    simulatedPayment: false,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 6: Event Announcement + Home Feed Integration Tests', () {
    late MockCommunityRepository mockRepo;
    late CommunityController controller;

    setUp(() {
      Get.reset();
      Get.testMode = true;
      mockRepo = MockCommunityRepository();
      controller = CommunityController(repository: mockRepo);
      Get.put<CommunityController>(controller);
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestApp({
      required Widget child,
      Locale locale = const Locale('en', 'US'),
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );
    }

    test('1. Real backend event post deserialization (PostResponse contract)', () {
      final backendJson = {
        'postId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'author': {
          'id': 'user_org_backend',
          'fullName': 'Tech Hub Cambodia',
          'username': 'techhubkh',
          'avatarUrl': 'https://example.com/avatar.jpg',
        },
        'contentText': 'Learn practical Flutter development with industry leaders.',
        'imageUrl': 'https://example.com/cover.jpg',
        'postType': 'ANNOUNCEMENT',
        'visibility': 'PUBLIC',
        'eventId': 'event-uuid-999',
        'attachedEvent': {
          'id': 'event-uuid-999',
          'title': 'Tech Workshop 2026',
          'description': 'Learn practical Flutter development with industry leaders.',
          'category': 'Workshop',
          'startDateTime': '2026-09-20T14:00:00',
          'endDateTime': '2026-09-20T17:00:00',
          'mode': 'IN_PERSON',
          'locationName': 'Phnom Penh',
          'attendeeCount': 65,
          'attendeeLimit': 100,
          'paid': true,
          'price': 10.0,
          'currency': 'USD',
          'coverImageUrl': 'https://example.com/cover.jpg',
        },
        'likeCount': 24,
        'commentCount': 3,
        'likedByMe': false,
        'savedByMe': false,
        'createdAt': '2026-09-14T10:00:00Z',
      };

      final post = CommunityPostModel.fromJson(backendJson);

      expect(post.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(post.isEventPost, isTrue);
      expect(post.isAnnouncementPost, isTrue);
      expect(post.eventId, 'event-uuid-999');
      expect(post.attachedEvent, isNotNull);
      expect(post.attachedEvent!.title, 'Tech Workshop 2026');
      expect(post.attachedEvent!.locationName, 'Phnom Penh');
      expect(post.attachedEvent!.attendeesCount, 65);
      expect(post.attachedEvent!.isPaid, isTrue);
      expect(post.attachedEvent!.formattedPrice, '\$10 USD');
    });

    testWidgets('2. Event announcement rendering: title, image, date/time, location, CTA', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final announcementPost = CommunityPostModel(
        id: 'post_announcement_1',
        userId: 'user_1',
        authorName: 'GenLink Tech Team',
        authorTag: '@genlink_team',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Special Tech Workshop announcement for all students!',
        postType: 'announcement',
        attachedEvent: EventModel(
          id: 'ev_flutter_2026',
          title: 'Tech Workshop 2026',
          description: 'Learn practical Flutter development from basics to production.',
          category: 'Workshop',
          eventType: 'In person',
          location: 'Phnom Penh',
          locationName: 'Phnom Penh',
          organizerName: 'GenLink Tech Team',
          startDateTime: DateTime(2026, 9, 20, 14, 0),
          endDateTime: DateTime(2026, 9, 20, 17, 0),
          imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97',
          attendeesCount: 45,
          isPaid: false,
        ),
      );

      await tester.pumpWidget(createTestApp(
        child: PostCardWidget(
          post: announcementPost,
          controller: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Announcement Badge
      expect(find.text('EVENT ANNOUNCEMENT'), findsOneWidget);
      expect(find.text('WORKSHOP'), findsOneWidget);

      // Event Title
      expect(find.text('Tech Workshop 2026'), findsOneWidget);

      // Date / Time
      expect(find.textContaining('20 Sep 2026'), findsOneWidget);
      expect(find.textContaining('2:00 PM'), findsOneWidget);

      // Location
      expect(find.text('Phnom Penh'), findsOneWidget);

      // Short Description
      expect(find.text('Learn practical Flutter development from basics to production.'), findsOneWidget);

      // Clear Event CTA
      expect(find.text('View Event'), findsOneWidget);
    });

    testWidgets('3. Event CTA: tap opens real EventDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final targetEvent = EventModel(
        id: 'ev_detail_target',
        title: 'Flutter Advanced Architecture',
        description: 'Clean Architecture with GetX and Dio in Flutter.',
        category: 'Tech',
        location: 'Phnom Penh',
        organizerName: 'Google Developer Group',
      );

      final post = CommunityPostModel(
        id: 'post_nav_test',
        userId: 'u1',
        authorName: 'GDG Phnom Penh',
        authorTag: '@gdgphnompenh',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Join our architecture workshop!',
        postType: 'announcement',
        attachedEvent: targetEvent,
      );

      await tester.pumpWidget(createTestApp(
        child: PostCardWidget(
          post: post,
          controller: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap View Event CTA button
      await tester.tap(find.text('View Event'));
      await tester.pumpAndSettle();

      // Verify real EventDetailsScreen is pushed
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Flutter Advanced Architecture'), findsWidgets);
    });

    testWidgets('4. Missing optional fields: compact card without empty void image', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final compactEvent = EventModel(
        id: 'ev_no_image',
        title: 'Quick Hackathon Standup',
        description: 'Sync with teams before hacking starts.',
        category: 'Standup',
        imageUrl: '', // NO IMAGE
        location: '', // NO LOCATION
        eventType: 'In person',
        startDateTime: DateTime(2026, 9, 21, 9, 0),
      );

      final post = CommunityPostModel(
        id: 'post_compact_test',
        userId: 'u1',
        authorName: 'Hackathon Admin',
        authorTag: '@admin',
        authorAvatar: '',
        timeAgo: '10m',
        content: 'Standup in 30 minutes!',
        postType: 'announcement',
        attachedEvent: compactEvent,
      );

      await tester.pumpWidget(createTestApp(
        child: PostCardWidget(
          post: post,
          controller: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Title & CTA are rendered
      expect(find.text('Quick Hackathon Standup'), findsOneWidget);
      expect(find.text('View Event'), findsOneWidget);

      // No oversized placeholder should be rendered when imageUrl is empty
      expect(find.text('GENLINK COMMUNITY EVENT'), findsNothing);
    });

    testWidgets('5. Khmer localization: translates badge, CTA, and dates', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final kmEvent = EventModel(
        id: 'ev_km_demo',
        title: 'សន្និសីទបច្ចេកវិទ្យា ២០២៦',
        category: 'Technology',
        eventType: 'Online',
        mode: 'ONLINE',
        startDateTime: DateTime(2026, 9, 20, 14, 0),
        organizerName: 'សមាគមបច្ចេកវិទ្យា',
        attendeesCount: 30,
      );

      final kmPost = CommunityPostModel(
        id: 'post_km_announcement',
        userId: 'u_km',
        authorName: 'សមាគមបច្ចេកវិទ្យា',
        authorTag: '@techkh',
        authorAvatar: '',
        timeAgo: '2h',
        content: 'សូមស្វាគមន៍មកកាន់សន្និសីទបច្ចេកវិទ្យា',
        postType: 'announcement',
        attachedEvent: kmEvent,
      );

      await tester.pumpWidget(createTestApp(
        locale: const Locale('km', 'KH'),
        child: PostCardWidget(
          post: kmPost,
          controller: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Khmer Badge
      expect(find.text('សេចក្ដីប្រកាសព្រឹត្តិការណ៍'), findsOneWidget);

      // Khmer CTA
      expect(find.text('មើលព្រឹត្តិការណ៍'), findsOneWidget);

      // Khmer Online Event label
      expect(find.text('ព្រឹត្តិការណ៍អនឡាញ'), findsOneWidget);
    });

    testWidgets('6. Light Mode and Dark Mode rendering', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testEvent = EventModel(
        id: 'ev_theme_test',
        title: 'Theme Adaptability Workshop',
        category: 'Design',
        location: 'AUB Campus',
      );

      final post = CommunityPostModel(
        id: 'post_theme_test',
        userId: 'u1',
        authorName: 'UI Club',
        authorTag: '@uiclub',
        authorAvatar: '',
        timeAgo: '5m',
        content: 'Testing themes',
        postType: 'announcement',
        attachedEvent: testEvent,
      );

      // Light Mode test
      await tester.pumpWidget(createTestApp(
        themeMode: ThemeMode.light,
        child: PostCardWidget(post: post, controller: controller),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Theme Adaptability Workshop'), findsOneWidget);

      // Dark Mode test
      await tester.pumpWidget(createTestApp(
        themeMode: ThemeMode.dark,
        child: PostCardWidget(post: post, controller: controller),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Theme Adaptability Workshop'), findsOneWidget);
    });

    testWidgets('7. Mobile phone layout responsive check (360x640 constraint)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final post = CommunityPostModel(
        id: 'post_mobile_test',
        userId: 'u1',
        authorName: 'Mobile Club Phnom Penh',
        authorTag: '@mobileclub',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'Long post content testing mobile layout constraints and avoiding RenderFlex overflow issues.',
        postType: 'announcement',
        attachedEvent: EventModel(
          id: 'ev_mobile',
          title: 'Mobile Dev Cambodia Summit 2026 — Very Long Title That May Wrap',
          location: 'Building B, Royal University of Phnom Penh (RUPP)',
          category: 'MobileDev',
          startDateTime: DateTime(2026, 9, 20, 14, 0),
          attendeesCount: 150,
          isPaid: true,
          price: 20.0,
          currency: 'USD',
        ),
      );

      FlutterErrorDetails? caughtError;
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtError = details;
      };

      await tester.pumpWidget(createTestApp(
        child: PostCardWidget(post: post, controller: controller),
      ));
      await tester.pumpAndSettle();

      FlutterError.onError = oldHandler;

      expect(caughtError, isNull);
      expect(tester.takeException(), isNull);
      expect(find.text('View Event'), findsOneWidget);
    });

    test('8. Existing Event functionality: RSVP synchronization between feed and events', () {
      final event = EventModel(
        id: 'ev_feed_sync_1',
        title: 'Cloud Native Cambodia',
        organizerName: 'Cloud Community',
        attendeesCount: 20,
        isRsvped: false,
      );

      controller.addEventLocally(event);
      expect(controller.events.first.isRsvped, isFalse);
      expect(controller.posts.first.attachedEvent?.isRsvped, isFalse);
      expect(controller.posts.first.attachedEvent?.attendeesCount, 20);

      // RSVP
      controller.toggleRsvp('ev_feed_sync_1');
      expect(controller.events.first.isRsvped, isTrue);
      expect(controller.events.first.attendeesCount, 21);
      expect(controller.posts.first.attachedEvent?.isRsvped, isTrue);
      expect(controller.posts.first.attachedEvent?.attendeesCount, 21);

      // Un-RSVP
      controller.toggleRsvp('ev_feed_sync_1');
      expect(controller.events.first.isRsvped, isFalse);
      expect(controller.events.first.attendeesCount, 20);
      expect(controller.posts.first.attachedEvent?.isRsvped, isFalse);
      expect(controller.posts.first.attachedEvent?.attendeesCount, 20);
    });

    testWidgets('9. Resolving event via controller.events when attachedEvent is not embedded', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Event exists in controller.events
      final globalEvent = EventModel(
        id: 'event-uuid-cached-123',
        title: 'Resolved From Cache Event',
        category: 'Summit',
        location: 'Phnom Penh',
      );
      controller.events.add(globalEvent);

      // Post only has eventId, attachedEvent is null
      final postWithIdOnly = CommunityPostModel(
        id: 'post_with_id_only',
        userId: 'u1',
        authorName: 'Organizer',
        authorTag: '@org',
        authorAvatar: '',
        timeAgo: '1h',
        content: 'Check out this event by ID!',
        postType: 'announcement',
        eventId: 'event-uuid-cached-123',
        attachedEvent: null,
      );

      await tester.pumpWidget(createTestApp(
        child: PostCardWidget(
          post: postWithIdOnly,
          controller: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Resolved from controller.events by eventId
      expect(find.text('Resolved From Cache Event'), findsOneWidget);
      expect(find.text('View Event'), findsOneWidget);
    });

    test('10. Feed refresh: re-fetches posts and updates attached events', () async {
      mockRepo.remotePosts = [
        CommunityPostModel(
          id: 'post_refreshed_1',
          userId: 'u_refresh',
          authorName: 'Refreshed Author',
          authorTag: '@refresh',
          authorAvatar: '',
          timeAgo: 'Just now',
          content: 'Refreshed Feed Event',
          postType: 'announcement',
          attachedEvent: EventModel(
            id: 'ev_refreshed',
            title: 'Refreshed Tech Conference',
            category: 'Conference',
          ),
        ),
      ];

      await controller.fetchPosts(isRefresh: true);

      expect(controller.posts.length, 1);
      expect(controller.posts.first.content, 'Refreshed Feed Event');
      expect(controller.posts.first.attachedEvent?.title, 'Refreshed Tech Conference');
      expect(controller.events.any((e) => e.id == 'ev_refreshed'), isTrue);
    });
  });
}
