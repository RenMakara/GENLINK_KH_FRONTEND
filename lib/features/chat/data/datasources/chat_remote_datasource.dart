import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/chat_models.dart';

class ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSource({required this.dio});

  final List<ChatConversationModel> _mockConversations = [
    ChatConversationModel(
      id: 'conv_1',
      name: 'Chhaeng Sokuntheara',
      avatar: 'assets/images/sokuntheara_profile.png',
      isGroup: false,
      isOnline: true,
      lastMessage: 'Hey Sokny! Did you see the new CampusLink design?',
      lastMessageTime: '12m ago',
      unreadCount: 2,
    ),
    ChatConversationModel(
      id: 'conv_2',
      name: 'AUB Flutter & Cloud Devs',
      avatar: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200',
      isGroup: true,
      isOnline: true,
      lastMessage: 'Sum Sambo: Meeting at 3 PM in Lab 204 for hackathon demo.',
      lastMessageTime: '1h ago',
      unreadCount: 5,
      membersCount: 18,
    ),
    ChatConversationModel(
      id: 'conv_3',
      name: 'Sum Sambo',
      avatar: 'assets/images/sum_sambo_profile.png',
      isGroup: false,
      isOnline: false,
      lastMessage: 'I reviewed the Spring Boot security endpoints 👍',
      lastMessageTime: '3h ago',
      unreadCount: 0,
    ),
    ChatConversationModel(
      id: 'conv_4',
      name: 'Heng Chansela',
      avatar: 'assets/images/heng_chansela_profile.png',
      isGroup: false,
      isOnline: true,
      lastMessage: 'Thanks for sharing the study notes!',
      lastMessageTime: 'Yesterday',
      unreadCount: 0,
    ),
    ChatConversationModel(
      id: 'conv_5',
      name: 'Ren Makara',
      avatar: 'assets/images/ren_makara_profile.png',
      isGroup: false,
      isOnline: false,
      lastMessage: 'AuthGate microservices documentation has been updated.',
      lastMessageTime: '2 days ago',
      unreadCount: 0,
    ),
  ];

  final Map<String, List<ChatMessageModel>> _mockMessages = {
    'conv_1': [
      ChatMessageModel(
        id: 'm_101',
        conversationId: 'conv_1',
        senderId: 'user_sokuntheara',
        senderName: 'Chhaeng Sokuntheara',
        senderAvatar: 'assets/images/sokuntheara_profile.png',
        content: 'Hi Sokny! How is the frontend development going?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        timeAgo: '30m ago',
        isMine: false,
      ),
      ChatMessageModel(
        id: 'm_102',
        conversationId: 'conv_1',
        senderId: 'user_me',
        senderName: 'Sokny Enat',
        senderAvatar: 'assets/images/user_profile.png',
        content: 'Hey Sokuntheara! Clean architecture and GetX wiring are looking great.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        timeAgo: '20m ago',
        isMine: true,
      ),
      ChatMessageModel(
        id: 'm_103',
        conversationId: 'conv_1',
        senderId: 'user_sokuntheara',
        senderName: 'Chhaeng Sokuntheara',
        senderAvatar: 'assets/images/sokuntheara_profile.png',
        content: 'Awesome! Did you see the new CampusLink design?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        timeAgo: '12m ago',
        isMine: false,
        isRead: false,
      ),
    ],
    'conv_2': [
      ChatMessageModel(
        id: 'm_201',
        conversationId: 'conv_2',
        senderId: 'user_sambo',
        senderName: 'Sum Sambo',
        senderAvatar: 'assets/images/sum_sambo_profile.png',
        content: 'Meeting at 3 PM in Lab 204 for hackathon demo.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        timeAgo: '1h ago',
        isMine: false,
        isRead: false,
      ),
    ],
  };

  Future<List<ChatConversationModel>> fetchConversations() async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>(ApiEndpoints.chats),
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        if (rawData is List && rawData.isNotEmpty) {
          return rawData
              .map((json) => ChatConversationModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return _mockConversations;
  }

  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    try {
      final response = await guardDio(
        () => dio.get<dynamic>('${ApiEndpoints.chats}/$conversationId/messages'),
      );
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        final rawData = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        if (rawData is List && rawData.isNotEmpty) {
          return rawData
              .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return _mockMessages[conversationId] ?? [
      ChatMessageModel(
        id: 'm_default',
        conversationId: conversationId,
        senderId: 'user_other',
        senderName: 'Member',
        content: 'Hello! Let\'s connect and collaborate on GenLink KH.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        timeAgo: '2h ago',
        isMine: false,
      ),
    ];
  }

  Future<ChatMessageModel> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    final newMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'current_user',
      senderName: 'Sokny Enat',
      senderAvatar: 'assets/images/user_profile.png',
      content: content,
      timestamp: DateTime.now(),
      timeAgo: 'Just now',
      isMine: true,
      isRead: true,
      messageType: messageType,
      mediaUrl: mediaUrl,
    );

    try {
      await guardDio(
        () => dio.post<dynamic>(
          '${ApiEndpoints.chats}/$conversationId/messages',
          data: {
            'content': content,
            'messageType': messageType,
            'mediaUrl': mediaUrl,
          },
        ),
      );
    } catch (_) {}


    if (!_mockMessages.containsKey(conversationId)) {
      _mockMessages[conversationId] = [];
    }
    _mockMessages[conversationId]!.add(newMsg);

    final convIdx = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (convIdx != -1) {
      _mockConversations[convIdx].lastMessage = content;
      _mockConversations[convIdx].lastMessageTime = 'Just now';
    }

    return newMsg;
  }

  Future<bool> markConversationRead(String conversationId) async {
    final convIdx = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (convIdx != -1) {
      _mockConversations[convIdx].unreadCount = 0;
    }
    return true;
  }
}
