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
  });

  /// Evaluates whether the given user ID matches this post's author ID.
  /// Falls back to [isOwner] flag when [currentUserId] is not provided.
  bool checkIsOwner(String? currentUserId) {
    if (currentUserId != null && currentUserId.isNotEmpty) {
      if (userId == currentUserId) return true;
      if (isOwner &&
          (userId == 'user_me' ||
              userId == 'current_user' ||
              userId == 'demo_user_1')) {
        return true;
      }
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
      isFollowing:
          json['isFollowing'] as bool? ??
          json['following'] as bool? ??
          (authorObj?['isFollowing'] as bool?) ??
          (authorObj?['following'] as bool?) ??
          false,
      isRepostedByMe: json['isRepostedByMe'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'Public',
      community: json['community'] as String? ?? 'All GenLink',
      repostedBy: json['repostedBy'] as String?,
      repostCaption: json['repostCaption'] as String?,
      originalPostId: json['originalPostId'] as String?,
      reposterId: json['reposterId'] as String?,
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
      'isFollowing': isFollowing,
      'isRepostedByMe': isRepostedByMe,
      'isOwner': isOwner,
      'visibility': visibility,
      'community': community,
      'repostedBy': repostedBy,
      'repostCaption': repostCaption,
      'originalPostId': originalPostId,
      'reposterId': reposterId,
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
    final authorObj = json['author'] as Map<String, dynamic>?;
    return CommentModel(
      id: json['commentId'] as String? ?? json['id'] as String? ?? '',
      postId: json['postId'] as String? ??
          json['discussionId'] as String? ??
          '',
      userId: json['userId'] as String? ??
          authorObj?['userId'] as String? ??
          '',
      userName: json['userName'] as String? ??
          authorObj?['fullName'] as String? ??
          authorObj?['username'] as String? ??
          'User',
      userAvatar: json['userAvatar'] as String? ??
          authorObj?['avatarUrl'] as String? ??
          '',
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? 'Just now',
      likesCount: json['likeCount'] as int? ?? json['likesCount'] as int? ?? 0,
      isLiked: json['likedByMe'] as bool? ?? json['isLiked'] as bool? ?? false,
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
