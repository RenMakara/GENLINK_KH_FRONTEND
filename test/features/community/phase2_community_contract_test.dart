import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/community/data/datasources/community_remote_datasource.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/navigation/story_deep_link_handler.dart';

void main() {
  group('Phase 2 community REST contracts', () {
    test(
      'rich post edit sends persisted fields and clears a removed video',
      () async {
        RequestOptions? request;
        final dataSource = CommunityRemoteDataSource(
          dio: _dio((options) async {
            request = options;
            return _response({
              'data': {
                'postId': 'post-1',
                'contentText': 'updated',
                'postType': 'TEXT',
                'visibility': 'PUBLIC',
                'location': 'Library',
                'linkUrl': 'https://example.com',
                'linkPreviewTitle': 'Example',
                'linkPreviewDomain': 'example.com',
                'eventId': 'event-1',
              },
            });
          }),
        );

        await dataSource.updatePost(
          'post-1',
          content: 'updated',
          imageUrls: const ['genlink-media://image-1'],
          videoUrl: '',
          visibility: 'Public',
          location: 'Library',
          linkUrl: 'https://example.com',
          linkPreviewTitle: 'Example',
          linkPreviewDomain: 'example.com',
          eventId: 'event-1',
          replaceRichFields: true,
        );

        expect(request?.method, 'PUT');
        expect(request?.path, '/api/v1/community/posts/post-1');
        final body = request!.data as Map<String, dynamic>;
        expect(body['replaceRichFields'], isTrue);
        expect(body['location'], 'Library');
        expect(body['linkUrl'], 'https://example.com');
        expect(body['linkPreviewTitle'], 'Example');
        expect(body['linkPreviewDomain'], 'example.com');
        expect(body['attachedEventId'], 'event-1');
        expect(body['imageMediaIds'], ['image-1']);
        expect(body['videoUrl'], '');
        expect(body['videoMediaId'], isNull);
      },
    );

    test(
      'bookmark failure calls only the Profile Saved API and preserves error',
      () async {
        final paths = <String>[];
        final dataSource = CommunityRemoteDataSource(
          dio: _dio((options) async {
            paths.add(options.path);
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              error: const AppError(
                message: 'Saved item denied',
                errorCode: 'SAVED_ITEM_DENIED',
                statusCode: 403,
              ),
            );
          }),
        );

        await expectLater(
          dataSource.toggleBookmark('post-2', isCurrentlyBookmarked: false),
          throwsA(
            isA<AppError>()
                .having(
                  (error) => error.message,
                  'message',
                  'Saved item denied',
                )
                .having((error) => error.statusCode, 'statusCode', 403),
          ),
        );
        expect(paths, ['/api/v1/profile/saved']);
        expect(
          paths,
          isNot(contains('/api/v1/community/posts/post-2/bookmark')),
        );
      },
    );

    test('delete, report, and follow failures do not become success', () async {
      final paths = <String>[];
      final dataSource = CommunityRemoteDataSource(
        dio: _dio((options) async {
          paths.add('${options.method} ${options.path}');
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            error: const AppError(
              message: 'Permission denied',
              errorCode: 'FORBIDDEN',
              statusCode: 403,
            ),
          );
        }),
      );

      for (final action in <Future<bool> Function()>[
        () => dataSource.deletePost('post-3'),
        () => dataSource.reportPost('post-3'),
        () => dataSource.followUser('user-4'),
        () => dataSource.unfollowUser('user-4'),
      ]) {
        await expectLater(action(), throwsA(isA<AppError>()));
      }
      expect(paths, [
        'DELETE /api/v1/community/posts/post-3',
        'POST /api/v1/community/posts/post-3/report',
        'POST /api/v1/community/users/user-4/follow',
        'DELETE /api/v1/community/users/user-4/follow',
      ]);
    });

    test(
      'discussion comment edit uses PUT and returns the server response',
      () async {
        RequestOptions? request;
        final dataSource = CommunityRemoteDataSource(
          dio: _dio((options) async {
            request = options;
            return _response({
              'data': {
                'commentId': 'comment-1',
                'content': 'edited by owner',
                'mine': true,
              },
            });
          }),
        );

        final updated = await dataSource.updateDiscussionComment(
          'comment-1',
          'edited by owner',
        );

        expect(request?.method, 'PUT');
        expect(
          request?.path,
          '/api/v1/community/discussions/comments/comment-1',
        );
        expect(request?.data, {'content': 'edited by owner'});
        expect(updated.id, 'comment-1');
        expect(updated.text, 'edited by owner');
      },
    );
  });

  group('Phase 2 story links and event date boundaries', () {
    test('accepts only the canonical HTTPS story URL', () {
      expect(
        StoryDeepLinkHandler.storyIdFromUri(
          Uri.parse('https://genlink.app/story/story_123'),
        ),
        'story_123',
      );
      expect(
        StoryDeepLinkHandler.storyIdFromUri(
          Uri.parse('https://genlink.app/story/story_123/extra'),
        ),
        isNull,
      );
      expect(
        StoryDeepLinkHandler.storyIdFromUri(
          Uri.parse('http://genlink.app/story/story_123'),
        ),
        isNull,
      );
      expect(
        StoryDeepLinkHandler.storyIdFromUri(
          Uri.parse('https://evil.example/story/story_123'),
        ),
        isNull,
      );
      expect(
        StoryDeepLinkHandler.storyIdFromUri(
          Uri.parse('https://genlink.app/story/%2Fprivate'),
        ),
        isNull,
      );
    });

    test(
      'event filters use local date boundaries, including week and month edges',
      () {
        final monday = DateTime(2026, 9, 28, 0, 15);
        expect(
          CommunityController.matchesEventDateFilter(
            DateTime(2026, 9, 28),
            'Today',
            now: monday,
          ),
          isTrue,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            DateTime(2026, 9, 27, 23, 59),
            'Today',
            now: monday,
          ),
          isFalse,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            DateTime(2026, 9, 28),
            'This Week',
            now: monday,
          ),
          isTrue,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            DateTime(2026, 10, 5),
            'This Week',
            now: monday,
          ),
          isFalse,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            DateTime(2026, 9, 30, 23, 59),
            'This Month',
            now: monday,
          ),
          isTrue,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            DateTime(2026, 10, 1),
            'This Month',
            now: monday,
          ),
          isFalse,
        );
      },
    );

    test(
      'timezone conversion follows local midnight instead of UTC date text',
      () {
        final now = DateTime.utc(2026, 9, 27, 17, 30);
        final localMidnight = DateTime(
          now.toLocal().year,
          now.toLocal().month,
          now.toLocal().day,
        );
        final eventBeforeLocalMidnight = localMidnight
            .subtract(const Duration(seconds: 1))
            .toUtc();

        expect(
          CommunityController.matchesEventDateFilter(now, 'Today', now: now),
          isTrue,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            eventBeforeLocalMidnight,
            'Today',
            now: now,
          ),
          isFalse,
        );
        expect(
          CommunityController.matchesEventDateFilter(
            now.add(const Duration(minutes: 1)),
            'Upcoming',
            now: now,
          ),
          isTrue,
        );
      },
    );
  });
}

Dio _dio(Future<ResponseBody> Function(RequestOptions options) handler) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = _Adapter(handler);
}

ResponseBody _response(Map<String, dynamic> body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _Adapter implements HttpClientAdapter {
  const _Adapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}
