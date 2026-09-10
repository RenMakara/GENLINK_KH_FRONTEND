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
                // Backend returns DESC (newest first)
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

      // Inbound message for background chat
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

      // Set conversation active and receive another message
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

    testWidgets('ChatListScreen renders header, online row, and empty state', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Messages & Chats'), findsOneWidget);
      expect(find.text('Sokny Enat'), findsOneWidget);
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
  });
}
