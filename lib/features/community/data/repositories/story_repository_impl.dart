import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/utils/current_user.dart';
import '../../../media/data/datasources/media_remote_datasource.dart';
import '../../../media/data/repositories/media_repository_impl.dart';
import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import '../../domain/models/story_model.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final ApiClient? _apiClient;
  final MediaUploadService? _mediaUploadService;

  StoryRepositoryImpl({
    ApiClient? apiClient,
    MediaUploadService? mediaUploadService,
  })  : _apiClient = apiClient ??
            (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null),
        _mediaUploadService = mediaUploadService ??
            (Get.isRegistered<MediaUploadService>()
                ? Get.find<MediaUploadService>()
                : null);

  ApiClient? get _client =>
      _apiClient ??
      (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null);

  MediaUploadService? get _uploadService {
    if (_mediaUploadService != null) return _mediaUploadService;
    if (Get.isRegistered<MediaUploadService>()) {
      return Get.find<MediaUploadService>();
    }
    final client = _client;
    if (client != null) {
      return MediaUploadService(
        MediaRepositoryImpl(MediaRemoteDatasource(client)),
      );
    }
    return null;
  }

  @override
  Future<List<StoryGroupModel>> getStories() async {
    final client = _client;
    if (client == null) {
      return _buildFallbackOwnerOnlyList();
    }

    try {
      final currentUserId = CurrentUser.id;
      final currentUserAvatar = CurrentUser.avatarUrl;
      final currentUserName = CurrentUser.name;

      final remoteGroups = await client.get(
        ApiEndpoints.stories,
        parse: (data) => ApiClient.asList(data, (json) {
          final author = json['author'] is Map<String, dynamic>
              ? json['author'] as Map<String, dynamic>
              : const <String, dynamic>{};
          final stories = json['stories'] as List? ?? const [];
          final userId = author['userId']?.toString() ?? '';
          final isOwner = currentUserId.isNotEmpty
              ? (userId == currentUserId)
              : (json['isOwner'] as bool? ?? false);
          final hasUnseen = json['hasUnseen'] as bool? ?? false;

          final parsedStories = stories
              .map((s) => _storyFromJson((s as Map).cast<String, dynamic>()))
              .toList();

          return StoryGroupModel(
            userId: userId,
            userName: (author['fullName'] as String?) ??
                (author['username'] as String?) ??
                'User',
            userAvatar: (author['avatarUrl'] as String?) ?? '',
            isOwner: isOwner,
            hasUnseen: hasUnseen,
            stories: parsedStories,
          );
        }),
      );

      final ownerGroupIdx = remoteGroups.indexWhere((g) =>
          g.isOwner || (currentUserId.isNotEmpty && g.userId == currentUserId));

      if (ownerGroupIdx == -1) {
        final ownerGroup = StoryGroupModel(
          userId: currentUserId.isNotEmpty ? currentUserId : '',
          userName: currentUserName.isNotEmpty && currentUserName != 'Guest'
              ? currentUserName
              : (currentUserId.isNotEmpty ? currentUserId : 'User'),
          userAvatar: currentUserAvatar ?? '',
          isOwner: true,
          hasUnseen: false,
          stories: [],
        );
        return [ownerGroup, ...remoteGroups];
      } else {
        final ownerGroup = remoteGroups[ownerGroupIdx];
        final updatedOwnerGroup = StoryGroupModel(
          userId: ownerGroup.userId,
          userName: ownerGroup.userName,
          userAvatar: currentUserAvatar?.isNotEmpty == true
              ? currentUserAvatar!
              : ownerGroup.userAvatar,
          isOwner: true,
          hasUnseen: ownerGroup.hasUnseen,
          stories: ownerGroup.stories,
        );

        final otherGroups = List<StoryGroupModel>.from(remoteGroups)
          ..removeAt(ownerGroupIdx);

        return [updatedOwnerGroup, ...otherGroups];
      }
    } catch (e) {
      debugPrint('[StoryRepository] getStories error: $e');
      return _buildFallbackOwnerOnlyList();
    }
  }

  List<StoryGroupModel> _buildFallbackOwnerOnlyList() {
    final currentUserId = CurrentUser.id;
    final currentUserAvatar = CurrentUser.avatarUrl;
    final currentUserName = CurrentUser.name;
    return [
      StoryGroupModel(
        userId: currentUserId.isNotEmpty ? currentUserId : '',
        userName: currentUserName.isNotEmpty && currentUserName != 'Guest'
            ? currentUserName
            : (currentUserId.isNotEmpty ? currentUserId : 'User'),
        userAvatar: currentUserAvatar ?? '',
        isOwner: true,
        hasUnseen: false,
        stories: [],
      ),
    ];
  }

  @override
  Future<StoryItemModel> createStory({
    required StoryType type,
    String? mediaUrl,
    String? textContent,
    String? location,
    StorySettings? settings,
    String visibility = 'Friends',
    String replyPrivacy = 'Everyone',
    bool allowReactions = true,
    String? bgGradientStart,
    String? bgGradientEnd,
    List<MovableStoryLayer>? layers,
    double bgScale = 1.0,
    dynamic bgOffset,
    double bgRotation = 0.0,
    String? templateId,
    List<StoryTemplateSlot>? templateSlots,
  }) async {
    final client = _client;
    final uploadService = _uploadService;

    final resolvedSettings = settings ??
        StorySettings(
          visibility: StoryPrivacy.fromString(visibility),
          replyPermission: StoryReplyPermission.fromString(replyPrivacy),
          allowReactions: allowReactions,
        );

    String finalMediaUrl = mediaUrl ?? '';
    bool isVideo = type == StoryType.video || (finalMediaUrl.isNotEmpty && _isVideoPath(finalMediaUrl));
    debugPrint('[StoryUpload] Starting Story creation (type: $type, initial mediaUrl: $finalMediaUrl, isVideo: $isVideo)');

    if (finalMediaUrl.isNotEmpty &&
        !finalMediaUrl.startsWith('http://') &&
        !finalMediaUrl.startsWith('https://')) {
      final cleanPath = _normalizeFilePath(finalMediaUrl);
      final file = File(cleanPath);

      if (file.existsSync() && uploadService != null) {
        debugPrint('[StoryUpload] Uploading local media file: $cleanPath');
        final bytes = await file.readAsBytes();
        final contentType = _detectContentType(cleanPath, isVideo);

        final mediaEntity = await uploadService.upload(
          bytes: bytes,
          contentType: contentType,
          purpose: MediaPurpose.story,
        );
        finalMediaUrl = mediaEntity.url;
        debugPrint('[StoryUpload] Upload completed. CDN media URL: $finalMediaUrl');
      }
    } else if (finalMediaUrl.isEmpty && (type == StoryType.text || layers?.isNotEmpty == true)) {
      if (uploadService != null) {
        try {
          debugPrint('[StoryUpload] Rendering text story canvas to PNG and uploading...');
          final startColor = _parseColor(bgGradientStart, const Color(0xFF0F172A));
          final endColor = _parseColor(bgGradientEnd, const Color(0xFF1E293B));
          final pngBytes = await _renderCanvasToPng(
            textContent: textContent ?? '',
            startColor: startColor,
            endColor: endColor,
            layers: layers ?? const [],
          );

          final mediaEntity = await uploadService.upload(
            bytes: pngBytes,
            contentType: 'image/png',
            purpose: MediaPurpose.story,
          );
          finalMediaUrl = mediaEntity.url;
          isVideo = false;
          debugPrint('[StoryUpload] Text story canvas uploaded. CDN media URL: $finalMediaUrl');
        } catch (e) {
          debugPrint('[StoryRepository] Canvas rendering upload fallback: $e');
        }
      }
    }

    if (client != null && finalMediaUrl.isNotEmpty) {
      debugPrint('[StoryUpload] Posting Story to ${ApiEndpoints.stories} with mediaUrl: $finalMediaUrl');
      final serverStory = await client.post(
        ApiEndpoints.stories,
        body: {
          'mediaUrl': finalMediaUrl,
          'mediaType': isVideo ? 'VIDEO' : 'IMAGE',
          'caption': textContent,
        },
        parse: (data) => _storyFromJson(ApiClient.asMap(data)),
      );
      debugPrint('[StoryUpload] Story successfully posted to backend, storyId: ${serverStory.id}');

      return StoryItemModel(
        id: serverStory.id.isNotEmpty ? serverStory.id : 'story_${DateTime.now().millisecondsSinceEpoch}',
        type: isVideo ? StoryType.video : type,
        mediaUrl: serverStory.mediaUrl ?? (finalMediaUrl.isNotEmpty ? finalMediaUrl : null),
        textContent: textContent ?? serverStory.textContent,
        location: location,
        settings: resolvedSettings,
        bgGradientStart: bgGradientStart ?? '0xFF0F172A',
        bgGradientEnd: bgGradientEnd ?? '0xFF1E293B',
        layers: layers ?? const [],
        bgScale: bgScale,
        bgOffset: bgOffset ?? Offset.zero,
        bgRotation: bgRotation,
        templateId: templateId,
        templateSlots: templateSlots ?? const [],
        timeAgo: serverStory.timeAgo,
        createdAt: serverStory.createdAt,
      );
    }

    return StoryItemModel(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      type: isVideo ? StoryType.video : type,
      mediaUrl: (finalMediaUrl.isNotEmpty ? finalMediaUrl : (mediaUrl != null && mediaUrl.isNotEmpty ? mediaUrl : null)),
      textContent: textContent,
      location: location,
      settings: resolvedSettings,
      bgGradientStart: bgGradientStart ?? '0xFF0F172A',
      bgGradientEnd: bgGradientEnd ?? '0xFF1E293B',
      layers: layers ?? const [],
      bgScale: bgScale,
      bgOffset: bgOffset ?? Offset.zero,
      bgRotation: bgRotation,
      templateId: templateId,
      templateSlots: templateSlots ?? const [],
      timeAgo: 'Just now',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateStory(String storyId, StoryItemModel updatedStory) async {
  }

  @override
  Future<void> deleteStory(String storyId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.delete(ApiEndpoints.storyItem(storyId));
      } catch (e) {
        debugPrint('[StoryRepository] deleteStory error: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> markViewed(String storyId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.post(ApiEndpoints.storyView(storyId), parse: (_) {});
      } catch (e) {
        debugPrint('[StoryRepository] markViewed error: $e');
      }
    }
  }

  @override
  Future<List<StoryViewerModel>> getStoryViewers(String storyId) async {
    final client = _client;
    if (client != null) {
      try {
        return await client.get(
          ApiEndpoints.storyViewers(storyId),
          parse: (data) => ApiClient.asList(data, (json) {
            final viewedAtStr = json['viewedAt']?.toString();
            final viewedAt = viewedAtStr != null ? DateTime.tryParse(viewedAtStr) : null;
            return StoryViewerModel(
              id: json['userId']?.toString() ?? '',
              userName: (json['fullName'] as String?) ??
                  (json['username'] as String?) ??
                  'User',
              userAvatar: json['avatarUrl'] as String? ?? '',
              viewedTimeAgo: _timeAgo(viewedAt),
            );
          }),
        );
      } catch (e) {
        debugPrint('[StoryRepository] getStoryViewers error: $e');
        return [];
      }
    }
    return [
      StoryViewerModel(
        id: 'v1',
        userName: 'Chhaeng Sokuntheara',
        userAvatar: 'assets/images/sokuntheara_profile.png',
        viewedTimeAgo: '10m ago',
      ),
      StoryViewerModel(
        id: 'v2',
        userName: 'Heng Chansela',
        userAvatar: 'assets/images/heng_chansela_profile.png',
        viewedTimeAgo: '20m ago',
      ),
      StoryViewerModel(
        id: 'v3',
        userName: 'អំណត់',
        userAvatar: 'assets/images/amnot_profile.jpg',
        viewedTimeAgo: '25m ago',
      ),
      StoryViewerModel(
        id: 'v4',
        userName: 'Sum Sambo',
        userAvatar: 'assets/images/sum_sambo_profile.png',
        viewedTimeAgo: '40m ago',
      ),
    ];
  }

  @override
  Future<void> toggleLikeStory(String storyId) async {
  }

  @override
  Future<void> replyToStory(String storyId, String message) async {
    final client = _client;
    if (client != null) {
      try {
        await client.post(
          '${ApiEndpoints.stories}/$storyId/reply',
          body: {'message': message},
          parse: (_) => null,
        );
      } catch (e) {
        debugPrint('[StoryRepository] replyToStory error: $e');
        rethrow;
      }
    }
  }

  StoryItemModel storyFromJson(Map<String, dynamic> json) => _storyFromJson(json);

  StoryItemModel _storyFromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final mediaType = (json['mediaType'] as String?)?.toUpperCase() ?? 'IMAGE';
    final storyId = json['storyId']?.toString() ?? json['id']?.toString() ?? '';
    final mediaUrl = json['mediaUrl'] as String?;
    final caption = json['caption'] as String? ?? json['textContent'] as String?;
    final seen = json['seen'] as bool? ?? false;

    final viewersCount = (json['viewersCount'] as num?)?.toInt() ??
        (json['viewerCount'] as num?)?.toInt() ??
        (json['viewCount'] as num?)?.toInt() ??
        0;

    final rawViewers = json['viewers'] as List?;
    final List<StoryViewerModel> parsedViewers = rawViewers != null
        ? rawViewers
            .whereType<Map>()
            .map((v) => StoryViewerModel.fromJson(v.cast<String, dynamic>()))
            .toList()
        : const [];

    final rawType = (json['type'] as String?)?.toLowerCase() ??
        (json['storyType'] as String?)?.toLowerCase();
    final isVideoUrl = mediaUrl != null && _isVideoPath(mediaUrl);
    final StoryType resolvedType = rawType == 'text'
        ? StoryType.text
        : (rawType == 'template'
            ? StoryType.template
            : (rawType == 'video' || mediaType == 'VIDEO' || isVideoUrl ? StoryType.video : StoryType.photo));

    return StoryItemModel(
      id: storyId,
      type: resolvedType,
      mediaUrl: mediaUrl,
      textContent: caption,
      timeAgo: _timeAgo(createdAt),
      createdAt: createdAt,
      isViewed: seen,
      viewersCount: viewersCount > 0 ? viewersCount : parsedViewers.length,
      viewers: parsedViewers,
      visibility: json['visibility'] as String? ?? 'Public',
      replyPrivacy: json['replyPrivacy'] as String? ?? 'Everyone',
      allowReactions: json['allowReactions'] as bool? ?? true,
      location: json['location'] as String?,
      templateId: json['templateId'] as String?,
    );
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _normalizeFilePath(String path) {
    String clean = path.trim();
    if (clean.startsWith('file:')) {
      final normalized = clean.replaceAll('\\', '/');
      try {
        clean = Uri.parse(normalized).toFilePath();
      } catch (_) {
        clean = normalized.replaceFirst(RegExp(r'^file:/{1,3}'), '');
      }
    }
    clean = clean.replaceAll('\\', '/');
    if (clean.startsWith('/') && clean.length > 2 && clean[2] == ':') {
      clean = clean.substring(1);
    }
    return clean;
  }

  bool _isVideoPath(String path) {
    final clean = _normalizeFilePath(path).split('?').first.split('#').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.m4v') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.avi') ||
        clean.endsWith('.mkv');
  }

  String _detectContentType(String path, bool isVideo) {
    final p = path.toLowerCase();
    if (isVideo) {
      if (p.endsWith('.mov')) return 'video/quicktime';
      if (p.endsWith('.webm')) return 'video/webm';
      return 'video/mp4';
    }
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  Future<Uint8List> _renderCanvasToPng({
    required String textContent,
    required Color startColor,
    required Color endColor,
    required List<MovableStoryLayer> layers,
    int width = 720,
    int height = 1280,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width.toDouble(), height.toDouble()),
        [startColor, endColor],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    final textToDraw = textContent.trim().isNotEmpty
        ? textContent.trim()
        : layers.where((l) => l.type == LayerType.text).map((l) => l.text).join('\n');

    if (textToDraw.trim().isNotEmpty) {
      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 34,
          fontWeight: FontWeight.bold,
          maxLines: 12,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(textToDraw.trim());

      final paragraph = pb.build()
        ..layout(ui.ParagraphConstraints(width: width.toDouble() - 80));

      final textOffset = Offset(
        40,
        (height.toDouble() - paragraph.height) / 2,
      );
      canvas.drawParagraph(paragraph, textOffset);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
