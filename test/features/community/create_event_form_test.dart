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

    final confirmDate = find.byKey(const ValueKey('confirm_date_button'));
    if (confirmDate.evaluate().isNotEmpty) {
      await tester.tap(confirmDate);
    } else {
      final confirmText = find.text('Confirm');
      if (confirmText.evaluate().isNotEmpty) {
        await tester.tap(confirmText.first);
      } else {
        await tester.tap(find.text('OK').first);
      }
    }
    await tester.pumpAndSettle();

    final confirmTime = find.byKey(const ValueKey('confirm_time_button'));
    if (confirmTime.evaluate().isNotEmpty) {
      await tester.tap(confirmTime);
    } else {
      final confirmText = find.text('Confirm');
      if (confirmText.evaluate().isNotEmpty) {
        await tester.tap(confirmText.first);
      } else {
        await tester.tap(find.text('OK').first);
      }
    }
    await tester.pumpAndSettle();
  }

  group('CreateEventScreen Form & Conditional Validation Tests', () {
    testWidgets('TEST 1: Online event requires URL and creates successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Online event link*'), findsOneWidget);
      expect(find.text('Location*'), findsNothing);

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Online Tech Meetup');
      await tester.pumpAndSettle();

      await pickDummyDate(tester);

      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://meet.google.com/abc-defg-hij');
      await tester.pumpAndSettle();

      final descField = find.widgetWithText(TextField, 'Tell people about your event');
      await tester.ensureVisible(descField);
      await tester.enterText(descField, 'An exciting online meetup about Flutter.');
      await tester.pumpAndSettle();

      final createButton = find.text('Create');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      expect(find.text('Location*'), findsOneWidget);
      expect(find.text('Online event link*'), findsNothing);

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Flutter Campus Workshop');
      await tester.pumpAndSettle();

      await pickDummyDate(tester);

      final locField = find.widgetWithText(TextField, '📍 Enter event location');
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'ACLEDA University of Business');
      await tester.pumpAndSettle();

      final descField = find.widgetWithText(TextField, 'Tell people about your event');
      await tester.ensureVisible(descField);
      await tester.enterText(descField, 'In-person coding workshop.');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'In-Person Event No Location');
      await tester.pumpAndSettle();

      await pickDummyDate(tester);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Location is required.'), findsOneWidget);
    });

    testWidgets('TEST 4: Online without URL shows "Online event link is required."', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Online Event No URL');
      await tester.pumpAndSettle();

      await pickDummyDate(tester);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Online event link is required.'), findsOneWidget);
    });

    testWidgets('TEST 5: Switch Online -> In Person ignores previous URL and requires location', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://meet.google.com/temp');
      await tester.pumpAndSettle();

      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      expect(find.text('Online event link*'), findsNothing);
      expect(find.text('Location*'), findsOneWidget);

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Switched Event');
      await tester.pumpAndSettle();
      await pickDummyDate(tester);

      final locField = find.widgetWithText(TextField, '📍 Enter event location');
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'AUB Building A, Room 203');
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('In person'));
      await tester.pumpAndSettle();

      final locField = find.widgetWithText(TextField, '📍 Enter event location');
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'Phnom Penh Center');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Online'));
      await tester.pumpAndSettle();

      expect(find.text('Location*'), findsNothing);
      expect(find.text('Online event link*'), findsOneWidget);

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Switched Back Event');
      await tester.pumpAndSettle();
      await pickDummyDate(tester);

      final linkField = find.widgetWithText(TextField, 'e.g. https://meet.google.com/...');
      await tester.ensureVisible(linkField);
      await tester.enterText(linkField, 'https://zoom.us/j/123456');
      await tester.pumpAndSettle();

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
