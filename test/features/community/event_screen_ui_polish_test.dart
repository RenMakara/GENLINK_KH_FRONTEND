import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/filter_events_sheet.dart';

class _MockCommunityRepo implements CommunityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CommunityController controller;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    controller = Get.put(CommunityController(repository: _MockCommunityRepo()));
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const CommunityScreen(),
    );
  }

  testWidgets('Event tab renders without large search bar, shows Featured Events, and has Filter in Upcoming Events header', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Populate sample events
    controller.events.assignAll([
      EventModel(
        id: '1',
        title: 'Flutter Workshop 2026',
        subtitle: 'Build modern mobile apps',
        organizerName: 'GenLink Tech Club',
        eventType: 'In person',
        location: 'ACLEDA University of Business',
        onlineLink: '',
        dateString: 'Aug 31',
        timeString: '9:00 AM',
        description: 'Comprehensive hands-on workshop.',
        category: 'Workshop',
        imageUrl: '',
        attendeesCount: 42,
      ),
      EventModel(
        id: '2',
        title: 'AI Global Hackathon',
        subtitle: 'Virtual 48-hour challenge',
        organizerName: 'AI Society',
        eventType: 'Online',
        location: '',
        onlineLink: 'https://meet.google.com/test',
        dateString: 'Sep 05',
        timeString: '2:00 PM',
        description: 'Collaborate and build next-gen AI.',
        category: 'Hackathon',
        imageUrl: '',
        attendeesCount: 120,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Select Event tab
    final eventTab = find.text('Event');
    expect(eventTab, findsOneWidget);
    await tester.tap(eventTab);
    await tester.pumpAndSettle();

    // Verify large Search bar is removed
    expect(find.text('Search Events & Workshops...'), findsNothing);

    // Verify Featured Events header is removed so tabs transition directly into carousel
    expect(find.text('Featured Events'), findsNothing);
    expect(find.byType(FeaturedEventsCarousel), findsOneWidget);
    expect(find.text('Flutter Workshop 2026'), findsWidgets);

    // Verify In-Person vs Online labeling
    expect(find.text('📍 ACLEDA University of Business'), findsWidgets);
    expect(find.text('🌐 Online Event'), findsWidgets);

    // Verify Upcoming Events section and relocated Filter button
    expect(find.text('Upcoming Events'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Tap Filter button and verify FilterEventsSheet opens
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(FilterEventsSheet), findsOneWidget);

    // Close bottom sheet
    Get.back();
    await tester.pumpAndSettle();

    // Tap on an upcoming event card and verify navigation to EventDetailsScreen
    final upcomingCard = find.text('AI Global Hackathon').last;
    await tester.ensureVisible(upcomingCard);
    await tester.tap(upcomingCard);
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailsScreen), findsOneWidget);
  });

  testWidgets('Event tab displays clean empty state when events list is empty', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    controller.events.clear();

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Select Event tab
    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('No upcoming events'), findsOneWidget);
    expect(find.text('Discover events happening around your campus and community.'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsWidgets);
  });

  testWidgets('Event filter sheet filters events correctly by category and mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    controller.events.assignAll([
      EventModel(
        id: '1',
        title: 'Flutter Workshop 2026',
        organizerName: 'GenLink Tech Club',
        eventType: 'In person',
        location: 'ACLEDA University',
        dateString: 'Aug 31',
        timeString: '9:00 AM',
        category: 'Workshop',
      ),
      EventModel(
        id: '2',
        title: 'AI Global Hackathon',
        organizerName: 'AI Society',
        eventType: 'Online',
        dateString: 'Sep 05',
        timeString: '2:00 PM',
        category: 'Hackathon',
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    // Open Filter Sheet
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(FilterEventsSheet), findsOneWidget);

    // Select 'Online' filter
    await tester.tap(find.text('Online'));
    await tester.pumpAndSettle();

    // Tap Apply Filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Only Online Hackathon should be in the filtered list
    expect(controller.filteredEvents.length, equals(1));
    expect(controller.filteredEvents.first.title, equals('AI Global Hackathon'));
  });

  testWidgets('Event deduplication segregates featured events from upcoming events', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    controller.events.assignAll([
      EventModel(
        id: '1',
        title: 'Featured Event 1',
        organizerName: 'Club A',
        dateString: 'Aug 31',
        timeString: '9:00 AM',
        category: 'Workshop',
      ),
      EventModel(
        id: '2',
        title: 'Featured Event 2',
        organizerName: 'Club B',
        dateString: 'Sep 01',
        timeString: '10:00 AM',
        category: 'Seminar',
      ),
      EventModel(
        id: '3',
        title: 'Featured Event 3',
        organizerName: 'Club C',
        dateString: 'Sep 02',
        timeString: '11:00 AM',
        category: 'Hackathon',
      ),
      EventModel(
        id: '4',
        title: 'Upcoming Event 4',
        organizerName: 'Club D',
        dateString: 'Sep 03',
        timeString: '1:00 PM',
        category: 'Career',
      ),
      EventModel(
        id: '5',
        title: 'Upcoming Event 5',
        organizerName: 'Club E',
        dateString: 'Sep 04',
        timeString: '2:00 PM',
        category: 'Volunteer',
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    // FeaturedEventsCarousel is rendered
    expect(find.byType(FeaturedEventsCarousel), findsOneWidget);

    // Upcoming Event 4 and 5 are displayed in the upcoming list
    expect(find.text('Upcoming Event 4'), findsOneWidget);
    expect(find.text('Upcoming Event 5'), findsOneWidget);
  });

  testWidgets('EventDetailsScreen renders info rows, price, bookmark, and handles RSVP toggle', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testEvent = EventModel(
      id: 'event-101',
      title: 'Advanced Flutter Masterclass',
      subtitle: 'Build enterprise apps with Flutter 3.29',
      organizerName: 'GenLink Tech Academy',
      eventType: 'In person',
      location: 'CADT Innovation Center, Phnom Penh',
      dateString: 'Sep 10',
      timeString: '8:30 AM – 4:30 PM',
      description: 'An in-depth hands-on session exploring best architectural patterns.',
      category: 'Workshop',
      isPaid: false,
      attendeesCount: 88,
      isRsvped: false,
    );

    controller.events.assignAll([testEvent]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: EventDetailsScreen(
          event: testEvent,
          heroTag: 'event-image-event-101-featured',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Advanced Flutter Masterclass'), findsOneWidget);
    expect(find.text('Build enterprise apps with Flutter 3.29'), findsOneWidget);

    // Verify Category & Format badges
    expect(find.text('WORKSHOP'), findsOneWidget);
    expect(find.text('IN PERSON'), findsOneWidget);

    // Verify Info Rows
    expect(find.text('CADT Innovation Center, Phnom Penh'), findsOneWidget);
    expect(find.text('GenLink Tech Academy'), findsOneWidget);
    expect(find.text('88 Going'), findsOneWidget);

    // Verify RSVP button initial state
    expect(find.text('Register Now'), findsOneWidget);

    // Tap Bookmark button
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
