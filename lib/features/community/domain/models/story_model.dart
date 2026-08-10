import 'package:flutter/material.dart';

enum StoryType { photo, video, text, event, announcement, achievement }

enum LayerType { text, sticker, location, hashtag, mention, music, image }

enum TextStyleType { classic, bold, modern, campus, coding, khmer, handwriting, serif, monospace, minimal, elegant }

enum TextBgStyle { none, rounded, filled, outline, highlight }

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
  TextAlign alignment;

  MovableStoryLayer({
    required this.id,
    required this.type,
    required this.text,
    this.offset = const Offset(100, 250),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
    this.bgColor,
    this.fontStyle = TextStyleType.bold,
    this.bgStyle = TextBgStyle.none,
    this.alignment = TextAlign.center,
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
      alignment: alignment,
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
  final String visibility;
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
    this.visibility = 'Public',
    this.layers = const [],
    this.likesCount = 0,
    this.isLiked = false,
    this.isViewed = false,
    this.viewersCount = 0,
    this.viewers = const [],
    this.bgScale = 1.0,
    this.bgOffset = Offset.zero,
    this.bgRotation = 0.0,
  });

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
