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
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<List<EventModel>> getEvents({int page = 1, int limit = 10, String? category, String? status}) async => [];

  Future<EventModel> getEventDetails(String eventId) async => throw UnimplementedError();

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

  group('Step 10: Event Post in Feed — Domain & Controller Integration', () {
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

    test('CommunityPostModel correctly recognizes event posts', () {
      final textPost = CommunityPostModel(
        id: 'p1',
        userId: 'u1',
        authorName: 'Sophea',
        authorTag: '@sophea',
        authorAvatar: '',
        timeAgo: '1h',
        content: 'Hello GenLink',
        postType: 'text',
      );
      expect(textPost.isEventPost, isFalse);

      final eventPostByType = CommunityPostModel(
        id: 'p2',
        userId: 'u1',
        authorName: 'Organizer',
        authorTag: '@organizer',
        authorAvatar: '',
        timeAgo: '1h',
        content: 'Join our summit',
        postType: 'event',
      );
      expect(eventPostByType.isEventPost, isTrue);

      final eventPostByAttachment = CommunityPostModel(
        id: 'p3',
        userId: 'u1',
        authorName: 'Organizer',
        authorTag: '@organizer',
        authorAvatar: '',
        timeAgo: '1h',
        content: 'Check out this event',
        attachedEvent: EventModel(
          id: 'ev1',
          title: 'Khmer Tech Summit',
          organizerName: 'Tech Hub',
        ),
      );
      expect(eventPostByAttachment.isEventPost, isTrue);
    });

    test('addEventLocally inserts into both events and posts as an Event Post', () {
      final newEvent = EventModel(
        id: 'ev_local_1',
        title: 'AI for Youth Workshop',
        description: 'Hands-on AI coding workshop for Cambodian students',
        category: 'Workshop',
        eventType: 'In person',
        location: 'Rupp STEM Building, Phnom Penh',
        organizerName: 'GenLink Youth',
        organizerAvatar: 'assets/images/genlink_logo.png',
        dateString: '15 Oct 2026',
        timeString: '2:00 PM – 5:00 PM',
        attendeesCount: 25,
      );

      controller.addEventLocally(newEvent);

      expect(controller.events.first.id, 'ev_local_1');

      expect(controller.posts.length, 1);
      final feedPost = controller.posts.first;
      expect(feedPost.isEventPost, isTrue);
      expect(feedPost.postType, 'event');
      expect(feedPost.attachedEvent?.id, 'ev_local_1');
      expect(feedPost.attachedEvent?.title, 'AI for Youth Workshop');
      expect(feedPost.authorName, 'GenLink Youth');
    });

    test('toggleRsvp synchronizes RSVP state across events and feed posts', () {
      final event = EventModel(
        id: 'ev_sync_1',
        title: 'FinTech Forum',
        organizerName: 'FinTech Association',
        attendeesCount: 10,
        isRsvped: false,
      );

      controller.addEventLocally(event);
      expect(controller.events.first.isRsvped, isFalse);
      expect(controller.posts.first.attachedEvent?.isRsvped, isFalse);
      expect(controller.posts.first.attachedEvent?.attendeesCount, 10);

      controller.toggleRsvp('ev_sync_1');
      expect(controller.events.first.isRsvped, isTrue);
      expect(controller.events.first.attendeesCount, 11);
      expect(controller.posts.first.attachedEvent?.isRsvped, isTrue);
      expect(controller.posts.first.attachedEvent?.attendeesCount, 11);

      controller.toggleRsvp('ev_sync_1');
      expect(controller.events.first.isRsvped, isFalse);
      expect(controller.events.first.attendeesCount, 10);
      expect(controller.posts.first.attachedEvent?.isRsvped, isFalse);
      expect(controller.posts.first.attachedEvent?.attendeesCount, 10);
    });

    test('toggleEventBookmark toggles bookmark status for event in events list', () {
      final event = EventModel(
        id: 'ev_bm_1',
        title: 'Design Sprint',
        isBookmarked: false,
      );

      controller.addEventLocally(event);
      expect(controller.events.first.isBookmarked, isFalse);

      controller.toggleEventBookmark('ev_bm_1');
      expect(controller.events.first.isBookmarked, isTrue);

      controller.toggleEventBookmark('ev_bm_1');
      expect(controller.events.first.isBookmarked, isFalse);
    });
  });

  group('Step 10: Event Post in Feed — UI Widget Rendering & Interactions', () {
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

    testWidgets('Renders organizer header, badges, details, and View Event CTA', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eventPost = CommunityPostModel(
        id: 'post_ev_101',
        userId: 'user_org_1',
        authorName: 'CADT Innovation Hub',
        authorTag: '@cadt_hub',
        authorAvatar: '',
        timeAgo: '3h ago',
        content: 'Annual CADT Innovation Summit 2026',
        postType: 'event',
        attachedEvent: EventModel(
          id: 'cadt_summit_2026',
          title: 'CADT Innovation Summit 2026',
          description: 'Explore the latest in Cambodian digital innovation and AI technologies.',
          category: 'Technology',
          eventType: 'In person',
          location: 'CADT Campus, Phnom Penh',
          organizerName: 'CADT Innovation Hub',
          dateString: '20 Nov 2026',
          timeString: '8:30 AM – 4:30 PM',
          attendeesCount: 85,
          isPaid: true,
          price: 10.0,
        ),
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

      // Organizer Header
      expect(find.text('CADT Innovation Hub'), findsOneWidget);
      expect(find.textContaining('3h'), findsOneWidget);

      // Badges
      expect(find.textContaining('New Event'), findsOneWidget);
      expect(find.text('TECHNOLOGY'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);

      // Details
      expect(find.text('CADT Innovation Summit 2026'), findsOneWidget);
      expect(find.textContaining('20 Nov 2026 · 8:30 AM – 4:30 PM'), findsOneWidget);
      expect(find.textContaining('CADT Campus, Phnom Penh'), findsOneWidget);
      expect(find.text('Explore the latest in Cambodian digital innovation and AI technologies.'), findsOneWidget);
      expect(find.textContaining(RegExp(r'85 joined', caseSensitive: false)), findsOneWidget);

      // Primary CTA
      expect(find.text('View Event'), findsOneWidget);

      // Tap View Event navigates to EventDetailsScreen
      await tester.tap(find.text('View Event'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
    });

    testWidgets('Online event displays Online Event label without exposing raw meeting URL', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final onlinePost = CommunityPostModel(
        id: 'post_ev_online',
        userId: 'user_org_2',
        authorName: 'Web3 Cambodia',
        authorTag: '@web3kh',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Online Webinar',
        postType: 'event',
        attachedEvent: EventModel(
          id: 'ev_webinar',
          title: 'Blockchain & Smart Contracts 101',
          description: 'A beginner webinar on decentralized technology.',
          category: 'Webinar',
          eventType: 'Online',
          mode: 'ONLINE',
          onlineLink: 'https://meet.google.com/secret-room-token-12345',
          meetingUrl: 'https://meet.google.com/secret-room-token-12345',
          organizerName: 'Web3 Cambodia',
          dateString: '12 Dec 2026',
          timeString: '7:00 PM – 8:30 PM',
          attendeesCount: 42,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: onlinePost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Online Event'), findsOneWidget);
      expect(find.textContaining('https://meet.google.com/secret-room-token-12345'), findsNothing);
      expect(find.textContaining('secret-room-token-12345'), findsNothing);
    });

    testWidgets('Reflects Joined ✓ state when user is registered and remains tappable to view detail', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final rsvpedPost = CommunityPostModel(
        id: 'post_ev_rsvped',
        userId: 'user_org_3',
        authorName: 'DevCon Cambodia',
        authorTag: '@devconkh',
        authorAvatar: '',
        timeAgo: 'Just now',
        content: 'DevCon 2026 Announcement',
        postType: 'event',
        attachedEvent: EventModel(
          id: 'ev_devcon_2026',
          title: 'DevCon Cambodia 2026',
          category: 'Conference',
          eventType: 'In person',
          location: 'Phnom Penh',
          organizerName: 'DevCon Cambodia',
          dateString: '5 Oct 2026',
          timeString: '9:00 AM',
          attendeesCount: 300,
          isRsvped: true,
          myRsvpStatus: 'JOINED',
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: rsvpedPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Joined ✓'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);

      await tester.tap(find.text('Joined ✓'));
      await tester.pumpAndSettle();
      expect(find.byType(EventDetailsScreen), findsOneWidget);
    });

    testWidgets('Gracefully renders fallback when event model is corrupt or empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final corruptPost = CommunityPostModel(
        id: 'post_corrupt',
        userId: 'user_unknown',
        authorName: 'Anonymous',
        authorTag: '@anon',
        authorAvatar: '',
        timeAgo: '1m ago',
        content: 'Corrupt event post',
        postType: 'event',
        attachedEvent: EventModel(
          id: '',
          title: '',
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: corruptPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Event details currently unavailable'), findsOneWidget);
    });

    testWidgets('Renders localized Khmer labels in Khmer locale', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final kmPost = CommunityPostModel(
        id: 'post_km',
        userId: 'user_km',
        authorName: 'សមាគមបច្ចេកវិទ្យា',
        authorTag: '@techkh',
        authorAvatar: '',
        timeAgo: '2h',
        content: 'សិក្ខាសាលាពិសេស',
        postType: 'event',
        attachedEvent: EventModel(
          id: 'ev_km_1',
          title: 'សិក្ខាសាលាស្តីពី AI និងការអភិវឌ្ឍន៍',
          category: 'Workshop',
          eventType: 'Online',
          organizerName: 'សមាគមបច្ចេកវិទ្យា',
          attendeesCount: 50,
          isRsvped: false,
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: kmPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ព្រឹត្តិការណ៍ថ្មី'), findsOneWidget);
      expect(find.text('មើលព្រឹត្តិការណ៍'), findsOneWidget);
      expect(find.textContaining('ព្រឹត្តិការណ៍អនឡាញ'), findsOneWidget);
    });
  });
}
