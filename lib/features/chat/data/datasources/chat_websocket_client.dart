import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/models/chat_models.dart';

/// Lightweight, robust STOMP-over-WebSocket client for real-time GenLink chat.
///
/// Features:
/// - Connects to backend STOMP WebSocket endpoint using JWT Bearer token
/// - Subscribes to real-time user destination `/user/queue/chat`
/// - Safely parses incoming chat events into [ChatMessageModel]
/// - Automatic exponential-backoff reconnection
/// - Never crashes the application if the WebSocket server is unavailable (REST-first architecture)
class ChatWebSocketClient {
  static const String defaultDestination = '/user/queue/chat';

  final void Function(ChatMessageModel message)? onMessageReceived;
  final void Function(bool isConnected)? onConnectionChanged;

  WebSocket? _webSocket;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  bool _isConnected = false;
  bool _isManualDisconnect = false;
  int _reconnectAttempts = 0;
  String? _token;
  String? _endpointUrl;

  bool get isConnected => _isConnected;

  ChatWebSocketClient({
    this.onMessageReceived,
    this.onConnectionChanged,
  });

  static String resolveDefaultWebSocketUrl() {
    final baseUrl = AppConfig.apiBaseUrl;
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host ?? '18.143.33.191';
    final scheme = (uri?.scheme == 'https') ? 'wss' : 'ws';
    final portStr = (uri?.hasPort == true) ? ':${uri!.port}' : '';
    return '$scheme://$host$portStr/ws';
  }

  /// Connects using the STOMP protocol.
  Future<void> connect({
    String? token,
    String? url,
  }) async {
    _token = token ?? _token;
    _endpointUrl = url ?? _endpointUrl ?? resolveDefaultWebSocketUrl();
    _isManualDisconnect = false;

    _cleanupSocket();

    try {
      debugPrint('[ChatWebSocket] Connecting to $_endpointUrl...');
      _webSocket = await WebSocket.connect(_endpointUrl!).timeout(
        const Duration(seconds: 8),
      );

      _subscription = _webSocket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Send STOMP CONNECT frame
      _sendStompConnect();
    } catch (e) {
      debugPrint('[ChatWebSocket] Connection error (safe fallback to REST): $e');
      _setConnected(false);
      _scheduleReconnect();
    }
  }

  void _sendStompConnect() {
    final buffer = StringBuffer();
    buffer.write('CONNECT\n');
    buffer.write('accept-version:1.1,1.2\n');
    buffer.write('heart-beat:10000,10000\n');
    if (_token != null && _token!.isNotEmpty) {
      final cleanToken = _token!.startsWith('Bearer ') ? _token! : 'Bearer $_token';
      buffer.write('Authorization:$cleanToken\n');
    }
    buffer.write('\n');
    buffer.write('\x00');

    _sendRaw(buffer.toString());
  }

  void _sendStompSubscribe(String destination, {String id = 'sub-chat-0'}) {
    final buffer = StringBuffer();
    buffer.write('SUBSCRIBE\n');
    buffer.write('id:$id\n');
    buffer.write('destination:$destination\n');
    buffer.write('ack:auto\n');
    buffer.write('\n');
    buffer.write('\x00');

    _sendRaw(buffer.toString());
  }

  void _onData(dynamic rawData) {
    if (rawData is! String) return;

    final frames = rawData.split('\x00');
    for (final frame in frames) {
      final trimmed = frame.trim();
      if (trimmed.isEmpty) continue;
      _parseStompFrame(trimmed);
    }
  }

  void _parseStompFrame(String frame) {
    try {
      final lines = frame.split('\n');
      if (lines.isEmpty) return;
      final command = lines[0].trim();

      if (command == 'CONNECTED') {
        debugPrint('[ChatWebSocket] STOMP CONNECTED successfully');
        _reconnectAttempts = 0;
        _setConnected(true);
        _sendStompSubscribe(defaultDestination);
        _startHeartbeat();
      } else if (command == 'MESSAGE') {
        // Find empty line separating headers from body
        final headerBodySeparatorIndex = frame.indexOf('\n\n');
        final crlfSeparatorIndex = frame.indexOf('\r\n\r\n');
        final separatorIndex = headerBodySeparatorIndex != -1
            ? headerBodySeparatorIndex + 2
            : (crlfSeparatorIndex != -1 ? crlfSeparatorIndex + 4 : -1);

        if (separatorIndex != -1 && separatorIndex < frame.length) {
          final body = frame.substring(separatorIndex).trim();
          _handleMessagePayload(body);
        }
      } else if (command == 'ERROR') {
        debugPrint('[ChatWebSocket] STOMP ERROR frame received: $frame');
      }
    } catch (e) {
      debugPrint('[ChatWebSocket] Error parsing STOMP frame: $e');
    }
  }

  void _handleMessagePayload(String body) {
    if (body.isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final conversationId = (decoded['conversationId'] ??
                decoded['chatRoomId'] ??
                decoded['roomId'] ??
                '')
            .toString();
        final message = ChatMessageModel.fromJson(
          decoded,
          conversationId: conversationId,
        );
        onMessageReceived?.call(message);
      }
    } catch (e) {
      debugPrint('[ChatWebSocket] Failed to parse message JSON: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendRaw('\n');
    });
  }

  void _onError(dynamic error) {
    debugPrint('[ChatWebSocket] Socket error: $error');
    _setConnected(false);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[ChatWebSocket] Socket closed');
    _setConnected(false);
    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isManualDisconnect) return;
    _reconnectTimer?.cancel();

    _reconnectAttempts++;
    final backoffSeconds = (_reconnectAttempts * 2).clamp(2, 30);
    debugPrint('[ChatWebSocket] Scheduling reconnect attempt $_reconnectAttempts in ${backoffSeconds}s');

    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isManualDisconnect && !_isConnected) {
        connect(token: _token, url: _endpointUrl);
      }
    });
  }

  void _sendRaw(String data) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      try {
        _webSocket!.add(data);
      } catch (e) {
        debugPrint('[ChatWebSocket] Error sending raw data: $e');
      }
    }
  }

  void _setConnected(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      onConnectionChanged?.call(value);
    }
  }

  void _cleanupSocket() {
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    try {
      _webSocket?.close();
    } catch (_) {}
    _webSocket = null;
  }

  void disconnect() {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _cleanupSocket();
    _setConnected(false);
  }
}
