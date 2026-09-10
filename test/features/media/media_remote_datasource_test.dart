import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/features/media/data/datasources/media_remote_datasource.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(Dio());

  Object? lastPostPath;
  Object? lastPostBody;
  dynamic mockResponseData;

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return parse(mockResponseData);
  }
}

void main() {
  late _FakeApiClient fakeApiClient;
  late Dio fakeUploadClient;
  late MediaRemoteDatasource datasource;

  setUp(() {
    fakeApiClient = _FakeApiClient();
    fakeUploadClient = Dio();
    datasource = MediaRemoteDatasource(fakeApiClient, uploadClient: fakeUploadClient);
  });

  group('MediaRemoteDatasource', () {
    test('presign sends correct wire payload and parses PresignedUpload', () async {
      fakeApiClient.mockResponseData = {
        'mediaId': 'uuid-1234',
        'uploadUrl': 'https://sgp1.digitaloceanspaces.com/genlink/stories/test.jpg?sig=abc',
        'storageKey': 'stories/test.jpg',
        'requiredHeaders': {'Content-Type': 'image/jpeg'},
        'expiresInSeconds': 300,
      };

      final result = await datasource.presign(
        contentType: 'image/jpeg',
        sizeBytes: 1024,
        purpose: MediaPurpose.story,
        checksumSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      expect(result.mediaId, 'uuid-1234');
      expect(result.uploadUrl, contains('https://sgp1.digitaloceanspaces.com'));
      expect(result.storageKey, 'stories/test.jpg');
      expect(result.requiredHeaders['Content-Type'], 'image/jpeg');
      expect(result.expiresInSeconds, 300);
      expect(fakeApiClient.lastPostBody, {
        'contentType': 'image/jpeg',
        'sizeBytes': 1024,
        'purpose': 'STORY',
        'checksumSha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      });
    });

    test('uploadBytes extracts XML error and status code on storage failure', () async {
      final mockDio = Dio();
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 403,
                  data: '<?xml version="1.0"?><Error><Code>AccessDenied</Code><Message>Bucket is private</Message></Error>',
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final ds = MediaRemoteDatasource(fakeApiClient, uploadClient: mockDio);

      const target = PresignedUpload(
        mediaId: 'm1',
        uploadUrl: 'https://genlink.sgp1.digitaloceanspaces.com/test.jpg',
        storageKey: 'stories/test.jpg',
        requiredHeaders: {'Content-Type': 'image/jpeg'},
        expiresInSeconds: 300,
      );

      expect(
        () => ds.uploadBytes(target: target, bytes: Uint8List.fromList([1, 2, 3])),
        throwsA(isA<AppError>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.errorCode, 'errorCode', 'STORAGE_HTTP_403')
            .having((e) => e.message, 'message', contains('AccessDenied: Bucket is private'))),
      );
    });

    test('confirm posts to confirm endpoint and parses MediaEntity', () async {
      fakeApiClient.mockResponseData = {
        'mediaId': 'uuid-1234',
        'url': 'https://genlink.sgp1.cdn.digitaloceanspaces.com/stories/test.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 1024,
      };

      final result = await datasource.confirm(
        mediaId: 'uuid-1234',
        width: 1080,
        height: 1920,
      );

      expect(result.mediaId, 'uuid-1234');
      expect(result.url, 'https://genlink.sgp1.cdn.digitaloceanspaces.com/stories/test.jpg');
      expect(result.contentType, 'image/jpeg');
      expect(result.sizeBytes, 1024);
      expect(fakeApiClient.lastPostBody, {
        'mediaId': 'uuid-1234',
        'width': 1080,
        'height': 1920,
        'durationMs': null,
      });
    });
  });
}
