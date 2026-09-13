import 'dart:convert';
import 'community_models.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/utils/current_user.dart';

class PollOptionModel {
  final String text;
  int votes;
  bool isVoted;

  PollOptionModel({required this.text, this.votes = 0, this.isVoted = false});
}

class CommunityPostModel {
  final String id;
  final String userId;
  final String authorName;
  final String authorTag;
  final String authorAvatar;
  final bool isVerified;
  final String timeAgo;
  final String content;
  final List<String> imageUrls;
  int likesCount;
  int commentsCount;
  int sharesCount;
  String get authorId => userId;
  int get repostsCount => sharesCount;
  bool isLiked;
  bool isBookmarked;
  bool isFollowing;
  bool isRepostedByMe;
  final bool isOwner;
  final String visibility;
  final String community;
  final String? repostedBy;
  final String? repostCaption;
  final String? originalPostId;
  final String? reposterId;
  final String? location;
  final String? linkUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDomain;
  final String? pollQuestion;
  final List<PollOptionModel>? pollOptions;
  final String? pollDuration;
  final bool allowMultipleAnswers;
  final bool hideResultsUntilVote;
  final List<CommentModel> comments;
  final EventModel? attachedEvent;
  final String? postType;
  final String? discussionTitle;
  final String? category;
  /// Step 3B-Frontend: prepared for backend VIDEO support.
  /// Populated from JSON 'videoUrl' once backend returns it.
  final String? videoUrl;

  /// True when this post carries a video (not images).
  bool get isVideoPost => videoUrl != null && videoUrl!.isNotEmpty;

