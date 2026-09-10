import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/media_entity.dart';
import '../models/media_models.dart';

import 'package:flutter/foundation.dart';

class MediaRemoteDatasource {
  MediaRemoteDatasource(this._client, {Dio? uploadClient})
      : _uploadClient = uploadClient ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(minutes: 2),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final ApiClient _client;

  final Dio _uploadClient;

  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) async {
    debugPrint('[StoryUpload] Requesting presigned URL: ${ApiEndpoints.mediaPresign}');
    try {
      final target = await _client.post(
        ApiEndpoints.mediaPresign,
        body: {
          'contentType': contentType,
          'sizeBytes': sizeBytes,
          'purpose': purpose.wireValue,
          'checksumSha256': checksumSha256,
        },
        parse: (data) {
          debugPrint('[StoryUpload] Presign response body: $data');
          return MediaMapper.presignFrom(ApiClient.asMap(data));
        },
      );
      final hasUrl = target.uploadUrl.isNotEmpty;
      debugPrint('[StoryUpload] Presign response: 200');
      debugPrint('[StoryUpload] Presigned URL received: $hasUrl');
      final host = Uri.tryParse(target.uploadUrl)?.host ?? 'unknown';
      debugPrint('[StoryUpload] Presign destination host: $host');
      return target;
    } catch (e) {
      debugPrint('[StoryUpload] Failed at: presign');
      debugPrint('[StoryUpload] Exact exception type: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) async {
    final host = Uri.tryParse(target.uploadUrl)?.host ?? 'unknown';
    debugPrint('[StoryUpload] Upload destination host: $host');
    debugPrint('[StoryUpload] Uploading file (${bytes.length} bytes)');

    try {
      final response = await _uploadClient.put<void>(
        target.uploadUrl,
        data: bytes,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            ...target.requiredHeaders,
            Headers.contentLengthHeader: bytes.length,
          },
          contentType: null,
          followRedirects: true,
        ),
      );
      debugPrint('[StoryUpload] Upload response status: ${response.statusCode ?? 200}');
    } on DioException catch (e) {
      debugPrint('[StoryUpload] Failed at: uploadBytes');
      debugPrint('[StoryUpload] Exact exception type: ${e.runtimeType} (${e.type})');
      debugPrint('[StoryUpload] Upload response status code: ${e.response?.statusCode}');
      debugPrint('[StoryUpload] Upload response body: ${e.response?.data}');
      debugPrint('[StoryUpload] Inner error: ${e.error}');

      final status = e.response?.statusCode;
      final responseData = e.response?.data?.toString() ?? '';
      String errorDetails = e.message ?? 'Unknown storage error';

      if (responseData.isNotEmpty) {
        final codeMatch = RegExp(r'<Code>(.*?)</Code>').firstMatch(responseData);
        final messageMatch = RegExp(r'<Message>(.*?)</Message>').firstMatch(responseData);
        if (codeMatch != null || messageMatch != null) {
          final code = codeMatch?.group(1) ?? 'STORAGE_ERROR';
          final msg = messageMatch?.group(1) ?? '';
          errorDetails = '$code${msg.isNotEmpty ? ': $msg' : ''}';
        } else {
          errorDetails = responseData;
        }
      } else if (e.error != null) {
        errorDetails = e.error.toString();
      }

      throw AppError(
        message: 'Media upload failed ($host): $errorDetails',
        errorCode: status != null ? 'STORAGE_HTTP_$status' : 'STORAGE_UPLOAD_ERROR',
        statusCode: status,
      );
    } catch (e) {
      debugPrint('[StoryUpload] Failed at: uploadBytes (non-Dio error)');
      debugPrint('[StoryUpload] Exact exception type: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) async {
    debugPrint('[StoryUpload] Confirming mediaId: $mediaId');
    try {
      final entity = await _client.post(
        ApiEndpoints.mediaConfirm,
        body: {
          'mediaId': mediaId,
          'width': width,
          'height': height,
          'durationMs': durationMs,
        },
        parse: (data) => MediaMapper.mediaFrom(ApiClient.asMap(data)),
      );
      debugPrint('[StoryUpload] Media confirmed successfully, url: ${entity.url}');
      return entity;
    } catch (e) {
      debugPrint('[StoryUpload] Failed at: confirm');
      debugPrint('[StoryUpload] Exact exception type: ${e.runtimeType}: $e');
      rethrow;
    }
  }

  Future<void> delete(String mediaId) =>
      _client.delete(ApiEndpoints.mediaItem(mediaId));
}
