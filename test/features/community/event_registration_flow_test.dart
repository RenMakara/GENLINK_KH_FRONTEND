import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_register_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_success_screen.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestWidget({
    required EventModel event,
    Locale locale = const Locale('en', 'US'),
    ThemeMode themeMode = ThemeMode.dark,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: EventRegisterScreen(event: event),
    );
  }

  EventModel sampleEvent({bool isRsvped = false}) {
    return EventModel(
      id: 'event_test_101',
      title: 'Career Talk Series: Tech in Banking',
      description: 'Join top engineering leaders from banking sectors.',
      dateString: '2 Aug 2026',
      timeString: '9:30 AM',
      location: 'ACLEDA University of Business',
      eventType: 'In person',
      category: 'Career',
      organizerName: 'ACLEDA Tech Club',
      attendeesCount: 45,
      isRsvped: isRsvped,
    );
  }

  testWidgets('1. CRITICAL: Full Name field MUST start EMPTY and not pre-filled', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Verify header and compact summary card exist
    expect(find.text('Register for Event'), findsOneWidget);
    expect(find.text('Career Talk Series: Tech in Banking'), findsOneWidget);
    expect(find.textContaining('ACLEDA University of Business'), findsAtLeastNWidgets(1));

    // Find all text fields on screen
    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeastNWidgets(3)); // Name, Email, Phone

    // First text field is Full Name - verify its controller has empty text
    final nameField = tester.widget<TextField>(textFields.first);
    expect(nameField.controller?.text, isEmpty);
    expect(nameField.controller?.text, isNot(contains('Enat')));
    expect(nameField.controller?.text, isNot(contains('Sokny')));
  });

  testWidgets('2. Validation: Submitting empty form displays required error messages', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Tap Register Now button while form is empty
    final registerBtn = find.text('Register Now');
    expect(registerBtn, findsOneWidget);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Verify required error texts appear
    expect(find.text('Full name is required.'), findsOneWidget);
    expect(find.text('University is required.'), findsOneWidget);
    expect(find.text('Faculty is required.'), findsOneWidget);
    expect(find.text('Year of study is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Phone number is required.'), findsOneWidget);
    expect(find.text('You must agree to the Terms & Conditions.'), findsOneWidget);
  });

  testWidgets('3. Selectors: University and Year selector bottom sheets open and pick values', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Tap University selector
    final uniFinder = find.text('Select your university');
    await tester.ensureVisible(uniFinder);
    await tester.tap(uniFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet opened with university list
    expect(find.text('Institute of Technology of Cambodia (ITC)'), findsOneWidget);
    await tester.tap(find.text('Institute of Technology of Cambodia (ITC)'));
    await tester.pumpAndSettle();

    // Verify university is updated on form
    expect(find.text('Institute of Technology of Cambodia (ITC)'), findsOneWidget);

    // Tap Year selector
    final yearFinder = find.text('Select year');
    await tester.ensureVisible(yearFinder);
    await tester.tap(yearFinder);
    await tester.pumpAndSettle();

    // Verify year options and pick Year 3
    expect(find.text('Year 3 (Junior)'), findsOneWidget);
    await tester.tap(find.text('Year 3 (Junior)'));
    await tester.pumpAndSettle();

    // Verify Year is selected on form
    expect(find.text('Year 3 (Junior)'), findsOneWidget);
  });

  testWidgets('4. Full Registration flow: Fill all fields -> Submit -> Navigates to EventSuccessScreen', (tester) async {
    final controller = CommunityController();
    final event = sampleEvent();
    controller.events.add(event);
    Get.put<CommunityController>(controller);

    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Enter Full Name
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Dara Pich');

    // Select University
    final uniFinder = find.text('Select your university');
    await tester.ensureVisible(uniFinder);
    await tester.tap(uniFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACLEDA University of Business (AUB)'));
    await tester.pumpAndSettle();

    // Select Faculty
    final facFinder = find.text('Select your faculty');
    await tester.ensureVisible(facFinder);
    await tester.tap(facFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer Science & IT'));
    await tester.pumpAndSettle();

    // Select Year
    final yearFinder = find.text('Select year');
    await tester.ensureVisible(yearFinder);
    await tester.tap(yearFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year 2 (Sophomore)'));
    await tester.pumpAndSettle();

    // Enter Email and Phone
    final emailField = textFields.at(1);
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'dara.pich@genlink.edu.kh');

    final phoneField = textFields.at(2);
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '+855 12 999 888');

    // Toggle Terms checkbox
    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Tap Register Now
    final registerBtn = find.text('Register Now');
    await tester.tap(registerBtn);
    await tester.pump(); // Start loading state

    // Verify loading label
    expect(find.text('Creating registration...'), findsOneWidget);

    // Fast-forward simulated network delay
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify navigated to EventSuccessScreen
    expect(find.byType(EventSuccessScreen), findsOneWidget);
    expect(find.text('Registration Successful!'), findsOneWidget);
    expect(find.text('View Ticket'), findsOneWidget);

    // Verify RSVP state updated in controller
    expect(controller.events.firstWhere((e) => e.id == event.id).isRsvped, isTrue);
  });

  testWidgets('5. Already Registered event displays registered banner and disables re-registration', (tester) async {
    final event = sampleEvent(isRsvped: true);
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Verify registered banner is shown
    expect(find.text("You're already registered"), findsAtLeastNWidgets(1));
    expect(find.text('You have already secured your spot for this event.'), findsOneWidget);
  });

  testWidgets('6. Khmer localization: Screen renders correctly in Khmer without text overflow', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(
      event: event,
      locale: const Locale('km', 'KH'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ចុះឈ្មោះចូលរួមព្រឹត្តិការណ៍'), findsOneWidget);
    expect(find.text('ព័ត៌មានរបស់អ្នក'), findsOneWidget);
    expect(find.text('ព័ត៌មានសិក្សា'), findsOneWidget);
    expect(find.text('ព័ត៌មានទំនាក់ទំនង'), findsOneWidget);
    expect(find.text('ឈ្មោះពេញ *'), findsOneWidget);
    expect(find.text('ចុះឈ្មោះឥឡូវនេះ'), findsOneWidget);
  });
}
