import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/notification/data/firebase_mobile_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobilePushNotificationPayload', () {
    test('parses the backend navigation contract', () {
      final payload = MobilePushNotificationPayload.fromData(
        const {
          'deliveryId': 'delivery-1',
          'type': 'COMMUNITY_EVENT_RSVP',
          'referenceType': 'EVENT',
          'referenceId': 'event-1',
          'dedupeKey': 'event-rsvp:event-1:user-1',
        },
        title: 'New event RSVP',
        body: 'A student registered for your event.',
      );

      expect(payload.title, 'New event RSVP');
      expect(payload.body, 'A student registered for your event.');
      expect(payload.type, 'COMMUNITY_EVENT_RSVP');
      expect(payload.deliveryId, 'delivery-1');
      expect(payload.referenceType, 'EVENT');
      expect(payload.referenceId, 'event-1');
      expect(payload.dedupeKey, 'event-rsvp:event-1:user-1');
      expect(payload.notificationId, greaterThan(0));
    });

    test('uses safe defaults when a data-only message omits display text', () {
      final payload = MobilePushNotificationPayload.fromData(const {});

      expect(payload.title, 'GenLink KH');
      expect(payload.body, 'You have a new notification.');
      expect(payload.type, 'SYSTEM');
    });
  });

  group('MobilePushNotificationRouter', () {
    test('routes event and finance references to existing screens', () {
      expect(
        MobilePushNotificationRouter.destinationFor(
          MobilePushNotificationPayload.fromData(const {
            'type': 'COMMUNITY_EVENT_RSVP',
            'referenceType': 'EVENT',
          }),
        ),
        MobilePushNotificationDestination.events,
      );
      expect(
        MobilePushNotificationRouter.destinationFor(
          MobilePushNotificationPayload.fromData(const {
            'type': 'BUDGET_WARNING',
          }),
        ),
        MobilePushNotificationDestination.budget,
      );
      expect(
        MobilePushNotificationRouter.destinationFor(
          MobilePushNotificationPayload.fromData(const {
            'type': 'COMMUNITY_EVENT_PAYMENT',
            'referenceType': 'EVENT',
          }),
        ),
        MobilePushNotificationDestination.events,
      );
    });

    test('routes chat and social references to chat and friend request screens', () {
      expect(
        MobilePushNotificationRouter.destinationFor(
          MobilePushNotificationPayload.fromData(const {
            'type': 'CHAT_NEW_MESSAGE',
            'referenceType': 'CHAT_ROOM',
            'referenceId': 'room-123',
          }),
        ),
        MobilePushNotificationDestination.chat,
      );
      expect(
        MobilePushNotificationRouter.destinationFor(
          MobilePushNotificationPayload.fromData(const {
            'type': 'COMMUNITY_FOLLOW_REQUEST',
            'referenceType': 'USER',
            'referenceId': 'user-456',
          }),
        ),
        MobilePushNotificationDestination.friendRequests,
      );
    });

    test('falls back to the notification center for unknown metadata', () {
      expect(
        MobilePushNotificationRouter.destinationFor(
          MobilePushNotificationPayload.fromData(const {
            'type': 'UNMAPPED_SYSTEM_ALERT',
          }),
        ),
        MobilePushNotificationDestination.notifications,
      );
    });
  });
}