  /// True when this post represents an event post.
  bool get isEventPost =>
      (postType?.toLowerCase() == 'event') || attachedEvent != null;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorTag,
    required this.authorAvatar,
    this.isVerified = false,
    required this.timeAgo,
    required this.content,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.isRepostedByMe = false,
    this.isOwner = false,
    this.visibility = 'Public',
    this.community = 'All GenLink',
    this.repostedBy,
    this.repostCaption,
    this.originalPostId,
    this.reposterId,
    this.location,
    this.linkUrl,
    this.linkPreviewTitle,
    this.linkPreviewDomain,
    this.pollQuestion,
    this.pollOptions,
    this.pollDuration,
    this.allowMultipleAnswers = false,
    this.hideResultsUntilVote = true,
    this.comments = const [],
    this.attachedEvent,
    this.postType,
    this.discussionTitle,
    this.category,
    this.videoUrl,
  });

  bool checkIsOwner(String? currentUserId) {
    if (currentUserId != null && currentUserId.isNotEmpty) {
      if (userId == currentUserId) return true;
      return false;
    }
    return isOwner;
  }

  CommunityPostModel copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorTag,
    String? authorAvatar,
    bool? isVerified,
    String? timeAgo,
    String? content,
    List<String>? imageUrls,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isBookmarked,
    bool? isFollowing,
    bool? isRepostedByMe,
    bool? isOwner,
    String? visibility,
    String? community,
    String? repostedBy,
    String? repostCaption,
    String? originalPostId,
    String? reposterId,
    bool clearRepostInfo = false,
    String? location,
    String? linkUrl,
    String? linkPreviewTitle,
    String? linkPreviewDomain,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool? allowMultipleAnswers,
    List<CommentModel>? comments,
    EventModel? attachedEvent,
    String? postType,
    String? discussionTitle,
    String? category,
    String? videoUrl,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorTag: authorTag ?? this.authorTag,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      isVerified: isVerified ?? this.isVerified,
      timeAgo: timeAgo ?? this.timeAgo,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFollowing: isFollowing ?? this.isFollowing,
      isRepostedByMe: isRepostedByMe ?? (clearRepostInfo ? false : this.isRepostedByMe),
      isOwner: isOwner ?? this.isOwner,
      visibility: visibility ?? this.visibility,
      community: community ?? this.community,
      repostedBy: clearRepostInfo ? null : (repostedBy ?? this.repostedBy),
      repostCaption: clearRepostInfo ? null : (repostCaption ?? this.repostCaption),
      originalPostId: clearRepostInfo ? null : (originalPostId ?? this.originalPostId),
      reposterId: clearRepostInfo ? null : (reposterId ?? this.reposterId),
      location: location ?? this.location,
      linkUrl: linkUrl ?? this.linkUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDomain: linkPreviewDomain ?? this.linkPreviewDomain,
      pollQuestion: pollQuestion ?? this.pollQuestion,
      pollOptions: pollOptions ?? this.pollOptions,
      pollDuration: pollDuration ?? this.pollDuration,
      allowMultipleAnswers: allowMultipleAnswers ?? this.allowMultipleAnswers,
      comments: comments ?? this.comments,
      attachedEvent: attachedEvent ?? this.attachedEvent,
      postType: postType ?? this.postType,
      discussionTitle: discussionTitle ?? this.discussionTitle,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final authorObj = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : null;
    final rawAuthorName =
        authorObj?['fullName'] as String? ??
        json['authorName'] as String? ??
        json['username'] as String? ??
        'User';
    final rawAuthorTag = authorObj?['username'] != null
        ? '@${authorObj!['username']}'
        : (json['authorTag'] as String? ?? '@user');
    final rawAuthorAvatar =
        authorObj?['avatarUrl'] as String? ??
        json['authorAvatar'] as String? ??
        json['avatar'] as String? ??
        '';
    final userId =
        authorObj?['userId']?.toString() ??
        json['userId']?.toString() ??
        'user_1';

    final currentUserId = CurrentUser.id;
    final isMe = currentUserId.isNotEmpty &&
        (userId == currentUserId || authorObj?['userId']?.toString() == currentUserId);

    final authorName = (rawAuthorName.isNotEmpty && rawAuthorName != 'User')
        ? rawAuthorName
        : (isMe && CurrentUser.name.isNotEmpty && CurrentUser.name != 'Guest'
            ? CurrentUser.name
            : rawAuthorName);

    final authorTag = (rawAuthorTag.isNotEmpty && rawAuthorTag != '@user')
        ? rawAuthorTag
        : (isMe && CurrentUser.username.isNotEmpty
            ? '@${CurrentUser.username}'
            : rawAuthorTag);

    final authorAvatar = rawAuthorAvatar.isNotEmpty
        ? rawAuthorAvatar
        : (isMe && CurrentUser.avatarUrl?.isNotEmpty == true
            ? CurrentUser.avatarUrl!
            : rawAuthorAvatar);

    final isPostOwner = (json['isOwner'] as bool?) ??
        (json['mine'] as bool?) ??
        isMe;

    List<String> imagesList = [];
    if (json['imageUrls'] is List) {
      imagesList = (json['imageUrls'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['imageUrl'] != null &&
        (json['imageUrl'] as String).trim().isNotEmpty) {
      final raw = (json['imageUrl'] as String).trim();
      if (raw.startsWith('[') && raw.endsWith(']')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            imagesList = decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {
          imagesList = [raw];
        }
      } else if (raw.contains(',')) {
        imagesList = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        imagesList = [raw];
      }
    }

    EventModel? parsedEvent;
    if (json['attachedEvent'] is Map<String, dynamic>) {
      parsedEvent = EventModel.fromJson(json['attachedEvent'] as Map<String, dynamic>);
    } else if (json['event'] is Map<String, dynamic>) {
      parsedEvent = EventModel.fromJson(json['event'] as Map<String, dynamic>);
    } else if (json['eventId'] != null) {
      parsedEvent = EventModel.fromJson(json);
    }

    return CommunityPostModel(
      id: json['postId'] as String? ?? json['id'] as String? ?? json['discussionId'] as String? ?? '',
      userId: userId,
      authorName: authorName,
      authorTag: authorTag,
      authorAvatar: authorAvatar,
      isVerified:
          json['isVerified'] as bool? ?? json['verified'] as bool? ?? false,
      timeAgo: formatCommunityTimestamp(
        json['createdAt'] as String? ??
            json['timeAgo'] as String? ??
            'Just now',
      ),
      content:
          json['contentText'] as String? ??
          json['content'] as String? ??
          json['text'] as String? ??
          '',
      imageUrls: imagesList,
      likesCount:
          json['likeCount'] as int? ??
          json['likesCount'] as int? ??
          json['likes'] as int? ??
          json['reactionCount'] as int? ??
          0,
      commentsCount:
          json['commentCount'] as int? ??
          json['commentsCount'] as int? ??
          json['comments'] as int? ??
          0,
      sharesCount: json['sharesCount'] as int? ?? json['shares'] as int? ?? 0,
      isLiked: json['likedByMe'] as bool? ?? json['isLiked'] as bool? ?? json['reactedByMe'] as bool? ?? false,
      isBookmarked:
          json['savedByMe'] as bool? ?? json['isBookmarked'] as bool? ?? false,
      isFollowing:
          json['isFollowing'] as bool? ??
          json['following'] as bool? ??
          (authorObj?['isFollowing'] as bool?) ??
          (authorObj?['following'] as bool?) ??
          false,
      isRepostedByMe: json['isRepostedByMe'] as bool? ?? false,
      isOwner: isPostOwner,
      visibility: json['visibility'] as String? ?? 'Public',
      community: json['community'] as String? ?? 'All GenLink',
      repostedBy: json['repostedBy'] as String?,
      repostCaption: json['repostCaption'] as String?,
      originalPostId: json['originalPostId'] as String?,
      reposterId: json['reposterId'] as String?,
      postType: json['postType'] as String? ?? (parsedEvent != null ? 'event' : null),
      discussionTitle: json['discussionTitle'] as String? ?? json['title'] as String?,
      category: json['category'] as String?,
      // Step 3B-Frontend: read videoUrl — null-safe; returns null until backend supports it
      videoUrl: json['videoUrl'] as String?,
      attachedEvent: parsedEvent,
      comments:
          (json['commentsList'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': id,
      'userId': userId,
      'authorName': authorName,
      'authorTag': authorTag,
      'authorAvatar': authorAvatar,
      'verified': isVerified,
      'createdAt': timeAgo,
      'text': content,
      'images': imageUrls,
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.join(',') : null,
      'likes': likesCount,
      'comments': commentsCount,
      'shares': sharesCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'isFollowing': isFollowing,
      'isRepostedByMe': isRepostedByMe,
      'isOwner': isOwner,
      'visibility': visibility,
      'community': community,
      'repostedBy': repostedBy,
      'repostCaption': repostCaption,
      'originalPostId': originalPostId,
      'reposterId': reposterId,
      'postType': postType,
      'discussionTitle': discussionTitle,
      'category': category,
      'videoUrl': videoUrl,
      if (attachedEvent != null) 'attachedEvent': attachedEvent!.toJson(),
    };
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String authorId;
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  int likesCount;
  bool isLiked;
  final String? parentCommentId;
  final bool isOwner;
  final List<CommentModel> replies;

  /// Check whether the given [currentUserId] owns this comment using stable IDs.
  bool checkIsOwner(String? currentUserId) {
    if (authorId.isNotEmpty && currentUserId != null && currentUserId.isNotEmpty) {
      return authorId == currentUserId;
    }
    if (userId.isNotEmpty && currentUserId != null && currentUserId.isNotEmpty) {
      return userId == currentUserId;
    }
    return isOwner;
  }

  /// Whether the comment has been edited after creation.
  bool get isEdited {
    if (updatedAt == null || createdAt == null) return false;
    return updatedAt!.difference(createdAt!).inSeconds.abs() > 1;
  }

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    String? authorId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
    this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.parentCommentId,
    this.isOwner = false,
    this.replies = const [],
  }) : authorId = (authorId != null && authorId.isNotEmpty) ? authorId : userId;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final authorObj = json['author'] as Map<String, dynamic>?;
    final rawDate = json['createdAt'] as String? ?? json['timeAgo'] as String?;
    final rawUpdatedDate = json['updatedAt'] as String?;
    final parsedUtc = CommunityDateFormatter.parseToUtc(rawDate);
    final parsedUpdatedUtc = CommunityDateFormatter.parseToUtc(rawUpdatedDate);
    final formattedTime = formatCommunityTimestamp(parsedUtc ?? rawDate ?? 'Just now');

    final extractedAuthorId = authorObj?['id']?.toString() ??
        authorObj?['userId']?.toString() ??
        json['authorId']?.toString() ??
        json['userId']?.toString() ??
        '';

    final resolvedUserId = json['userId'] as String? ??
        authorObj?['userId'] as String? ??
        authorObj?['id'] as String? ??
        extractedAuthorId;

    return CommentModel(
      id: json['commentId'] as String? ?? json['id'] as String? ?? '',
      postId: json['postId'] as String? ??
          json['discussionId'] as String? ??
          '',
      userId: resolvedUserId,
      authorId: extractedAuthorId,
      userName: json['userName'] as String? ??
          authorObj?['fullName'] as String? ??
          authorObj?['username'] as String? ??
          'User',
      userAvatar: json['userAvatar'] as String? ??
          authorObj?['avatarUrl'] as String? ??
          '',
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      timeAgo: formattedTime.isNotEmpty ? formattedTime : 'Just now',
      createdAt: parsedUtc?.toLocal(),
      updatedAt: parsedUpdatedUtc?.toLocal(),
      likesCount: json['likeCount'] as int? ?? json['likesCount'] as int? ?? 0,
      isLiked: json['likedByMe'] as bool? ?? json['isLiked'] as bool? ?? false,
      parentCommentId: json['parentCommentId'] as String?,
      isOwner: json['mine'] as bool? ?? json['isOwner'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? userId,
    String? authorId,
    String? userName,
    String? userAvatar,
    String? text,
    String? timeAgo,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    bool? isLiked,
    String? parentCommentId,
    bool? isOwner,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      authorId: authorId ?? this.authorId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isOwner: isOwner ?? this.isOwner,
      replies: replies ?? this.replies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'authorId': authorId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'timeAgo': timeAgo,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
      'likesCount': likesCount,
      'isLiked': isLiked,
      'parentCommentId': parentCommentId,
      'isOwner': isOwner,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

class StoryModel {
  final String id;
  final String name;
  final String avatarText;
  final bool isUser;
  final bool hasActiveStory;
  final String? storyImage;

  StoryModel({
    required this.id,
    required this.name,
    required this.avatarText,
    this.isUser = false,
    this.hasActiveStory = true,
    this.storyImage,
  });
}

class RecommendedGroupModel {
  final String id;
  final String name;
  final String memberCount;
  final String iconText;
  bool isJoined;

  RecommendedGroupModel({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.iconText,
    this.isJoined = false,
  });
}

class SuggestedUserModel {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  bool isFollowing;

  SuggestedUserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    this.isFollowing = false,
  });
}
