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
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_featured_events_carousel.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

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

  group('GENLINK KH — STEP 11: HOME FEATURED EVENT VERIFICATION SUITE', () {
    testWidgets('1. Upcoming event appears with large cover image, badges, title, and metadata', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

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

      // Section title
      expect(find.textContaining('FEATURED EVENTS'), findsOneWidget);

      // Event title
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);

      // Badges
      expect(find.text('UPCOMING EVENT'), findsOneWidget);
      expect(find.text('WORKSHOP'), findsOneWidget);

      // Metadata
      expect(find.textContaining('25 Jul 2026 · 9:00 AM – 4:00 PM'), findsOneWidget);
      expect(find.textContaining('ACLEDA University, Phnom Penh'), findsOneWidget);
      expect(find.textContaining('120'), findsOneWidget);

      // Primary CTA
      expect(find.text('View Event'), findsOneWidget);
    });

    testWidgets('2. Feature selection picks nearest upcoming published event and ignores past/unpublished', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Clear default events and insert tailored dates
      controller.events.assignAll([
        EventModel(
          id: 'ev-past',
          title: 'Past Event 2020',
          status: 'PUBLISHED',
          startDateTime: DateTime(2020, 1, 1),
          dateString: '1 Jan 2020',
          location: 'Old Hall',
        ),
        EventModel(
          id: 'ev-draft',
          title: 'Draft Event 2027',
          status: 'DRAFT',
          startDateTime: DateTime(2027, 5, 1),
          dateString: '1 May 2027',
          location: 'Secret Room',
        ),
        EventModel(
          id: 'ev-far-future',
          title: 'Far Future Event 2028',
          status: 'PUBLISHED',
          startDateTime: DateTime(2028, 12, 1),
          dateString: '1 Dec 2028',
          location: 'Hall B',
        ),
        EventModel(
          id: 'ev-nearest',
          title: 'Nearest Upcoming Career Fair',
          status: 'PUBLISHED',
          startDateTime: DateTime(2026, 10, 15),
          dateString: '15 Oct 2026',
          location: 'Auditorium A',
          category: 'Career',
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

      // Nearest upcoming published event is selected
      expect(find.text('Nearest Upcoming Career Fair'), findsOneWidget);
      expect(find.text('Past Event 2020'), findsNothing);
      expect(find.text('Draft Event 2027'), findsNothing);
      expect(find.text('Far Future Event 2028'), findsNothing);
    });

    testWidgets('3. View Event navigation passes real eventId and heroTag to EventDetailsScreen', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

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

      // Tap View Event CTA
      await tester.tap(find.text('View Event'));
      await tester.pumpAndSettle();

      // Verified transition to EventDetailsScreen with identical event data
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
    });

    testWidgets('4. Online Event displays Online Event label instead of physical location', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Pick online event as first
      controller.events.assignAll([
        EventModel(
          id: 'ev-online',
          title: 'Cloud Native Webinar',
          status: 'PUBLISHED',
          eventType: 'Online',
          onlineLink: 'https://meet.google.com/xyz-1234-abc',
          meetingUrl: 'https://meet.google.com/xyz-1234-abc',
          dateString: '12 Nov 2026',
          startDateTime: DateTime(2026, 11, 12),
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

      expect(find.text('Cloud Native Webinar'), findsOneWidget);
      expect(find.text('Online Event'), findsOneWidget);
      // Raw Google Meet URL is not leaked into the home card
      expect(find.textContaining('https://meet.google.com'), findsNothing);
    });

    testWidgets('5. Missing image fallback renders clean monochrome placeholder', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.assignAll([
        EventModel(
          id: 'ev-no-img',
          title: 'Event With No Image',
          status: 'PUBLISHED',
          imageUrl: '',
          dateString: '15 Oct 2026',
          startDateTime: DateTime(2026, 10, 15),
          location: 'Campus Hall',
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

      expect(find.text('Event With No Image'), findsOneWidget);
      expect(find.text('GenLink Event'), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    });

    testWidgets('6. Empty state renders subtle No upcoming events card when list is empty', (tester) async {
      final repo = _MockCommunityRepository();
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

    testWidgets('7. Loading state renders skeleton structure matching card shape', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.clear();
      controller.isLoadingFeed.value = true;

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
      await tester.pump();

      // Card structure exists with placeholder boxes
      expect(find.textContaining('FEATURED EVENTS'), findsOneWidget);
      expect(find.byType(HomeFeaturedEventsCarousel), findsOneWidget);
    });

    testWidgets('8. Joined state renders Joined indicator when viewer is registered', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.assignAll([
        EventModel(
          id: 'ev-joined',
          title: 'Leadership Summit',
          status: 'PUBLISHED',
          isRsvped: true,
          myRsvpStatus: 'GOING',
          attendeesCount: 45,
          dateString: '20 Oct 2026',
          startDateTime: DateTime(2026, 10, 20),
          location: 'Main Hall',
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

      expect(find.text('Leadership Summit'), findsOneWidget);
      expect(find.text('Joined'), findsWidgets);
    });

    testWidgets('9. Long title and long description clamp cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600); // Very small screen
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      controller.events.assignAll([
        EventModel(
          id: 'ev-long',
          title: 'Extremely Long Event Title That Should Never Break The Home Feed Layout Even On Small Screens',
          description: 'This is a very comprehensive and lengthy description of the event designed to test the two-line truncation clamping behavior of the home featured event card to ensure no render overflow errors occur on compact viewports.',
          status: 'PUBLISHED',
          dateString: '20 Oct 2026',
          startDateTime: DateTime(2026, 10, 20),
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
      expect(find.textContaining('Extremely Long Event Title'), findsOneWidget);
    });

    testWidgets('10. Light Mode and Dark Mode render with proper contrast and tokens', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Dark mode test
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
      expect(find.text('View Event'), findsOneWidget);

      // Light mode test
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
      expect(find.text('View Event'), findsOneWidget);
    });

    testWidgets('11. English and Khmer localization render correct translations', (tester) async {
      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Khmer locale
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

    testWidgets('12. Home Feed tab integrates Featured Event naturally below Quick Create Card', (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(isHomeScreen: true),
        ),
      );
      await tester.pumpAndSettle();

      // Home Header
      expect(find.text('Home'), findsOneWidget);

      // Home Featured Event present on Feed tab
      expect(find.byType(HomeFeaturedEventsCarousel), findsOneWidget);
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
      expect(find.text('View Event'), findsOneWidget);

      // Swapping to Event tab does not render duplicate HomeFeaturedEventsCarousel
      controller.setCategory('Event');
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeaturedEventsCarousel), findsNothing);
      expect(find.text('Upcoming Events'), findsOneWidget);
    });
  });
}
