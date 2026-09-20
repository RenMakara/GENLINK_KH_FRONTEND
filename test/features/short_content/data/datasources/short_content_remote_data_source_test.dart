import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/features/short_content/data/datasources/short_content_remote_data_source.dart';
import 'package:genlink_frontend/features/short_content/domain/models/short_content_models.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  dynamic responseData;
  final getPaths = <String>[];
  final getQueries = <Map<String, dynamic>?>[];
  final postPaths = <String>[];
  final postBodies = <Object?>[];
  final deletePaths = <String>[];

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    getPaths.add(path);
    getQueries.add(query);
    return parse(responseData);
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    postPaths.add(path);
    postBodies.add(body);
    return parse(responseData);
  }

  @override
  Future<T> deleteWithResult<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    deletePaths.add(path);
    return parse(responseData);
  }

  @override
  Future<void> delete(String path, {Map<String, dynamic>? query}) async {
    deletePaths.add(path);
  }
}

const _itemPayload = {
  'shortContentId': 'short-1',
  'title': 'Short',
  'description': 'Description',
  'category': 'FOCUS',
  'videoUrl': 'https://cdn.example.com/short.mp4',
  'thumbnailUrl': 'https://cdn.example.com/short.jpg',
  'creatorId': 'creator-1',
  'likeCount': 5,
  'saveCount': 2,
  'shareCount': 1,
  'liked': false,
  'saved': false,
};

void main() {
  test('creates short content with the backend metadata contract', () async {
    final apiClient = _FakeApiClient()..responseData = _itemPayload;
    final dataSource = ShortContentRemoteDataSourceImpl(apiClient);

    final created = await dataSource.create(
      const ShortContentCreateRequest(
        title: 'Study tip',
        description: 'A short lesson',
        category: 'FOCUS',
        videoUrl: 'https://cdn.example.com/short.mp4',
      ),
    );

    expect(created.shortContentId, 'short-1');
    expect(apiClient.postPaths, ['/api/v1/entertainment/short-content']);
    expect(apiClient.postBodies, [
      {
        'title': 'Study tip',
        'description': 'A short lesson',
        'category': 'FOCUS',
        'videoUrl': 'https://cdn.example.com/short.mp4',
      },
    ]);
  });

  test('uses the verified paged, like, save, and share endpoints', () async {
    final apiClient = _FakeApiClient()
      ..responseData = {
        'content': [_itemPayload],
        'page': 1,
        'size': 20,
        'totalElements': 21,
        'totalPages': 2,
        'hasNext': false,
      };
    final dataSource = ShortContentRemoteDataSourceImpl(apiClient);

    final page = await dataSource.getFeed(page: 1, size: 20, category: 'FOCUS');

    apiClient.responseData = _itemPayload;
    final detail = await dataSource.getById('short-1');
    final liked = await dataSource.like('short-1');
    final unliked = await dataSource.unlike('short-1');
    final saved = await dataSource.save('short-1');
    final unsaved = await dataSource.unsave('short-1');
    final shared = await dataSource.share('short-1');
    await dataSource.delete('short-1');

    expect(page.content.single.shortContentId, 'short-1');
    expect(apiClient.getPaths, [
      '/api/v1/entertainment/short-content',
      '/api/v1/entertainment/short-content/short-1',
    ]);
    expect(apiClient.getQueries, [
      {'page': 1, 'size': 20, 'category': 'FOCUS'},
      null,
    ]);
    expect(liked.shortContentId, 'short-1');
    expect(detail.shortContentId, 'short-1');
    expect(unliked.shortContentId, 'short-1');
    expect(saved.shortContentId, 'short-1');
    expect(unsaved.shortContentId, 'short-1');
    expect(shared.shortContentId, 'short-1');
    expect(apiClient.postPaths, [
      '/api/v1/entertainment/short-content/short-1/like',
      '/api/v1/entertainment/short-content/short-1/save',
      '/api/v1/entertainment/short-content/short-1/share',
    ]);
    expect(apiClient.deletePaths, [
      '/api/v1/entertainment/short-content/short-1/like',
      '/api/v1/entertainment/short-content/short-1/save',
      '/api/v1/entertainment/short-content/short-1',
    ]);
  });
}
