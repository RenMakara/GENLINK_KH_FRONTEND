import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_register_screen.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Widget createWidget({
    required EventModel event,
    Locale locale = const Locale('en', 'US'),
    ThemeMode themeMode = ThemeMode.dark,
    Size screenSize = const Size(390, 844),
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: EventDetailsScreen(
          event: event,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRetry: onRetry,
        ),
      ),
    );
  }

  group('Event Details Redesign Verification Tests', () {
    testWidgets('1. Online event with meeting URL renders action and no raw URL', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final event = EventModel(
        id: 'online-1',
        title: 'Virtual Tech Conference 2026',
        subtitle: 'Global livestream on mobile innovation',
        organizerName: 'Google Developer Group',
        eventType: 'Online',
        mode: 'ONLINE',
        meetingUrl: 'https://meet.google.com/xyz-abcd-efg',
        onlineLink: 'https://meet.google.com/xyz-abcd-efg',
        dateString: '10 Oct 2026',
        timeString: '2:00 PM – 4:00 PM',
        description: 'Explore the future of tech with live demos and keynotes.',
      );

      await tester.pumpWidget(createWidget(event: event));
      await tester.pumpAndSettle();

      expect(find.text('ONLINE EVENT'), findsOneWidget);
      expect(find.text('Join Online Event'), findsOneWidget);
      expect(find.text('https://meet.google.com/xyz-abcd-efg'), findsNothing);
    });

    testWidgets('2. In-person event with coordinates renders location and View on Map', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final event = EventModel(
        id: 'in-person-1',
        title: 'Campus Hackathon 2026',
        subtitle: '24 hours of coding',
        organizerName: 'ACLEDA Tech Club',
        eventType: 'In person',
        mode: 'IN_PERSON',
        locationName: 'ACLEDA University Innovation Hub',
        location: 'ACLEDA University Innovation Hub',
        latitude: 11.5564,
        longitude: 104.9282,
        dateString: '15 Oct 2026',
        timeString: '9:00 AM – 5:00 PM',
      );

      await tester.pumpWidget(createWidget(event: event));
      await tester.pumpAndSettle();

      expect(find.text('IN PERSON'), findsOneWidget);
      expect(find.text('ACLEDA University Innovation Hub'), findsOneWidget);
      expect(find.text('View on Map'), findsOneWidget);

      await tester.ensureVisible(find.text('View on Map'));
      await tester.tap(find.text('View on Map'));
      await tester.pumpAndSettle();

      expect(find.textContaining('11.5564° N'), findsOneWidget);
      expect(find.textContaining('104.9282° E'), findsOneWidget);
      expect(find.text('Copy Location'), findsOneWidget);
    });

    testWidgets('3. Free event displays Free Entry correctly', (tester) async {
      final event = EventModel(
        id: 'free-event',
        title: 'Free Design Workshop',
        organizerName: 'Design Guild',
        dateString: '12 Oct 2026',
        timeString: '10:00 AM',
        isPaid: false,
      );

      await tester.pumpWidget(createWidget(event: event));
      await tester.pumpAndSettle();

      expect(find.text('Free Entry'), findsOneWidget);
      expect(find.text('No Registration Fee'), findsOneWidget);
    });

    testWidgets('4. Paid event displays actual price and currency from backend', (tester) async {
      final eventUsd = EventModel(
        id: 'paid-usd',
        title: 'Advanced AI Masterclass',
        organizerName: 'AI Institute',
        dateString: '20 Oct 2026',
        timeString: '1:00 PM',
        isPaid: true,
        price: 15.0,
        currency: 'USD',
      );

      await tester.pumpWidget(createWidget(event: eventUsd));
      await tester.pumpAndSettle();

      expect(find.text('\$15 USD'), findsOneWidget);
      expect(find.text('Standard Ticket'), findsOneWidget);

      final eventKhr = EventModel(
        id: 'paid-khr',
        title: 'Khmer Youth Summit',
        organizerName: 'Youth Foundation',
        dateString: '22 Oct 2026',
        timeString: '8:00 AM',
        isPaid: true,
        price: 20000.0,
        currency: 'KHR',
      );

      await tester.pumpWidget(createWidget(event: eventKhr));
      await tester.pumpAndSettle();

      expect(find.text('20,000 KHR'), findsOneWidget);
    });

    testWidgets('5. Multi-day date and time formatting', (tester) async {
      final event = EventModel(
        id: 'multiday-1',
        title: 'Camp Dev 2026',
        organizerName: 'Dev Group',
        dateString: '',
        timeString: '',
        startDateTime: DateTime(2026, 10, 25, 9, 0),
        endDateTime: DateTime(2026, 10, 27, 16, 0),
      );

      await tester.pumpWidget(createWidget(event: event));
      await tester.pumpAndSettle();

      expect(find.text('25–27 Oct 2026'), findsOneWidget);
      expect(find.text('9:00 AM – 4:00 PM'), findsOneWidget);
    });

    testWidgets('6. Missing optional fields safe handling without crashes', (tester) async {
      final emptyEvent = EventModel(
        id: 'minimal-1',
        title: 'Minimal Event Title',
        organizerName: '',
        dateString: '',
        timeString: '',
        location: '',
        description: '',
      );

      await tester.pumpWidget(createWidget(event: emptyEvent));
      await tester.pumpAndSettle();

      expect(find.text('Minimal Event Title'), findsOneWidget);
      expect(find.text('Date TBC'), findsOneWidget);
      expect(find.text('Location TBC'), findsOneWidget);
      expect(find.text('GenLink Community'), findsOneWidget);
      expect(find.text('Register Now'), findsOneWidget);
    });

    testWidgets('7. Registered user displays "You\'re Registered"', (tester) async {
      final registeredEvent = EventModel(
        id: 'reg-event',
        title: 'Registered Conference',
        organizerName: 'Org',
        dateString: '1 Oct',
        timeString: '10 AM',
        isRsvped: true,
      );

      await tester.pumpWidget(createWidget(event: registeredEvent));
      await tester.pumpAndSettle();

      expect(find.text("You're Registered"), findsOneWidget);
    });

    testWidgets('8. Non-registered user opens EventRegisterScreen', (tester) async {
      final event = EventModel(
        id: 'open-event',
        title: 'Flutter Workshop 2026',
        subtitle: 'Build real-world mobile apps',
        organizerName: 'AUB Academy',
        dateString: '25 Oct 2026',
        timeString: '9:00 AM',
        isRsvped: false,
      );

      await tester.pumpWidget(createWidget(event: event));
      await tester.pumpAndSettle();

      final registerBtn = find.text('Register Now');
      expect(registerBtn, findsOneWidget);

      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.byType(EventRegisterScreen), findsOneWidget);
    });

    testWidgets('9. Full event displays "Event Full" and disables registration', (tester) async {
      final fullEvent = EventModel(
        id: 'full-event',
        title: 'Sold Out Seminar',
        organizerName: 'Org',
        dateString: '5 Oct',
        timeString: '2 PM',
        attendeeLimit: 100,
        attendeesCount: 100,
        isFull: true,
      );

      await tester.pumpWidget(createWidget(event: fullEvent));
      await tester.pumpAndSettle();

      expect(find.text('Event Full'), findsWidgets);
      expect(find.text('Register Now'), findsNothing);
    });

    testWidgets('10. Organizer/owner state shows organizer controls and menu', (tester) async {
      final ownerEvent = EventModel(
        id: 'owner-event',
        title: 'My Hosted Event',
        organizerName: 'me',
        dateString: '12 Oct',
        timeString: '10 AM',
      );

      await tester.pumpWidget(createWidget(event: ownerEvent));
      await tester.pumpAndSettle();

      expect(find.text("You're the Organizer"), findsWidgets);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Delete Event'), findsOneWidget);
    });

    testWidgets('11. Light Mode renders without overflow or visual defects', (tester) async {
      final event = EventModel(
        id: 'light-event',
        title: 'Light Theme Event Testing',
        organizerName: 'Community Org',
        dateString: '3 Nov 2026',
        timeString: '9:00 AM',
      );

      await tester.pumpWidget(createWidget(
        event: event,
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Light Theme Event Testing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Dark Mode renders without overflow or visual defects', (tester) async {
      final event = EventModel(
        id: 'dark-event',
        title: 'Dark Theme Event Testing',
        organizerName: 'Community Org',
        dateString: '3 Nov 2026',
        timeString: '9:00 AM',
      );

      await tester.pumpWidget(createWidget(
        event: event,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dark Theme Event Testing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Khmer localization displays Khmer labels and dates', (tester) async {
      final event = EventModel(
        id: 'khmer-event',
        title: 'សិក្ខាសាលា Flutter ២០២៦',
        organizerName: 'AUB Academy',
        dateString: '',
        timeString: '',
        startDateTime: DateTime(2026, 10, 25, 9, 0),
        endDateTime: DateTime(2026, 10, 25, 16, 0),
        mode: 'ONLINE',
        isPaid: false,
      );

      await tester.pumpWidget(createWidget(
        event: event,
        locale: const Locale('km', 'KH'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ចុះឈ្មោះឥឡូវនេះ'), findsOneWidget);
      expect(find.textContaining('តុលា ២០២៦'), findsOneWidget);
      expect(find.textContaining('ព្រឹក – 4:00 ល្ងាច'), findsOneWidget);
      expect(find.text('ចូលរួមដោយឥតគិតថ្លៃ'), findsOneWidget);
    });

    testWidgets('14. Small phone screen (360x640) renders without layout overflow', (tester) async {
      final event = EventModel(
        id: 'small-phone',
        title: 'Super Long Event Title That Needs To Wrap Naturally Across Multiple Screen Lines Without Clipping Or Overflow',
        subtitle: 'A descriptive subtitle that also needs proper layout spacing on compact mobile screens',
        organizerName: 'GenLink Developer Community Academy',
        dateString: '25 Oct 2026',
        timeString: '9:00 AM – 4:00 PM',
        location: 'Phnom Penh Center Convention Hall Building A Room 402',
        isPaid: true,
        price: 5.0,
        currency: 'USD',
        attendeeLimit: 120,
        attendeesCount: 85,
      );

      await tester.pumpWidget(createWidget(
        event: event,
        screenSize: const Size(360, 640),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Register Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Large phone screen (430x932) renders with clean structure', (tester) async {
      final event = EventModel(
        id: 'large-phone',
        title: 'Large Screen Event Display Test',
        organizerName: 'GenLink Organization',
        dateString: '25 Oct 2026',
        timeString: '9:00 AM',
      );

      await tester.pumpWidget(createWidget(
        event: event,
        screenSize: const Size(430, 932),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Large Screen Event Display Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. Description "Read more" and "Read less" expandable interaction', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final longDesc = 'First line of the event overview.\n'
          'Second paragraph explaining detailed topics and objectives.\n'
          'Third paragraph covering prerequisites, target audience, mentors, tools, repositories, and hands-on exercises.\n'
          'Fourth paragraph with concluding guidance, Q&A sessions, refreshments, and networking opportunities for attendees.';

      final event = EventModel(
        id: 'expand-event',
        title: 'Deep Learning Workshop',
        organizerName: 'AI Club',
        dateString: '1 Dec 2026',
        timeString: '10:00 AM',
        description: longDesc,
      );

      await tester.pumpWidget(createWidget(event: event));
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);

      await tester.ensureVisible(find.text('Read more'));
      await tester.tap(find.text('Read more'));
      await tester.pumpAndSettle();

      expect(find.text('Read less'), findsOneWidget);

      await tester.ensureVisible(find.text('Read less'));
      await tester.tap(find.text('Read less'));
      await tester.pumpAndSettle();

      expect(find.text('Read more'), findsOneWidget);
    });

    testWidgets('17. Loading skeleton state renders placeholders', (tester) async {
      final event = EventModel(
        id: 'dummy',
        title: '',
        organizerName: '',
        dateString: '',
        timeString: '',
      );

      await tester.pumpWidget(createWidget(event: event, isLoading: true));
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. Error state renders retry button and invokes callback', (tester) async {
      bool retryCalled = false;
      final event = EventModel(
        id: 'dummy',
        title: '',
        organizerName: '',
        dateString: '',
        timeString: '',
      );

      await tester.pumpWidget(createWidget(
        event: event,
        errorMessage: 'Network timeout',
        onRetry: () => retryCalled = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load event'), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });
  });
}
