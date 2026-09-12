import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/chat_models.dart';

/// Clean local persistence datasource for Chat conversations and messages.
///
/// Reuses the existing project [FlutterSecureStorage] technology with an
/// in-process fallback store for environments (such as headless tests)
/// where platform channels are not registered.
///
/// When [storage] is null (the default), all operations are handled synchronously
/// via the in-process store, preventing unmocked platform channel timeouts in tests.
///
/// Ensures complete user isolation by scoping all storage keys by `userId`.
class ChatLocalDataSource {
  final FlutterSecureStorage? _storage;
  static final Map<String, String> _staticFallback = {};

  static const _kConvPrefix = 'genlink_chat_convs_';
  static const _kMsgPrefix = 'genlink_chat_msgs_';

  // ignore: prefer_initializing_formals
  ChatLocalDataSource({FlutterSecureStorage? storage}) : _storage = storage;

  FlutterSecureStorage? get storage => _storage;

  /// Reset the in-memory fallback store (useful in test teardown).
  static void resetStaticStore() {
    _staticFallback.clear();
  }

  String _convKey(String userId) => '$_kConvPrefix$userId';
  String _msgKey(String userId, String conversationId) =>
      '$_kMsgPrefix${userId}_$conversationId';

  Future<void> _write(String key, String value) async {
    _staticFallback[key] = value;
    final s = _storage;
    if (s == null) return;
    try {
      await s.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> _read(String key) async {
    final s = _storage;
    if (s == null || _staticFallback.containsKey(key)) {
      return _staticFallback[key];
    }
    try {
      final val = await s.read(key: key);
      if (val != null) {
        _staticFallback[key] = val;
        return val;
      }
      return _staticFallback[key];
    } catch (_) {
      return _staticFallback[key];
    }
  }

  Future<void> _delete(String key) async {
    _staticFallback.remove(key);
    final s = _storage;
    if (s == null) return;
    try {
      await s.delete(key: key);
    } catch (_) {}
  }

  /// Retrieve all cached conversations for a specific user.
  Future<List<ChatConversationModel>> getConversations(String userId) async {
    final raw = await _read(_convKey(userId));
    if (raw == null || raw.isEmpty) return <ChatConversationModel>[];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ChatConversationModel.fromJson)
            .toList();
      }
    } catch (_) {}
    return <ChatConversationModel>[];
  }

  /// Save or replace the entire list of cached conversations for a user.
  Future<void> saveConversations(
    String userId,
    List<ChatConversationModel> convs,
  ) async {
    final encoded = jsonEncode(convs.map((c) => c.toJson()).toList());
    await _write(_convKey(userId), encoded);
  }

  /// Upsert a single conversation for a user.
  Future<void> saveConversation(
    String userId,
    ChatConversationModel conv,
  ) async {
    final list = await getConversations(userId);
    final idx = list.indexWhere((c) => c.id == conv.id);
    if (idx != -1) {
      list[idx] = conv;
    } else {
      list.insert(0, conv);
    }
    await saveConversations(userId, list);
  }

  /// Retrieve cached messages for a conversation scoped by user.
  Future<List<ChatMessageModel>> getMessages(
    String userId,
    String conversationId,
  ) async {
    final raw = await _read(_msgKey(userId, conversationId));
    if (raw == null || raw.isEmpty) return <ChatMessageModel>[];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        final messages = list
            .whereType<Map<String, dynamic>>()
            .map((json) =>
                ChatMessageModel.fromJson(json, conversationId: conversationId))
            .toList();
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      }
    } catch (_) {}
    return <ChatMessageModel>[];
  }

  /// Save or replace the entire message history for a conversation.
  Future<void> saveMessages(
    String userId,
    String conversationId,
    List<ChatMessageModel> messages,
  ) async {
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _write(_msgKey(userId, conversationId), encoded);
  }

  /// Append or update a single message in the cached conversation.
  Future<void> saveMessage(
    String userId,
    String conversationId,
    ChatMessageModel message,
  ) async {
    final list = await getMessages(userId, conversationId);
    final idx = list.indexWhere((m) => m.id == message.id);
    if (idx != -1) {
      list[idx] = message;
    } else {
      list.add(message);
    }
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await saveMessages(userId, conversationId, list);

    // Update conversation lastMessage metadata
    final convs = await getConversations(userId);
    final cIdx = convs.indexWhere((c) => c.id == conversationId);
    if (cIdx != -1) {
      final c = convs[cIdx];
      c.lastMessage = message.content;
      c.lastMessageTime =
          message.timeAgo.isNotEmpty ? message.timeAgo : 'Just now';
      convs.removeAt(cIdx);
      convs.insert(0, c);
      await saveConversations(userId, convs);
    }
  }

  /// Delete a message from local cache.
  Future<void> deleteMessage(
    String userId,
    String conversationId,
    String messageId,
  ) async {
    final list = await getMessages(userId, conversationId);
    list.removeWhere((m) => m.id == messageId);
    await saveMessages(userId, conversationId, list);

    // Update lastMessage metadata in conversation
    final convs = await getConversations(userId);
    final cIdx = convs.indexWhere((c) => c.id == conversationId);
    if (cIdx != -1) {
      final c = convs[cIdx];
      if (list.isNotEmpty) {
        c.lastMessage = list.last.content;
        c.lastMessageTime = list.last.timeAgo;
      } else {
        c.lastMessage = '';
      }
      await saveConversations(userId, convs);
    }
  }

  /// Delete an entire conversation and its cached messages.
  Future<void> deleteConversation(String userId, String conversationId) async {
    final list = await getConversations(userId);
    list.removeWhere((c) => c.id == conversationId);
    await saveConversations(userId, list);
    await _delete(_msgKey(userId, conversationId));
  }

  /// Update pinned message for a conversation.
  Future<void> updateConversationPinStatus(
    String userId,
    String conversationId,
    ChatMessageModel? pinnedMessage,
  ) async {
    final list = await getConversations(userId);
    final cIdx = list.indexWhere((c) => c.id == conversationId);
    if (cIdx != -1) {
      list[cIdx] = list[cIdx].copyWith(pinnedMessage: pinnedMessage);
      await saveConversations(userId, list);
    }
  }

  /// Clear all chat storage keys.
  Future<void> clearAll({String? userId}) async {
    if (userId != null) {
      final convs = await getConversations(userId);
      for (final c in convs) {
        await _delete(_msgKey(userId, c.id));
      }
      await _delete(_convKey(userId));
    } else {
      _staticFallback.clear();
      final s = _storage;
      if (s != null) {
        try {
          await s.deleteAll();
        } catch (_) {}
      }
    }
  }
}
