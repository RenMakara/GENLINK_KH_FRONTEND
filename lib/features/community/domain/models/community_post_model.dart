import 'community_models.dart';

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
  int get repostsCount => sharesCount;
  bool isLiked;
  bool isBookmarked;
  bool isFollowing;
  final bool isOwner;
  final String visibility;
  final String community;
  final String? repostedBy;
  final String? repostCaption;
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
    this.isOwner = false,
    this.visibility = 'Public',
    this.community = 'All GenLink',
    this.repostedBy,
    this.repostCaption,
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
  });

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
    bool? isOwner,
    String? visibility,
    String? community,
    String? repostedBy,
    String? repostCaption,
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
      isOwner: isOwner ?? this.isOwner,
      visibility: visibility ?? this.visibility,
      community: community ?? this.community,
      repostedBy: repostedBy ?? this.repostedBy,
      repostCaption: repostCaption ?? this.repostCaption,
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
    );
  }

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    // Parse Spring Boot AuthorSummary object or fallback flat properties
    final authorObj = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : null;
    final authorName =
        authorObj?['fullName'] as String? ??
        json['authorName'] as String? ??
        json['username'] as String? ??
        'User';
    final authorTag = authorObj?['username'] != null
        ? '@${authorObj!['username']}'
        : (json['authorTag'] as String? ?? '@user');
    final authorAvatar =
        authorObj?['avatarUrl'] as String? ??
        json['authorAvatar'] as String? ??
        json['avatar'] as String? ??
        '';
    final userId =
        authorObj?['userId'] as String? ??
        json['userId'] as String? ??
        'user_1';

    // Parse image list or single imageUrl
    List<String> imagesList = [];
    if (json['imageUrls'] is List) {
      imagesList = (json['imageUrls'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['images'] is List) {
      imagesList = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['imageUrl'] != null &&
        (json['imageUrl'] as String).isNotEmpty) {
      imagesList = [json['imageUrl'] as String];
    }

    return CommunityPostModel(
      id: json['postId'] as String? ?? json['id'] as String? ?? '',
      userId: userId,
      authorName: authorName,
      authorTag: authorTag,
      authorAvatar: authorAvatar,
      isVerified:
          json['isVerified'] as bool? ?? json['verified'] as bool? ?? false,
      timeAgo:
          json['timeAgo'] as String? ??
          json['createdAt'] as String? ??
          'Just now',
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
          0,
      commentsCount:
          json['commentCount'] as int? ??
          json['commentsCount'] as int? ??
          json['comments'] as int? ??
          0,
      sharesCount: json['sharesCount'] as int? ?? json['shares'] as int? ?? 0,
      isLiked: json['likedByMe'] as bool? ?? json['isLiked'] as bool? ?? false,
      isBookmarked:
          json['savedByMe'] as bool? ?? json['isBookmarked'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'Public',
      community: json['community'] as String? ?? 'All GenLink',
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
      'likes': likesCount,
      'comments': commentsCount,
      'shares': sharesCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'isOwner': isOwner,
      'visibility': visibility,
      'community': community,
    };
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;
  int likesCount;
  bool isLiked;
  final String? parentCommentId;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
    this.likesCount = 0,
    this.isLiked = false,
    this.parentCommentId,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'User',
      userAvatar: json['userAvatar'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? 'Just now',
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      parentCommentId: json['parentCommentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'timeAgo': timeAgo,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'parentCommentId': parentCommentId,
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
