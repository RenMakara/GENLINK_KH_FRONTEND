import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/media_entity.dart';
import '../models/media_models.dart';

/// Talks to the media endpoints, and to the storage provider for the upload.
class MediaRemoteDatasource {
  MediaRemoteDatasource(this._client, {Dio? uploadClient})
      : _uploadClient = uploadClient ?? Dio();

  final ApiClient _client;

  /// A bare [Dio] for the direct upload — deliberately **not** the app's
  /// configured client.
  ///
  /// The presigned URL is absolute (so a baseUrl would corrupt it) and carries
  /// its own authorisation in the query string. Sending our `Authorization`
  /// header alongside it makes the storage provider reject the request, and the
  /// auth interceptor's 401 refresh logic has no meaning here.
  final Dio _uploadClient;

  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) {
    return _client.post(
      ApiEndpoints.mediaPresign,
      body: {
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'purpose': purpose.wireValue,
        'checksumSha256': checksumSha256,
      },
      parse: (data) => MediaMapper.presignFrom(ApiClient.asMap(data)),
    );
  }

  /// PUT the bytes straight to storage.
  ///
  /// [PresignedUpload.requiredHeaders] is sent verbatim: the signature covers
  /// those headers, so altering `Content-Type` (Dio likes to append a charset)
  /// or dropping one is a 403.
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      await _uploadClient.put<void>(
        target.uploadUrl,
        data: Stream<List<int>>.fromIterable([bytes]),
        onSendProgress: onProgress,
        options: Options(
          headers: {
            ...target.requiredHeaders,
            Headers.contentLengthHeader: bytes.length,
          },
          // Stop Dio from inferring a content type; the signed one is already
          // in requiredHeaders and must survive untouched.
          contentType: null,
          followRedirects: false,
        ),
      );
    } on DioException catch (e) {
      throw AppError.fromDio(e);
    }
  }

  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) {
    return _client.post(
      ApiEndpoints.mediaConfirm,
      body: {
        'mediaId': mediaId,
        'width': width,
        'height': height,
        'durationMs': durationMs,
      },
      parse: (data) => MediaMapper.mediaFrom(ApiClient.asMap(data)),
    );
  }

  Future<void> delete(String mediaId) =>
      _client.delete(ApiEndpoints.mediaItem(mediaId));
}
