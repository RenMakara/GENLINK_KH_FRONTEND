import 'dart:typed_data';

import '../../domain/entities/media_entity.dart';
import '../../domain/repositories/media_repository.dart';
import '../datasources/media_remote_datasource.dart';

class MediaRepositoryImpl implements MediaRepository {
  const MediaRepositoryImpl(this._remote);

  final MediaRemoteDatasource _remote;

  @override
  Future<PresignedUpload> presign({
    required String contentType,
    required int sizeBytes,
    required MediaPurpose purpose,
    required String checksumSha256,
  }) =>
      _remote.presign(
        contentType: contentType,
        sizeBytes: sizeBytes,
        purpose: purpose,
        checksumSha256: checksumSha256,
      );

  @override
  Future<void> uploadBytes({
    required PresignedUpload target,
    required Uint8List bytes,
    void Function(int sent, int total)? onProgress,
  }) =>
      _remote.uploadBytes(
        target: target,
        bytes: bytes,
        onProgress: onProgress,
      );

  @override
  Future<MediaEntity> confirm({
    required String mediaId,
    int? width,
    int? height,
    int? durationMs,
  }) =>
      _remote.confirm(
        mediaId: mediaId,
        width: width,
        height: height,
        durationMs: durationMs,
      );

  @override
  Future<void> delete(String mediaId) => _remote.delete(mediaId);
}
