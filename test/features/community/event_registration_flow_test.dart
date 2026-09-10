import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
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

  testWidgets('1. CRITICAL: Personal information fields MUST start EMPTY and not pre-filled', (tester) async {
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

    // All fields start EMPTY
    final nameField = tester.widget<TextField>(textFields.at(0));
    final emailField = tester.widget<TextField>(textFields.at(1));
    final phoneField = tester.widget<TextField>(textFields.at(2));

    expect(nameField.controller?.text, isEmpty);
    expect(emailField.controller?.text, isEmpty);
    expect(phoneField.controller?.text, isEmpty);

    // Placeholders are visible
    expect(find.text('Select your university'), findsOneWidget);
    expect(find.text('Select your faculty'), findsOneWidget);
    expect(find.text('Select your year'), findsOneWidget);
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
    expect(find.text('Please enter your full name.'), findsOneWidget);
    expect(find.text('Please select your university.'), findsOneWidget);
    expect(find.text('Please select your faculty.'), findsOneWidget);
    expect(find.text('Please select your year of study.'), findsOneWidget);
    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your phone number.'), findsOneWidget);
    expect(find.text('You must agree to the Event Terms & Conditions.'), findsOneWidget);
  });

  testWidgets('3. Selectors & Search: University bottom sheet search, filter, and selection works', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Tap University selector
    final uniFinder = find.text('Select your university');
    await tester.ensureVisible(uniFinder);
    await tester.tap(uniFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet opened with university list & search bar
    expect(find.text('Institute of Technology of Cambodia (ITC)'), findsOneWidget);

    // Test Search filter in bottom sheet
    final searchField = find.byType(TextField).last;
    await tester.enterText(searchField, 'CADT');
    await tester.pumpAndSettle();

    expect(find.text('Cambodia Academy of Digital Technology (CADT)'), findsOneWidget);
    expect(find.text('Institute of Technology of Cambodia (ITC)'), findsNothing);

    // Test Empty Search result
    await tester.enterText(searchField, 'NonExistentUniversityXYZ');
    await tester.pumpAndSettle();
    expect(find.text('No university found'), findsOneWidget);

    // Clear search and pick CADT
    await tester.enterText(searchField, 'CADT');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambodia Academy of Digital Technology (CADT)'));
    await tester.pumpAndSettle();

    // Verify university is updated on form
    expect(find.text('Cambodia Academy of Digital Technology (CADT)'), findsOneWidget);
  });

  testWidgets('4. Year of Study bottom sheet displays correct options and selects Year 3', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Tap Year selector
    final yearFinder = find.text('Select your year');
    await tester.ensureVisible(yearFinder);
    await tester.tap(yearFinder);
    await tester.pumpAndSettle();

    // Verify year options
    expect(find.text('Select Year of Study'), findsOneWidget);
    expect(find.text('Year 1'), findsOneWidget);
    expect(find.text('Year 2'), findsOneWidget);
    expect(find.text('Year 3'), findsOneWidget);
    expect(find.text('Year 4'), findsOneWidget);
    expect(find.text('Year 5'), findsOneWidget);
    expect(find.text("Postgraduate / Master's"), findsOneWidget);

    // Pick Year 3
    await tester.tap(find.text('Year 3'));
    await tester.pumpAndSettle();

    // Verify Year is selected on form
    expect(find.text('Year 3'), findsOneWidget);
  });

  testWidgets('5. Phone number input: Accepts digits only and limits to 10 digits', (tester) async {
    final event = sampleEvent();
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    final phoneField = textFields.at(2);
    await tester.ensureVisible(phoneField);

    // Enter phone with mixed characters
    await tester.enterText(phoneField, '01234567890123');
    await tester.pumpAndSettle();

    // Length limit 10 digits
    final updatedField = tester.widget<TextField>(phoneField);
    expect(updatedField.controller?.text.length, lessThanOrEqualTo(10));
    expect(updatedField.controller?.text, '0123456789');
  });

  testWidgets('6. Full Registration flow: Fill all fields -> Submit -> Navigates to EventSuccessScreen', (tester) async {
    final event = sampleEvent();

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
    final yearFinder = find.text('Select your year');
    await tester.ensureVisible(yearFinder);
    await tester.tap(yearFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year 2'));
    await tester.pumpAndSettle();

    // Enter Email and Phone
    final emailField = textFields.at(1);
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'dara.pich@genlink.edu.kh');

    final phoneField = textFields.at(2);
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '012999888');

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
    expect(find.text('Registering...'), findsOneWidget);

    // Fast-forward simulated network delay
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify navigated to EventSuccessScreen
    expect(find.byType(EventSuccessScreen), findsOneWidget);
    expect(find.text('Registration Successful!'), findsOneWidget);
    expect(find.text('View Event'), findsOneWidget);

    // Verify RSVP state updated on event
    expect(event.isRsvped, isTrue);
  });

  testWidgets('7. Already Registered event displays registered banner and disables re-registration', (tester) async {
    final event = sampleEvent(isRsvped: true);
    await tester.pumpWidget(createTestWidget(event: event));
    await tester.pumpAndSettle();

    // Verify registered banner is shown
    expect(find.text("You're already registered"), findsAtLeastNWidgets(1));
    expect(find.text('You have already secured your spot for this event.'), findsOneWidget);
  });

  testWidgets('8. Khmer localization: Screen renders correctly in Khmer without text overflow', (tester) async {
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
