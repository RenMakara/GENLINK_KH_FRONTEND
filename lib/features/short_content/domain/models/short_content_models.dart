class ShortContentModel {
  const ShortContentModel({
    required this.shortContentId,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.creatorId,
    this.creatorFullName,
    this.creatorUsername,
    this.creatorAvatarUrl,
    required this.likeCount,
    required this.saveCount,
    required this.shareCount,
    required this.liked,
    required this.saved,
  });

  final String shortContentId;
  final String title;
  final String description;
  final String? category;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? creatorId;
  final String? creatorFullName;
  final String? creatorUsername;
  final String? creatorAvatarUrl;
  final int likeCount;
  final int saveCount;
  final int shareCount;
  final bool liked;
  final bool saved;

  factory ShortContentModel.fromJson(Map<String, dynamic> json) {
    return ShortContentModel(
      shortContentId: (json['shortContentId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: _optionalString(json['category']),
      videoUrl: _optionalString(json['videoUrl']),
      thumbnailUrl: _optionalString(json['thumbnailUrl']),
      creatorId: _optionalString(json['creatorId']),
      creatorFullName: _optionalString(json['creatorFullName']),
      creatorUsername: _optionalString(json['creatorUsername']),
      creatorAvatarUrl: _optionalString(json['creatorAvatarUrl']),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      liked: json['liked'] == true,
      saved: json['saved'] == true,
    );
  }

  bool get hasVideo => videoUrl != null;

  bool get hasThumbnail => thumbnailUrl != null;

  String get shareText {
    final parts = <String>[];
    if (title.trim().isNotEmpty) parts.add(title.trim());
    if (description.trim().isNotEmpty) parts.add(description.trim());
    final mediaUrl = videoUrl ?? thumbnailUrl;
    if (mediaUrl != null) parts.add(mediaUrl);
    return parts.join('\n');
  }

  ShortContentModel copyWith({
    String? shortContentId,
    String? title,
    String? description,
    String? category,
    String? videoUrl,
    String? thumbnailUrl,
    String? creatorId,
    String? creatorFullName,
    String? creatorUsername,
    String? creatorAvatarUrl,
    int? likeCount,
    int? saveCount,
    int? shareCount,
    bool? liked,
    bool? saved,
  }) {
    return ShortContentModel(
      shortContentId: shortContentId ?? this.shortContentId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorFullName: creatorFullName ?? this.creatorFullName,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      shareCount: shareCount ?? this.shareCount,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
    );
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class ShortContentCreateRequest {
  const ShortContentCreateRequest({
    required this.title,
    required this.videoUrl,
    this.description,
    this.category,
    this.thumbnailUrl,
    this.videoMediaId,
    this.thumbnailMediaId,
  });

  final String title;
  final String? description;
  final String? category;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? videoMediaId;
  final String? thumbnailMediaId;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'videoMediaId': videoMediaId,
      'thumbnailMediaId': thumbnailMediaId,
    };
    body.removeWhere((key, value) => value == null);
    return body;
  }
}

class ShortContentPage {
  const ShortContentPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<ShortContentModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  factory ShortContentPage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List? ?? const [];
    return ShortContentPage(
      content: rawContent
          .whereType<Map>()
          .map(
            (item) => ShortContentModel.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] == true,
    );
  }
}
