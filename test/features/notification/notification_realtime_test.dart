import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/core/network/app_realtime_service.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_header_actions.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';

class _MockNotificationRepo extends Mock
    implements NotificationRepositoryImpl {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockNotificationRepo mockRepo;
  late NotificationController controller;

  setUp(() {
    Get.reset();
    mockRepo = _MockNotificationRepo();

    when(
      () => mockRepo.getNotifications(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => NotificationPage(
        items: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 1,
        hasNext: false,
      ),
    );
    when(() => mockRepo.getUnreadCount()).thenAnswer((_) async => 0);
    when(() => mockRepo.markAsRead(any())).thenAnswer((_) async => true);
    when(() => mockRepo.markAllAsRead()).thenAnswer((_) async => true);

    controller = NotificationController(repository: mockRepo);
    Get.put<NotificationController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('GenLink In-App Notification Realtime & Badge Regression Tests', () {
    test(
      'Test 1 — New notification realtime insertion: 2 existing + 1 realtime = 3 notifications',
      () async {
        final now = DateTime.now();
        final existing1 = NotificationModel(
          id: 'notif-1',
          type: NotificationType.like,
          category: NotificationCategory.social,
          title: 'User C liked your post',
          body: 'Post about Flutter',
          senderName: 'User C',
          timeAgo: '5m',
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        );
        final existing2 = NotificationModel(
          id: 'notif-2',
          type: NotificationType.comment,
          category: NotificationCategory.social,
          title: 'User D commented',
          body: 'Great progress!',
          senderName: 'User D',
          timeAgo: '10m',
          timestamp: now.subtract(const Duration(minutes: 10)),
          isRead: true,
        );

        controller.notifications.assignAll([existing1, existing2]);
        controller.totalUnreadCount.value = 1;

        expect(controller.notifications.length, 2);

        final realtimeNotification = NotificationModel(
          id: 'notif-3',
          type: NotificationType.like,
          category: NotificationCategory.social,
          title: 'User A liked your post',
          body: 'Liked your post',
          senderName: 'User A',
          timeAgo: 'Just now',
          timestamp: now,
          isRead: false,
        );

        await controller.onRealtimeNotificationReceived(realtimeNotification);

        expect(controller.notifications.length, 3);
        expect(controller.notifications.first.id, 'notif-3');
        expect(controller.notifications.any((n) => n.id == 'notif-1'), isTrue);
        expect(controller.notifications.any((n) => n.id == 'notif-2'), isTrue);
      },
    );

    test('Test 2 — Unread count increments reactively from 2 to 3', () async {
      final now = DateTime.now();
      controller.totalUnreadCount.value = 2;
      controller.notifications.assignAll([
        NotificationModel(
          id: 'existing-1',
          type: NotificationType.like,
          category: NotificationCategory.social,
          title: 'Existing 1',
          body: 'Body 1',
          senderName: 'User 1',
          timeAgo: '5m',
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        NotificationModel(
          id: 'existing-2',
          type: NotificationType.comment,
          category: NotificationCategory.social,
          title: 'Existing 2',
          body: 'Body 2',
          senderName: 'User 2',
          timeAgo: '10m',
          timestamp: now.subtract(const Duration(minutes: 10)),
          isRead: false,
        ),
      ]);

      expect(controller.totalUnreadCount.value, 2);

      final incoming = NotificationModel(
        id: 'incoming-3',
        type: NotificationType.follow,
        category: NotificationCategory.social,
        title: 'User B followed you',
        body: 'User B started following you',
        senderName: 'User B',
        timeAgo: 'Just now',
        timestamp: now,
        isRead: false,
      );

      await controller.onRealtimeNotificationReceived(incoming);

      expect(controller.totalUnreadCount.value, 3);
      expect(controller.unreadCount, 3);
    });

    test(
      'Test 3 — Duplicate event: same notification arriving twice creates only one item and increments count once',
      () async {
        final now = DateTime.now();
        controller.totalUnreadCount.value = 0;
        controller.notifications.clear();

        final jsonPayload = {
          'id': 'delivery-uuid-101',
          'type': 'COMMUNITY_POST_LIKE',
          'title': 'User A liked your post',
          'message': 'User A liked your post',
          'referenceType': 'POST',
          'referenceId': 'post-777',
          'createdAt': now.toUtc().toIso8601String(),
          'readStatus': false,
          'metadata': {
            'deliveryId': 'delivery-uuid-101',
            'dedupeKey': 'post-like:777:userA',
          },
        };

        await controller.onRealtimeNotificationReceivedFromJson(jsonPayload);
        expect(controller.notifications.length, 1);
        expect(controller.totalUnreadCount.value, 1);

        // Same event arrives again (e.g. from FCM or retry)
        await controller.onRealtimeNotificationReceivedFromJson(jsonPayload);

        expect(
          controller.notifications.length,
          1,
          reason: 'Duplicate notification must not be inserted',
        );
        expect(
          controller.totalUnreadCount.value,
          1,
          reason: 'Unread count must increment only once',
        );
      },
    );

    test(
      'Test 4 — Correct ordering: newest arrives now, existing is 5m old -> newest is at index 0',
      () async {
        final now = DateTime.now();
        final olderNotif = NotificationModel(
          id: 'old-1',
          type: NotificationType.eventReminder,
          category: NotificationCategory.events,
          title: 'Workshop in 2 hours',
          body: 'Event starts soon',
          senderName: 'Tech Club',
          timeAgo: '5m ago',
          timestamp: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        );
        controller.notifications.assignAll([olderNotif]);

        final newerNotif = NotificationModel(
          id: 'new-1',
          type: NotificationType.like,
          category: NotificationCategory.social,
          title: 'User A liked your post',
          body: 'Great photo!',
          senderName: 'User A',
          timeAgo: 'Just now',
          timestamp: now,
          isRead: false,
        );

        await controller.onRealtimeNotificationReceived(newerNotif);

        expect(controller.notifications.length, 2);
        expect(
          controller.notifications[0].id,
          'new-1',
          reason: 'Newest notification must be placed at index 0',
        );
        expect(controller.notifications[1].id, 'old-1');
      },
    );

    testWidgets(
      'Test 5 — Header synchronization: realtime event updates AppHeaderNotificationButton badge live',
      (tester) async {
        controller.totalUnreadCount.value = 1;

        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              appBar: AppBar(actions: const [AppHeaderNotificationButton()]),
            ),
          ),
        );

        expect(find.byType(AppHeaderNotificationButton), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        final incoming = NotificationModel(
          id: 'live-badge-notif',
          type: NotificationType.like,
          category: NotificationCategory.social,
          title: 'User B liked your post',
          body: 'Liked',
          senderName: 'User B',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
          isRead: false,
        );

        await controller.onRealtimeNotificationReceived(incoming);
        await tester.pumpAndSettle();

        expect(
          find.text('2'),
          findsOneWidget,
          reason: 'Header badge must reactively increment to 2 without refresh',
        );
      },
    );

    testWidgets(
      'Test 6 — Read synchronization: mark read decrements unread count and synchronizes header badge',
      (tester) async {
        final notif = NotificationModel(
          id: 'unread-item-1',
          type: NotificationType.like,
          category: NotificationCategory.social,
          title: 'User A liked your post',
          body: 'Liked',
          senderName: 'User A',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
          isRead: false,
        );
        controller.notifications.assignAll([notif]);
        controller.totalUnreadCount.value = 1;

        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              appBar: AppBar(actions: const [AppHeaderNotificationButton()]),
            ),
          ),
        );

        expect(find.text('1'), findsOneWidget);

        await controller.markAsRead('unread-item-1');
        await tester.pumpAndSettle();

        expect(controller.totalUnreadCount.value, 0);
        expect(controller.notifications.first.isRead, isTrue);
        expect(
          find.text('1'),
          findsNothing,
          reason: 'Badge must disappear when unread count reaches 0',
        );
      },
    );

    test(
      'Test 7 — Timestamp verification: parsed through CommunityDateFormatter preserving actual backend createdAt',
      () {
        final backendTimestampStr = '2026-09-17T12:00:00.000Z';
        final json = {
          'id': 'ts-notif-1',
          'type': 'COMMUNITY_POST_LIKE',
          'title': 'User A liked your post',
          'message': 'User A liked your post',
          'createdAt': backendTimestampStr,
          'readStatus': false,
        };

        final model = NotificationModel.fromJson(json);

        expect(
          model.timestamp.isUtc,
          isFalse,
          reason: 'Converted to local device time for accurate display',
        );
        expect(model.timeAgo, isNotEmpty);
        expect(model.timeAgo, isNot('Unknown'));
      },
    );

    test(
      'Test 8 — Mobile Push compatibility: STOMP event + FCM foreground push does not duplicate notification',
      () async {
        final now = DateTime.now();
        controller.notifications.clear();
        controller.totalUnreadCount.value = 0;

        // 1. Simulating STOMP WebSocket arrival
        final stompJson = {
          'deliveryId': 'shared-delivery-uuid-999',
          'type': 'COMMUNITY_POST_LIKE',
          'title': 'User A liked your post',
          'message': 'User A liked your post',
          'referenceType': 'POST',
          'referenceId': 'post-100',
          'dedupeKey': 'post-like:post-100:user-a',
          'createdAt': now.toUtc().toIso8601String(),
        };
        await controller.onRealtimeNotificationReceivedFromJson(stompJson);
        expect(controller.notifications.length, 1);
        expect(controller.totalUnreadCount.value, 1);

        // 2. Simulating simultaneous FCM foreground payload delivery for the same action
        final fcmPayload = {
          'title': 'User A liked your post',
          'body': 'User A liked your post',
          'type': 'COMMUNITY_POST_LIKE',
          'deliveryId': 'shared-delivery-uuid-999',
          'referenceType': 'POST',
          'referenceId': 'post-100',
          'dedupeKey': 'post-like:post-100:user-a',
        };
        await controller.onRealtimeNotificationReceivedFromPayload(fcmPayload);

        expect(
          controller.notifications.length,
          1,
          reason:
              'STOMP and FCM for the same deliveryId must not create duplicates',
        );
        expect(controller.totalUnreadCount.value, 1);
      },
    );

    test(
      'AppRealtimeService stream simulation correctly routes to NotificationController',
      () async {
        final realtimeService = AppRealtimeService();
        Get.put<AppRealtimeService>(realtimeService);

        controller.notifications.clear();
        controller.totalUnreadCount.value = 0;

        final payload = {
          'id': 'simulated-ws-1',
          'type': 'COMMUNITY_POST_LIKE',
          'title': 'Live socket like',
          'message': 'Someone liked your post via WebSocket',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'readStatus': false,
        };

        realtimeService.simulateIncomingNotification(payload);

        expect(controller.notifications.length, 1);
        expect(controller.notifications.first.title, 'Live socket like');
        expect(controller.totalUnreadCount.value, 1);
      },
    );

    test(
      'backend entertainment and productivity notification types parse to truthful UI states',
      () {
        final challenge = NotificationModel.fromJson(const {
          'deliveryId': 'challenge-delivery',
          'type': 'ENTERTAINMENT_CHALLENGE',
          'referenceType': 'CHALLENGE',
          'referenceId': 'challenge-1',
        });
        final badge = NotificationModel.fromJson(const {
          'deliveryId': 'badge-delivery',
          'type': 'ENTERTAINMENT_BADGE',
          'referenceType': 'BADGE',
          'referenceId': 'badge-1',
        });
        final levelUp = NotificationModel.fromJson(const {
          'deliveryId': 'level-delivery',
          'type': 'ENTERTAINMENT_LEVEL_UP',
          'referenceType': 'ACHIEVEMENT',
          'referenceId': 'user-1',
        });
        final habit = NotificationModel.fromJson(const {
          'deliveryId': 'habit-delivery',
          'type': 'PRODUCTIVITY_HABIT',
          'referenceType': 'HABIT',
          'referenceId': 'habit-1',
        });
        final goal = NotificationModel.fromJson(const {
          'deliveryId': 'goal-delivery',
          'type': 'PRODUCTIVITY_GOAL',
          'referenceType': 'GOAL',
          'referenceId': 'goal-1',
        });

        expect(challenge.type, NotificationType.challengeReward);
        expect(challenge.category, NotificationCategory.updates);
        expect(challenge.id, 'challenge-delivery');
        expect(challenge.metadata?['deliveryId'], 'challenge-delivery');
        expect(badge.type, NotificationType.badgeAwarded);
        expect(badge.category, NotificationCategory.updates);
        expect(levelUp.type, NotificationType.levelUp);
        expect(levelUp.targetType, 'ACHIEVEMENT');
        expect(habit.type, NotificationType.streakMilestone);
        expect(habit.category, NotificationCategory.reminders);
        expect(goal.type, NotificationType.goalMilestone);
        expect(goal.category, NotificationCategory.reminders);
      },
    );

    test(
      'delivery id deduplicates a STOMP payload before the REST identity is known',
      () async {
        controller.notifications.clear();
        controller.totalUnreadCount.value = 0;
        final payload = {
          'deliveryId': 'same-delivery',
          'type': 'ENTERTAINMENT_BADGE',
          'title': 'Badge unlocked',
          'message': 'Quiz Champion',
          'referenceType': 'BADGE',
          'referenceId': 'badge-1',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'readStatus': false,
        };

        await controller.onRealtimeNotificationReceivedFromJson(payload);
        await controller.onRealtimeNotificationReceivedFromJson(payload);

        expect(controller.notifications.length, 1);
        expect(controller.notifications.single.id, 'same-delivery');
        expect(controller.totalUnreadCount.value, 1);
      },
    );
  });
}
