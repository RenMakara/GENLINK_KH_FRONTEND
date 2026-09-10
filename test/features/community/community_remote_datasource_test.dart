import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';

void main() {
  group('CommunityRemoteDataSource.fetchPosts', () {
    test('returns an empty list when backend returns content: [] (0 posts in database)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 200,
          responseBody: {
            'success': true,
            'message': 'Feed retrieved',
            'data': {
              'content': <dynamic>[],
              'page': 0,
              'size': 10,
              'totalElements': 0,
              'totalPages': 0,
              'hasNext': false,
            },
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final posts = await dataSource.fetchPosts(page: 1, limit: 10);

      expect(posts, isEmpty);
    });

    test('returns parsed posts when backend returns real posts from database', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 200,
          responseBody: {
            'success': true,
            'message': 'Feed retrieved',
            'data': {
              'content': [
                {
                  'postId': 'post-uuid-1',
                  'author': {
                    'userId': 'user-uuid-1',
                    'fullName': 'Sokny Enat',
                    'username': 'soknyenat',
                    'avatarUrl': 'https://example.com/avatar.png',
                  },
                  'contentText': 'Real post content from database',
                  'imageUrl': 'https://example.com/post.png',
                  'postType': 'NORMAL',
                  'visibility': 'PUBLIC',
                  'language': 'EN',
                  'likeCount': 15,
                  'commentCount': 3,
                  'likedByMe': true,
                  'savedByMe': false,
                  'hashtags': ['#Flutter'],
                  'poll': null,
                  'createdAt': '2026-09-09T08:00:00Z',
                },
              ],
              'page': 0,
              'size': 10,
              'totalElements': 1,
              'totalPages': 1,
              'hasNext': false,
            },
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final posts = await dataSource.fetchPosts(page: 1, limit: 10);

      expect(posts.length, 1);
      final post = posts.first;
      expect(post.id, 'post-uuid-1');
      expect(post.userId, 'user-uuid-1');
      expect(post.authorName, 'Sokny Enat');
      expect(post.authorTag, '@soknyenat');
      expect(post.authorAvatar, 'https://example.com/avatar.png');
      expect(post.content, 'Real post content from database');
      expect(post.imageUrls, ['https://example.com/post.png']);
      expect(post.likesCount, 15);
      expect(post.commentsCount, 3);
      expect(post.isLiked, isTrue);
      expect(post.isBookmarked, isFalse);
    });

    test('throws AppError on 401 Unauthorized without falling back to mock posts', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 401,
          responseBody: {
            'success': false,
            'message': 'Unauthorized',
            'errorCode': 'UNAUTHORIZED',
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);

      expect(
        () => dataSource.fetchPosts(page: 1, limit: 10),
        throwsA(isA<AppError>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws AppError on network error without falling back to mock posts', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _ErrorAdapter(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/community/posts/feed'),
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timed out',
          ),
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);

      expect(
        () => dataSource.fetchPosts(page: 1, limit: 10),
        throwsA(isA<AppError>()),
      );
    });
  });

  group('CommunityRemoteDataSource.createPost', () {
    test('sends TEXT postType and returns real post authored by authenticated user', () async {
      Map<String, dynamic>? capturedPayload;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingMockAdapter(
          statusCode: 201,
          responseBody: {
            'success': true,
            'message': 'Post created successfully',
            'data': {
              'postId': 'new-post-123',
              'author': {
                'userId': 'account-a-id',
                'fullName': 'Nat User',
                'username': 'nat',
                'avatarUrl': 'https://example.com/nat.png',
              },
              'contentText': 'Hello from Account A',
              'postType': 'TEXT',
              'visibility': 'PUBLIC',
              'likeCount': 0,
              'commentCount': 0,
              'likedByMe': false,
              'savedByMe': false,
            },
          },
          onFetch: (options) {
            if (options.data is Map<String, dynamic>) {
              capturedPayload = options.data as Map<String, dynamic>;
            }
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final post = await dataSource.createPost(
        content: 'Hello from Account A',
        imageUrls: [],
        visibility: 'Public',
      );

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['postType'], 'TEXT');
      expect(capturedPayload!['visibility'], 'PUBLIC');
      expect(capturedPayload!['contentText'], 'Hello from Account A');

      expect(post.id, 'new-post-123');
      expect(post.userId, 'account-a-id');
      expect(post.authorName, 'Nat User');
      expect(post.authorTag, '@nat');
      expect(post.authorAvatar, 'https://example.com/nat.png');
      expect(post.content, 'Hello from Account A');
    });

    test('sends IMAGE postType when imageUrls are provided', () async {
      Map<String, dynamic>? capturedPayload;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _CapturingMockAdapter(
          statusCode: 201,
          responseBody: {
            'success': true,
            'data': {
              'postId': 'img-post-456',
              'author': {
                'userId': 'account-b-id',
                'fullName': 'Bob Builder',
                'username': 'bob',
                'avatarUrl': null,
              },
              'contentText': 'Post with image',
              'postType': 'IMAGE',
              'visibility': 'PUBLIC',
            },
          },
          onFetch: (options) {
            if (options.data is Map<String, dynamic>) {
              capturedPayload = options.data as Map<String, dynamic>;
            }
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);
      final post = await dataSource.createPost(
        content: 'Post with image',
        imageUrls: ['https://example.com/photo.jpg'],
      );

      expect(capturedPayload!['postType'], 'IMAGE');
      expect(capturedPayload!['imageUrl'], 'https://example.com/photo.jpg');
      expect(post.authorName, 'Bob Builder');
      expect(post.authorAvatar, isEmpty);
    });

    test('throws AppError when backend returns 400 without falling back to mock post', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _MockAdapter(
          statusCode: 400,
          responseBody: {
            'success': false,
            'message': 'Bad Request',
          },
        );

      final dataSource = CommunityRemoteDataSource(dio: dio);

      expect(
        () => dataSource.createPost(content: 'Fail test'),
        throwsA(isA<AppError>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter({required this.statusCode, required this.responseBody});

  final int statusCode;
  final Map<String, dynamic> responseBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CapturingMockAdapter implements HttpClientAdapter {
  _CapturingMockAdapter({
    required this.statusCode,
    required this.responseBody,
    this.onFetch,
  });

  final int statusCode;
  final Map<String, dynamic> responseBody;
  final void Function(RequestOptions options)? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch?.call(options);
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ErrorAdapter implements HttpClientAdapter {
  _ErrorAdapter(this.error);

  final DioException error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw error;
  }

  @override
  void close({bool force = false}) {}
}
