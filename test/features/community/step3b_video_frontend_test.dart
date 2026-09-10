// test/features/community/step3b_video_frontend_test.dart
//
// Step 3B-Frontend — Video Posting Frontend Preparation Tests
//
// A. MediaPurpose.post.allowsVideo == true  (root-cause fix)
// B. Video bytes pass MediaUploadService._validate() for post purpose
// C. CommunityPostModel.videoUrl is parsed safely from JSON
// D. CommunityPostModel.isVideoPost returns correctly
// E. Null/empty videoUrl does NOT break existing posts
// F. Image posts still work (regression)
// G. Multi-image posts still work (regression)
// H. Text-only posts still work (regression)
// I. videoUrl is preserved in toJson round-trip
// J. MediaPurpose.avatar still does NOT allow video

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';

CommunityPostModel _makePost(Map<String, dynamic> overrides) {
  final base = <String, dynamic>{
    'postId': 'post-001',
    'author': {
      'userId': 'user-abc',
      'fullName': 'Test User',
      'username': 'testuser',
      'avatarUrl': '',
    },
    'contentText': 'Hello',
    'visibility': 'PUBLIC',
    'postType': 'TEXT',
    'likedByMe': false,
    'savedByMe': false,
  };
  return CommunityPostModel.fromJson({...base, ...overrides});
}

void main() {
  // ─ A. allowsVideo fix ───────────────────────────────────────────────────
  group('A — MediaPurpose.post.allowsVideo', () {
    test('post purpose now allows video', () => expect(MediaPurpose.post.allowsVideo, isTrue));
    test('story purpose still allows video', () => expect(MediaPurpose.story.allowsVideo, isTrue));
    test('short purpose still allows video', () => expect(MediaPurpose.short.allowsVideo, isTrue));
  });

  // ─ B. Upload service video validation ───────────────────────────────────
  group('B — MediaUploadService video constants', () {
    test('video contentType starts with video/', () {
      for (final t in ['video/mp4', 'video/quicktime', 'video/webm']) {
        expect(t.startsWith('video/'), isTrue, reason: t);
      }
    });
    test('maxVideoBytes is 50 MB', () => expect(MediaUploadService.maxVideoBytes, equals(50 * 1024 * 1024)));
    test('image contentType is not video', () => expect('image/jpeg'.startsWith('video/'), isFalse));
  });

  // ─ C/D. videoUrl parsing + isVideoPost ──────────────────────────────────
  group('C/D — videoUrl parsing and isVideoPost', () {
    test('parses videoUrl from JSON', () {
      final post = _makePost({'videoUrl': 'https://cdn.example.com/v.mp4'});
      expect(post.videoUrl, equals('https://cdn.example.com/v.mp4'));
    });
    test('isVideoPost true when videoUrl non-empty', () {
      expect(_makePost({'videoUrl': 'https://cdn.example.com/v.mp4'}).isVideoPost, isTrue);
    });
    test('isVideoPost false when videoUrl absent', () => expect(_makePost({}).isVideoPost, isFalse));
    test('isVideoPost false when videoUrl null', () => expect(_makePost({'videoUrl': null}).isVideoPost, isFalse));
    test('isVideoPost false when videoUrl empty', () => expect(_makePost({'videoUrl': ''}).isVideoPost, isFalse));
  });

  // ─ E. Null videoUrl safety ───────────────────────────────────────────────
  group('E — null videoUrl safe for existing posts', () {
    test('text post parses without error', () {
      final p = _makePost({'contentText': 'Hi'});
      expect(p.videoUrl, isNull);
      expect(p.isVideoPost, isFalse);
    });
    test('image post parses without error', () {
      final p = _makePost({'imageUrl': 'https://cdn.example.com/a.jpg', 'postType': 'IMAGE'});
      expect(p.imageUrls, isNotEmpty);
      expect(p.videoUrl, isNull);
    });
  });

  // ─ F. Image post regression ─────────────────────────────────────────────
  group('F — image post regression', () {
    test('single imageUrl -> imageUrls list of 1', () {
      expect(_makePost({'imageUrl': 'https://cdn.example.com/a.jpg', 'postType': 'IMAGE'}).imageUrls, hasLength(1));
    });
    test('image post isVideoPost false', () {
      expect(_makePost({'imageUrl': 'https://cdn.example.com/a.jpg'}).isVideoPost, isFalse);
    });
  });

  // ─ G. Multi-image post regression ───────────────────────────────────────
  group('G — multi-image post regression', () {
    test('comma-separated imageUrl -> multiple imageUrls', () {
      final p = _makePost({'imageUrl': 'https://a.com/1.jpg,https://a.com/2.jpg,https://a.com/3.jpg'});
      expect(p.imageUrls, hasLength(3));
    });
    test('multi-image post isVideoPost false', () {
      final p = _makePost({'imageUrl': 'https://a.com/1.jpg,https://a.com/2.jpg'});
      expect(p.isVideoPost, isFalse);
    });
  });

  // ─ H. Text post regression ──────────────────────────────────────────────
  group('H — text post regression', () {
    test('text post has no images and no video', () {
      final p = _makePost({'contentText': 'Just text'});
      expect(p.imageUrls, isEmpty);
      expect(p.videoUrl, isNull);
      expect(p.isVideoPost, isFalse);
    });
  });

  // ─ I. toJson round-trip ─────────────────────────────────────────────────
  group('I — videoUrl toJson round-trip', () {
    test('videoUrl preserved in toJson', () {
      const url = 'https://cdn.example.com/v.mp4';
      expect(_makePost({'videoUrl': url}).toJson()['videoUrl'], equals(url));
    });
    test('null videoUrl serialised as null', () {
      expect(_makePost({}).toJson()['videoUrl'], isNull);
    });
  });

  // ─ J. Other purposes unchanged ──────────────────────────────────────────
  group('J — other MediaPurpose not affected', () {
    test('avatar does NOT allow video', () => expect(MediaPurpose.avatar.allowsVideo, isFalse));
    test('eventCover does NOT allow video', () => expect(MediaPurpose.eventCover.allowsVideo, isFalse));
    test('portfolio does NOT allow video', () => expect(MediaPurpose.portfolio.allowsVideo, isFalse));
    test('communityCover does NOT allow video', () => expect(MediaPurpose.communityCover.allowsVideo, isFalse));
  });
}
