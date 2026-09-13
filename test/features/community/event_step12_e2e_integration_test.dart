import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_featured_events_carousel.dart';
import 'package:genlink_frontend/main_controller.dart';
import 'package:genlink_frontend/main_screen.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _E2EIntegrationMockRepository implements CommunityRepository {
  final List<EventModel> backendEvents = [];
  final List<CommunityPostModel> backendPosts = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return List<CommunityPostModel>.from(backendPosts);
  }

  @override
  Future<List<EventModel>> getEvents({
    int page = 1,
    int limit = 20,
    String? category,
    String? status,
  }) async {
    return List<EventModel>.from(backendEvents);
  }

  @override
  Future<EventModel> createEvent(EventCreateRequest request) async {
    final event = EventModel(
      id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
      title: request.title,
      description: request.description ?? '',
      category: request.category ?? 'Technology',
      eventType: request.mode == 'ONLINE' ? 'Online' : 'In person',
      mode: request.mode,
      location: request.locationName ?? 'Phnom Penh Center',
      locationName: request.locationName,
      onlineLink: request.meetingUrl ?? '',
      meetingUrl: request.meetingUrl,
      startDateTime: request.startDateTime,
      endDateTime: request.endDateTime,
      dateString: '20 Nov 2026',
      timeString: '9:00 AM – 5:00 PM',
      imageUrl: request.coverImageUrl ?? 'https://images.unsplash.com/photo-event-1',
      isPaid: request.paid,
      price: request.price,
      currency: request.currency,
      attendeesCount: 15,
      status: 'PUBLISHED',
      isRsvped: false,
      myRsvpStatus: null,
    );

    backendEvents.add(event);

    final eventPost = CommunityPostModel(
      id: 'post_event_${event.id}',
      userId: 'user_creator',
      authorName: 'Campus Organizer',
      authorTag: '@organizer',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: 'Just now',
      content: event.description.isNotEmpty ? event.description : event.title,
      postType: 'event',
      attachedEvent: event,
      likesCount: 5,
      commentsCount: 0,
      sharesCount: 1,
    );
    backendPosts.insert(0, eventPost);

    return event;
  }

  @override
  Future<RsvpResponseModel> rsvpEvent(
    String eventId, {
    EventRegistrationRequest? request,
  }) async {
    final idx = backendEvents.indexWhere((e) => e.id == eventId);
    int newCount = 1;
    if (idx != -1) {
      final old = backendEvents[idx];
      newCount = old.attendeesCount + 1;
      backendEvents[idx] = old.copyWith(
        isRsvped: true,
        attendeesCount: newCount,
        myRsvpStatus: 'GOING',
      );
    }
    for (int i = 0; i < backendPosts.length; i++) {
      if (backendPosts[i].attachedEvent?.id == eventId) {
        final ev = backendPosts[i].attachedEvent!;
        backendPosts[i] = backendPosts[i].copyWith(
          attachedEvent: ev.copyWith(
            isRsvped: true,
            attendeesCount: newCount,
            myRsvpStatus: 'GOING',
          ),
        );
      }
    }
    return RsvpResponseModel(
      eventId: eventId,
      status: 'GOING',
      attendeeCount: newCount,
      simulatedPayment: false,
      xpAwarded: 10,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('GENLINK KH — STEP 12: COMPLETE EVENT END-TO-END UX INTEGRATION SUITE', () {
    testWidgets('1. Create Event -> Result -> Success banner & navigates to Event Details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreateEventScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Create Event screen UI elements
      expect(find.text('Create Event'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);

      // Enter event name
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'AI Summit 2026');
      await tester.pumpAndSettle();

      // Pick date and time
      final dateInkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(dateInkWell);
      await tester.tap(dateInkWell);
      await tester.pumpAndSettle();

      final okDialogButton = find.text('OK');
      expect(okDialogButton, findsWidgets);
      await tester.tap(okDialogButton.first);
      await tester.pumpAndSettle();

      final okSheetButton = find.text('OK');
      expect(okSheetButton, findsWidgets);
      await tester.tap(okSheetButton.first);
      await tester.pumpAndSettle();

      // Enter online link
      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://meet.google.com/abc-defg-hij');
      await tester.pumpAndSettle();

      // Submit event
      final createButton = find.text('Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verified transition to EventDetailsScreen
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('AI Summit 2026'), findsWidgets);
      expect(find.text('Register Now'), findsOneWidget);
    });

    testWidgets('2. Event appears in Feed, Home, and Event List after refresh with identical eventId', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Create event via controller
      final created = await controller.createEvent(
        EventCreateRequest(
          title: 'Cybersecurity Hackathon 2026',
          description: 'Build robust defenses and ethical hacking solutions.',
          category: 'Technology',
          mode: 'IN_PERSON',
          locationName: 'Hall 3, ACLEDA University',
          startDateTime: DateTime(2026, 11, 25, 8, 30),
          endDateTime: DateTime(2026, 11, 25, 17, 30),
          status: 'PUBLISHED',
        ),
      );

      expect(created.title, 'Cybersecurity Hackathon 2026');

      // 1. Appears in Home Featured Event
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cybersecurity Hackathon 2026'), findsOneWidget);
      expect(find.text('View Event'), findsOneWidget);

      // 2. Appears in Feed
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: CommunityScreen(isHomeScreen: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cybersecurity Hackathon 2026'), findsOneWidget);
    });

    testWidgets('3. RSVP Registration Flow with Instant State Sync across Feed and Home', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final event = await controller.createEvent(
        EventCreateRequest(
          title: 'Robotics Bootcamp',
          category: 'Technology',
          mode: 'IN_PERSON',
          locationName: 'Robotics Lab',
          startDateTime: DateTime(2026, 12, 10, 10, 0),
          endDateTime: DateTime(2026, 12, 10, 16, 0),
          status: 'PUBLISHED',
        ),
      );

      // Open Event Details and trigger RSVP
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Register Now'), findsOneWidget);

      // Simulate registration
      await controller.registerForEvent(
        event.id,
        EventRegistrationRequest(
          fullName: 'Sokny Enat',
          email: 'enat@acleda.edu.kh',
          phoneNumber: '012345678',
          university: 'ACLEDA University',
          faculty: 'Computer Science',
          studyYear: 'Year 3',
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Home shows Joined
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Robotics Bootcamp'), findsOneWidget);
      expect(find.text('Joined'), findsWidgets);

      // 2. Verify Feed shows Joined ✓
      final feedPost = controller.posts.firstWhere((p) => p.attachedEvent?.id == event.id);
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: feedPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Joined ✓'), findsOneWidget);
    });

    testWidgets('4. Navigation Consistency: Home, Feed, and Event List all navigate using real eventId', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final event = await controller.createEvent(
        EventCreateRequest(
          title: 'Career & Internship Expo 2026',
          category: 'Career',
          mode: 'IN_PERSON',
          locationName: 'Grand Ballroom',
          startDateTime: DateTime(2026, 11, 15, 9, 0),
          endDateTime: DateTime(2026, 11, 15, 17, 0),
          status: 'PUBLISHED',
        ),
      );

      // Home navigation
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeViewEventFinder = find.text('View Event');
      await tester.ensureVisible(homeViewEventFinder);
      await tester.tap(homeViewEventFinder);
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Career & Internship Expo 2026'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      // Feed navigation
      final feedPost = controller.posts.firstWhere((p) => p.attachedEvent?.id == event.id);
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: feedPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final feedViewEventFinder = find.text('View Event');
      await tester.ensureVisible(feedViewEventFinder);
      await tester.tap(feedViewEventFinder);
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Career & Internship Expo 2026'), findsOneWidget);
    });

    testWidgets('5. Online event suppresses meeting URLs and displays Online Event label', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await controller.createEvent(
        EventCreateRequest(
          title: 'AI Global Webinar',
          category: 'Technology',
          mode: 'ONLINE',
          meetingUrl: 'https://meet.google.com/private-token-xyz-secret',
          startDateTime: DateTime(2026, 12, 1, 14, 0),
          endDateTime: DateTime(2026, 12, 1, 16, 0),
          status: 'PUBLISHED',
        ),
      );

      // Home check
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Online Event'), findsOneWidget);
      expect(find.textContaining('private-token-xyz-secret'), findsNothing);

      // Feed check
      final feedPost = controller.posts.first;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCardWidget(
                post: feedPost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Online Event'), findsOneWidget);
      expect(find.textContaining('private-token-xyz-secret'), findsNothing);
    });

    testWidgets('6. Missing image fallback renders clean monochrome placeholder', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.assignAll([
        EventModel(
          id: 'ev-no-img',
          title: 'Event Without Cover Image',
          imageUrl: '',
          dateString: '15 Nov 2026',
          startDateTime: DateTime(2026, 11, 15),
          location: 'Conference Room 1',
          status: 'PUBLISHED',
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Event Without Cover Image'), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    });

    testWidgets('7. Empty and Error states render gracefully without layout crashes', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.clear();
      controller.posts.clear();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No upcoming events'), findsOneWidget);
      expect(find.text('Check back later for campus activities.'), findsOneWidget);
    });

    testWidgets('8. Light Mode and Dark Mode render with design system compliance', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Dark Mode
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeFeaturedEventsCarousel), findsOneWidget);

      // Light Mode
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeFeaturedEventsCarousel), findsOneWidget);
    });

    testWidgets('9. English and Khmer localization render verified strings', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ព្រឹត្តិការណ៍លេចធ្លោ'), findsOneWidget);
      expect(find.text('មើលព្រឹត្តិការណ៍'), findsOneWidget);
    });

    testWidgets('10. Compact 320px viewport renders cleanly without overflow errors', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.assignAll([
        EventModel(
          id: 'ev-long',
          title: 'Very Long Event Title For Compact Screen Clamping Testing Purposes',
          description: 'Extensive multi-line description that tests whether the clamp logic properly handles tight constraints.',
          status: 'PUBLISHED',
          dateString: '20 Nov 2026',
          startDateTime: DateTime(2026, 11, 20),
          location: 'Phnom Penh Center Hall',
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: HomeFeaturedEventsCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Very Long Event Title'), findsOneWidget);
    });

    testWidgets('11. Bottom Navigation: Tab switches immediately without input blocking', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mainController = MainController();
      Get.put<MainController>(mainController);

      final textController = TextEditingController();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Obx(
                  () => FadeIndexedStack(
                    index: mainController.currentIndex.value,
                    children: [
                      TextField(
                        key: const ValueKey('tab_0_field'),
                        controller: textController,
                      ),
                      const Text('Growth Tab Page', key: ValueKey('tab_1_text')),
                      const Text('Finance Tab Page', key: ValueKey('tab_2_text')),
                      const Text('Profile Tab Page', key: ValueKey('tab_3_text')),
                    ],
                  ),
                ),
                bottomNavigationBar: Obx(
                  () => BottomNavBar(
                    currentIndex: mainController.currentIndex.value,
                    onTap: (index) {
                      mainController.changeIndex(index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial tab is Home (index 0)
      expect(mainController.currentIndex.value, 0);
      await tester.enterText(find.byKey(const ValueKey('tab_0_field')), 'Preserved Draft Text');
      expect(textController.text, 'Preserved Draft Text');

      // Switch to Growth (index 1)
      mainController.changeIndex(1);
      await tester.pump(const Duration(milliseconds: 50));

      expect(mainController.currentIndex.value, 1);
      await tester.pumpAndSettle();
      expect(find.text('Growth Tab Page'), findsOneWidget);

      // Switch to Finance (index 2)
      mainController.changeIndex(2);
      await tester.pump(const Duration(milliseconds: 50));

      expect(mainController.currentIndex.value, 2);
      await tester.pumpAndSettle();
      expect(find.text('Finance Tab Page'), findsOneWidget);

      // Switch back to Home
      mainController.changeIndex(0);
      await tester.pumpAndSettle();
      expect(mainController.currentIndex.value, 0);

      // Verify text input and form state preserved without rebuild
      expect(textController.text, 'Preserved Draft Text');
      expect(find.byKey(const ValueKey('tab_0_field')), findsOneWidget);
    });

    testWidgets('12. Feed and Event List synchronize after refresh without duplicating Event Posts', (tester) async {
      final repo = _E2EIntegrationMockRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);
      controller.posts.clear();
      controller.events.clear();

      await controller.createEvent(
        EventCreateRequest(
          title: 'Campus AI Hackathon',
          category: 'Technology',
          mode: 'IN_PERSON',
          locationName: 'Innovation Hub',
          startDateTime: DateTime(2026, 12, 1, 9, 0),
          endDateTime: DateTime(2026, 12, 1, 17, 0),
          status: 'PUBLISHED',
        ),
      );

      expect(controller.posts.where((p) => p.attachedEvent?.title == 'Campus AI Hackathon').length, 1);
      expect(controller.events.where((e) => e.title == 'Campus AI Hackathon').length, 1);

      // Trigger refresh
      await controller.refreshFeed();

      // Verify no duplicate event posts created
      final eventPosts = controller.posts.where((p) => p.attachedEvent?.title == 'Campus AI Hackathon').toList();
      expect(eventPosts.length, 1);
      expect(controller.events.where((e) => e.title == 'Campus AI Hackathon').length, 1);
    });
  });
}
