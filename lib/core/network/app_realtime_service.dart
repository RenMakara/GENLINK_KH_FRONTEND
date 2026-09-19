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
import 'stomp_frame.dart';

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class RealtimeErrorEvent {
  const RealtimeErrorEvent({
    required this.message,
    this.code,
    this.destination,
  });

  final String message;
  final String? code;
  final String? destination;
}

/// Lightweight, resilient STOMP-over-WebSocket client for real-time app events.
///
/// Connects to the backend `/ws` endpoint, authenticates with JWT in the STOMP CONNECT frame,
/// and owns all application subscriptions, including quiz matches.
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
  bool _allowReconnect = true;
  int _reconnectAttempts = 0;
  Completer<bool>? _connectionCompleter;

  final _desiredQuizMatchIds = <String>{};
  final _activeSubscriptionIds = <String>{};

  final _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatStreamController =
      StreamController<ChatMessageModel>.broadcast();
  final _matchStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<RealtimeConnectionState>.broadcast();
  final _errorStreamController =
      StreamController<RealtimeErrorEvent>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;
  Stream<ChatMessageModel> get chatStream => _chatStreamController.stream;
  Stream<Map<String, dynamic>> get matchStream => _matchStreamController.stream;
  Stream<RealtimeConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<RealtimeErrorEvent> get errorStream => _errorStreamController.stream;

  bool get isConnected => _isConnected;

  /// Waits for the existing STOMP connection to reach CONNECTED.
  ///
  /// This is intentionally exposed by the shared service so feature
  /// controllers never open their own WebSocket connection.
  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (_isConnected) return true;

    final waiter = _connectionCompleter ??= Completer<bool>();
    if (!_isConnecting) {
      unawaited(connect());
    }

    try {
      return await waiter.future.timeout(timeout, onTimeout: () => false);
    } finally {
      if (identical(_connectionCompleter, waiter) && waiter.isCompleted) {
        _connectionCompleter = null;
      }
    }
  }

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

    _allowReconnect = true;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[Realtime] No auth token found; skipping connection.');
      _emitConnectionState(RealtimeConnectionState.disconnected);
      _completeConnection(false);
      return;
    }

    _isConnecting = true;
    _emitConnectionState(RealtimeConnectionState.connecting);
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
      _emitConnectionState(RealtimeConnectionState.error);
      _emitError(RealtimeErrorEvent(message: e.toString()));
      _cleanupSocket();
      _completeConnection(false);
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
      final parsed = StompFrameCodec.parse(frame);
      if (parsed == null) continue;
      _processStompFrame(parsed);
    }
  }

  void _processStompFrame(StompFrame frame) {
    final command = frame.command;

    if (command == 'CONNECTED') {
      _isConnected = true;
      _reconnectAttempts = 0;
      _activeSubscriptionIds.clear();
      _emitConnectionState(RealtimeConnectionState.connected);
      _completeConnection(true);
      debugPrint('[Realtime] STOMP connected. Subscribing to queues.');
      _subscribe('/user/queue/notifications', 'sub-notifications');
      _subscribe('/user/queue/chat', 'sub-chat');
      _subscribe('/user/queue/match', 'sub-match');
      for (final matchId in _desiredQuizMatchIds) {
        _subscribe(
          '/topic/quiz/match/$matchId',
          _quizMatchSubscriptionId(matchId),
        );
      }
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
      final body = frame.body.trim();
      if (body.isEmpty) return;

      final destination = frame.headers['destination'] ?? '';
      _dispatchMessage(destination, body);
      return;
    }

    if (command == 'ERROR') {
      final message = frame.headers['message'] ??
          (frame.body.trim().isEmpty ? 'Realtime server error' : frame.body.trim());
      _emitError(
        RealtimeErrorEvent(
          message: message,
          code: frame.headers['code'],
          destination: frame.headers['destination'],
        ),
      );
    }
  }

  void _subscribe(String destination, String subscriptionId) {
    if (_socket == null || !_isConnected) return;
    if (!_activeSubscriptionIds.add(subscriptionId)) return;
    final subFrame =
        'SUBSCRIBE\n'
        'id:$subscriptionId\n'
        'destination:$destination\n\n'
        '\x00';
    _socket!.add(subFrame);
    debugPrint('[Realtime] Subscribed to $destination');
  }

  void _unsubscribe(String subscriptionId) {
    if (_socket == null || !_activeSubscriptionIds.remove(subscriptionId)) return;
    _socket!.add('UNSUBSCRIBE\nid:$subscriptionId\n\n\x00');
  }

  String _quizMatchSubscriptionId(String matchId) => 'sub-quiz-match-$matchId';

  /// Subscribes to the participant-protected match topic from the backend.
  Future<bool> subscribeQuizMatch(String matchId) async {
    if (matchId.trim().isEmpty) return false;
    final normalized = matchId.trim();
    _desiredQuizMatchIds.add(normalized);
    final connected = await ensureConnected();
    if (!connected || !_desiredQuizMatchIds.contains(normalized)) return false;
    _subscribe(
      '/topic/quiz/match/$normalized',
      _quizMatchSubscriptionId(normalized),
    );
    return true;
  }

  Future<void> unsubscribeQuizMatch(String matchId) async {
    final normalized = matchId.trim();
    if (normalized.isEmpty) return;
    _desiredQuizMatchIds.remove(normalized);
    _unsubscribe(_quizMatchSubscriptionId(normalized));
  }

  /// Sends a STOMP SEND frame through the existing shared WebSocket.
  Future<void> sendStompMessage(
    String destination, {
    Map<String, dynamic>? body,
  }) async {
    final connected = await ensureConnected();
    if (!connected || _socket == null) {
      throw StateError('Realtime connection is not available');
    }

    if (body == null) {
      _socket!.add('SEND\ndestination:$destination\n\n\x00');
      return;
    }

    final encodedBody = jsonEncode(body);
    final contentLength = utf8.encode(encodedBody).length;
    _socket!.add(
      'SEND\n'
      'destination:$destination\n'
      'content-type:application/json\n'
      'content-length:$contentLength\n\n'
      '$encodedBody\x00',
    );
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
      } else if (destination.contains('/queue/match') ||
          destination.startsWith('/topic/quiz/match/')) {
        _matchStreamController.add(decoded);
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
    _emitConnectionState(RealtimeConnectionState.error);
    _cleanupSocket();
    _completeConnection(false);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[Realtime] Socket closed by server.');
    _emitConnectionState(RealtimeConnectionState.disconnected);
    _cleanupSocket();
    _completeConnection(false);
    _scheduleReconnect();
  }

  void _cleanupSocket() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _activeSubscriptionIds.clear();
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void _scheduleReconnect() {
    if (_isDisposed || !_allowReconnect) return;
    _reconnectTimer?.cancel();
    _emitConnectionState(RealtimeConnectionState.reconnecting);
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
    _allowReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _completeConnection(false);
    _cleanupSocket();
    _emitConnectionState(RealtimeConnectionState.disconnected);
  }

  void _completeConnection(bool connected) {
    final completer = _connectionCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(connected);
  }

  void _emitConnectionState(RealtimeConnectionState state) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  void _emitError(RealtimeErrorEvent error) {
    if (!_errorStreamController.isClosed) {
      _errorStreamController.add(error);
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    disconnect();
    _notificationStreamController.close();
    _chatStreamController.close();
    _matchStreamController.close();
    _connectionStateController.close();
    _errorStreamController.close();
    super.onClose();
  }
}
