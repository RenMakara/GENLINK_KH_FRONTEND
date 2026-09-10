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
import 'package:genlink_frontend/features/community/presentation/screens/events_screen.dart';

class _MockCommunityRepo implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async => CommunityPostModel(
    id: 'post_new',
    userId: 'user_1',
    authorName: 'Test',
    authorTag: 'test',
    authorAvatar: '',
    timeAgo: 'Just now',
    content: content,
    imageUrls: imageUrls,
    visibility: visibility,
    community: community,
  );

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

  testWidgets('Event tab renders compact modern event cards without large hero carousel and without filter button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

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

    final eventTab = find.text('Event');
    expect(eventTab, findsOneWidget);
    await tester.tap(eventTab);
    await tester.pumpAndSettle();

    expect(find.text('Search Events & Workshops...'), findsNothing);
    expect(find.text('Featured Events'), findsNothing);

    expect(find.text('Filter'), findsNothing);
    expect(find.byIcon(Icons.tune_rounded), findsNothing);

    expect(find.text('Upcoming Events'), findsOneWidget);

    expect(find.text('Flutter Workshop 2026'), findsOneWidget);
    expect(find.text('AI Global Hackathon'), findsOneWidget);

    expect(find.text('Workshop'), findsOneWidget);
    expect(find.text('Hackathon'), findsOneWidget);

    expect(find.text('📍 ACLEDA University of Business'), findsOneWidget);
    expect(find.text('🌐 Online Event'), findsOneWidget);

    expect(find.byIcon(Icons.bookmark_border_rounded), findsWidgets);

    final upcomingCard = find.text('AI Global Hackathon');
    await tester.tap(upcomingCard);
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailsScreen), findsOneWidget);
  });

  testWidgets('Event tab displays clean empty state when events list is empty', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    controller.events.clear();
    controller.isLoadingFeed.value = false;
    controller.hasError.value = false;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    expect(find.text('No upcoming events'), findsOneWidget);
    expect(find.text('New events will appear here.'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsWidgets);
  });

  testWidgets('Tapping bookmark button toggles bookmark state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testEvent = EventModel(
      id: 'event-1',
      title: 'Mobile App Workshop',
      organizerName: 'Dev Club',
      eventType: 'In person',
      location: 'CADT Campus',
      dateString: 'Oct 12',
      timeString: '10:00 AM',
      category: 'Workshop',
      isBookmarked: false,
    );

    controller.events.assignAll([testEvent]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    await tester.pumpAndSettle();

    expect(controller.events.first.isBookmarked, isTrue);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets('Standalone EventsScreen renders list, search, and handles filtering', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    controller.events.assignAll([
      EventModel(
        id: '1',
        title: 'Flutter Workshop 2026',
        organizerName: 'Club A',
        eventType: 'In person',
        location: 'ACLEDA Campus',
        dateString: 'Aug 31',
        timeString: '9:00 AM',
        category: 'Workshop',
      ),
      EventModel(
        id: '2',
        title: 'AI Global Hackathon',
        organizerName: 'Club B',
        eventType: 'Online',
        dateString: 'Sep 05',
        timeString: '2:00 PM',
        category: 'Hackathon',
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const EventsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Workshop 2026'), findsOneWidget);
    expect(find.text('AI Global Hackathon'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Flutter');
    await tester.pumpAndSettle();

    expect(find.text('Flutter Workshop 2026'), findsOneWidget);
    expect(find.text('AI Global Hackathon'), findsNothing);
  });
}
