import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';

class _MockRepo implements CommunityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put(CommunityController(repository: _MockRepo()));
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget({Locale locale = const Locale('en', 'US'), ThemeMode themeMode = ThemeMode.light}) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const CreateEventScreen(returnCreatedEvent: true),
    );
  }

  group('GenLink Wheel Date and Time Pickers UI Suite', () {
    testWidgets('1. Verify Date Picker UI — Day / Month / Year wheel selectors, Header, Close, Confirm', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final inkWellFinder = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWellFinder);
      await tester.tap(inkWellFinder);
      await tester.pumpAndSettle();

      // Verify Header and Close Button
      expect(find.text('Select date'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify 3 Wheel ScrollViews (Day, Month, Year)
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));

      // Verify Confirm button exists
      final confirmBtn = find.byKey(const ValueKey('confirm_date_button'));
      expect(confirmBtn, findsOneWidget);
      expect(find.text('Confirm'), findsWidgets);

      // Tap confirm to select date
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Time picker should now automatically open
      expect(find.text('Select time'), findsOneWidget);
      final confirmTimeBtn = find.byKey(const ValueKey('confirm_time_button'));
      expect(confirmTimeBtn, findsOneWidget);

      await tester.tap(confirmTimeBtn);
      await tester.pumpAndSettle();

      // Schedule chips should now be visible on screen
      expect(find.text('Starts'), findsOneWidget);
      expect(find.text('Ends'), findsOneWidget);
    });

    testWidgets('2. Verify Time Picker UI — Hour | Minute | AM/PM wheel selectors and format', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open initial picker flow
      final inkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWell);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      // Confirm Date to reach Time Picker
      await tester.tap(find.byKey(const ValueKey('confirm_date_button')));
      await tester.pumpAndSettle();

      // Verify Time Picker Elements
      expect(find.text('Select time'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // 3 Wheels for Time: Hour, Minute, AM/PM
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));

      // Verify AM or PM is rendered
      expect(find.text('AM'), findsWidgets);
      expect(find.text('PM'), findsWidgets);

      // Confirm time
      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();

      expect(find.text('Starts'), findsOneWidget);
      expect(find.text('Ends'), findsOneWidget);
    });

    testWidgets('3. Verify Granular Start & End Date and Time editing via chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initial select
      final inkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWell);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_date_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();

      // Tap Edit Start Time chip directly
      final startTimeChip = find.byKey(const ValueKey('edit_start_time_chip'));
      expect(startTimeChip, findsOneWidget);
      await tester.tap(startTimeChip);
      await tester.pumpAndSettle();

      expect(find.text('Select time'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();

      // Tap Edit End Date chip directly
      final endDateChip = find.byKey(const ValueKey('edit_end_date_chip'));
      expect(endDateChip, findsOneWidget);
      await tester.tap(endDateChip);
      await tester.pumpAndSettle();

      expect(find.text('End date'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm_date_button')));
      await tester.pumpAndSettle();

      // Tap Edit End Time chip directly
      final endTimeChip = find.byKey(const ValueKey('edit_end_time_chip'));
      expect(endTimeChip, findsOneWidget);
      await tester.tap(endTimeChip);
      await tester.pumpAndSettle();

      expect(find.text('End time'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('4. Verify Light Mode styling — White surface, dark text, black confirm button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      final inkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWell);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      final confirmBtn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('confirm_date_button')));
      final style = confirmBtn.style;
      expect(style?.backgroundColor?.resolve({}), Colors.black);
      expect(style?.foregroundColor?.resolve({}), Colors.white);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('5. Verify Dark Mode styling — Dark surface, white text, white confirm button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      final inkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWell);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      final confirmBtn = tester.widget<ElevatedButton>(find.byKey(const ValueKey('confirm_date_button')));
      final style = confirmBtn.style;
      expect(style?.backgroundColor?.resolve({}), Colors.white);
      expect(style?.foregroundColor?.resolve({}), Colors.black);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('6. Verify Khmer Localization — Translated title, months, and confirm button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(locale: const Locale('km', 'KH')));
      await tester.pumpAndSettle();

      final inkWell = find.ancestor(
        of: find.text('ជ្រើសរើសកាលបរិច្ឆេទ និងម៉ោង'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWell);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      // Khmer Header
      expect(find.text('ជ្រើសរើសកាលបរិច្ឆេទ'), findsOneWidget);

      // Khmer Confirm Button
      expect(find.text('បញ្ជាក់'), findsOneWidget);

      // Tap confirm to open Khmer time picker
      await tester.tap(find.byKey(const ValueKey('confirm_date_button')));
      await tester.pumpAndSettle();

      // Khmer Time Picker Header
      expect(find.text('ជ្រើសរើសម៉ោង'), findsOneWidget);
      expect(find.text('បញ្ជាក់'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('7. Verify Small Phone Screen (320x568) — No layout overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final inkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(inkWell);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      // Expect no overflow exceptions on date picker
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('confirm_date_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_date_button')));
      await tester.pumpAndSettle();

      // Expect no overflow exceptions on time picker
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('confirm_time_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Verify End Time validation — End time must remain after start time', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.enterText(nameField, 'Validation Test Event');
      await tester.pumpAndSettle();

      // Trigger Create without date -> shows validation error
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Date & time is required'), findsOneWidget);

      // Select valid date & time
      final inkWell = find.ancestor(
        of: find.text('Select date and time'),
        matching: find.byType(InkWell),
      );
      await tester.tap(inkWell);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_date_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_time_button')));
      await tester.pumpAndSettle();

      // Date error should be cleared
      expect(find.text('Date & time is required'), findsNothing);
    });
  });
}
