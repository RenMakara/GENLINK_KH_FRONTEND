import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_register_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/events_screen.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return null;
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x54,
    0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05,
    0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockCommunityRepo implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async =>
      CommunityPostModel(
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
  Future<bool> toggleEventBookmark(String eventId, {required bool isCurrentlyBookmarked}) async => true;

  @override
  Future<bool> deleteEvent(String eventId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserEntity _makeTestUser({
  required String id,
  required String fullName,
  required String username,
  String? avatarUrl,
}) {
  return UserEntity(
    id: id,
    fullName: fullName,
    username: username,
    email: '$username@example.com',
    avatarUrl: avatarUrl,
    emailVerified: true,
    accountStatus: 'ACTIVE',
    totalXp: 100,
    level: 2,
    preferredLanguage: 'en',
    role: 'STUDENT',
    active: true,
  );
}

void main() {
  late CommunityController communityController;
  late _MockAuthController authController;

  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
    Get.reset();
    Get.testMode = true;
    communityController = Get.put(CommunityController(repository: _MockCommunityRepo()));
    authController = _MockAuthController();
    Get.put<AuthController>(authController);
  });

  tearDown(() {
    HttpOverrides.global = null;
    Get.reset();
  });

  group('Event Model JSON & Organizer Avatar Mapping Tests', () {
    test('EventModel.fromJson maps organizer avatar from nested organizer object', () {
      final jsonWithAvatarUrl = {
        'id': 'ev_test_1',
        'title': 'Test Event 1',
        'organizer': {
          'id': 'org_1',
          'name': 'GDG Phnom Penh',
          'avatarUrl': 'https://example.com/avatar1.png',
        },
      };
      final event1 = EventModel.fromJson(jsonWithAvatarUrl);
      expect(event1.organizerAvatar, equals('https://example.com/avatar1.png'));

      final jsonWithAvatar = {
        'id': 'ev_test_2',
        'title': 'Test Event 2',
        'organizer': {
          'id': 'org_2',
          'name': 'AUB Club',
          'avatar': 'https://example.com/avatar2.png',
        },
      };
      final event2 = EventModel.fromJson(jsonWithAvatar);
      expect(event2.organizerAvatar, equals('https://example.com/avatar2.png'));

      final jsonWithProfileImage = {
        'id': 'ev_test_3',
        'title': 'Test Event 3',
        'organizer': {
          'id': 'org_3',
          'name': 'CADT Community',
          'profileImage': 'https://example.com/avatar3.png',
        },
      };
      final event3 = EventModel.fromJson(jsonWithProfileImage);
      expect(event3.organizerAvatar, equals('https://example.com/avatar3.png'));
    });

    test('EventModel.fromJson maps organizer avatar from top-level fields', () {
      final jsonTopLevel = {
        'id': 'ev_test_4',
        'title': 'Test Event 4',
        'organizerName': 'RUPP STEM',
        'organizerAvatar': 'https://example.com/avatar4.png',
      };
      final event = EventModel.fromJson(jsonTopLevel);
      expect(event.organizerAvatar, equals('https://example.com/avatar4.png'));
    });

    test('EventModel.fromJson sanitizes empty or whitespace avatar string to null', () {
      final jsonEmpty = {
        'id': 'ev_test_5',
        'title': 'Test Event 5',
        'organizer': {
          'name': 'No Avatar Org',
          'avatarUrl': '   ',
        },
      };
      final event = EventModel.fromJson(jsonEmpty);
      expect(event.organizerAvatar, isNull);
    });

    test('EventModel.fromJson maps organizer name from organizer.name and organizer.displayName', () {
      final jsonName = {
        'id': 'ev_test_name',
        'title': 'Test Event Name',
        'organizer': {
          'id': 'org_nat',
          'name': 'nat',
          'avatarUrl': 'https://example.com/nat.png',
        },
      };
      final event1 = EventModel.fromJson(jsonName);
      expect(event1.organizerName, equals('nat'));
      expect(event1.organizerAvatar, equals('https://example.com/nat.png'));

      final jsonDisplayName = {
        'id': 'ev_test_disp',
        'title': 'Test Event Display Name',
        'organizer': {
          'id': 'org_nat_2',
          'displayName': 'Sokny Nat',
        },
      };
      final event2 = EventModel.fromJson(jsonDisplayName);
      expect(event2.organizerName, equals('Sokny Nat'));
    });
  });

  group('Issue 1: Bookmark Color Neutral Consistency Tests', () {
    testWidgets('Unsaved event renders outline bookmark with neutral/muted color', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final unsavedEvent = EventModel(
        id: 'ev_unsaved',
        title: 'Neutral Bookmark Event',
        organizerName: 'Tech Guild',
        eventType: 'In person',
        location: 'Phnom Penh',
        dateString: 'Oct 20',
        timeString: '10:00 AM',
        category: 'Workshop',
        isBookmarked: false,
      );

      communityController.events.assignAll([unsavedEvent]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: EventsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final bookmarkIcon = find.byIcon(Icons.bookmark_border_rounded);
      expect(bookmarkIcon, findsOneWidget);

      final iconWidget = tester.widget<Icon>(bookmarkIcon);
      expect(iconWidget.color, isNot(equals(AppColors.communityAccent)));
      expect(iconWidget.color, isNot(equals(Colors.blue)));
    });

    testWidgets('Saved event renders filled bookmark with monochrome neutral color (no blue)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final savedEvent = EventModel(
        id: 'ev_saved',
        title: 'Saved Bookmark Event',
        organizerName: 'Tech Guild',
        eventType: 'In person',
        location: 'Phnom Penh',
        dateString: 'Oct 20',
        timeString: '10:00 AM',
        category: 'Workshop',
        isBookmarked: true,
      );

      communityController.events.assignAll([savedEvent]);

      // Test Dark Mode: should be white, NOT blue
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: EventsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final bookmarkIconDark = find.byIcon(Icons.bookmark_rounded);
      expect(bookmarkIconDark, findsOneWidget);
      final iconDark = tester.widget<Icon>(bookmarkIconDark);
      expect(iconDark.color, equals(Colors.white));
      expect(iconDark.color, isNot(equals(AppColors.communityAccent)));
      expect(iconDark.color, isNot(equals(Colors.blue)));

      // Test Light Mode: should be black87, NOT blue
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: const Scaffold(body: EventsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final bookmarkIconLight = find.byIcon(Icons.bookmark_rounded);
      expect(bookmarkIconLight, findsOneWidget);
      final iconLight = tester.widget<Icon>(bookmarkIconLight);
      expect(iconLight.color, equals(Colors.black87));
      expect(iconLight.color, isNot(equals(AppColors.communityAccent)));
      expect(iconLight.color, isNot(equals(Colors.blue)));
    });

    testWidgets('CommunityScreen Events Tab uses neutral monochrome bookmark', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final savedEvent = EventModel(
        id: 'ev_comm_saved',
        title: 'Community Tab Saved Event',
        organizerName: 'Community Org',
        eventType: 'In person',
        location: 'Phnom Penh',
        dateString: 'Oct 25',
        timeString: '3:00 PM',
        category: 'Conference',
        isBookmarked: true,
      );
      communityController.events.assignAll([savedEvent]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Event Tab
      final eventTab = find.text('Event');
      expect(eventTab, findsOneWidget);
      await tester.tap(eventTab);
      await tester.pumpAndSettle();

      final bookmarkIcon = find.byIcon(Icons.bookmark_rounded);
      expect(bookmarkIcon, findsOneWidget);
      final iconWidget = tester.widget<Icon>(bookmarkIcon);
      expect(iconWidget.color, isNot(equals(AppColors.communityAccent)));
      expect(iconWidget.color, isNot(equals(Colors.blue)));
    });

    testWidgets('EventDetail and EventList bookmark visual consistency (neutral outline vs filled, no blue)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final event = EventModel(
        id: 'ev_consistent_bm',
        title: 'Consistent Bookmark Event',
        organizerName: 'Dev Org',
        eventType: 'In person',
        location: 'Hall 1',
        dateString: 'Nov 20',
        timeString: '10:00 AM',
        category: 'Workshop',
        isBookmarked: false,
      );

      communityController.events.assignAll([event]);

      // Verify Event Details Screen unsaved bookmark is white/neutral outline
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();

      final unsavedFinder = find.byIcon(Icons.bookmark_border_rounded);
      expect(unsavedFinder, findsOneWidget);
      final unsavedIcon = tester.widget<Icon>(unsavedFinder);
      expect(unsavedIcon.color, isNot(equals(Colors.blue)));

      // Tap to save
      await tester.tap(unsavedFinder);
      await tester.pumpAndSettle();

      final savedFinder = find.byIcon(Icons.bookmark_rounded);
      expect(savedFinder, findsOneWidget);
      final savedIcon = tester.widget<Icon>(savedFinder);
      expect(savedIcon.color, equals(Colors.white));
      expect(savedIcon.color, isNot(equals(Colors.blue)));
    });
  });

  group('Issue 2: Organizer Avatar Data Flow & Fallback Tests', () {
    testWidgets('Organizer avatar uses neutral initials placeholder when no avatar URL and user is not organizer', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Set logged in user as someone else with an avatar
      authController.currentUser.value = _makeTestUser(
        id: 'user_logged_in',
        fullName: 'Current Logged In User',
        username: 'userlogin',
        avatarUrl: 'https://example.com/current_user_avatar.png',
      );

      final otherUserEvent = EventModel(
        id: 'ev_other_user',
        title: 'Other User Event',
        organizerId: 'org_different_person',
        organizerName: 'Alice Johnson',
        organizerAvatar: null, // No avatar URL
        eventType: 'In person',
        location: 'Building B',
        dateString: 'Nov 01',
        timeString: '10:00 AM',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: otherUserEvent),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initials 'A' is rendered for Alice Johnson
      expect(find.text('A'), findsOneWidget);

      final circleAvatarFinder = find.byType(CircleAvatar);
      expect(circleAvatarFinder, findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(circleAvatarFinder);
      expect(circleAvatar.foregroundImage, isNull);
    });

    testWidgets('Organizer avatar uses CurrentUser avatar ONLY when current user IS organizer and event avatar is null', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      authController.currentUser.value = _makeTestUser(
        id: 'user_my_id',
        fullName: 'My User',
        username: 'myuser',
        avatarUrl: 'https://example.com/my_own_avatar.png',
      );

      final myEvent = EventModel(
        id: 'ev_my_event',
        title: 'My Own Event',
        organizerId: 'user_my_id', // User IS organizer
        organizerName: 'My User',
        organizerAvatar: null,
        eventType: 'In person',
        location: 'Hall A',
        dateString: 'Nov 02',
        timeString: '1:00 PM',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: myEvent),
        ),
      );
      await tester.pumpAndSettle();

      final circleAvatarFinder = find.byType(CircleAvatar);
      expect(circleAvatarFinder, findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(circleAvatarFinder);
      expect(circleAvatar.foregroundImage, isA<NetworkImage>());
      expect(
        (circleAvatar.foregroundImage as NetworkImage).url,
        equals('https://example.com/my_own_avatar.png'),
      );
    });
  });

  group('Issue 3: CreateEventScreen Discard Draft Dialog Styling Tests', () {
    testWidgets('Discard Draft Dialog renders 16px radius, red Discard, neutral Keep Editing', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const CreateEventScreen(returnCreatedEvent: true),
        ),
      );
      await tester.pumpAndSettle();

      // Enter event name to mark draft dirty
      final nameField = find.widgetWithText(TextField, 'Event name');
      await tester.enterText(nameField, 'Draft Event to Discard');
      await tester.pumpAndSettle();

      // Tap back button
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Discard draft dialog should appear
      expect(find.text('Discard Draft?'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);

      // Verify rounded shape of AlertDialog
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      final dialog = tester.widget<AlertDialog>(dialogFinder);
      final shape = dialog.shape as RoundedRectangleBorder?;
      expect(shape, isNotNull);
      expect(shape!.borderRadius, equals(BorderRadius.circular(16)));

      // Verify Keep Editing dismisses dialog
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard Draft?'), findsNothing);
      expect(find.text('Draft Event to Discard'), findsOneWidget);
    });
  });

  group('Issue 4 & 5: University & Faculty Selector UI Polish Tests', () {
    testWidgets('University selector opens bottom sheet with 24px radius, search field, checkmark', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testEvent = EventModel(
        id: 'ev_reg_test',
        title: 'Registration Polish Event',
        organizerName: 'ACLEDA University',
        eventType: 'In person',
        location: 'Phnom Penh',
        dateString: 'Nov 15',
        timeString: '9:00 AM',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventRegisterScreen(event: testEvent),
        ),
      );
      await tester.pumpAndSettle();

      // Tap University selector field
      final uniField = find.text('Select your university');
      expect(uniField, findsOneWidget);
      await tester.tap(uniField);
      await tester.pumpAndSettle();

      // Bottom sheet is visible with search field
      final searchInput = find.widgetWithText(TextField, 'Search university...');
      expect(searchInput, findsOneWidget);

      // Verify bottom sheet top rounded corner 24px via modal sheet Material shape
      final sheetMaterialFinder = find.byWidgetPredicate((w) =>
          w is Material &&
          w.shape is RoundedRectangleBorder &&
          (w.shape as RoundedRectangleBorder).borderRadius ==
              const BorderRadius.vertical(top: Radius.circular(24)));
      expect(sheetMaterialFinder, findsOneWidget);

      // Select an option (e.g. ACLEDA University of Business)
      final acledaOption = find.text('ACLEDA University of Business (AUB)');
      expect(acledaOption, findsOneWidget);
      await tester.tap(acledaOption);
      await tester.pumpAndSettle();

      // Now open again and verify checkmark on selected option
      final selectedUniField = find.text('ACLEDA University of Business (AUB)');
      expect(selectedUniField, findsOneWidget);
      await tester.tap(selectedUniField);
      await tester.pumpAndSettle();

      // Checkmark icon should be present for the selected item
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Faculty selector opens bottom sheet with consistent 24px styling', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testEvent = EventModel(
        id: 'ev_reg_fac_test',
        title: 'Registration Faculty Event',
        organizerName: 'CADT',
        eventType: 'In person',
        location: 'Phnom Penh',
        dateString: 'Nov 15',
        timeString: '9:00 AM',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventRegisterScreen(event: testEvent),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Faculty selector field
      final facultyField = find.text('Select your faculty');
      expect(facultyField, findsOneWidget);
      await tester.tap(facultyField);
      await tester.pumpAndSettle();

      // Bottom sheet search field
      final searchInput = find.widgetWithText(TextField, 'Search faculty...');
      expect(searchInput, findsOneWidget);

      // Verify sheet top rounded corner 24px
      final sheetMaterialFinder = find.byWidgetPredicate((w) =>
          w is Material &&
          w.shape is RoundedRectangleBorder &&
          (w.shape as RoundedRectangleBorder).borderRadius ==
              const BorderRadius.vertical(top: Radius.circular(24)));
      expect(sheetMaterialFinder, findsOneWidget);

      // Select Computer Science & IT
      final csOption = find.text('Computer Science & IT');
      expect(csOption, findsOneWidget);
      await tester.tap(csOption);
      await tester.pumpAndSettle();

      expect(find.text('Computer Science & IT'), findsOneWidget);
    });
  });

  group('Issue 6: Delete Event & Owner Actions UX Tests', () {
    testWidgets('Owner sees More (...) button on top cover bar with Edit and Delete options', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      authController.currentUser.value = _makeTestUser(
        id: 'user_owner_id',
        fullName: 'Event Owner',
        username: 'owner',
      );

      final ownedEvent = EventModel(
        id: 'ev_owned_1',
        title: 'Owned Event for Deletion',
        organizerId: 'user_owner_id', // Matches current user
        organizerName: 'Event Owner',
        eventType: 'In person',
        location: 'Auditorium',
        dateString: 'Dec 01',
        timeString: '2:00 PM',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: ownedEvent),
        ),
      );
      await tester.pumpAndSettle();

      // Owner should see the top more_horiz_rounded button
      final moreButton = find.byIcon(Icons.more_horiz_rounded);
      expect(moreButton, findsOneWidget);

      // Tap the More button to open popup menu
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Delete Event'), findsOneWidget);

      // Tap Delete Event to open confirmation dialog
      await tester.tap(find.text('Delete Event'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Event?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this event? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel dismisses confirmation
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Event?'), findsNothing);
    });

    testWidgets('Non-owner does NOT see More (...) button on top cover bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      authController.currentUser.value = _makeTestUser(
        id: 'user_guest_id',
        fullName: 'Guest User',
        username: 'guest',
      );

      final otherEvent = EventModel(
        id: 'ev_not_owned',
        title: 'Non-owned Event',
        organizerId: 'different_organizer_id',
        organizerName: 'Different Organizer',
        eventType: 'In person',
        location: 'Auditorium',
        dateString: 'Dec 01',
        timeString: '2:00 PM',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: otherEvent),
        ),
      );
      await tester.pumpAndSettle();

      // Top more_horiz_rounded button MUST NOT exist for non-owners
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
    });
  });

  group('Issue 7: Event Category Icons (No Emojis) Tests', () {
    testWidgets('Category badges display Material icons instead of emoji characters in EventsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final workshopEvent = EventModel(
        id: 'ev_cat_1',
        title: 'Flutter Masterclass',
        organizerName: 'Dev Club',
        eventType: 'In person',
        location: 'Room 101',
        dateString: 'Nov 20',
        timeString: '10:00 AM',
        category: 'Workshop',
      );
      communityController.events.assignAll([workshopEvent]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: EventsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category icon is rendered (build_outlined for Workshop)
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);

      // Verify emoji characters are NOT used in category badge
      expect(find.textContaining('💻'), findsNothing);
      expect(find.textContaining('🎨'), findsNothing);
      expect(find.textContaining('🚀'), findsNothing);
    });

    testWidgets('EventDetailsScreen cover category badge shows Material icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final hackathonEvent = EventModel(
        id: 'ev_hackathon',
        title: 'Global Hackathon 2026',
        organizerName: 'Tech Hub',
        eventType: 'Online',
        dateString: 'Dec 05',
        timeString: '8:00 AM',
        category: 'Hackathon',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: hackathonEvent),
        ),
      );
      await tester.pumpAndSettle();

      // Hackathon uses terminal outlined icon
      expect(find.byIcon(Icons.terminal_outlined), findsOneWidget);
      expect(find.textContaining('🚀'), findsNothing);
    });

    testWidgets('CreateEventScreen category options use Material icons without emojis', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          themeMode: ThemeMode.dark,
          home: const CreateEventScreen(returnCreatedEvent: true),
        ),
      );
      await tester.pumpAndSettle();

      // Open category picker bottom sheet
      final catPickerFinder = find.text('Select a category');
      expect(catPickerFinder, findsOneWidget);
      await tester.ensureVisible(catPickerFinder);
      await tester.tap(catPickerFinder);
      await tester.pumpAndSettle();

      // Verify category chips render Material icons
      expect(find.byIcon(Icons.computer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.byIcon(Icons.business_center_outlined), findsOneWidget);

      // Verify emoji characters are NOT used
      expect(find.textContaining('💻'), findsNothing);
      expect(find.textContaining('🎨'), findsNothing);
      expect(find.textContaining('💼'), findsNothing);
    });
  });

  group('Issue 9 & Localization: Khmer Localization & Dual Theme Rendering Tests', () {
    testWidgets('Khmer localization renders correctly without missing translations or overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final event = EventModel(
        id: 'ev_km_1',
        title: 'សិក្ខាសាលា Flutter',
        organizerName: 'GenLink Cambodia',
        eventType: 'In person',
        location: 'ភ្នំពេញ',
        dateString: 'Dec 10',
        timeString: '9:00 AM',
        category: 'Workshop',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Light and dark theme rendering for EventDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final event = EventModel(
        id: 'ev_theme_test',
        title: 'Theme Test Event',
        organizerName: 'Design Guild',
        eventType: 'In person',
        location: 'Room A',
        dateString: 'Dec 12',
        timeString: '10:00 AM',
        category: 'Workshop',
      );

      // Light mode
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dark mode
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Issue 8: Organizer Notification Flow & Mapping Tests', () {
    test('NotificationModel.fromJson parses EVENT_RSVP correctly into events category', () {
      final json = {
        'id': 'notif_rsvp_1',
        'type': 'EVENT_RSVP',
        'title': 'New Event Registration',
        'body': 'Nat registered for How to Write CV & Cover Letters Effectively.',
        'targetId': 'ev_cv_workshop',
        'targetType': 'EVENT',
        'actorName': 'Nat',
        'actorAvatar': 'https://example.com/nat_avatar.png',
        'createdAt': '2026-09-20T05:30:00Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.type, equals(NotificationType.eventRsvp));
      expect(notif.category, equals(NotificationCategory.events));
      expect(notif.title, equals('New Event Registration'));
      expect(notif.body, equals('Nat registered for How to Write CV & Cover Letters Effectively.'));
      expect(notif.targetId, equals('ev_cv_workshop'));
      expect(notif.targetType, equals('EVENT'));
      expect(notif.senderName, equals('Nat'));
    });

    test('NotificationModel.fromJson parses lowercase event_rsvp and rsvp keywords', () {
      final json = {
        'id': 'notif_rsvp_2',
        'notificationType': 'event_rsvp',
        'title': 'Event RSVP',
        'message': 'Sokny registered for Tech Conference',
        'targetId': 'ev_conf_1',
        'targetType': 'EVENT',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.type, equals(NotificationType.eventRsvp));
      expect(notif.category, equals(NotificationCategory.events));
    });
  });
}
