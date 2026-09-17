import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../features/chat/domain/models/chat_models.dart';
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/notification/presentation/controllers/notification_controller.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Lightweight, resilient STOMP-over-WebSocket client for real-time notifications and chat.
///
/// Connects to the backend `/ws` endpoint, authenticates with JWT in the STOMP CONNECT frame,
/// and subscribes to `/user/queue/notifications` and `/user/queue/chat`.
class AppRealtimeService extends GetxService {
  AppRealtimeService({
    SecureStorage? secureStorage,
    String? wsUrl,
  }) : _storage = secureStorage ?? SecureStorage(),
       _customWsUrl = wsUrl;

  final SecureStorage _storage;
  final String? _customWsUrl;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;

  final _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatStreamController =
      StreamController<ChatMessageModel>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;
  Stream<ChatMessageModel> get chatStream => _chatStreamController.stream;

  bool get isConnected => _isConnected;

  String get _resolvedWsUrl {
    final custom = _customWsUrl;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final base = AppConfig.apiBaseUrl;
    final wsBase = base.startsWith('https://')
        ? base.replaceFirst('https://', 'wss://')
        : base.replaceFirst('http://', 'ws://');
    return '$wsBase/ws';
  }

  /// Initiates connection if authenticated.
  Future<void> connect() async {
    if (_isDisposed || _isConnected || _isConnecting) return;

    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[Realtime] No auth token found; skipping connection.');
      return;
    }

    _isConnecting = true;
    final targetUrl = _resolvedWsUrl;

    try {
      debugPrint('[Realtime] Connecting to WebSocket: $targetUrl');
      _socket = await WebSocket.connect(targetUrl).timeout(
        const Duration(seconds: 10),
      );

      _socketSubscription = _socket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      _sendStompConnect(token);
    } catch (e) {
      debugPrint('[Realtime] WebSocket connection failed: $e');
      _cleanupSocket();
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _sendStompConnect(String token) {
    if (_socket == null) return;
    final connectFrame =
        'CONNECT\n'
        'accept-version:1.1,1.2\n'
        'heart-beat:10000,10000\n'
        'Authorization:Bearer $token\n\n'
        '\x00';
    _socket!.add(connectFrame);
  }

  void _onData(dynamic rawData) {
    if (rawData is! String) return;
    final frames = rawData.split('\x00');
    for (final frame in frames) {
      final trimmed = frame.trim();
      if (trimmed.isEmpty) continue;
      _processStompFrame(trimmed);
    }
  }

  void _processStompFrame(String frame) {
    final lines = frame.split('\n');
    if (lines.isEmpty) return;
    final command = lines[0].trim();

    if (command == 'CONNECTED') {
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('[Realtime] STOMP connected. Subscribing to queues.');
      _subscribe('/user/queue/notifications', 'sub-notifications');
      _subscribe('/user/queue/chat', 'sub-chat');
      _startHeartbeat();
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().syncLatestNotifications();
      }
      if (Get.isRegistered<ChatController>()) {
        final chatCtrl = Get.find<ChatController>();
        chatCtrl.fetchUnreadCount();
        chatCtrl.fetchConversations();
      }
      return;
    }

    if (command == 'MESSAGE') {
      final headers = <String, String>{};
      int bodyStartIndex = 1;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) {
          bodyStartIndex = i + 1;
          break;
        }
        final colonIdx = line.indexOf(':');
        if (colonIdx != -1) {
          final k = line.substring(0, colonIdx).trim();
          final v = line.substring(colonIdx + 1).trim();
          headers[k] = v;
        }
      }

      final body = lines.sublist(bodyStartIndex).join('\n').trim();
      if (body.isEmpty) return;

      final destination = headers['destination'] ?? '';
      _dispatchMessage(destination, body);
    }
  }

  void _subscribe(String destination, String subscriptionId) {
    if (_socket == null) return;
    final subFrame =
        'SUBSCRIBE\n'
        'id:$subscriptionId\n'
        'destination:$destination\n\n'
        '\x00';
    _socket!.add(subFrame);
    debugPrint('[Realtime] Subscribed to $destination');
  }

  void _dispatchMessage(String destination, String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) return;

      if (destination.contains('/queue/notifications')) {
        debugPrint('[Realtime] Received notification payload: $rawBody');
        _notificationStreamController.add(decoded);
        final type = (decoded['type'] ?? '').toString().toUpperCase();
        final refType =
            (decoded['referenceType'] ?? '').toString().toUpperCase();
        final isChat =
            type == 'CHAT' || refType == 'CHAT_ROOM' || refType == 'CHAT';

        if (!isChat && Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>()
              .onRealtimeNotificationReceivedFromJson(decoded);
        }
        if (isChat && Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().onChatNotificationReceived(decoded);
        }
      } else if (destination.contains('/queue/chat')) {
        debugPrint('[Realtime] Received chat payload: $rawBody');
        final conversationId = (decoded['conversationId'] ??
                decoded['roomId'] ??
                decoded['chatRoomId'] ??
                '')
            .toString();
        final chatMsg = ChatMessageModel.fromJson(
          decoded,
          conversationId: conversationId,
        );
        _chatStreamController.add(chatMsg);
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().onMessageReceived(chatMsg);
        }
      }
    } catch (e) {
      debugPrint('[Realtime] Error decoding message on $destination: $e');
    }
  }

  /// Directly simulates an incoming notification (for testing & offline fallbacks).
  void simulateIncomingNotification(Map<String, dynamic> json) {
    _notificationStreamController.add(json);
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>()
          .onRealtimeNotificationReceivedFromJson(json);
    }
  }

  /// Directly simulates an incoming chat message (for testing & offline fallbacks).
  void simulateIncomingChatMessage(ChatMessageModel message) {
    _chatStreamController.add(message);
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().onMessageReceived(message);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      try {
        _socket?.add('\n');
      } catch (_) {}
    });
  }

  void _onError(dynamic error) {
    debugPrint('[Realtime] Socket error: $error');
    _cleanupSocket();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[Realtime] Socket closed by server.');
    _cleanupSocket();
    _scheduleReconnect();
  }

  void _cleanupSocket() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    final delaySeconds = (_reconnectAttempts < 5)
        ? (2 * (1 << _reconnectAttempts))
        : 30;
    _reconnectAttempts++;
    debugPrint('[Realtime] Scheduling reconnect in $delaySeconds seconds.');
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  /// Disconnects the socket and cancels all timers.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _cleanupSocket();
  }

  @override
  void onClose() {
    _isDisposed = true;
    disconnect();
    _notificationStreamController.close();
    _chatStreamController.close();
    super.onClose();
  }
}
