import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';

class _MockCommunityRepo implements CommunityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CommunityController communityController;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    communityController = Get.put(CommunityController(repository: _MockCommunityRepo()));
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const CreateEventScreen(returnCreatedEvent: true),
    );
  }

  Future<void> pickDummyDate(WidgetTester tester) async {
    final inkWellFinder = find.ancestor(
      of: find.text('Select date and time'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(inkWellFinder);
    await tester.tap(inkWellFinder);
    await tester.pumpAndSettle();

    // DatePicker confirmation OK
    final okDialogButton = find.text('OK');
    expect(okDialogButton, findsWidgets);
    await tester.tap(okDialogButton.first);
    await tester.pumpAndSettle();

    // TimePicker sheet confirmation OK
    final okSheetButton = find.text('OK');
    expect(okSheetButton, findsWidgets);
    await tester.tap(okSheetButton.first);
    await tester.pumpAndSettle();
  }

  group('CreateEventScreen Form & Conditional Validation Tests', () {
    testWidgets('TEST 1: Online event requires URL and creates successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Default is Online
      expect(find.text('Online event link*'), findsOneWidget);
      expect(find.text('Location*'), findsNothing);

      // Enter Event Name
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Online Tech Meetup');
      await tester.pumpAndSettle();

      // Pick Date & Time
      await pickDummyDate(tester);

      // Enter Online Event Link
      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://meet.google.com/abc-defg-hij');
      await tester.pumpAndSettle();

      // Enter Description
      final descField = find.widgetWithText(TextField, 'Tell people about your event');
      await tester.ensureVisible(descField);
      await tester.enterText(descField, 'An exciting online meetup about Flutter.');
      await tester.pumpAndSettle();

      // Tap Create
      final createButton = find.text('Create');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify event was added
      expect(communityController.events.isNotEmpty, isTrue);
      final created = communityController.events.first;
      expect(created.title, 'Online Tech Meetup');
      expect(created.eventType, 'Online');
      expect(created.onlineLink, 'https://meet.google.com/abc-defg-hij');
      expect(created.location, isEmpty);
    });

    testWidgets('TEST 2: In-Person event requires Location and creates successfully with empty online link', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to In Person
      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      expect(find.text('Location*'), findsOneWidget);
      expect(find.text('Online event link*'), findsNothing);

      // Enter Event Name
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Flutter Campus Workshop');
      await tester.pumpAndSettle();

      // Pick Date & Time
      await pickDummyDate(tester);

      // Enter Location
      final locField = find.widgetWithText(TextField, '📍 Enter event location');
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'ACLEDA University of Business');
      await tester.pumpAndSettle();

      // Enter Description
      final descField = find.widgetWithText(TextField, 'Tell people about your event');
      await tester.ensureVisible(descField);
      await tester.enterText(descField, 'In-person coding workshop.');
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify event was added
      expect(communityController.events.isNotEmpty, isTrue);
      final created = communityController.events.first;
      expect(created.title, 'Flutter Campus Workshop');
      expect(created.eventType, 'In person');
      expect(created.location, 'ACLEDA University of Business');
      expect(created.onlineLink, isEmpty);
    });

    testWidgets('TEST 3: In-Person without location shows "Location is required."', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to In Person
      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      // Enter Event Name
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'In-Person Event No Location');
      await tester.pumpAndSettle();

      // Pick Date & Time
      await pickDummyDate(tester);

      // Leave Location empty and tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Location is required.'), findsOneWidget);
    });

    testWidgets('TEST 4: Online without URL shows "Online event link is required."', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Default is Online
      // Enter Event Name
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Online Event No URL');
      await tester.pumpAndSettle();

      // Pick Date & Time
      await pickDummyDate(tester);

      // Leave URL empty and tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Online event link is required.'), findsOneWidget);
    });

    testWidgets('TEST 5: Switch Online -> In Person ignores previous URL and requires location', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter URL while Online
      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://meet.google.com/temp');
      await tester.pumpAndSettle();

      // Switch to In Person
      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      // Online link should be hidden, location shown
      expect(find.text('Online event link*'), findsNothing);
      expect(find.text('Location*'), findsOneWidget);

      // Fill Name and Date
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Switched Event');
      await tester.pumpAndSettle();
      await pickDummyDate(tester);

      // Fill Location
      final locField = find.widgetWithText(TextField, '📍 Enter event location');
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'AUB Building A, Room 203');
      await tester.pumpAndSettle();

      // Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(communityController.events.isNotEmpty, isTrue);
      final created = communityController.events.first;
      expect(created.eventType, 'In person');
      expect(created.location, 'AUB Building A, Room 203');
      expect(created.onlineLink, isEmpty);
    });

    testWidgets('TEST 6: Switch In Person -> Online ignores previous Location and requires URL', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to In Person and enter Location
      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      final locField = find.widgetWithText(TextField, '📍 Enter event location');
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'Phnom Penh Center');
      await tester.pumpAndSettle();

      // Switch back to Online
      await tester.tap(find.text('Online'));
      await tester.pumpAndSettle();

      // Location should be hidden, Online link shown
      expect(find.text('Location*'), findsNothing);
      expect(find.text('Online event link*'), findsOneWidget);

      // Fill Name and Date
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Switched Back Event');
      await tester.pumpAndSettle();
      await pickDummyDate(tester);

      // Fill URL
      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://zoom.us/j/123456');
      await tester.pumpAndSettle();

      // Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(communityController.events.isNotEmpty, isTrue);
      final created = communityController.events.first;
      expect(created.eventType, 'Online');
      expect(created.onlineLink, 'https://zoom.us/j/123456');
      expect(created.location, isEmpty);
    });
  });
}
