import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/create_group_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_system_message.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_filter_chip.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/group_member_tile.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_story_reply_card.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/message_bubble.dart';
import 'package:genlink_frontend/features/home/presentation/widgets/home_header_actions.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/features/chat/chat_navigation.dart';
import 'package:genlink_frontend/features/chat/presentation/bindings/chat_binding.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUp(() {
    Get.reset();
  });

  group('Chat Models & Serialization Tests', () {
    test('ChatMessageModel parses from backend ChatMessageResponse correctly', () {
      final json = {
        'messageId': 'msg-123',
        'sender': {
          'userId': 'user-1',
          'fullName': 'Sokny Enat',
          'username': 'sokny',
          'avatarUrl': 'https://example.com/avatar.jpg',
        },
        'type': 'TEXT',
        'content': 'Hello from backend!',
        'mediaUrl': null,
        'mine': true,
        'createdAt': '2026-09-01T10:00:00Z',
      };

      final msg = ChatMessageModel.fromJson(json, conversationId: 'room-abc');
      expect(msg.id, 'msg-123');
      expect(msg.conversationId, 'room-abc');
      expect(msg.senderId, 'user-1');
      expect(msg.senderName, 'Sokny Enat');
      expect(msg.senderAvatar, 'https://example.com/avatar.jpg');
      expect(msg.content, 'Hello from backend!');
      expect(msg.isMine, isTrue);
      expect(msg.messageType, 'text');
    });

    test('ChatConversationModel parses from ChatRoomSummaryResponse correctly', () {
      final json = {
        'roomId': 'room-xyz',
        'type': 'PRIVATE',
        'title': null,
        'counterpart': {
          'userId': 'user-2',
          'fullName': 'Heng Chansela',
          'username': 'chansela',
          'avatarUrl': 'https://example.com/chansela.png',
        },
        'lastMessage': {
          'messageId': 'msg-999',
          'sender': {'userId': 'user-2', 'fullName': 'Heng Chansela'},
          'type': 'TEXT',
          'content': 'See you at the university library!',
          'createdAt': '2026-09-01T09:30:00Z',
        },
        'unreadCount': 2,
        'lastActivityAt': '2026-09-01T09:30:00Z',
      };

      final conv = ChatConversationModel.fromJson(json);
      expect(conv.id, 'room-xyz');
      expect(conv.name, 'Heng Chansela');
      expect(conv.avatar, 'https://example.com/chansela.png');
      expect(conv.profileUserId, 'user-2');
      expect(conv.profileUsername, 'chansela');
      expect(conv.isGroup, isFalse);
      expect(conv.lastMessage, 'See you at the university library!');
      expect(conv.unreadCount, 2);
    });

    test('ChatConversationModel parses group room response correctly', () {
      final json = {
        'roomId': 'group-1',
        'type': 'GROUP',
        'name': 'GenLink Study Group',
        'members': [
          {'userId': 'user-1', 'fullName': 'Sokny'},
          {'userId': 'user-2', 'fullName': 'Chansela'},
        ],
        'createdAt': '2026-09-01T08:00:00Z',
      };

      final groupConv = ChatConversationModel.fromRoomResponse(json);
      expect(groupConv.id, 'group-1');
      expect(groupConv.name, 'GenLink Study Group');
      expect(groupConv.isGroup, isTrue);
      expect(groupConv.membersCount, 2);
    });
  });

  group('ChatRemoteDataSource Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;

    setUp(() {
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
    });

    test('fetchConversations unwraps ApiResponse and PageResponse correctly', () async {
      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'roomId': 'room-1',
                  'type': 'PRIVATE',
                  'counterpart': {
                    'userId': 'user-1',
                    'fullName': 'Sokny Enat',
                  },
                  'unreadCount': 0,
                  'lastMessage': {
                    'content': 'Hey!',
                    'type': 'TEXT',
                    'createdAt': '2026-09-01T10:00:00Z',
                  },
                },
              ],
            },
          },
        ),
      );

      final list = await dataSource.fetchConversations();
      expect(list.length, 1);
      expect(list.first.id, 'room-1');
      expect(list.first.name, 'Sokny Enat');
      expect(list.first.lastMessage, 'Hey!');
    });

    test('fetchMessages sorts messages chronologically (oldest first, newest last)', () async {
      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-2',
                  'sender': {'userId': 'u1', 'fullName': 'Sokny'},
                  'type': 'TEXT',
                  'content': 'Second message',
                  'createdAt': '2026-09-01T10:05:00Z',
                },
                {
                  'messageId': 'msg-1',
                  'sender': {'userId': 'u1', 'fullName': 'Sokny'},
                  'type': 'TEXT',
                  'content': 'First message',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );

      final messages = await dataSource.fetchMessages('room-1');
      expect(messages.length, 2);
      expect(messages[0].id, 'msg-1');
      expect(messages[0].content, 'First message');
      expect(messages[1].id, 'msg-2');
      expect(messages[1].content, 'Second message');
    });

    test('sendMessage sends POST request with correct payload', () async {
      when(() => mockDio.post<dynamic>(
        any(),
        data: any(named: 'data'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'messageId': 'msg-new',
              'sender': {'userId': 'me', 'fullName': 'Me'},
              'type': 'TEXT',
              'content': 'How are you?',
              'mine': true,
              'createdAt': '2026-09-01T10:10:00Z',
            },
          },
        ),
      );

      final msg = await dataSource.sendMessage('room-1', 'How are you?');
      expect(msg.id, 'msg-new');
      expect(msg.content, 'How are you?');
      expect(msg.isMine, isTrue);
    });

    test('openPrivateChat creates or gets 1:1 conversation', () async {
      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/private/user-2'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-private-2',
              'type': 'PRIVATE',
              'members': [
                {'userId': 'user-2', 'fullName': 'Chansela', 'username': 'chansela'},
              ],
            },
          },
        ),
      );

      final conv = await dataSource.openPrivateChat('user-2');
      expect(conv.id, 'room-private-2');
      expect(conv.name, 'Chansela');
    });

    test('deleteMessage sends DELETE request', () async {
      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/messages/msg-1'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final result = await dataSource.deleteMessage('room-1', 'msg-1');
      expect(result, isTrue);
    });
  });

  group('ChatController State Management & Workflows', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;

    setUp(() {
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
      repository = ChatRepositoryImpl(remoteDataSource: dataSource);

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );

      controller = ChatController(repository: repository);
    });

    test('openConversation resets unreadCount and marks read on backend', () async {
      final conv = ChatConversationModel(
        id: 'room-100',
        name: 'Study Buddy',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Let us meet!',
        lastMessageTime: '5m ago',
        unreadCount: 3,
      );
      controller.conversations.add(conv);

      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-100/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-100/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'm1',
                  'sender': {'userId': 'u1', 'fullName': 'Study Buddy'},
                  'type': 'TEXT',
                  'content': 'Let us meet!',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );

      await controller.openConversation(conv);

      expect(controller.activeConversation.value?.id, 'room-100');
      expect(conv.unreadCount, 0);
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Let us meet!');
    });

    test('sendMessage sends message and moves conversation to top', () async {
      final conv = ChatConversationModel(
        id: 'room-100',
        name: 'Friend',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Old message',
        lastMessageTime: '1h ago',
      );
      controller.conversations.add(conv);
      controller.activeConversation.value = conv;

      when(() => mockDio.post<dynamic>(
        any(),
        data: any(named: 'data'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-100/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'messageId': 'm-new',
              'sender': {'userId': 'me', 'fullName': 'Me'},
              'type': 'TEXT',
              'content': 'Hello friend!',
              'mine': true,
              'createdAt': '2026-09-01T10:15:00Z',
            },
          },
        ),
      );

      controller.textController.text = 'Hello friend!';
      await controller.sendMessage();

      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello friend!');
      expect(conv.lastMessage, 'Hello friend!');
      expect(controller.textController.text, isEmpty);
    });

    test('onMessageReceived appends to active chat or increments badge', () {
      final conv = ChatConversationModel(
        id: 'room-200',
        name: 'Active Chat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hi',
        lastMessageTime: '10m ago',
        unreadCount: 0,
      );
      controller.conversations.add(conv);

      final incomingBgMsg = ChatMessageModel(
        id: 'msg-bg',
        conversationId: 'room-200',
        senderId: 'user-other',
        senderName: 'Active Chat',
        content: 'New message received!',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(incomingBgMsg);
      expect(conv.unreadCount, 1);
      expect(conv.lastMessage, 'New message received!');

      controller.activeConversation.value = conv;
      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-200/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final incomingActiveMsg = ChatMessageModel(
        id: 'msg-active',
        conversationId: 'room-200',
        senderId: 'user-other',
        senderName: 'Active Chat',
        content: 'Another live message',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(incomingActiveMsg);
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Another live message');
    });

    test('deleteMessage removes message from active thread', () async {
      final conv = ChatConversationModel(
        id: 'room-100',
        name: 'Chat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Test',
        lastMessageTime: 'now',
      );
      controller.activeConversation.value = conv;

      final msg = ChatMessageModel(
        id: 'msg-to-delete',
        conversationId: 'room-100',
        senderId: 'me',
        senderName: 'Me',
        content: 'Mistake message',
        timestamp: DateTime.now(),
        timeAgo: 'now',
        isMine: true,
      );
      controller.activeMessages.add(msg);

      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-100/messages/msg-to-delete'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final ok = await controller.deleteMessage('msg-to-delete');
      expect(ok, isTrue);
      expect(controller.activeMessages.isEmpty, isTrue);
    });

    test('muteConversation toggles isMuted and preserves conversation in list', () async {
      final conv = ChatConversationModel(
        id: 'room-mute',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hey',
        lastMessageTime: '1m ago',
        isMuted: false,
      );
      controller.conversations.add(conv);

      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-mute/mute'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final ok = await controller.muteConversation('room-mute');
      expect(ok, isTrue);
      expect(controller.conversations.first.isMuted, isTrue);

      // Unmute
      final ok2 = await controller.muteConversation('room-mute');
      expect(ok2, isTrue);
      expect(controller.conversations.first.isMuted, isFalse);
    });

    test('archiveConversation and unarchiveConversation manage isArchived without data loss', () async {
      final conv = ChatConversationModel(
        id: 'room-archive',
        name: 'Heng Chansela',
        avatar: 'assets/images/heng_chansela_profile.png',
        lastMessage: 'Let us study',
        lastMessageTime: 'Just now',
        isArchived: false,
      );
      controller.conversations.add(conv);

      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-archive/archive'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final ok = await controller.archiveConversation('room-archive');
      expect(ok, isTrue);
      expect(controller.conversations.first.isArchived, isTrue);
      expect(controller.conversations.first.lastMessage, 'Let us study');

      // Unarchive
      final unarchiveOk = await controller.unarchiveConversation('room-archive');
      expect(unarchiveOk, isTrue);
      expect(controller.conversations.first.isArchived, isFalse);
    });

    test('deleteConversation removes conversation from local state without touching user profile', () async {
      final conv = ChatConversationModel(
        id: 'room-del',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Goodbye',
        lastMessageTime: '1m ago',
      );
      controller.conversations.add(conv);

      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-del'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final ok = await controller.deleteConversation('room-del');
      expect(ok, isTrue);
      expect(controller.conversations.any((c) => c.id == 'room-del'), isFalse);
    });

    test('complete conversation persistence and deduplication flow', () async {
      // Step 1: Open private chat with Sokny Enat
      final opened = await controller.openPrivateChat(
        'user_sokny',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
      );
      expect(opened, isNotNull);
      expect(controller.conversations.length, 1);
      expect(controller.conversations.first.name, 'Sokny Enat');

      // Step 2: Send message
      controller.textController.text = 'Hello Sokny!';
      await controller.sendMessage();

      // Step 3: Verify conversation in list is updated
      expect(controller.conversations.length, 1);
      expect(controller.conversations.first.lastMessage, 'Hello Sokny!');
      expect(controller.conversations.first.lastMessageTime, 'Just now');
      expect(controller.conversations.first.unreadCount, 0);

      // Step 4: Re-open the same private chat
      final reopened = await controller.openPrivateChat(
        'user_sokny',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
      );

      // Step 5: Verify no duplicate conversation was created
      expect(reopened?.id, opened?.id);
      expect(controller.conversations.length, 1);
      expect(controller.conversations.first.lastMessage, 'Hello Sokny!');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello Sokny!');
    });
  });

  group('Chat UI Widget Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;

    setUp(() {
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
      repository = ChatRepositoryImpl(remoteDataSource: dataSource);

      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );

      controller = Get.put(ChatController(repository: repository));
    });

    testWidgets('ChatListScreen renders header and empty state', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Messages & Chats'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('ChatDetailScreen renders conversation header and message bubbles', (tester) async {
      final conv = ChatConversationModel(
        id: 'room-test',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hello!',
        lastMessageTime: 'Just now',
        isOnline: true,
      );

      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([
        ChatMessageModel(
          id: 'm1',
          conversationId: 'room-test',
          senderId: 'user-sokny',
          senderName: 'Sokny Enat',
          content: 'Hello! How are you doing today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          timeAgo: '5m ago',
          isMine: false,
        ),
        ChatMessageModel(
          id: 'm2',
          conversationId: 'room-test',
          senderId: 'me',
          senderName: 'Me',
          content: 'Doing great! Thanks for asking.',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: true,
        ),
      ]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sokny Enat'), findsWidgets);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Hello! How are you doing today?'), findsOneWidget);
      expect(find.text('Doing great! Thanks for asking.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Testing message');
      await tester.pump();
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('ChatDetailScreen renders Story Reply Card preview inside bubble', (tester) async {
      final conv = ChatConversationModel(
        id: 'room-reply',
        name: 'Chansela',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Loved this story!',
        lastMessageTime: 'Just now',
      );

      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([
        ChatMessageModel(
          id: 'm-reply',
          conversationId: 'room-reply',
          senderId: 'user-chansela',
          senderName: 'Chansela',
          content: 'Loved this story!',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
          messageType: 'story_reply',
        ),
      ]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('↩ Replied to Story'), findsOneWidget);
      expect(find.text('Loved this story!'), findsOneWidget);
    });

    testWidgets('ChatDetailScreen renders Finance Message Card with professional styling', (tester) async {
      final conv = ChatConversationModel(
        id: 'room-finance',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Sent \$5.00: Lunch share',
        lastMessageTime: 'Just now',
      );

      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([
        ChatMessageModel(
          id: 'm-fin',
          conversationId: 'room-finance',
          senderId: 'user-sokny',
          senderName: 'Sokny Enat',
          content: 'Sent \$5.00: Lunch share',
          timestamp: DateTime.now(),
          timeAgo: 'Just now',
          isMine: false,
          messageType: 'finance',
          financeTransaction: ChatFinanceTransaction(
            transactionId: 'txn-1',
            type: 'send',
            amount: 5.0,
            currency: 'USD',
            status: 'completed',
            note: 'Lunch share',
            timestamp: DateTime.now(),
          ),
        ),
      ]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$5.00'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('View in Finance'), findsOneWidget);
      expect(find.text('Lunch share'), findsOneWidget);
    });

    testWidgets('ChatSystemMessage renders subtle centered pill message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatSystemMessage(text: 'Chenda added Dara to the group'),
          ),
        ),
      );

      expect(find.text('Chenda added Dara to the group'), findsOneWidget);
    });

    testWidgets('ChatFilterChip renders selected and unselected states correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ChatFilterChip(
                  label: 'All',
                  isSelected: true,
                  onTap: () {},
                ),
                ChatFilterChip(
                  label: 'Unread',
                  isSelected: false,
                  count: 3,
                  onTap: () {
                    tapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Unread'));
      expect(tapped, isTrue);
    });

    testWidgets('GroupMemberTile renders selection checkmark and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupMemberTile(
              name: 'Heng Chansela',
              handle: '@chansela',
              isOnline: true,
              isSelected: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Heng Chansela'), findsOneWidget);
      expect(find.text('@chansela'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Heng Chansela'));
      expect(tapped, isTrue);
    });

    testWidgets('CreateGroupScreen renders group info, member search, and selection', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Group Chat'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Select Members'), findsOneWidget);

      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();

      expect(find.text('Selected · 1'), findsOneWidget);
    });

    testWidgets('ChatListScreen renders properly in Dark Mode', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          home: const ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Messages & Chats'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('Chat screens localize properly in Khmer locale', (tester) async {
      Get.clearTranslations();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('km', 'KH');

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          fallbackLocale: const Locale('en', 'US'),
          home: const ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('សារ និងការជជែក'), findsOneWidget);
      expect(find.text('មិនទាន់មានសារនៅឡើយទេ'), findsOneWidget);
    });

    testWidgets('ChatListItem reveals Mute, Archive, Delete actions on swipe left', (tester) async {
      bool muted = false;
      bool archived = false;
      bool deleted = false;

      final conv = ChatConversationModel(
        id: 'room-swipe',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hello swipe test',
        lastMessageTime: '1m ago',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatListItem(
              conversation: conv,
              onTap: () {},
              onMute: () => muted = true,
              onArchive: () => archived = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sokny Enat'), findsOneWidget);

      // Drag left to reveal actions
      await tester.drag(find.text('Sokny Enat'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Mute'));
      await tester.pumpAndSettle();
      expect(muted, isTrue);

      await tester.drag(find.text('Sokny Enat'), const Offset(-150, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(archived, isTrue);

      await tester.drag(find.text('Sokny Enat'), const Offset(-150, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('ChatController sendStoryReply updates state and active messages', (tester) async {
      final reply = await controller.sendStoryReply(
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        message: 'Great story picture!',
        mediaUrl: 'https://example.com/story.jpg',
        storyId: 'story-123',
      );

      expect(reply.messageType, 'story_reply');
      expect(reply.content, 'Great story picture!');
      expect(controller.activeConversation.value?.name, 'Sokny Enat');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Great story picture!');

      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('sendStoryReply isolates messages from previously active conversation, moves to top, and displays story card in detail screen', (tester) async {
      // 1. Setup conversation A (Heng Chansela) as currently active with its own messages
      final convA = ChatConversationModel(
        id: 'room_chansela',
        name: 'Heng Chansela',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: 'Chansela secret message',
        lastMessageTime: '10m ago',
        unreadCount: 3,
      );
      final convB = ChatConversationModel(
        id: 'room_sokny',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: 'Old Sokny message',
        lastMessageTime: '1h ago',
        unreadCount: 5,
      );

      controller.conversations.assignAll([convA, convB]);
      controller.activeConversation.value = convA;
      controller.activeMessages.assignAll([
        ChatMessageModel(
          id: 'msg_a1',
          conversationId: convA.id,
          senderId: 'user_chansela',
          senderName: 'Heng Chansela',
          content: 'Secret discussion with Chansela',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          timeAgo: '5m ago',
          isMine: false,
        ),
      ]);

      // 2. Send a story reply to conversation B (Sokny Enat)
      final reply = await controller.sendStoryReply(
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        message: 'Awesome photo from Angkor Wat!',
        mediaUrl: 'assets/images/user_profile.png',
        storyId: 'story-angkor-456',
        userId: 'sokny',
      );

      // 3. Assert active conversation switch & list order
      expect(controller.activeConversation.value?.name, 'Sokny Enat');
      expect(controller.conversations.first.name, 'Sokny Enat');
      expect(controller.conversations.first.unreadCount, 0);
      expect(controller.conversations.first.lastMessage, 'Awesome photo from Angkor Wat!');

      // 4. Assert message isolation: previous conversation messages must NOT leak
      expect(controller.activeMessages.any((m) => m.content.contains('Secret discussion with Chansela')), isFalse);
      expect(controller.activeMessages.any((m) => m.id == reply.id), isTrue);

      // 5. Mount ChatDetailScreen to verify the story card is actually rendered
      controller.isLoadingMessages.value = false;
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Awesome photo from Angkor Wat!'), findsOneWidget);
      expect(find.text('Sokny Enat'), findsWidgets);
      expect(find.byType(ChatStoryReplyCard), findsOneWidget);
    });

    testWidgets('ChatListScreen delete confirmation dialog cancel preserves conversation and delete removes it', (tester) async {
      Get.testMode = true;
      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'roomId': 'room-dialog-test',
                  'type': 'PRIVATE',
                  'title': 'Sokny Enat',
                  'counterpart': {
                    'userId': 'user_sokny',
                    'fullName': 'Sokny Enat',
                    'avatarUrl': 'assets/images/user_profile.png',
                  },
                  'lastMessage': {'content': 'Testing dialog', 'createdAt': '2026-09-01T10:00:00Z'},
                  'unreadCount': 0,
                }
              ]
            }
          },
        ),
      );
      await controller.fetchConversations();

      await tester.pumpWidget(
        GetMaterialApp(
          home: const ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(ChatListItem),
        matching: find.text('Sokny Enat'),
      );
      expect(itemFinder, findsOneWidget);

      // Drag left to reveal actions
      await tester.drag(itemFinder, const Offset(-150, 0));
      await tester.pumpAndSettle();

      // Tap Delete to open confirmation dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete conversation?'), findsOneWidget);
      expect(find.text('This conversation will be removed from your chat list.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel -> conversation preserved
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.conversations.length, 1);
      expect(itemFinder, findsOneWidget);

      // Drag left again and confirm Delete
      await tester.drag(itemFinder, const Offset(-150, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      final deleteButtons = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(deleteButtons);
      await tester.pumpAndSettle();

      expect(controller.conversations.isEmpty, isTrue);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('ChatListScreen archive removes conversation from normal list', (tester) async {
      Get.testMode = true;
      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'roomId': 'room-arch-test',
                  'type': 'PRIVATE',
                  'title': 'Heng Chansela',
                  'counterpart': {
                    'userId': 'user_chansela',
                    'fullName': 'Heng Chansela',
                    'avatarUrl': 'assets/images/heng_chansela_profile.png',
                  },
                  'lastMessage': {'content': 'Going to archive', 'createdAt': '2026-09-01T10:00:00Z'},
                  'unreadCount': 0,
                }
              ]
            }
          },
        ),
      );
      await controller.fetchConversations();

      await tester.pumpWidget(
        GetMaterialApp(
          home: const ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinder = find.descendant(
        of: find.byType(ChatListItem),
        matching: find.text('Heng Chansela'),
      );
      expect(itemFinder, findsOneWidget);

      // Drag left to reveal actions
      await tester.drag(itemFinder, const Offset(-150, 0));
      await tester.pumpAndSettle();

      // Tap Archive
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(controller.conversations.first.isArchived, isTrue);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('ChatDetailScreen renders empty conversation state with friendly greeting prompt', (tester) async {
      final conv = ChatConversationModel(
        id: 'room-empty-step4',
        name: 'Dara Heng',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: '',
        lastMessageTime: '',
      );
      controller.activeConversation.value = conv;
      controller.activeMessages.clear();
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start a conversation...'), findsOneWidget);
      expect(find.text('Say Hello'), findsOneWidget);

      await tester.tap(find.text('Say Hello'));
      await tester.pumpAndSettle();

      expect(controller.activeMessages.isNotEmpty, isTrue);
      expect(controller.activeMessages.first.content, 'Hello! 👋');
    });

    testWidgets('ChatDetailScreen sets reply banner and links replyTo', (tester) async {
      final originalMsg = ChatMessageModel(
        id: 'msg-orig-1',
        conversationId: 'room-reply-test',
        senderId: 'user-other',
        senderName: 'Sokny Enat',
        content: 'Do you have the lecture notes?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        timeAgo: '5m ago',
        isMine: false,
      );

      final conv = ChatConversationModel(
        id: 'room-reply-test',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: 'Do you have the lecture notes?',
        lastMessageTime: '5m ago',
      );
      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([originalMsg]);
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Do you have the lecture notes?'), findsOneWidget);

      // Trigger reply via controller
      controller.setReplyingTo(originalMsg);
      await tester.pumpAndSettle();

      // Composer reply banner is visible
      expect(find.text('Replying to Sokny Enat'), findsOneWidget);

      // Type reply and send
      controller.textController.text = 'Yes, uploading them now!';
      await controller.sendMessage();
      await tester.pumpAndSettle();

      // Reply banner is cleared
      expect(controller.replyingToMessage.value, isNull);

      // Sent message has replyTo reference
      final sentMsg = controller.activeMessages.last;
      expect(sentMsg.replyTo, isNotNull);
      expect(sentMsg.replyTo!.messageId, 'msg-orig-1');
      expect(sentMsg.replyTo!.senderName, 'Sokny Enat');
      expect(sentMsg.replyTo!.content, 'Do you have the lecture notes?');
    });

    testWidgets('ChatDetailScreen reaction chips display and toggle', (tester) async {
      final msg = ChatMessageModel(
        id: 'msg-react-1',
        conversationId: 'room-react-test',
        senderId: 'user-other',
        senderName: 'Chansela',
        content: 'Great job team!',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      final conv = ChatConversationModel(
        id: 'room-react-test',
        name: 'Chansela',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: 'Great job team!',
        lastMessageTime: 'Just now',
      );
      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([msg]);
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle reaction 👍
      controller.toggleReaction('msg-react-1', '👍');
      await tester.pumpAndSettle();

      expect(controller.activeMessages.first.reactions.length, 1);
      expect(controller.activeMessages.first.reactions.first.emoji, '👍');
      expect(controller.activeMessages.first.reactions.first.count, 1);
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap reaction chip to toggle off
      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();

      expect(controller.activeMessages.first.reactions.isEmpty, isTrue);
      expect(find.text('👍'), findsNothing);
    });

    testWidgets('ChatDetailScreen pinned message banner displays and unpins', (tester) async {
      final msg = ChatMessageModel(
        id: 'msg-pin-1',
        conversationId: 'room-pin-test',
        senderId: 'user-other',
        senderName: 'Prof. John',
        content: 'Final submission deadline is Friday 5 PM.',
        timestamp: DateTime.now(),
        timeAgo: '1h ago',
        isMine: false,
      );

      final conv = ChatConversationModel(
        id: 'room-pin-test',
        name: 'CS101 Group',
        avatar: 'assets/images/user_profile.png',
        isGroup: true,
        membersCount: 25,
        lastMessage: 'Final submission deadline is Friday 5 PM.',
        lastMessageTime: '1h ago',
      );
      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([msg]);
      controller.isLoadingMessages.value = false;

      // Pin message
      controller.togglePinMessage(msg);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pinned Message'), findsOneWidget);
      expect(find.text('Prof. John: Final submission deadline is Friday 5 PM.'), findsOneWidget);

      // Unpin via banner close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(controller.pinnedMessage.value, isNull);
      expect(find.text('Pinned Message'), findsNothing);
    });

    testWidgets('ChatDetailScreen typing indicator displays active typing user', (tester) async {
      final conv = ChatConversationModel(
        id: 'room-typing-test',
        name: 'Heng Chansela',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: 'Hey',
        lastMessageTime: '2m ago',
      );
      controller.activeConversation.value = conv;
      controller.activeMessages.clear();
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heng Chansela is typing...'), findsNothing);

      controller.typingUserName.value = 'Heng Chansela';
      await tester.pump();

      expect(find.text('Heng Chansela is typing...'), findsOneWidget);

      controller.typingUserName.value = null;
      await tester.pump();

      expect(find.text('Heng Chansela is typing...'), findsNothing);
    });

    testWidgets('ChatDetailScreen delete message confirmation dialog cancels and deletes message', (tester) async {
      final msg = ChatMessageModel(
        id: 'msg-del-1',
        conversationId: 'room-del-test',
        senderId: 'me',
        senderName: 'Me',
        content: 'Accidental message',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
      );

      final conv = ChatConversationModel(
        id: 'room-del-test',
        name: 'Sokny',
        avatar: 'assets/images/user_profile.png',
        isOnline: true,
        lastMessage: 'Accidental message',
        lastMessageTime: 'Just now',
      );
      controller.activeConversation.value = conv;
      controller.activeMessages.assignAll([msg]);
      controller.isLoadingMessages.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Long press message to show action sheet
      await tester.longPress(find.text('Accidental message'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);

      // Tap Delete in action sheet to open confirmation dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete message?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this message?'), findsOneWidget);

      // Tap Cancel -> message preserved
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.activeMessages.length, 1);

      // Long press again and confirm Delete
      await tester.longPress(find.text('Accidental message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      final deleteBtn = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(controller.activeMessages.isEmpty, isTrue);
    });
  });

  group('Chat Unread Count, Deep Link & Header Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;

    setUp(() {
      Get.reset();
      Get.testMode = true;
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
      repository = ChatRepositoryImpl(remoteDataSource: dataSource);
      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );
      controller = ChatController(repository: repository);
      Get.put<ChatController>(controller);
    });

    test('ChatRemoteDataSource and Controller fetchUnreadCount successfully', () async {
      when(() => mockDio.get<dynamic>(any(that: contains('unread-count')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/unread-count'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {'unreadCount': 7},
          },
        ),
      );

      final count = await dataSource.fetchUnreadCount();
      expect(count, 7);

      await controller.fetchUnreadCount();
      expect(controller.unreadCount.value, 7);
      expect(controller.totalUnreadCount, 7);
    });

    test('openConversationById fetches room and opens conversation', () async {
      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-deep-link')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-deep-link'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-deep-link',
              'type': 'PRIVATE',
              'counterpart': {
                'userId': 'user-deep',
                'fullName': 'Deep Link User',
                'username': 'deeplink',
              },
              'unreadCount': 0,
            },
          },
        ),
      );

      when(() => mockDio.post<dynamic>(any(that: contains('/read')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-deep-link/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-deep-link/messages'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );

      await controller.openConversationById('room-deep-link');
      expect(controller.activeConversation.value, isNotNull);
      expect(controller.activeConversation.value!.id, 'room-deep-link');
      expect(controller.activeConversation.value!.name, 'Deep Link User');
    });

    testWidgets('AppHeaderChatButton displays unread badge and synchronizes with controller', (tester) async {
      controller.unreadCount.value = 0;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(child: Row(children: [AppHeaderChatButton()])),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At count 0, no badge text
      expect(find.byType(AppHeaderChatButton), findsOneWidget);
      expect(find.text('0'), findsNothing);

      // At count 5, badge displays '5'
      controller.unreadCount.value = 5;
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);

      // At count 150, badge displays '99+'
      controller.unreadCount.value = 150;
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('ChatDetailScreen initializes from Get.arguments roomId', (tester) async {
      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-arg-1')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-arg-1'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-arg-1',
              'type': 'PRIVATE',
              'counterpart': {
                'userId': 'user-arg',
                'fullName': 'Argument User',
              },
              'unreadCount': 0,
            },
          },
        ),
      );
      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );
      when(() => mockDio.get<dynamic>(any(that: contains('/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/messages'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: '/chat-detail',
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/chat-detail', arguments: {'roomId': 'room-arg-1'});
      await tester.pumpAndSettle();

      expect(find.text('Argument User'), findsWidgets);
      expect(controller.activeConversation.value?.id, 'room-arg-1');
    });

    testWidgets('MessageBubble renders error icon when deliveryStatus is failed', (tester) async {
      final failedMessage = ChatMessageModel(
        id: 'msg-fail',
        conversationId: 'room-1',
        senderId: 'user-me',
        senderName: 'Me',
        content: 'This message failed to send',
        isMine: true,
        deliveryStatus: 'failed',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: failedMessage,
              onLongPress: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('This message failed to send'), findsOneWidget);
    });
  });

  group('Stale Chat State, Room Isolation & Race Condition Regression Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;

    final convA = ChatConversationModel(
      id: 'room-A',
      name: 'User A',
      avatar: 'assets/images/user_profile.png',
      lastMessage: 'Message from A',
      lastMessageTime: '10m ago',
      unreadCount: 0,
    );

    final convB = ChatConversationModel(
      id: 'room-B',
      name: 'User B',
      avatar: 'assets/images/user_profile.png',
      lastMessage: 'Message from B',
      lastMessageTime: '5m ago',
      unreadCount: 0,
    );

    final convC = ChatConversationModel(
      id: 'room-C',
      name: 'User C',
      avatar: 'assets/images/user_profile.png',
      lastMessage: 'Message from C',
      lastMessageTime: '1m ago',
      unreadCount: 0,
    );

    final msgB = ChatMessageModel(
      id: 'msg-B-1',
      conversationId: 'room-B',
      senderId: 'user-B',
      senderName: 'User B',
      content: 'Hello from User B',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      timeAgo: '5m ago',
      isMine: false,
    );

    setUp(() {
      Get.reset();
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
      repository = ChatRepositoryImpl(remoteDataSource: dataSource);
      controller = ChatController(repository: repository);
      Get.put<ChatController>(controller);

      controller.conversations.assignAll([convA, convB, convC]);

      when(() => mockDio.post<dynamic>(any(that: contains('/read')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-A/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-A/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-A-1',
                  'sender': {'userId': 'user-A', 'fullName': 'User A'},
                  'type': 'TEXT',
                  'content': 'Hello from User A',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-B/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-B/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-B-1',
                  'sender': {'userId': 'user-B', 'fullName': 'User B'},
                  'type': 'TEXT',
                  'content': 'Hello from User B',
                  'createdAt': '2026-09-01T10:05:00Z',
                },
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-C/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-C/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-C-1',
                  'sender': {'userId': 'user-C', 'fullName': 'User C'},
                  'type': 'TEXT',
                  'content': 'Hello from User C',
                  'createdAt': '2026-09-01T10:10:00Z',
                },
              ],
            },
          },
        ),
      );
    });

    test('Test 1 — A -> B: visible messages are strictly B messages without A leakage', () async {
      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User A');

      await controller.openConversation(convB);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);
    });

    test('Test 2 — A -> B -> A: each room always displays its own history repeatedly', () async {
      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.first.content, 'Hello from User A');

      await controller.openConversation(convB);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.first.content, 'Hello from User B');

      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.first.content, 'Hello from User A');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-B'), isFalse);
    });

    test('Test 3 — Async race condition: slow A response does not overwrite fast B response', () async {
      final completerA = Completer<Response<dynamic>>();

      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-A/messages')))).thenAnswer(
        (_) => completerA.future,
      );

      // Start slow request for A
      final futureA = controller.openConversation(convA);

      // Immediately switch to fast request B
      final futureB = controller.openConversation(convB);
      await futureB;

      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User B');

      // Now complete the slow request A
      completerA.complete(
        Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-A/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-A-1',
                  'sender': {'userId': 'user-A', 'fullName': 'User A'},
                  'type': 'TEXT',
                  'content': 'Hello from User A (stale)',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );
      await futureA;

      // Assert B remains active and A's response was completely ignored
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);
    });

    test('Test 4 — Realtime isolation: incoming message for inactive room does not modify active room', () {
      controller.activeRoomId.value = 'room-B';
      controller.activeConversation.value = convB;
      controller.activeMessages.assignAll([msgB]);

      // Message for Room A arrives in the background
      final incomingMsgA = ChatMessageModel(
        id: 'msg-A-new',
        conversationId: 'room-A',
        senderId: 'user-A',
        senderName: 'User A',
        content: 'Background message for A',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(incomingMsgA);

      // Assert Room B messages are completely untouched
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);

      // Assert Room A's unreadCount in conversations list was incremented
      final updatedConvA = controller.conversations.firstWhere((c) => c.id == 'room-A');
      expect(updatedConvA.unreadCount, 1);
      expect(updatedConvA.lastMessage, 'Background message for A');

      // Now message for active Room B arrives
      final incomingMsgB = ChatMessageModel(
        id: 'msg-B-new',
        conversationId: 'room-B',
        senderId: 'user-B',
        senderName: 'User B',
        content: 'Live message for B',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(incomingMsgB);

      // Assert Room B messages now has the new message appended
      expect(controller.activeMessages.length, 2);
      expect(controller.activeMessages.last.content, 'Live message for B');
    });

    test('Test 5 — Notification deep link: opening via deep link loads target history only', () async {
      await controller.openConversation(convB);
      expect(controller.activeRoomId.value, 'room-B');

      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-notif')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-notif'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-notif',
              'type': 'PRIVATE',
              'counterpart': {
                'userId': 'user-notif',
                'fullName': 'Notification User',
              },
              'unreadCount': 0,
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-notif/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-notif/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-notif-1',
                  'sender': {'userId': 'user-notif', 'fullName': 'Notification User'},
                  'type': 'TEXT',
                  'content': 'Urgent notification message',
                  'createdAt': '2026-09-01T12:00:00Z',
                },
              ],
            },
          },
        ),
      );

      await controller.openConversationById('room-notif');

      expect(controller.activeRoomId.value, 'room-notif');
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Urgent notification message');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-B'), isFalse);
    });

    test('Test 6 — Repeated switching: A -> B -> C -> A -> C -> B preserves strict isolation', () async {
      final sequence = ['room-A', 'room-B', 'room-C', 'room-A', 'room-C', 'room-B'];
      final convMap = {'room-A': convA, 'room-B': convB, 'room-C': convC};
      final expectedMsg = {
        'room-A': 'Hello from User A',
        'room-B': 'Hello from User B',
        'room-C': 'Hello from User C',
      };

      for (final roomId in sequence) {
        await controller.openConversation(convMap[roomId]!);
        expect(controller.activeRoomId.value, roomId);
        expect(controller.activeMessages.length, 1);
        expect(controller.activeMessages.first.content, expectedMsg[roomId]);
        expect(controller.activeMessages.every((m) => m.conversationId == roomId), isTrue);
      }
    });

    test('Test 7 — Back navigation cleanup: leaveConversation clears activeRoomId and messages', () async {
      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.isNotEmpty, isTrue);

      controller.leaveConversation(roomId: 'room-A');
      expect(controller.activeRoomId.value, isNull);
      expect(controller.activeConversation.value, isNull);
      expect(controller.activeMessages, isEmpty);
      expect(controller.isLoadingMessages.value, isFalse);
    });

    test('Test 8 — Empty conversation handling: conversation B with 0 messages never retains A messages', () async {
      await controller.openConversation(convA);
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Hello from User A');

      // Room Empty has empty content
      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-empty/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-empty/messages'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );

      final convEmpty = ChatConversationModel(
        id: 'room-empty',
        name: 'Empty User',
        avatar: 'assets/images/user_profile.png',
        lastMessage: '',
        lastMessageTime: 'Just now',
        unreadCount: 0,
      );

      await controller.openConversation(convEmpty);
      expect(controller.activeRoomId.value, 'room-empty');
      expect(controller.activeMessages, isEmpty);
    });

    testWidgets('Widget Test: ChatDetailScreen switches from A to B cleanly without displaying A messages', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: '/chat-detail',
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open Chat A
      Get.toNamed('/chat-detail', arguments: {'roomId': 'room-A'});
      await tester.pumpAndSettle();

      expect(find.text('User A'), findsWidgets);
      expect(find.text('Hello from User A'), findsOneWidget);
      // Back to home via AppBackButton
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();
      expect(controller.activeRoomId.value, isNull);

      // Open Chat B
      Get.toNamed('/chat-detail', arguments: {'roomId': 'room-B'});
      await tester.pumpAndSettle();

      expect(find.text('User B'), findsWidgets);
      expect(find.text('Hello from User B'), findsOneWidget);
      expect(find.text('Hello from User A'), findsNothing);
    });
  });

  group('Section I Regression: Chat & Notification Integration & Realtime Sync Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;
    late ChatConversationModel convA;
    late ChatConversationModel convB;

    setUp(() {
      Get.reset();
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
      repository = ChatRepositoryImpl(remoteDataSource: dataSource);
      controller = ChatController(repository: repository);
      Get.put<ChatController>(controller);

      convA = ChatConversationModel(
        id: 'room-A',
        name: 'User A',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hello from User A',
        lastMessageTime: '10m ago',
        unreadCount: 0,
      );

      convB = ChatConversationModel(
        id: 'room-B',
        name: 'User B',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hello from User B',
        lastMessageTime: '5m ago',
        unreadCount: 0,
      );

      controller.conversations.assignAll([convA, convB]);

      when(() => mockDio.post<dynamic>(any(that: contains('/read')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/unread-count')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/unread-count'),
          statusCode: 200,
          data: {'success': true, 'data': {'unreadCount': 5}},
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/room-A/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-A/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-A-1',
                  'sender': {'userId': 'user-A', 'fullName': 'User A'},
                  'type': 'TEXT',
                  'content': 'Hello from User A',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/room-B/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-B/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-B-1',
                  'sender': {'userId': 'user-B', 'fullName': 'User B'},
                  'type': 'TEXT',
                  'content': 'Hello from User B',
                  'createdAt': '2026-09-01T11:00:00Z',
                },
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: equals('/api/v1/community/chats/room-A')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-A'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-A',
              'type': 'PRIVATE',
              'name': 'User A',
              'members': [
                {'userId': 'user-A', 'fullName': 'User A'},
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: equals('/api/v1/community/chats/room-B')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-B'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-B',
              'type': 'PRIVATE',
              'name': 'User B',
              'members': [
                {'userId': 'user-B', 'fullName': 'User B'},
              ],
            },
          },
        ),
      );
    });

    test('1. Incoming chat message increments Chat unread badge when not in active conversation', () {
      expect(controller.unreadCount.value, 0);
      expect(controller.totalUnreadCount, 0);

      final incomingMsg = ChatMessageModel(
        id: 'msg-realtime-1',
        conversationId: 'room-A',
        senderId: 'user-A',
        senderName: 'User A',
        content: 'New unread message from A',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(incomingMsg);

      expect(controller.unreadCount.value, 1);
      expect(controller.totalUnreadCount, 1);
      expect(controller.conversations.firstWhere((c) => c.id == 'room-A').unreadCount, 1);
      expect(controller.conversations.firstWhere((c) => c.id == 'room-A').lastMessage, 'New unread message from A');
    });

    test('2. Incoming chat message does not increment unread when active conversation is open', () async {
      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.unreadCount.value, 0);

      final incomingMsg = ChatMessageModel(
        id: 'msg-realtime-active',
        conversationId: 'room-A',
        senderId: 'user-A',
        senderName: 'User A',
        content: 'I am chatting with you live',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(incomingMsg);

      expect(controller.unreadCount.value, 0);
      expect(controller.activeMessages.any((m) => m.id == 'msg-realtime-active'), isTrue);
      expect(controller.activeMessages.last.content, 'I am chatting with you live');
    });

    test('3. Chat notification increments Notification badge', () async {
      final notifRepo = NotificationRepositoryImpl(remoteDataSource: NotificationRemoteDataSource(dio: mockDio));
      final notifController = NotificationController(repository: notifRepo);
      Get.put<NotificationController>(notifController);

      expect(notifController.totalUnreadCount.value, 0);

      final chatNotif = NotificationModel(
        id: 'notif-chat-1',
        type: NotificationType.chat,
        title: 'User A',
        body: 'Sent you a message',
        senderName: 'User A',
        timeAgo: 'Just now',
        timestamp: DateTime.now(),
        targetType: 'CHAT_ROOM',
        targetId: 'room-A',
      );

      await notifController.onRealtimeNotificationReceived(chatNotif);

      expect(notifController.totalUnreadCount.value, 1);
      expect(notifController.notifications.length, 1);
      expect(notifController.notifications.first.targetId, 'room-A');
    });

    test('4. Chat notification parses correct conversation/room ID', () {
      final json = {
        'id': 'notif-100',
        'type': 'CHAT',
        'referenceType': 'CHAT_ROOM',
        'referenceId': 'room-A',
        'title': 'User A',
        'message': 'Hello from User A',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final model = NotificationModel.fromJson(json);
      expect(model.type, NotificationType.chat);
      expect(model.targetType, 'CHAT_ROOM');
      expect(model.targetId, 'room-A');
    });

    test('5 & 6. ChatDetailScreen with roomId parameter loads conversation messages explicitly', () async {
      final conv = await controller.openConversationById('room-B');
      expect(conv, isNotNull);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.isNotEmpty, isTrue);
      expect(controller.activeMessages.first.content, 'Hello from User B');
    });

    test('7. Chat A -> Chat B does not show A messages', () async {
      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.first.content, 'Hello from User A');

      await controller.openConversation(convB);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.first.content, 'Hello from User B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);
    });

    test('8. Chat notification A while viewing B opens A correctly and invalidates B', () async {
      await controller.openConversation(convB);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.first.content, 'Hello from User B');

      // Tapping notification A
      await controller.openConversationById('room-A');
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.first.content, 'Hello from User A');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-B'), isFalse);
    });

    test('9. Realtime message appears immediately in active Chat Detail', () async {
      await controller.openConversation(convA);
      expect(controller.activeMessages.length, 1);

      final liveMsg = ChatMessageModel(
        id: 'msg-live-1',
        conversationId: 'room-A',
        senderId: 'user-A',
        senderName: 'User A',
        content: 'Immediate realtime text',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(liveMsg);

      expect(controller.activeMessages.length, 2);
      expect(controller.activeMessages.last.id, 'msg-live-1');
      expect(controller.activeMessages.last.content, 'Immediate realtime text');
    });

    test('10. Realtime message for another conversation does NOT appear in active Chat Detail', () async {
      await controller.openConversation(convA);
      expect(controller.activeRoomId.value, 'room-A');
      final beforeCount = controller.activeMessages.length;

      final msgOther = ChatMessageModel(
        id: 'msg-from-other-room',
        conversationId: 'room-B',
        senderId: 'user-B',
        senderName: 'User B',
        content: 'Secret from B',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(msgOther);

      expect(controller.activeMessages.length, beforeCount);
      expect(controller.activeMessages.any((m) => m.id == 'msg-from-other-room'), isFalse);
      expect(controller.conversations.firstWhere((c) => c.id == 'room-B').unreadCount, 1);
      expect(controller.conversations.firstWhere((c) => c.id == 'room-B').lastMessage, 'Secret from B');
      expect(controller.unreadCount.value, 1);
    });

    test('11. Reconnect / duplicate message events do not duplicate messages or double-count unread', () {
      final dupMsg = ChatMessageModel(
        id: 'msg-dup-check',
        conversationId: 'room-B',
        senderId: 'user-B',
        senderName: 'User B',
        content: 'Duplicated message text',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(dupMsg);
      expect(controller.unreadCount.value, 1);
      expect(controller.conversations.firstWhere((c) => c.id == 'room-B').unreadCount, 1);

      // Duplicate arrival
      controller.onMessageReceived(dupMsg);
      expect(controller.unreadCount.value, 1);
      expect(controller.conversations.firstWhere((c) => c.id == 'room-B').unreadCount, 1);
    });

    test('12. Opening conversation marks it read and clears unread badge', () async {
      controller.conversations.firstWhere((c) => c.id == 'room-A').unreadCount = 3;
      controller.unreadCount.value = 3;
      expect(controller.totalUnreadCount, 3);

      await controller.openConversation(convA);

      expect(controller.conversations.firstWhere((c) => c.id == 'room-A').unreadCount, 0);
      expect(controller.unreadCount.value, 0);
      expect(controller.totalUnreadCount, 0);
    });

    test('14. Message loading indicator properly resets to false even if concurrent calls occur', () async {
      final completer = Completer<Response<dynamic>>();
      when(() => mockDio.get<dynamic>(any(that: contains('/messages')))).thenAnswer(
        (_) => completer.future,
      );

      final future = controller.openConversation(convA);
      expect(controller.isLoadingMessages.value, isTrue);

      completer.complete(
        Response(
          requestOptions: RequestOptions(path: '/messages'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );
      await future;

      expect(controller.isLoadingMessages.value, isFalse);
    });

    testWidgets('15. ChatDetailScreen renders loaded messages and dismisses loading indicator', (tester) async {
      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-spinner-test')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-spinner-test'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-spinner-test',
              'type': 'PRIVATE',
              'counterpart': {
                'userId': 'user-spinner',
                'fullName': 'Ren Makara',
              },
              'unreadCount': 0,
            },
          },
        ),
      );
      when(() => mockDio.get<dynamic>(any(that: contains('/api/v1/community/chats/room-spinner-test/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-spinner-test/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-1',
                  'sender': {'userId': 'user-spinner', 'fullName': 'Ren Makara'},
                  'type': 'TEXT',
                  'content': 'Hello from Ren Makara!',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(roomId: 'room-spinner-test'),
        ),
      );

      // Loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Loading is gone, message is rendered
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hello from Ren Makara!'), findsOneWidget);
      expect(controller.isLoadingMessages.value, isFalse);
    });
  });

  group('Section J Regression: Chat Navigation Lifecycle & Re-entry Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;
    late ChatConversationModel convA;
    late ChatConversationModel convB;

    setUp(() {
      Get.reset();
      mockDio = MockDio();
      dataSource = ChatRemoteDataSource(dio: mockDio);
      repository = ChatRepositoryImpl(remoteDataSource: dataSource);
      controller = ChatController(repository: repository);
      Get.put<ChatController>(controller, permanent: true);

      convA = ChatConversationModel(
        id: 'room-A',
        name: 'User A',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hello from User A',
        lastMessageTime: '10m ago',
        unreadCount: 0,
      );

      convB = ChatConversationModel(
        id: 'room-B',
        name: 'User B',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Hello from User B',
        lastMessageTime: '5m ago',
        unreadCount: 0,
      );

      controller.conversations.assignAll([convA, convB]);

      when(() => mockDio.post<dynamic>(any(that: contains('/read')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/unread-count')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/unread-count'),
          statusCode: 200,
          data: {'success': true, 'data': {'unreadCount': 0}},
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/room-A/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-A/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-A-1',
                  'sender': {'userId': 'user-A', 'fullName': 'User A'},
                  'type': 'TEXT',
                  'content': 'Hello from User A',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: contains('/room-B/messages')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-B/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-B-1',
                  'sender': {'userId': 'user-B', 'fullName': 'User B'},
                  'type': 'TEXT',
                  'content': 'Hello from User B',
                  'createdAt': '2026-09-01T11:00:00Z',
                },
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: equals('/api/v1/community/chats/room-A')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-A'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-A',
              'type': 'PRIVATE',
              'name': 'User A',
              'members': [
                {'userId': 'user-A', 'fullName': 'User A'},
              ],
            },
          },
        ),
      );

      when(() => mockDio.get<dynamic>(any(that: equals('/api/v1/community/chats/room-B')))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-B'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'roomId': 'room-B',
              'type': 'PRIVATE',
              'name': 'User B',
              'members': [
                {'userId': 'user-B', 'fullName': 'User B'},
              ],
            },
          },
        ),
      );
    });

    testWidgets('Test 1: Header Chat -> Chat Detail A -> Back -> Header Chat -> Chat Detail A loads messages on second visit', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: AppRoutes.chatDetail,
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Open Chat A via ChatNavigation
      ChatNavigation.openChatDetail('room-A', conversation: convA);
      await tester.pumpAndSettle();

      expect(find.text('User A'), findsWidgets);
      expect(find.text('Hello from User A'), findsOneWidget);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages, isNotEmpty);

      // Step 2: Exit / Back to Home
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();
      expect(controller.activeRoomId.value, isNull);

      // Step 3: Re-enter Chat A via Header Chat -> Chat Detail
      ChatNavigation.openChatDetail('room-A', conversation: convA);
      await tester.pumpAndSettle();

      // Verify: Messages are reliably displayed and not cleared or blank
      expect(find.text('User A'), findsWidgets);
      expect(find.text('Hello from User A'), findsOneWidget);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages, isNotEmpty);
      expect(controller.isLoadingMessages.value, isFalse);
    });

    testWidgets('Test 2: Header Chat -> Chat Detail A -> Back -> Header Chat -> Chat Detail B loads only Room B messages', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: AppRoutes.chatDetail,
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open A
      ChatNavigation.openChatDetail('room-A', conversation: convA);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);

      // Back
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // Open B
      ChatNavigation.openChatDetail('room-B', conversation: convB);
      await tester.pumpAndSettle();

      expect(find.text('Hello from User B'), findsOneWidget);
      expect(find.text('Hello from User A'), findsNothing);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);
    });

    test('Test 3: Chat A -> B -> A switching restores target history cleanly', () async {
      await controller.ensureConversationLoaded('room-A', conversation: convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.first.content, 'Hello from User A');

      await controller.ensureConversationLoaded('room-B', conversation: convB);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.first.content, 'Hello from User B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);

      await controller.ensureConversationLoaded('room-A', conversation: convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.first.content, 'Hello from User A');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-B'), isFalse);
    });

    testWidgets('Test 4: Public Profile -> Chat A -> Back -> Public Profile -> Chat A preserves message history', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: AppRoutes.chatDetail,
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Profile path initiates ChatNavigation.openChatDetail
      ChatNavigation.openChatDetail('room-A', conversation: convA);
      await tester.pumpAndSettle();

      expect(find.text('Hello from User A'), findsOneWidget);

      // Back
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // Re-enter from Profile
      ChatNavigation.openChatDetail('room-A', conversation: convA);
      await tester.pumpAndSettle();

      expect(find.text('Hello from User A'), findsOneWidget);
      expect(controller.activeMessages, isNotEmpty);
    });

    testWidgets('Test 5: Header Chat -> A, then Notification -> B loads B without A leakage', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: AppRoutes.chatDetail,
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // In Room A
      ChatNavigation.openChatDetail('room-A', conversation: convA);
      await tester.pumpAndSettle();
      expect(find.text('Hello from User A'), findsOneWidget);

      // Push notification arrives for Room B and user taps it
      ChatNavigation.openChatDetail('room-B');
      await tester.pumpAndSettle();

      expect(find.text('Hello from User B'), findsOneWidget);
      expect(find.text('Hello from User A'), findsNothing);
      expect(controller.activeRoomId.value, 'room-B');
      expect(controller.activeMessages.any((m) => m.conversationId == 'room-A'), isFalse);
    });

    test('Test 6: Fast exit and re-entry before async fetch completes does not result in empty or corrupted state', () async {
      final completer1 = Completer<Response<dynamic>>();
      final completer2 = Completer<Response<dynamic>>();
      var callCount = 0;

      when(() => mockDio.get<dynamic>(any(that: contains('/room-A/messages')))).thenAnswer((_) {
        callCount++;
        if (callCount == 1) return completer1.future;
        return completer2.future;
      });

      // Visit 1: Start loading A
      final future1 = controller.ensureConversationLoaded('room-A', conversation: convA);
      expect(controller.isLoadingMessages.value, isTrue);

      // User exits immediately
      controller.leaveConversation();
      expect(controller.activeRoomId.value, isNull);

      // Visit 2: Re-enter A immediately
      final future2 = controller.ensureConversationLoaded('room-A', conversation: convA);
      expect(controller.activeRoomId.value, 'room-A');

      // Completer 1 resolves (stale request)
      completer1.complete(
        Response(
          requestOptions: RequestOptions(path: '/room-A/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-A-old',
                  'sender': {'userId': 'user-A', 'fullName': 'User A'},
                  'type': 'TEXT',
                  'content': 'Stale message from request 1',
                  'createdAt': '2026-09-01T10:00:00Z',
                },
              ],
            },
          },
        ),
      );
      await future1;

      // Completer 2 resolves (current request)
      completer2.complete(
        Response(
          requestOptions: RequestOptions(path: '/room-A/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'content': [
                {
                  'messageId': 'msg-A-fresh',
                  'sender': {'userId': 'user-A', 'fullName': 'User A'},
                  'type': 'TEXT',
                  'content': 'Fresh message from request 2',
                  'createdAt': '2026-09-01T10:05:00Z',
                },
              ],
            },
          },
        ),
      );
      await future2;

      // Verify: Sequence token protected state, messages contain fresh data and not empty
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.id, 'msg-A-fresh');
      expect(controller.activeMessages.first.content, 'Fresh message from request 2');
      expect(controller.isLoadingMessages.value, isFalse);
    });

    test('Test 7: Realtime message after re-entering A appends immediately to active conversation', () async {
      // First visit
      await controller.ensureConversationLoaded('room-A', conversation: convA);
      expect(controller.activeMessages.length, 1);

      // Exit
      controller.leaveConversation();
      expect(controller.activeRoomId.value, isNull);

      // Re-enter
      await controller.ensureConversationLoaded('room-A', conversation: convA);
      expect(controller.activeRoomId.value, 'room-A');
      expect(controller.activeMessages.length, 1);

      // Incoming live message
      final liveMsg = ChatMessageModel(
        id: 'msg-live-reentry',
        conversationId: 'room-A',
        senderId: 'user-A',
        senderName: 'User A',
        content: 'Realtime text after re-entry',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );

      controller.onMessageReceived(liveMsg);

      expect(controller.activeMessages.length, 2);
      expect(controller.activeMessages.last.id, 'msg-live-reentry');
      expect(controller.activeMessages.last.content, 'Realtime text after re-entry');
      expect(controller.unreadCount.value, 0); // Active conversation does not increment unread badge
    });

    testWidgets('Test 8: ChatController permanent singleton is preserved across route transitions and not recreated', (tester) async {
      Get.reset();
      final mockDioInstance = MockDio();
      Get.put<Dio>(mockDioInstance);

      // Register via ChatBinding which sets permanent: true
      ChatBinding().dependencies();

      expect(Get.isRegistered<ChatController>(), isTrue);
      final initialControllerInstance = Get.find<ChatController>();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: Text('Home')),
          getPages: [
            GetPage(
              name: AppRoutes.chatDetail,
              page: () => const ChatDetailScreen(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to chat detail
      ChatNavigation.openChatDetail('room-A');
      await tester.pumpAndSettle();

      // Navigate back
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // Controller should still be registered and be the exact same instance
      expect(Get.isRegistered<ChatController>(), isTrue);
      final postPopControllerInstance = Get.find<ChatController>();
      expect(identical(initialControllerInstance, postPopControllerInstance), isTrue);
    });
  });
}


