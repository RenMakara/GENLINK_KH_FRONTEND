import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/chat/chat_navigation.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_header_actions.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';

class MockDio extends Mock implements Dio {}
class MockNotificationRepository extends Mock implements NotificationRepositoryImpl {}

void main() {
  late MockDio mockDio;
  late ChatRemoteDataSource dataSource;
  late ChatRepositoryImpl repository;
  late ChatController controller;

  final convA = ChatConversationModel(
    id: 'room-A',
    name: 'User A',
    avatar: 'assets/images/user_profile.png',
    isGroup: false,
    isOnline: true,
    lastMessage: 'Message from A',
    lastMessageTime: '10:00 AM',
    unreadCount: 1,
  );

  final convB = ChatConversationModel(
    id: 'room-B',
    name: 'User B',
    avatar: 'assets/images/heng_chansela_profile.png',
    isGroup: false,
    isOnline: true,
    lastMessage: 'Message from B',
    lastMessageTime: '10:30 AM',
    unreadCount: 2,
  );

  setUp(() {
    Get.reset();
    mockDio = MockDio();
    Get.put<Dio>(mockDio);

    when(() => mockDio.get<dynamic>(any(that: contains('/community/chats/unread-count'))))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/unread-count'),
              statusCode: 200,
              data: {'success': true, 'data': {'unreadCount': 0}},
            ));

    when(() => mockDio.post<dynamic>(any(that: contains('/read'))))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/read'),
              statusCode: 200,
              data: {'success': true},
            ));

    when(() => mockDio.get<dynamic>(any(that: contains('/community/chats/room-A/messages'))))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/room-A/messages'),
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'content': [
                    {
                      'messageId': 'msg-A1',
                      'sender': {'userId': 'user-A', 'fullName': 'User A'},
                      'type': 'TEXT',
                      'content': 'Hello from User A',
                      'createdAt': '2026-09-01T10:00:00Z',
                    },
                  ],
                },
              },
            ));

    when(() => mockDio.get<dynamic>(any(that: contains('/community/chats/room-B/messages'))))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/room-B/messages'),
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'content': [
                    {
                      'messageId': 'msg-B1',
                      'sender': {'userId': 'user-B', 'fullName': 'User B'},
                      'type': 'TEXT',
                      'content': 'Hello from User B',
                      'createdAt': '2026-09-01T10:30:00Z',
                    },
                  ],
                },
              },
            ));

    when(() => mockDio.get<dynamic>(any(that: anyOf(equals('/api/v1/community/chats'), endsWith('/community/chats')))))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: '/community/chats'),
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'content': [
                    {
                      'roomId': 'room-A',
                      'type': 'PRIVATE',
                      'counterpart': {'userId': 'user-A', 'fullName': 'User A'},
                      'lastMessage': {'content': 'Message from A'},
                      'unreadCount': 1,
                    },
                    {
                      'roomId': 'room-B',
                      'type': 'PRIVATE',
                      'counterpart': {'userId': 'user-B', 'fullName': 'User B'},
                      'lastMessage': {'content': 'Message from B'},
                      'unreadCount': 2,
                    },
                  ],
                },
              },
            ));

    dataSource = ChatRemoteDataSource(dio: mockDio);
    repository = ChatRepositoryImpl(remoteDataSource: dataSource);
    controller = ChatController(repository: repository);
    Get.put<ChatController>(controller, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Chat Navigation Lifecycle & Build-Phase Regression Tests', () {
    testWidgets('Header -> Chat A -> Back -> Header -> Chat A: messages are displayed and not cleared', (tester) async {
      controller.conversations.assignAll([convA, convB]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.chat,
          getPages: [
            GetPage(name: AppRoutes.chat, page: () => const ChatListScreen()),
            GetPage(name: AppRoutes.chatDetail, page: () => const ChatDetailScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 1. First entry: tap User A in list
      expect(find.text('User A'), findsWidgets);
      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();

      // Verify ChatDetail is open and messages are displayed
      expect(find.text('Hello from User A'), findsOneWidget);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.length, 1);

      // 2. Back to Chat List
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ChatListScreen), findsOneWidget);
      expect(controller.activeRoomId.value, isNull);
      expect(controller.activeMessages, isEmpty);

      // 3. Second entry: tap User A in list again
      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();

      // CRITICAL CHECK: Message history must NOT be cleared or empty
      expect(find.text('Hello from User A'), findsOneWidget);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User A');
    });

    testWidgets('Header -> Chat A -> Back -> Header -> Chat B: shows B messages without stale A messages', (tester) async {
      controller.conversations.assignAll([convA, convB]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.chat,
          getPages: [
            GetPage(name: AppRoutes.chat, page: () => const ChatListScreen()),
            GetPage(name: AppRoutes.chatDetail, page: () => const ChatDetailScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open A
      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);

      // Back
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // Open B
      await tester.tap(find.text('User B').first);
      await tester.pumpAndSettle();

      // Verify B messages displayed, no A messages
      expect(find.text('Hello from User B'), findsOneWidget);
      expect(find.text('Hello from User A'), findsNothing);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.every((m) => m.conversationId == 'room-B'), isTrue);
    });

    testWidgets('Header -> Chat A -> Back -> Header -> Chat B -> A: switches between rooms cleanly', (tester) async {
      controller.conversations.assignAll([convA, convB]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.chat,
          getPages: [
            GetPage(name: AppRoutes.chat, page: () => const ChatListScreen()),
            GetPage(name: AppRoutes.chatDetail, page: () => const ChatDetailScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // A
      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);

      // Back
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // B
      await tester.tap(find.text('User B').first);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User B'), findsOneWidget);

      // Back
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // Back to A
      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);
      expect(find.text('Hello from User B'), findsNothing);
      expect(controller.activeRoomId.value, 'room-A');
    });

    testWidgets('Header Chat navigation during an active Obx build does not throw setState() during build', (tester) async {
      controller.conversations.assignAll([convA]);

      // A test widget that triggers navigation while rebuilding inside an Obx
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Obx(() {
              // This Obx listens to conversations and unreadCount
              final count = controller.conversations.length;
              final unread = controller.unreadCount.value;
              return Column(
                children: [
                  Text('Convs: $count, Unread: $unread'),
                  ElevatedButton(
                    onPressed: () {
                      ChatNavigation.openChatDetail('room-A', conversation: convA);
                    },
                    child: const Text('Open A'),
                  ),
                ],
              );
            }),
          ),
          getPages: [
            GetPage(name: AppRoutes.chatDetail, page: () => const ChatDetailScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tapping Open A mounts ChatDetailScreen while Obx is active
      await tester.tap(find.text('Open A'));
      // This must NOT throw 'setState() or markNeedsBuild() called during build'
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Hello from User A'), findsOneWidget);
      expect(controller.activeRoomId.value, 'room-A');
    });

    testWidgets('Realtime message received while Chat A is open appends correctly', (tester) async {
      controller.conversations.assignAll([convA]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.chat,
          getPages: [
            GetPage(name: AppRoutes.chat, page: () => const ChatListScreen()),
            GetPage(name: AppRoutes.chatDetail, page: () => const ChatDetailScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);

      // Simulate live incoming message for room-A
      controller.onMessageReceived(
        ChatMessageModel(
          id: 'msg-live-100',
          conversationId: 'room-A',
          senderId: 'user-A',
          senderName: 'User A',
          content: 'Live message just arrived',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live message just arrived'), findsOneWidget);
      expect(controller.activeMessages.length, 2);
    });

    testWidgets('Realtime message received for another room does not pollute the active room', (tester) async {
      controller.conversations.assignAll([convA, convB]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.chat,
          getPages: [
            GetPage(name: AppRoutes.chat, page: () => const ChatListScreen()),
            GetPage(name: AppRoutes.chatDetail, page: () => const ChatDetailScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('User A').first);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);

      // Simulate live incoming message for room-B
      controller.onMessageReceived(
        ChatMessageModel(
          id: 'msg-live-B',
          conversationId: 'room-B',
          senderId: 'user-B',
          senderName: 'User B',
          content: 'Secret message for B',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
        ),
      );
      await tester.pumpAndSettle();

      // Active room A must NOT show B's message
      expect(find.text('Secret message for B'), findsNothing);
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.any((m) => m.id == 'msg-live-B'), isFalse);
    });

    testWidgets('Header chat button badge increments in realtime upon incoming message or notification', (tester) async {
      controller.unreadCount.value = 0;
      convA.unreadCount = 0;
      convB.unreadCount = 0;
      controller.conversations.assignAll([convA, convB]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Row(
                children: [
                  AppHeaderChatButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no count badge
      expect(find.text('1'), findsNothing);

      // Incoming message via onMessageReceived
      controller.onMessageReceived(
        ChatMessageModel(
          id: 'msg-realtime-1',
          conversationId: 'room-A',
          senderId: 'user-A',
          senderName: 'User A',
          content: 'Hello realtime 1',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
        ),
      );
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Second incoming message via onMessageReceived
      controller.onMessageReceived(
        ChatMessageModel(
          id: 'msg-realtime-2',
          conversationId: 'room-B',
          senderId: 'user-B',
          senderName: 'User B',
          content: 'Hello realtime 2',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
        ),
      );
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      // Third incoming message via onChatNotificationReceived
      controller.onChatNotificationReceived({
        'referenceId': 'room-A',
        'type': 'CHAT',
        'referenceType': 'CHAT_ROOM',
        'message': 'Hello from notification',
        'dedupeKey': 'notif-msg-3',
      });
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Chat message received via both chat queue and notification queue increments badge only once (no double-counting to 2)', (tester) async {
      controller.unreadCount.value = 0;
      convA.unreadCount = 0;
      controller.conversations.assignAll([convA]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Row(
                children: [
                  AppHeaderChatButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1'), findsNothing);

      // 1. Frame arrives on /user/queue/chat
      controller.onMessageReceived(
        ChatMessageModel(
          id: 'msg-uuid-999',
          conversationId: 'room-A',
          senderId: 'user-A',
          senderName: 'User A',
          content: 'Hello dedupe',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
        ),
      );
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // 2. Same frame arrives on /user/queue/notifications with dedupeKey containing msg-uuid-999
      controller.onChatNotificationReceived({
        'referenceId': 'room-A',
        'type': 'CHAT',
        'referenceType': 'CHAT_ROOM',
        'message': 'Hello dedupe',
        'dedupeKey': 'chat-msg:msg-uuid-999:recipient-user-id',
      });
      await tester.pump();

      // Must STAY at 1, NOT increment to 2!
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(controller.unreadCount.value, 1);
    });

    testWidgets('Notification Bell badge ignores chat notifications and only shows non-chat notifications', (tester) async {
      final mockNotifRepo = MockNotificationRepository();
      when(() => mockNotifRepo.getUnreadCount()).thenAnswer((_) async => 0);
      when(() => mockNotifRepo.getNotifications(page: any(named: 'page'), size: any(named: 'size')))
          .thenAnswer((_) async => NotificationPage.empty());

      final notifController = NotificationController(repository: mockNotifRepo);
      Get.put<NotificationController>(notifController);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Row(
                children: [
                  AppHeaderNotificationButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no badge
      expect(find.text('1'), findsNothing);

      // 1. Add chat notification -> Notification Bell badge must NOT increment
      notifController.notifications.add(
        NotificationModel(
          id: 'chat-notif-1',
          type: NotificationType.chat,
          title: 'New message from nat',
          body: 'Hello',
          senderName: 'nat',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
      await tester.pump();
      expect(find.text('1'), findsNothing);

      // 2. Add comment notification -> Notification Bell badge DOES increment to 1
      notifController.notifications.add(
        NotificationModel(
          id: 'comment-notif-1',
          type: NotificationType.comment,
          title: 'New comment',
          body: 'Nice post',
          senderName: 'nat',
          timeAgo: 'Just now',
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });
  });
}
