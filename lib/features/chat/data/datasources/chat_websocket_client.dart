import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/models/chat_models.dart';

typedef WebSocketFactory = Future<dynamic> Function(Uri uri);

class ChatWebSocketClient {
  final SecureStorage? secureStorage;
  final WebSocketFactory? webSocketFactory;
  final String? wsBaseUrl;

  dynamic _socket;
  StreamSubscription? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;

  final StreamController<ChatMessageModel> _messageController =
      StreamController<ChatMessageModel>.broadcast();

  ChatWebSocketClient({
    this.secureStorage,
    this.webSocketFactory,
    this.wsBaseUrl,
  });

  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Uri _resolveWsUri() {
    final base = wsBaseUrl ?? AppConfig.apiBaseUrl;
    final uri = Uri.parse(base);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return Uri.parse('$scheme://${uri.host}$port/ws');
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    _shouldReconnect = true;

    try {
      final token = await secureStorage?.readAccessToken();
      final wsUri = _resolveWsUri();

      debugPrint('[ChatWS] Connecting to $wsUri...');

      if (webSocketFactory != null) {
        _socket = await webSocketFactory!(wsUri);
      } else {
        _socket = await WebSocket.connect(wsUri.toString());
      }

      _socketSubscription = _socket.listen(
        (data) => _onData(data),
        onError: (err) => _onError(err),
        onDone: () => _onDone(),
      );

      // Send STOMP CONNECT frame
      _sendStompConnect(token);
    } catch (e) {
      debugPrint('[ChatWS] Connection error: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _sendStompConnect(String? token) {
    final buffer = StringBuffer();
    buffer.write('CONNECT\n');
    buffer.write('accept-version:1.2\n');
    buffer.write('host:genlink\n');
    buffer.write('heart-beat:10000,10000\n');
    if (token != null && token.isNotEmpty) {
      buffer.write('Authorization:Bearer $token\n');
      buffer.write('passcode:$token\n');
    }
    buffer.write('\n\x00');
    _sendRaw(buffer.toString());
  }

  void _sendStompSubscribe() {
    const frame = 'SUBSCRIBE\n'
        'id:sub-chat-0\n'
        'destination:/user/queue/chat\n'
        'ack:auto\n\n\x00';
    _sendRaw(frame);
    debugPrint('[ChatWS] Subscribed to /user/queue/chat');
  }

  void _sendRaw(String data) {
    try {
      _socket?.add(data);
    } catch (e) {
      debugPrint('[ChatWS] Send error: $e');
    }
  }

  void _onData(dynamic data) {
    final text = data is String ? data : utf8.decode(data as List<int>);

    if (text.startsWith('CONNECTED')) {
      _isConnected = true;
      _isConnecting = false;
      debugPrint('[ChatWS] STOMP CONNECTED successfully');
      _sendStompSubscribe();
      _startHeartbeat();
      return;
    }

    if (text.startsWith('MESSAGE')) {
      _handleMessageFrame(text);
      return;
    }

    if (text.startsWith('ERROR')) {
      debugPrint('[ChatWS] STOMP ERROR: $text');
      return;
    }

    // Heartbeat ping/pong newline
    if (text == '\n' || text == '\r\n') {
      return;
    }
  }

  @visibleForTesting
  void onDataForTesting(dynamic data) => _onData(data);

  void _handleMessageFrame(String frame) {
    try {
      final bodyIndex = frame.indexOf('\n\n');
      if (bodyIndex == -1) return;

      var body = frame.substring(bodyIndex + 2);
      final nullIndex = body.indexOf('\x00');
      if (nullIndex != -1) {
        body = body.substring(0, nullIndex);
      }
      body = body.trim();
      if (body.isEmpty) return;

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final roomId = decoded['roomId']?.toString() ??
            decoded['conversationId']?.toString() ??
            '';
        final message = ChatMessageModel.fromJson(
          decoded,
          conversationId: roomId,
        );
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('[ChatWS] Message parsing error: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isConnected) {
        _sendRaw('\n');
      }
    });
  }

  void _onError(dynamic err) {
    debugPrint('[ChatWS] Socket error: $err');
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[ChatWS] Socket closed');
    _isConnected = false;
    _isConnecting = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldReconnect && !_isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _isConnected = false;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    try {
      _sendRaw('DISCONNECT\n\n\x00');
    } catch (_) {}
    _socketSubscription?.cancel();
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
