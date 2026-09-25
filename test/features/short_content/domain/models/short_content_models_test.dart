import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/features/short_content/domain/models/short_content_models.dart';

void main() {
  test('serializes create request without an optional thumbnail', () {
    final request = ShortContentCreateRequest(
      title: 'Study tip',
      description: 'A short lesson',
      category: 'FINANCE',
      videoUrl: 'https://cdn.example.com/short-1.mp4',
    );

    expect(request.toJson(), {
      'title': 'Study tip',
      'description': 'A short lesson',
      'category': 'FINANCE',
      'videoUrl': 'https://cdn.example.com/short-1.mp4',
    });
  });

  test('serializes confirmed media IDs for server-side URL resolution', () {
    final request = ShortContentCreateRequest(
      title: 'Study tip',
      videoUrl: 'https://cdn.example.com/short-1.mp4',
      videoMediaId: 'video-media-1',
      thumbnailMediaId: 'thumbnail-media-1',
    );

    expect(request.toJson(), {
      'title': 'Study tip',
      'videoUrl': 'https://cdn.example.com/short-1.mp4',
      'videoMediaId': 'video-media-1',
      'thumbnailMediaId': 'thumbnail-media-1',
    });
  });

  test('parses the backend ShortContentResponse contract', () {
    final item = ShortContentModel.fromJson({
      'shortContentId': 'short-1',
      'title': 'Study tip',
      'description': 'A short lesson',
      'category': 'FINANCE',
      'videoUrl': 'https://cdn.example.com/short-1.mp4',
      'thumbnailUrl': 'https://cdn.example.com/short-1.jpg',
      'creatorId': 'creator-1',
      'creatorFullName': 'Ren Makara',
      'creatorUsername': 'renmakara',
      'creatorAvatarUrl': 'https://cdn.example.com/avatar.jpg',
      'likeCount': 12,
      'saveCount': 4,
      'shareCount': 3,
      'liked': true,
      'saved': false,
    });

    expect(item.shortContentId, 'short-1');
    expect(item.category, 'FINANCE');
    expect(item.videoUrl, 'https://cdn.example.com/short-1.mp4');
    expect(item.thumbnailUrl, 'https://cdn.example.com/short-1.jpg');
    expect(item.creatorFullName, 'Ren Makara');
    expect(item.creatorUsername, 'renmakara');
    expect(item.creatorAvatarUrl, 'https://cdn.example.com/avatar.jpg');
    expect(item.likeCount, 12);
    expect(item.saved, isFalse);
    expect(item.hasVideo, isTrue);
    expect(item.shareText, contains(item.videoUrl!));
  });

  test('parses page metadata without fabricating content', () {
    final page = ShortContentPage.fromJson({
      'content': [
        {
          'shortContentId': 'short-1',
          'title': 'First',
          'description': null,
          'category': null,
          'videoUrl': null,
          'thumbnailUrl': null,
          'creatorId': null,
          'likeCount': 0,
          'saveCount': 0,
          'shareCount': 0,
          'liked': false,
          'saved': false,
        },
      ],
      'page': 2,
      'size': 20,
      'totalElements': 41,
      'totalPages': 3,
      'hasNext': true,
    });

    expect(page.content.single.shortContentId, 'short-1');
    expect(page.page, 2);
    expect(page.size, 20);
    expect(page.totalElements, 41);
    expect(page.totalPages, 3);
    expect(page.hasNext, isTrue);
  });
}
