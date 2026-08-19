import 'package:flutter/material.dart';

enum StoryType { photo, video, text, event, announcement, achievement }

enum LayerType { text, sticker, location, hashtag, mention, music, image }

enum TextStyleType {
  classic,
  bold,
  modern,
  campus,
  coding,
  khmer,
  handwriting,
  serif,
  monospace,
  minimal,
  elegant,
}

enum TextBgStyle { none, rounded, filled, outline, highlight }

enum TextEffectType { none, shadow, outline, glow }

class MovableStoryLayer {
  final String id;
  final LayerType type;
  String text;
  Offset offset;
  double scale;
  double rotation;
  Color color;
  Color? bgColor;
  TextStyleType fontStyle;
  TextBgStyle bgStyle;
  TextEffectType effect;
  TextAlign alignment;
  double fontSize;

  MovableStoryLayer({
    required this.id,
    required this.type,
    required this.text,
    this.offset = const Offset(100, 250),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
    this.bgColor,
    this.fontStyle = TextStyleType.classic,
    this.bgStyle = TextBgStyle.none,
    this.effect = TextEffectType.none,
    this.alignment = TextAlign.center,
    this.fontSize = 28.0,
  });

  MovableStoryLayer clone() {
    return MovableStoryLayer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      text: text,
      offset: Offset(offset.dx + 20, offset.dy + 20),
      scale: scale,
      rotation: rotation,
      color: color,
      bgColor: bgColor,
      fontStyle: fontStyle,
      bgStyle: bgStyle,
      effect: effect,
      alignment: alignment,
      fontSize: fontSize,
    );
  }
}

class StoryViewerModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String viewedTimeAgo;

  StoryViewerModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.viewedTimeAgo,
  });
}

enum StoryPrivacy {
  public,
  friends,
  onlyMe,
  custom;

  String get label {
    switch (this) {
      case StoryPrivacy.public:
        return 'Public';
      case StoryPrivacy.friends:
        return 'Friends';
      case StoryPrivacy.onlyMe:
        return 'Only Me';
      case StoryPrivacy.custom:
        return 'Custom';
    }
  }

  static StoryPrivacy fromString(String? val) {
    if (val == null) return StoryPrivacy.friends;
    final lower = val.toLowerCase().replaceAll(' ', '_');
    if (lower == 'public') return StoryPrivacy.public;
    if (lower == 'only_me' || lower == 'onlyme') return StoryPrivacy.onlyMe;
    if (lower == 'custom') return StoryPrivacy.custom;
    return StoryPrivacy.friends;
  }
}

enum StoryReplyPermission {
  everyone,
  friends,
  off;

  String get label {
    switch (this) {
      case StoryReplyPermission.everyone:
        return 'Everyone';
      case StoryReplyPermission.friends:
        return 'Friends';
      case StoryReplyPermission.off:
        return 'Off';
    }
  }

  static StoryReplyPermission fromString(String? val) {
    if (val == null) return StoryReplyPermission.everyone;
    final lower = val.toLowerCase();
    if (lower == 'friends') return StoryReplyPermission.friends;
    if (lower == 'off') return StoryReplyPermission.off;
    return StoryReplyPermission.everyone;
  }
}

class StorySettings {
  final StoryPrivacy visibility;
  final StoryReplyPermission replyPermission;
  final bool allowReactions;

  const StorySettings({
    this.visibility = StoryPrivacy.friends,
    this.replyPermission = StoryReplyPermission.everyone,
    this.allowReactions = true,
  });

  StorySettings copyWith({
    StoryPrivacy? visibility,
    StoryReplyPermission? replyPermission,
    bool? allowReactions,
  }) {
    return StorySettings(
      visibility: visibility ?? this.visibility,
      replyPermission: replyPermission ?? this.replyPermission,
      allowReactions: allowReactions ?? this.allowReactions,
    );
  }

  String get visibilityLabel => visibility.label;
  String get replyPermissionLabel => replyPermission.label;
}

class StoryItemModel {
  final String id;
  final StoryType type;
  final String? mediaUrl;
  final String? textContent;
  final String? bgGradientStart;
  final String? bgGradientEnd;
  final String? location;
  final String timeAgo;
  final DateTime createdAt;
  final StorySettings settings;
  final List<MovableStoryLayer> layers;
  int likesCount;
  bool isLiked;
  bool isViewed;
  int viewersCount;
  final List<StoryViewerModel> viewers;
  final double bgScale;
  final Offset bgOffset;
  final double bgRotation;

  StoryItemModel({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.textContent,
    this.bgGradientStart,
    this.bgGradientEnd,
    this.location,
    required this.timeAgo,
    required this.createdAt,
    StorySettings? settings,
    String? visibility,
    String? replyPrivacy,
    bool? allowReactions,
    this.layers = const [],
    this.likesCount = 0,
    this.isLiked = false,
    this.isViewed = false,
    this.viewersCount = 0,
    this.viewers = const [],
    this.bgScale = 1.0,
    this.bgOffset = Offset.zero,
    this.bgRotation = 0.0,
  }) : settings =
           settings ??
           StorySettings(
             visibility: StoryPrivacy.fromString(visibility ?? 'Friends'),
             replyPermission: StoryReplyPermission.fromString(
               replyPrivacy ?? 'Everyone',
             ),
             allowReactions: allowReactions ?? true,
           );

  StoryPrivacy get storyPrivacy => settings.visibility;
  StoryReplyPermission get storyReplyPermission => settings.replyPermission;
  String get visibility => settings.visibilityLabel;
  String get replyPrivacy => settings.replyPermissionLabel;
  bool get allowReactions => settings.allowReactions;

  bool get isExpired => DateTime.now().difference(createdAt).inHours >= 24;
}

class StoryGroupModel {
  final String userId;
  final String userName;
  final String userAvatar;
  final bool isOwner;
  final List<StoryItemModel> stories;

  StoryGroupModel({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.isOwner = false,
    bool hasUnseen = true,
    required this.stories,
  });

  bool get hasUnseen => stories.any((s) => !s.isViewed);
}
