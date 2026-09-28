import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:genlink_frontend/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';
import 'package:genlink_frontend/features/chat/presentation/controllers/chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'chat loads older pages without duplicates and keeps chronological order',
    () async {
      final requestedPages = <int>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _ChatAdapter((options) async {
          if (options.method == 'GET' && options.path.endsWith('/messages')) {
            // Page 0/size 30 uses Spring's matching default Pageable values;
            // subsequent history requests send an explicit page query.
            final page = options.queryParameters['page'] as int? ?? 0;
            requestedPages.add(page);
            return _response({
              'data': {
                'content': page == 0
                    ? [_message('m30', 30), _message('m29', 29)]
                    : [_message('m29', 29), _message('m28', 28)],
                'page': page,
                'hasNext': page == 0,
              },
            });
          }
          return _response({
            'data': {'unreadCount': 0},
          });
        });
      final repository = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSource(dio: dio),
      );
      final controller = ChatController(repository: repository);
      controller.conversations.add(
        ChatConversationModel(
          id: 'room-1',
          name: 'Chat with Lea',
          avatar: '',
          lastMessage: 'latest',
          lastMessageTime: 'now',
        ),
      );

      await controller.ensureConversationLoaded('room-1');
      expect(controller.activeMessages.map((message) => message.id), [
        'm29',
        'm30',
      ]);
      expect(controller.hasOlderMessages.value, isTrue);

      await controller.loadOlderMessages();

      expect(requestedPages, [0, 1]);
      expect(controller.activeMessages.map((message) => message.id), [
        'm28',
        'm29',
        'm30',
      ]);
      expect(controller.activeMessages.length, 3);
      expect(controller.hasOlderMessages.value, isFalse);
    },
  );
}

Map<String, dynamic> _message(String id, int minute) => {
  'messageId': id,
  'content': id,
  'createdAt': '2026-09-28T10:${minute.toString().padLeft(2, '0')}:00Z',
  'senderId': 'user-1',
  'senderName': 'Lea',
};

ResponseBody _response(Map<String, dynamic> body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _ChatAdapter implements HttpClientAdapter {
  const _ChatAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}
