import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:mocktail/mocktail.dart';

import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_websocket_client.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/screens/create_group_screen.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_system_message.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_filter_chip.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_list_item.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/chat_story_reply_card.dart';
import 'package:genlink_frontend/features/chat/presentation/widgets/group_member_tile.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
    ChatLocalDataSource.resetStaticStore();
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

    test('pinMessage and unpinMessage call correct endpoints', () async {
      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/pin/msg-1'),
          statusCode: 200,
          data: {'success': true},
        ),
      );
      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/pin'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final pinOk = await dataSource.pinMessage('room-1', 'msg-1');
      final unpinOk = await dataSource.unpinMessage('room-1');
      expect(pinOk, isTrue);
      expect(unpinOk, isTrue);
    });

    test('group operations (rename, add, remove, role, leave) call backend correctly', () async {
      when(() => mockDio.put<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1'),
          statusCode: 200,
          data: {'success': true},
        ),
      );
      when(() => mockDio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/members'),
          statusCode: 200,
          data: {'success': true},
        ),
      );
      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-1/members/u2'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      final renameOk = await dataSource.renameGroup('room-1', 'New Group Name');
      final addOk = await dataSource.addGroupMembers('room-1', ['u2', 'u3']);
      final removeOk = await dataSource.removeGroupMember('room-1', 'u2');
      final roleOk = await dataSource.changeMemberRole('room-1', 'u3', 'ADMIN');
      final leaveOk = await dataSource.leaveGroup('room-1');

      expect(renameOk, isTrue);
      expect(addOk, isTrue);
      expect(removeOk, isTrue);
      expect(roleOk, isTrue);
      expect(leaveOk, isTrue);
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

    test('optimistic message replacement reconciles temp local ID with server message ID without duplicating', () {
      final conv = ChatConversationModel(
        id: 'room-opt',
        name: 'Friend',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Pending...',
        lastMessageTime: 'Just now',
      );
      controller.activeConversation.value = conv;

      // 1. Optimistic local message is created while waiting for backend
      final localMsg = ChatMessageModel(
        id: 'msg_local_123456',
        conversationId: 'room-opt',
        senderId: 'current_user',
        senderName: 'Me',
        content: 'Hello via optimistic send',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
      );
      controller.activeMessages.add(localMsg);
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.id, 'msg_local_123456');

      // 2. Real server message arrives (e.g. from backend response or WebSocket push)
      final serverMsg = ChatMessageModel(
        id: 'msg_server_789',
        conversationId: 'room-opt',
        senderId: 'current_user',
        senderName: 'Me',
        content: 'Hello via optimistic send',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: true,
      );

      final added = controller.safeAddOrUpdateActiveMessage(serverMsg);
      expect(added, isTrue);

      // 3. Verify deduplication: count is still 1, but id is replaced with the server ID
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.id, 'msg_server_789');
      expect(controller.activeMessages.first.content, 'Hello via optimistic send');
    });

    test('rapid double-tap sendMessage is guarded against duplicate sending', () async {
      final conv = ChatConversationModel(
        id: 'room-double-tap',
        name: 'Friend',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Old',
        lastMessageTime: '1h ago',
      );
      controller.conversations.add(conv);
      controller.activeConversation.value = conv;

      when(() => mockDio.post<dynamic>(
        any(),
        data: any(named: 'data'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-double-tap/messages'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'messageId': 'm-double-1',
              'sender': {'userId': 'me', 'fullName': 'Me'},
              'type': 'TEXT',
              'content': 'Quick double tap!',
              'mine': true,
              'createdAt': DateTime.now().toIso8601String(),
            },
          },
        ),
      );

      // First tap
      controller.textController.text = 'Quick double tap!';
      await controller.sendMessage();
      expect(controller.activeMessages.length, 1);

      // Rapid second tap with same content immediately
      controller.textController.text = 'Quick double tap!';
      await controller.sendMessage();

      // Verified: duplicate was suppressed
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Quick double tap!');
    });

    test('rapid double-tap sendStoryReply is guarded against duplicate sending', () async {
      // First story reply
      final firstReply = await controller.sendStoryReply(
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        message: 'Loved this story photo!',
        storyId: 'story-100',
        userId: 'user_sokny',
      );
      expect(firstReply, isNotNull);
      expect(controller.activeMessages.length, 1);

      // Immediate second call with identical message
      final secondReply = await controller.sendStoryReply(
        userName: 'Sokny Enat',
        userAvatar: 'assets/images/user_profile.png',
        message: 'Loved this story photo!',
        storyId: 'story-100',
        userId: 'user_sokny',
      );

      // Verified: second call returns the existing message without duplicating in activeMessages
      expect(secondReply.id, firstReply.id);
      expect(controller.activeMessages.length, 1);
    });

    test('incoming WebSocket message with duplicate ID updates existing message rather than appending duplicate', () {
      final conv = ChatConversationModel(
        id: 'room-ws-dup',
        name: 'Friend',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Initial',
        lastMessageTime: 'Just now',
      );
      controller.conversations.add(conv);
      controller.activeConversation.value = conv;

      final initialMsg = ChatMessageModel(
        id: 'msg-ws-1',
        conversationId: 'room-ws-dup',
        senderId: 'user-2',
        senderName: 'Friend',
        content: 'Original content',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );
      controller.onMessageReceived(initialMsg);
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Original content');

      // Duplicate delivery (e.g. STOMP reconnect echo)
      final duplicateDelivery = ChatMessageModel(
        id: 'msg-ws-1',
        conversationId: 'room-ws-dup',
        senderId: 'user-2',
        senderName: 'Friend',
        content: 'Updated content from server',
        timestamp: DateTime.now(),
        timeAgo: 'Just now',
        isMine: false,
      );
      controller.onMessageReceived(duplicateDelivery);

      // Verified: updated in place, count remains 1
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Updated content from server');
    });

    test('deduplicateMessages strips duplicates, merges optimistic messages, and enforces chronological order', () {
      final now = DateTime.now();
      final rawList = [
        ChatMessageModel(
          id: 'msg-3',
          conversationId: 'room-c',
          senderId: 'u1',
          senderName: 'User 1',
          content: 'Third message',
          timestamp: now.add(const Duration(minutes: 2)),
          timeAgo: '2m',
          isMine: false,
        ),
        ChatMessageModel(
          id: 'msg_local_1',
          conversationId: 'room-c',
          senderId: 'me',
          senderName: 'Me',
          content: 'First message',
          timestamp: now,
          timeAgo: 'now',
          isMine: true,
        ),
        ChatMessageModel(
          id: 'msg-server-1',
          conversationId: 'room-c',
          senderId: 'me',
          senderName: 'Me',
          content: 'First message',
          timestamp: now.add(const Duration(seconds: 1)),
          timeAgo: 'now',
          isMine: true,
        ),
        ChatMessageModel(
          id: 'msg-3', // Exact duplicate
          conversationId: 'room-c',
          senderId: 'u1',
          senderName: 'User 1',
          content: 'Third message',
          timestamp: now.add(const Duration(minutes: 2)),
          timeAgo: '2m',
          isMine: false,
        ),
        ChatMessageModel(
          id: 'msg-2',
          conversationId: 'room-c',
          senderId: 'u2',
          senderName: 'User 2',
          content: 'Second message',
          timestamp: now.add(const Duration(minutes: 1)),
          timeAgo: '1m',
          isMine: false,
        ),
      ];

      final deduped = controller.deduplicateMessages(rawList);

      // msg_local_1 was merged with msg-server-1, msg-3 exact duplicate was removed
      expect(deduped.length, 3);
      expect(deduped[0].id, 'msg-server-1');
      expect(deduped[0].content, 'First message');
      expect(deduped[1].id, 'msg-2');
      expect(deduped[1].content, 'Second message');
      expect(deduped[2].id, 'msg-3');
      expect(deduped[2].content, 'Third message');
    });

    test('ChatWebSocketClient safe instantiation and disconnection', () {
      final wsClient = ChatWebSocketClient(
        onMessageReceived: (_) {},
        onConnectionChanged: (_) {},
      );

      expect(wsClient.isConnected, isFalse);
      // Disconnecting when not connected should be safe and not throw
      expect(() => wsClient.disconnect(), returnsNormally);
    });

    test('togglePinMessage pins message and unpins message updating state and calling backend', () async {
      final conv = ChatConversationModel(
        id: 'room-pin-test',
        name: 'Friend',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Let us pin this',
        lastMessageTime: '1m ago',
      );
      final msg = ChatMessageModel(
        id: 'msg-to-pin',
        conversationId: 'room-pin-test',
        senderId: 'me',
        senderName: 'Me',
        content: 'Important pin',
        timestamp: DateTime.now(),
        timeAgo: 'now',
        isMine: true,
      );

      controller.conversations.add(conv);
      controller.activeConversation.value = conv;
      controller.activeMessages.add(msg);

      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-pin-test/pin/msg-to-pin'),
          statusCode: 200,
          data: {'success': true},
        ),
      );
      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-pin-test/pin'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      // Pin message
      controller.togglePinMessage(msg);
      expect(controller.pinnedMessage.value?.id, 'msg-to-pin');
      expect(controller.activeMessages.first.isPinned, isTrue);

      // Unpin message
      controller.togglePinMessage(msg);
      expect(controller.pinnedMessage.value, isNull);
      expect(controller.activeMessages.first.isPinned, isFalse);
    });

    test('onMessageReceived resolves conversationId from sender when omitted in WS event payload', () {
      final conv = ChatConversationModel(
        id: 'room-sokny-1',
        name: 'Sokny Enat',
        avatar: 'assets/images/user_profile.png',
        lastMessage: 'Old',
        lastMessageTime: '1h ago',
        unreadCount: 0,
      );
      controller.conversations.add(conv);
      controller.activeConversation.value = conv;

      // STOMP ChatMessageResponse without roomId
      final wsMsgWithoutRoomId = ChatMessageModel(
        id: 'msg-ws-no-room',
        conversationId: '', // Empty, as delivered in ChatMessageResponse
        senderId: 'user_sokny',
        senderName: 'Sokny Enat',
        content: 'Direct message from Sokny',
        timestamp: DateTime.now(),
        timeAgo: 'now',
        isMine: false,
      );

      when(() => mockDio.post<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/room-sokny-1/read'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      controller.onMessageReceived(wsMsgWithoutRoomId);

      // Successfully resolved to room-sokny-1, appended to active messages
      expect(controller.activeMessages.length, 1);
      expect(controller.activeMessages.first.content, 'Direct message from Sokny');
      expect(conv.lastMessage, 'Direct message from Sokny');
    });

    test('group management methods in ChatController update conversation list and active state', () async {
      final groupConv = ChatConversationModel(
        id: 'group-100',
        name: 'Old Group Name',
        avatar: 'assets/images/user_profile.png',
        isGroup: true,
        lastMessage: 'Welcome',
        lastMessageTime: '1h ago',
      );
      controller.conversations.add(groupConv);
      controller.activeConversation.value = groupConv;

      when(() => mockDio.put<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/group-100'),
          statusCode: 200,
          data: {'success': true},
        ),
      );
      when(() => mockDio.delete<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats/group-100/leave'),
          statusCode: 200,
          data: {'success': true},
        ),
      );

      // Rename group
      final renamed = await controller.renameGroup('group-100', 'New Group Name');
      expect(renamed, isTrue);
      expect(controller.conversations.first.name, 'New Group Name');
      expect(controller.activeConversation.value?.name, 'New Group Name');

      // Leave group
      final left = await controller.leaveGroup('group-100');
      expect(left, isTrue);
      expect(controller.conversations.isEmpty, isTrue);
      expect(controller.activeConversation.value, isNull);
    });
  });

  group('Chat UI Widget Tests', () {
    late MockDio mockDio;
    late ChatRemoteDataSource dataSource;
    late ChatRepositoryImpl repository;
    late ChatController controller;

    setUp(() async {
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
      await controller.fetchConversations();
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

    testWidgets('CreateGroupScreen selects multiple members, filters with search, and clear all removes them', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first member
      await tester.tap(find.text('Sokny Enat'));
      await tester.pumpAndSettle();
      expect(find.text('Selected · 1'), findsOneWidget);

      // Tap second member
      await tester.tap(find.text('Heng Chansela'));
      await tester.pumpAndSettle();
      expect(find.text('Selected · 2'), findsOneWidget);

      // Tap Clear all
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('Selected · 2'), findsNothing);

      // Search filtering
      await tester.enterText(find.byType(TextField).last, 'Ren');
      await tester.pumpAndSettle();
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text('Sokny Enat'), findsNothing);
    });

    testWidgets('CreateGroupScreen renders in Dark Mode without layout overflow', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          home: const CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Group Chat'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('CreateGroupScreen localizes properly in Khmer locale', (tester) async {
      Get.clearTranslations();
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('km', 'KH');

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          fallbackLocale: const Locale('en', 'US'),
          home: const CreateGroupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('បង្កើតក្រុមជជែកថ្មី'), findsOneWidget);
      expect(find.text('បង្កើត'), findsOneWidget);
      expect(find.text('ជ្រើសរើសសមាជិក'), findsOneWidget);
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

  group('Chat Step 12 — Persistence, Deduplication & User Isolation Regression Tests', () {
    late MockDio mockDio;
    late ChatLocalDataSource localDataSource;

    setUp(() {
      Get.reset();
      Get.testMode = true;
      mockDio = MockDio();
      localDataSource = ChatLocalDataSource();
      when(() => mockDio.get<dynamic>(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/community/chats'),
          statusCode: 200,
          data: {'success': true, 'data': {'content': []}},
        ),
      );
    });

    testWidgets('TEST 1 — 1-to-1 persistence: Sokny Enat to Heng Chansela survives app restart simulation', (tester) async {
      // 1. Start as Sokny Enat
      final repo1 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller1 = Get.put(ChatController(repository: repo1));

      // 2. Open Heng Chansela chat
      final conv = await controller1.openPrivateChat('user_chansela', name: 'Heng Chansela');
      expect(conv, isNotNull);

      // 3. Send "Hello Heng"
      controller1.textController.text = 'Hello Heng';
      await controller1.sendMessage();
      // 4. Send "This should survive refresh"
      controller1.textController.text = 'This should survive refresh';
      await controller1.sendMessage();

      // 5. Confirm both messages appear
      expect(controller1.activeMessages.length, 2);
      expect(controller1.activeMessages.map((m) => m.content).toList(), [
        'Hello Heng',
        'This should survive refresh',
      ]);

      // 6. Fully restart/refresh the Flutter app (simulate Get.reset() while preserving local persistent storage)
      Get.reset();

      // 7. Open Chat List (re-instantiate repository and controller)
      final repo2 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller2 = Get.put(ChatController(repository: repo2));
      await controller2.fetchConversations();

      // 8. Confirm Heng Chansela conversation still exists
      expect(controller2.conversations.length, 1);
      expect(controller2.conversations.first.name, 'Heng Chansela');
      expect(controller2.conversations.first.lastMessage, 'This should survive refresh');

      // 9. Open the conversation
      await controller2.openConversation(controller2.conversations.first);

      // 10. Confirm both messages are still there
      expect(controller2.activeMessages.length, 2);
      expect(controller2.activeMessages[0].content, 'Hello Heng');
      expect(controller2.activeMessages[1].content, 'This should survive refresh');

      // 11. Send another message
      controller2.textController.text = 'Surviving restart round 2';
      await controller2.sendMessage();
      expect(controller2.activeMessages.length, 3);

      // 12. Restart again
      Get.reset();
      final repo3 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller3 = Get.put(ChatController(repository: repo3));
      await controller3.fetchConversations();
      await controller3.openConversation(controller3.conversations.first);

      // 13. Confirm all messages remain
      expect(controller3.activeMessages.length, 3);
      expect(controller3.activeMessages.map((m) => m.content).toList(), [
        'Hello Heng',
        'This should survive refresh',
        'Surviving restart round 2',
      ]);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('TEST 2 — Conversation deduplication: opening Heng Chansela never creates duplicates after restart', (tester) async {
      // 1. Open Heng Chansela from Chat List or profile
      final repo1 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller1 = Get.put(ChatController(repository: repo1));
      await controller1.openPrivateChat('user_chansela', name: 'Heng Chansela');
      controller1.textController.text = 'First greeting';
      await controller1.sendMessage();
      expect(controller1.conversations.where((c) => c.name == 'Heng Chansela').length, 1);

      // 2. Restart app
      Get.reset();

      // 3. Open Heng Chansela again from Chat List or profile
      final repo2 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller2 = Get.put(ChatController(repository: repo2));
      await controller2.fetchConversations();
      await controller2.openPrivateChat('user_chansela', name: 'Heng Chansela');

      // 4. Confirm: strictly 1 Heng Chansela conversation exists in the list
      final matching = controller2.conversations.where((c) => c.name == 'Heng Chansela').toList();
      expect(matching.length, 1);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('TEST 3 — Story reply persistence: story metadata and card survive restart without downgrading', (tester) async {
      final repo1 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller1 = Get.put(ChatController(repository: repo1));

      // 1-3. Send story reply with image preview
      final replyMsg = await controller1.sendStoryReply(
        userName: 'Heng Chansela',
        userAvatar: 'assets/images/heng_chansela_profile.png',
        message: 'Nice view!',
        mediaUrl: 'assets/images/user_profile.png',
        storyId: 'story-sunset-99',
      );

      expect(replyMsg.messageType, 'story_reply');
      expect(replyMsg.storyReference?.storyId, 'story-sunset-99');
      expect(replyMsg.storyReference?.mediaUrl, 'assets/images/user_profile.png');

      // 4. Restart/refresh app
      Get.reset();

      // 5. Open Heng Chansela chat
      final repo2 = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controller2 = Get.put(ChatController(repository: repo2));
      await controller2.fetchConversations();
      final chanselaConv = controller2.conversations.firstWhere((c) => c.name == 'Heng Chansela');
      await controller2.openConversation(chanselaConv);

      // 6. Confirm story reply message still exists with thumbnail and metadata intact
      expect(controller2.activeMessages.isNotEmpty, isTrue);
      final persistedReply = controller2.activeMessages.firstWhere((m) => m.messageType == 'story_reply');
      expect(persistedReply.content, 'Nice view!');
      expect(persistedReply.storyReference, isNotNull);
      expect(persistedReply.storyReference!.storyId, 'story-sunset-99');
      expect(persistedReply.storyReference!.mediaUrl, 'assets/images/user_profile.png');

      // 7. Verify UI widget renders ChatStoryReplyCard
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChatStoryReplyCard), findsOneWidget);
      expect(find.text('Nice view!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('TEST 4 — Two-user isolation: User A messages never leak into User B store', (tester) async {
      // 1. User A (Sokny) sends secret message
      final repoA = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_sokny',
      );
      final controllerA = Get.put(ChatController(repository: repoA));
      await controllerA.openPrivateChat('user_chansela', name: 'Heng Chansela');
      controllerA.textController.text = 'Secret confidential note from Sokny';
      await controllerA.sendMessage();

      // 2. Switch to User B (Bob)
      Get.reset();
      final repoB = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_bob',
      );
      final controllerB = Get.put(ChatController(repository: repoB));
      await controllerB.fetchConversations();

      // 3. Confirm: User B does NOT see User A's private chats
      expect(controllerB.conversations.isEmpty, isTrue);
      expect(controllerB.activeMessages.isEmpty, isTrue);

      // Also directly query local datasource to guarantee cryptographic key separation
      final bobMessages = await localDataSource.getMessages('user_bob', 'private_user_chansela');
      expect(bobMessages.isEmpty, isTrue);
      final soknyMessages = await localDataSource.getMessages('user_sokny', 'private_user_chansela');
      expect(soknyMessages.length, 1);
      expect(soknyMessages.first.content, 'Secret confidential note from Sokny');
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('TEST 5 — Empty/new user: clean empty state renders with zero lingering chats or spinner', (tester) async {
      // 1. Switch to a brand new user with no chats
      Get.reset();
      final repoNew = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: mockDio, localDataSource: localDataSource),
        localDataSource: localDataSource,
        currentUserIdOverride: 'user_new_student',
      );
      final controllerNew = Get.put(ChatController(repository: repoNew));
      await controllerNew.fetchConversations();

      // 2. Render ChatListScreen
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ChatListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify clean empty state: "No messages yet", not a crash, not infinite spinner
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Connect with student peers and join group discussions.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(controllerNew.conversations.isEmpty, isTrue);
    });
  });
}

