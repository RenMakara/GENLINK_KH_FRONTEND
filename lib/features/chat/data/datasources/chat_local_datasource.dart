import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/models/chat_models.dart';

class ChatLocalDataSource {
  final FlutterSecureStorage _storage;
  final SecureStorage? secureStorage;
  final Map<String, String> _memoryFallback = {};

  ChatLocalDataSource({
    FlutterSecureStorage? storage,
    this.secureStorage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  Future<String> _userScope() async {
    final uid = await secureStorage?.readUserId();
    return (uid != null && uid.isNotEmpty) ? '${uid}_' : '';
  }

  Future<String> _conversationsKey() async =>
      'genlink_chat_${await _userScope()}conversations';

  Future<String> _messagesKey(String conversationId) async =>
      'genlink_chat_${await _userScope()}msgs_$conversationId';

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _memoryFallback[key] = value;
    }
  }

  Future<String?> _read(String key) async {
    try {
      final val = await _storage.read(key: key);
      return val ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    _memoryFallback.remove(key);
  }

  Future<void> saveConversations(List<ChatConversationModel> conversations) async {
    final list = conversations.map((c) => c.toJson()).toList();
    await _write(await _conversationsKey(), jsonEncode(list));
  }

  Future<List<ChatConversationModel>> getConversations() async {
    final raw = await _read(await _conversationsKey());
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => ChatConversationModel.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveMessages(String conversationId, List<ChatMessageModel> messages) async {
    final list = messages.map((m) => m.toJson()).toList();
    await _write(await _messagesKey(conversationId), jsonEncode(list));
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final raw = await _read(await _messagesKey(conversationId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => ChatMessageModel.fromJson(
                  item.cast<String, dynamic>(),
                  conversationId: conversationId,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveMessage(String conversationId, ChatMessageModel message) async {
    final existing = await getMessages(conversationId);
    final idx = existing.indexWhere((m) => m.id == message.id);
    if (idx != -1) {
      existing[idx] = message;
    } else {
      existing.add(message);
    }
    await saveMessages(conversationId, existing);
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    final existing = await getMessages(conversationId);
    existing.removeWhere((m) => m.id == messageId);
    await saveMessages(conversationId, existing);
  }

  Future<void> deleteConversation(String conversationId) async {
    final conversations = await getConversations();
    conversations.removeWhere((c) => c.id == conversationId);
    await saveConversations(conversations);
    await _delete(await _messagesKey(conversationId));
  }

  Future<void> clearAll() async {
    final conversations = await getConversations();
    for (final c in conversations) {
      await _delete(await _messagesKey(c.id));
    }
    await _delete(await _conversationsKey());
    _memoryFallback.clear();
  }
}
