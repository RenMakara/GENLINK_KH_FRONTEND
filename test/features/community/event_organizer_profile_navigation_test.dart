import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';
import 'package:genlink_frontend/features/profile/presentation/utils/profile_navigation.dart';

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventModel organizerUsername serialization & parsing', () {
    test('parses organizerUsername from backend organizer object', () {
      final json = {
        'eventId': 'event-101',
        'title': 'Flutter Workshop',
        'organizer': {
          'userId': 'user-uuid-123',
          'fullName': 'Nat Sok',
          'username': 'natsok_dev',
          'avatarUrl': 'https://example.com/avatar.png',
        },
      };

      final event = EventModel.fromJson(json);

      expect(event.id, equals('event-101'));
      expect(event.organizerName, equals('Nat Sok'));
      expect(event.organizerUsername, equals('natsok_dev'));
      expect(event.organizerId, equals('user-uuid-123'));
      expect(event.organizerAvatar, equals('https://example.com/avatar.png'));
    });

    test('toJson includes organizerUsername when present', () {
      final event = EventModel(
        id: 'event-102',
        title: 'Tech Meetup',
        organizerName: 'Nat',
        organizerUsername: 'nat_official',
        organizerId: 'org-123',
      );

      final json = event.toJson();
      expect(json['organizerUsername'], equals('nat_official'));
      expect(json['organizerName'], equals('Nat'));
    });

    test('copyWith updates or preserves organizerUsername', () {
      final original = EventModel(
        id: 'event-103',
        title: 'Original Title',
        organizerName: 'Nat',
        organizerUsername: 'nat_original',
      );

      final copiedWithSame = original.copyWith(title: 'New Title');
      expect(copiedWithSame.organizerUsername, equals('nat_original'));

      final copiedWithNew = original.copyWith(organizerUsername: 'nat_updated');
      expect(copiedWithNew.organizerUsername, equals('nat_updated'));
    });
  });

  group('ProfileNavigation routing logic', () {
    setUp(() {
      Get.reset();
      Get.testMode = true;
      final auth = _FakeAuthController();
      auth.currentUser.value = UserEntity(
        id: 'my-current-user-id',
        fullName: 'Current User',
        username: 'my_username',
        email: 'me@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'en',
        role: 'USER',
        active: true,
      );
      Get.put<AuthController>(auth);
    });

    tearDown(() {
      Get.reset();
    });

    test('ownerAwareUsername returns null when target matches current userId', () {
      final result = ProfileNavigation.ownerAwareUsername(
        userId: 'my-current-user-id',
      );
      expect(result, isNull);
    });

    test('ownerAwareUsername returns null when target matches current username', () {
      final result = ProfileNavigation.ownerAwareUsername(
        username: 'MY_USERNAME',
      );
      expect(result, isNull);
    });

    test('ownerAwareUsername returns username for other user', () {
      final result = ProfileNavigation.ownerAwareUsername(
        username: 'natsok_dev',
        userId: 'some-other-uuid',
      );
      expect(result, equals('natsok_dev'));
    });

    test('ownerAwareUsername returns userId when username is null for other user', () {
      final result = ProfileNavigation.ownerAwareUsername(
        username: null,
        userId: 'other-user-uuid-999',
      );
      expect(result, equals('other-user-uuid-999'));
    });
  });

  group('EventDetailsScreen organizer profile card tap', () {
    setUp(() {
      Get.reset();
      Get.testMode = true;
      final auth = _FakeAuthController();
      auth.currentUser.value = UserEntity(
        id: 'my-current-user-id',
        fullName: 'Current User',
        username: 'my_username',
        email: 'me@example.com',
        emailVerified: true,
        accountStatus: 'ACTIVE',
        totalXp: 100,
        level: 1,
        preferredLanguage: 'en',
        role: 'USER',
        active: true,
      );
      Get.put<AuthController>(auth);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('tapping organizer card navigates to public profile using organizerUsername', (tester) async {
      final event = EventModel(
        id: 'event-505',
        title: 'Flutter Developer Meetup',
        organizerName: 'Nat',
        organizerUsername: 'nat_dev',
        organizerId: 'nat-uuid-777',
      );

      String? openedRoute;
      Map<String, String?>? openedParams;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => EventDetailsScreen(event: event),
            ),
            GetPage(
              name: AppRoutes.profile,
              page: () {
                openedRoute = Get.currentRoute;
                openedParams = Get.parameters;
                return const Scaffold(body: Text('Profile Page'));
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Find organizer card containing the organizer name
      final organizerCard = find.text('Nat');
      expect(organizerCard, findsOneWidget);

      await tester.tap(organizerCard);
      await tester.pumpAndSettle();

      expect(openedRoute, contains(AppRoutes.profile));
      expect(openedParams?['username'], equals('nat_dev'));
    });

    testWidgets('tapping organizer card navigates to owner profile when viewer is organizer', (tester) async {
      final event = EventModel(
        id: 'event-506',
        title: 'My Hosted Event',
        organizerName: 'Current User',
        organizerUsername: 'my_username',
        organizerId: 'my-current-user-id',
      );

      String? openedRoute;
      Map<String, String?>? openedParams;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => EventDetailsScreen(event: event),
            ),
            GetPage(
              name: AppRoutes.profile,
              page: () {
                openedRoute = Get.currentRoute;
                openedParams = Get.parameters;
                return const Scaffold(body: Text('Profile Page'));
              },
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // The organizer card displays the organizer's name
      final organizerCard = find.text('Current User');
      expect(organizerCard, findsOneWidget);

      await tester.tap(organizerCard);
      await tester.pumpAndSettle();

      expect(openedRoute, equals(AppRoutes.profile));
      // Owner profile navigation does not pass username query param
      expect(openedParams?['username'], isNull);
    });
  });
}
