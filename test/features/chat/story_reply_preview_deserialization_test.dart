import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/chat/domain/models/chat_models.dart';

void main() {
  group('Story Reply Chat Message Deserialization & Thumbnail Support', () {
    test('Deserializes story reply when backend returns sharedContent JSON with STORY_REPLY', () {
      final backendJson = {
        'messageId': 'msg-101',
        'roomId': 'room-1',
        'type': 'TEXT',
        'content': 'Love this performance!',
        'mediaUrl': 'https://genlink-media-prod.s3.ap-southeast-1.amazonaws.com/stories/2026/09/dance.png',
        'sharedContent': jsonEncode({
          'type': 'STORY_REPLY',
          'storyId': 'story-999',
          'mediaUrl': 'https://genlink-media-prod.s3.ap-southeast-1.amazonaws.com/stories/2026/09/dance.png',
          'isExpired': false,
        }),
        'sender': {
          'userId': 'user-1',
          'fullName': 'Alice',
          'username': 'alice',
        },
        'mine': true,
        'createdAt': '2026-09-27T05:00:00Z',
      };

      final msg = ChatMessageModel.fromJson(backendJson, conversationId: 'room-1');

      expect(msg.messageType, equals('story_reply'));
      expect(msg.storyReference, isNotNull);
      expect(msg.storyReference!.storyId, equals('story-999'));
      expect(msg.storyReference!.mediaUrl, equals('https://genlink-media-prod.s3.ap-southeast-1.amazonaws.com/stories/2026/09/dance.png'));
      expect(msg.storyReference!.isExpired, isFalse);
      expect(msg.mediaUrl, equals('https://genlink-media-prod.s3.ap-southeast-1.amazonaws.com/stories/2026/09/dance.png'));
      expect(msg.sharedContent, isNull, reason: 'Story replies should not be treated as general shared cards');
    });

    test('Backward compatibility: detects story reply from /stories/ in mediaUrl when backend returns type TEXT', () {
      final backendJson = {
        'messageId': 'msg-102',
        'roomId': 'room-1',
        'type': 'TEXT',
        'content': 'my first performance before KNY 2023',
        'mediaUrl': 'https://genlink-media-prod.s3.ap-southeast-1.amazonaws.com/stories/2026/09/performance.png',
        'sharedContent': null,
        'sender': {
          'userId': 'user-2',
          'fullName': 'Void',
          'username': 'void',
        },
        'mine': false,
        'createdAt': '2026-09-27T05:10:00Z',
      };

      final msg = ChatMessageModel.fromJson(backendJson, conversationId: 'room-1');

      expect(msg.messageType, equals('story_reply'));
      expect(msg.storyReference, isNotNull);
      expect(msg.storyReference!.mediaUrl, equals('https://genlink-media-prod.s3.ap-southeast-1.amazonaws.com/stories/2026/09/performance.png'));
      expect(msg.content, equals('my first performance before KNY 2023'));
    });

    test('Standard text message without story mediaUrl remains standard text type', () {
      final backendJson = {
        'messageId': 'msg-103',
        'roomId': 'room-1',
        'type': 'TEXT',
        'content': 'Hello, how are you?',
        'mediaUrl': null,
        'sharedContent': null,
        'sender': {
          'userId': 'user-1',
          'fullName': 'Alice',
        },
        'mine': true,
        'createdAt': '2026-09-27T05:15:00Z',
      };

      final msg = ChatMessageModel.fromJson(backendJson, conversationId: 'room-1');

      expect(msg.messageType, equals('text'));
      expect(msg.storyReference, isNull);
      expect(msg.content, equals('Hello, how are you?'));
    });
  });
}
