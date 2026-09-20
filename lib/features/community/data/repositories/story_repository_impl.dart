import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/errors/app_error.dart';
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

          final authorUsername = (author['username'] as String?)?.trim();
          final authorFullName = (author['fullName'] as String?)?.trim();

          return StoryGroupModel(
            userId: userId,
            userName: (authorFullName != null && authorFullName.isNotEmpty)
                ? authorFullName
                : (authorUsername != null && authorUsername.isNotEmpty
                    ? authorUsername
                    : 'User'),
            userHandle: authorUsername,
            userAvatar: (author['avatarUrl'] as String?) ?? '',
            isOwner: isOwner,
            hasUnseen: hasUnseen,
            stories: parsedStories,
          );
        }),
      );

      final cleanRemoteGroups = remoteGroups.where((g) {
        final id = g.userId.toLowerCase();
        return !id.startsWith('demo_') && !id.startsWith('mock_');
      }).toList();

      final ownerGroupIdx = cleanRemoteGroups.indexWhere((g) =>
          g.isOwner || (currentUserId.isNotEmpty && g.userId == currentUserId));

      if (ownerGroupIdx == -1) {
        final ownerGroup = StoryGroupModel(
          userId: currentUserId.isNotEmpty ? currentUserId : '',
          userName: currentUserName.isNotEmpty && currentUserName != 'Guest'
              ? currentUserName
              : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'User'),
          userHandle:
              CurrentUser.username.isNotEmpty ? CurrentUser.username : null,
          userAvatar: currentUserAvatar ?? '',
          isOwner: true,
          hasUnseen: false,
          stories: [],
        );
        return [ownerGroup, ...cleanRemoteGroups];
      } else {
        final ownerGroup = cleanRemoteGroups[ownerGroupIdx];
        final updatedOwnerGroup = StoryGroupModel(
          userId: ownerGroup.userId,
          userName: ownerGroup.userName,
          userHandle: ownerGroup.userHandle ??
              (CurrentUser.username.isNotEmpty ? CurrentUser.username : null),
          userAvatar: currentUserAvatar?.isNotEmpty == true
              ? currentUserAvatar!
              : ownerGroup.userAvatar,
          isOwner: true,
          hasUnseen: ownerGroup.hasUnseen,
          stories: ownerGroup.stories,
        );

        final otherGroups = List<StoryGroupModel>.from(cleanRemoteGroups)
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
            : (CurrentUser.username.isNotEmpty ? CurrentUser.username : 'User'),
        userHandle:
            CurrentUser.username.isNotEmpty ? CurrentUser.username : null,
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
    if (client == null) {
      throw const AppError(
        message: 'ApiClient is unavailable',
        errorCode: 'API_CLIENT_UNAVAILABLE',
      );
    }

    final uploadService = _uploadService;

    final resolvedSettings = settings ??
        StorySettings(
          visibility: StoryPrivacy.fromString(visibility),
          replyPermission: StoryReplyPermission.fromString(replyPrivacy),
          allowReactions: allowReactions,
        );

    String finalMediaUrl = mediaUrl?.trim() ?? '';
    if (finalMediaUrl.isEmpty && templateSlots != null) {
      for (final slot in templateSlots) {
        if (slot.mediaPath != null && slot.mediaPath!.trim().isNotEmpty) {
          finalMediaUrl = slot.mediaPath!.trim();
          break;
        }
      }
    }

    bool isVideo = type == StoryType.video || (finalMediaUrl.isNotEmpty && _isVideoPath(finalMediaUrl));
    debugPrint('[StoryUpload] Starting Story creation (type: $type, initial mediaUrl: $finalMediaUrl, isVideo: $isVideo)');

    if (finalMediaUrl.isNotEmpty &&
        !finalMediaUrl.startsWith('http://') &&
        !finalMediaUrl.startsWith('https://')) {
      final cleanPath = finalMediaUrl.replaceAll(RegExp(r'^file://'), '');
      final file = File(cleanPath);

      if (!file.existsSync()) {
        throw AppError(
          message: 'Media file not found: $cleanPath',
          errorCode: 'MEDIA_NOT_FOUND',
        );
      }

      if (uploadService == null) {
        throw const AppError(
          message: 'Media upload service is unavailable',
          errorCode: 'UPLOAD_SERVICE_UNAVAILABLE',
        );
      }

      debugPrint('[StoryUpload] Uploading local media file: $cleanPath');
      final bytes = file.readAsBytesSync();
      final contentType = _detectContentType(cleanPath, isVideo);

      final mediaEntity = await uploadService.upload(
        bytes: bytes,
        contentType: contentType,
        purpose: MediaPurpose.story,
      );
      finalMediaUrl = mediaEntity.url;
      debugPrint('[StoryUpload] Upload completed. CDN media URL: $finalMediaUrl');
    } else if (finalMediaUrl.isEmpty && (type == StoryType.text || layers?.isNotEmpty == true)) {
      if (uploadService == null) {
        throw const AppError(
          message: 'Media upload service is unavailable for story canvas',
          errorCode: 'UPLOAD_SERVICE_UNAVAILABLE',
        );
      }

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
    }

    if (finalMediaUrl.trim().isEmpty) {
      throw const AppError(
        message: 'Story media URL cannot be empty',
        errorCode: 'INVALID_MEDIA_URL',
      );
    }

    debugPrint('[StoryUpload] Posting Story to ${ApiEndpoints.stories} with mediaUrl: $finalMediaUrl');
    final serverStory = await client.post(
      ApiEndpoints.stories,
      body: {
        'mediaUrl': finalMediaUrl,
        'mediaType': isVideo ? 'VIDEO' : 'IMAGE',
        'caption': textContent,
        'visibility': _toBackendVisibility(resolvedSettings.visibility),
        'replyPermission': _toBackendReplyPermission(resolvedSettings.replyPermission),
        'allowReactions': resolvedSettings.allowReactions,
      },
      parse: (data) => _storyFromJson(ApiClient.asMap(data)),
    );
    debugPrint('[StoryUpload] Story successfully posted to backend, storyId: ${serverStory.id}');

    if (serverStory.id.trim().isEmpty) {
      throw const AppError(
        message: 'Backend failed to return a valid story ID',
        errorCode: 'INVALID_STORY_ID',
      );
    }

    return StoryItemModel(
      id: serverStory.id,
      type: type,
      mediaUrl: serverStory.mediaUrl ?? finalMediaUrl,
      textContent: textContent ?? serverStory.textContent,
      location: location,
      settings: serverStory.settings,
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

  @override
  Future<StoryItemModel?> getStoryById(String storyId) async {
    final client = _client;
    if (client == null) return null;
    try {
      return await client.get(
        ApiEndpoints.storyItem(storyId),
        parse: (data) => _storyFromJson(ApiClient.asMap(data)),
      );
    } catch (e) {
      debugPrint('[StoryRepository] getStoryById error: $e');
      return null;
    }
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
    return [];
  }

  @override
  Future<void> toggleLikeStory(String storyId) async {
  }

  @override
  Future<void> replyToStory(String storyId, String message) async {
  }

  StoryItemModel _storyFromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final mediaType = (json['mediaType'] as String?)?.toUpperCase() ?? 'IMAGE';
    final storyId = json['storyId']?.toString() ?? json['id']?.toString() ?? '';
    final mediaUrl = json['mediaUrl'] as String?;
    final caption = json['caption'] as String? ?? json['textContent'] as String?;
    final seen = json['seen'] as bool? ?? false;

    final rawVisibility = json['visibility'] as String?;
    final rawReply = (json['replyPermission'] ?? json['replyPrivacy']) as String?;
    final rawAllowReactions = json['allowReactions'] as bool? ?? true;

    final settings = StorySettings(
      visibility: StoryPrivacy.fromString(rawVisibility ?? 'PUBLIC'),
      replyPermission: StoryReplyPermission.fromString(rawReply ?? 'EVERYONE'),
      allowReactions: rawAllowReactions,
    );

    return StoryItemModel(
      id: storyId,
      type: mediaType == 'VIDEO' ? StoryType.video : StoryType.photo,
      mediaUrl: mediaUrl,
      textContent: caption,
      timeAgo: _timeAgo(createdAt),
      createdAt: createdAt,
      isViewed: seen,
      settings: settings,
      visibility: settings.visibilityLabel,
      replyPrivacy: settings.replyPermissionLabel,
      allowReactions: settings.allowReactions,
      location: json['location'] as String?,
      templateId: json['templateId'] as String?,
    );
  }

  String _toBackendVisibility(StoryPrivacy privacy) {
    switch (privacy) {
      case StoryPrivacy.public:
        return 'PUBLIC';
      case StoryPrivacy.friends:
        return 'FRIENDS';
      case StoryPrivacy.onlyMe:
        return 'ONLY_ME';
      case StoryPrivacy.custom:
        return 'CUSTOM';
    }
  }

  String _toBackendReplyPermission(StoryReplyPermission permission) {
    switch (permission) {
      case StoryReplyPermission.everyone:
        return 'EVERYONE';
      case StoryReplyPermission.friends:
        return 'FRIENDS';
      case StoryReplyPermission.off:
        return 'OFF';
    }
  }

  String _timeAgo(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  bool _isVideoPath(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.m4v') ||
        p.endsWith('.webm') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv');
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

  @override
  Future<List<StoryMentionUser>> searchMentionUsers({String query = ''}) async {
    final client = _client;
    final cleanQuery = query.trim().toLowerCase().replaceAll('@', '');
    final List<StoryMentionUser> results = [];

    if (client == null) {
      return results;
    }

    final currentUserId = CurrentUser.id;
    if (currentUserId.isNotEmpty) {
      try {
        final followings = await client.get(
          ApiEndpoints.communityFollowing(currentUserId),
          parse: (data) => ApiClient.asList(data, (json) {
            final userMap = json['user'] is Map<String, dynamic>
                ? json['user'] as Map<String, dynamic>
                : json;
            return StoryMentionUser(
              id: userMap['userId']?.toString() ?? '',
              displayName: (userMap['fullName'] as String?)?.trim() ?? '',
              username: (userMap['username'] as String?)?.trim() ?? '',
              avatarUrl: (userMap['avatarUrl'] as String?)?.trim() ?? '',
            );
          }),
        );
        for (final u in followings) {
          if (u.id.startsWith('demo_') || u.id.startsWith('mock_')) continue;
          if (u.cleanUsername.isNotEmpty &&
              !results.any((r) =>
                  r.cleanUsername.toLowerCase() ==
                  u.cleanUsername.toLowerCase())) {
            results.add(u);
          }
        }
      } catch (_) {}
    }

    if (cleanQuery.isNotEmpty && !cleanQuery.contains(' ')) {
      try {
        final profile = await client.get(
          ApiEndpoints.publicProfile(cleanQuery),
          parse: (data) {
            final map = ApiClient.asMap(data);
            final uname = (map['username'] as String?)?.trim() ?? cleanQuery;
            final fname = (map['fullName'] as String?)?.trim() ?? uname;
            return StoryMentionUser(
              id: map['userId']?.toString() ?? '',
              displayName: fname,
              username: uname,
              avatarUrl: (map['avatarUrl'] as String?)?.trim() ?? '',
            );
          },
        );
        if (profile.id.startsWith('demo_') || profile.id.startsWith('mock_')) {
          // ignore mock profile
        } else if (profile.username.isNotEmpty &&
            !results.any((r) =>
                r.cleanUsername.toLowerCase() ==
                profile.cleanUsername.toLowerCase())) {
          results.add(profile);
        }
      } catch (_) {}
    }

    if (cleanQuery.isEmpty) {
      return results;
    }
    return results.where((u) => u.matchesQuery(cleanQuery)).toList();
  }
}
