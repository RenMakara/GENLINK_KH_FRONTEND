import 'dart:convert';
import 'community_models.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/utils/current_user.dart';

class PollOptionModel {
  final String id;
  final String text;
  int votes;
  bool isVoted;

  PollOptionModel({
    this.id = '',
    required this.text,
    this.votes = 0,
    this.isVoted = false,
  });

  PollOptionModel copyWith({
    String? id,
    String? text,
    int? votes,
    bool? isVoted,
  }) {
    return PollOptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
      isVoted: isVoted ?? this.isVoted,
    );
  }

  factory PollOptionModel.fromJson(
    Map<String, dynamic> json, {
    String? myOptionId,
  }) {
    final optionId =
        json['optionId']?.toString() ?? json['id']?.toString() ?? '';
    final rawVotes = json['voteCount'] ?? json['votes'];
    final votes = rawVotes is num ? rawVotes.toInt() : 0;
    final voted =
        json['isVoted'] as bool? ??
        (myOptionId != null && myOptionId.isNotEmpty && myOptionId == optionId);

    return PollOptionModel(
      id: optionId,
      text: json['text'] as String? ?? json['optionText'] as String? ?? '',
      votes: votes,
      isVoted: voted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'optionId': id,
    'text': text,
    'votes': votes,
    'voteCount': votes,
    'isVoted': isVoted,
  };
}

enum PostMediaType { image, video }

class PostMediaItem {
  final String url;
  final PostMediaType type;

  const PostMediaItem({required this.url, required this.type});

  bool get isVideo => type == PostMediaType.video;
  bool get isImage => type == PostMediaType.image;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostMediaItem &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          type == other.type;

  @override
  int get hashCode => Object.hash(url, type);

  @override
  String toString() => 'PostMediaItem(url: $url, type: $type)';
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
  final String? pollId;
  final String? pollQuestion;
  final List<PollOptionModel>? pollOptions;
  final String? pollDuration;
  final bool allowMultipleAnswers;
  final bool hideResultsUntilVote;
  final int pollTotalVotes;
  final bool hasVoted;
  final String? myOptionId;
  final List<CommentModel> comments;
  final EventModel? attachedEvent;
  final String? eventId;
  final String? postType;
  final String? discussionTitle;
  final String? category;
  final String? videoUrl;
  final String? videoMediaId;
  final List<String> imageMediaIds;
  final List<String>? mediaUrls;

  static bool isVideoUrl(String url) {
    final clean = url.trim().toLowerCase().split('?').first.split('#').first;
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.avi') ||
        clean.endsWith('.mkv') ||
        clean.endsWith('.3gp') ||
        clean.endsWith('.m4v');
  }

  bool isVideoItem(String url) {
    final trimmed = url.trim();
    if (videoUrl != null &&
        videoUrl!.trim().isNotEmpty &&
        trimmed == videoUrl!.trim()) {
      return true;
    }
    return isVideoUrl(trimmed);
  }

  /// Returns the ordered list of media items (both images and videos) for this post.
  List<PostMediaItem> get mediaItems {
    final urls = <String>[];

    if (mediaUrls != null && mediaUrls!.isNotEmpty) {
      urls.addAll(mediaUrls!.where((u) => u.trim().isNotEmpty));
    } else {
      final hasVideo = videoUrl != null && videoUrl!.trim().isNotEmpty;
      final trimmedVideo = hasVideo ? videoUrl!.trim() : null;

      final normalizedImages = imageUrls
          .map((u) => u.trim())
          .where((u) => u.isNotEmpty)
          .toList();

      if (trimmedVideo != null && normalizedImages.contains(trimmedVideo)) {
        urls.addAll(normalizedImages);
      } else if (trimmedVideo != null && normalizedImages.isNotEmpty) {
        urls.add(trimmedVideo);
        urls.addAll(normalizedImages);
      } else if (trimmedVideo != null) {
        urls.add(trimmedVideo);
      } else {
        urls.addAll(normalizedImages);
      }
    }

    return urls.map((url) {
      final isVid = isVideoItem(url);
      return PostMediaItem(
        url: url,
        type: isVid ? PostMediaType.video : PostMediaType.image,
      );
    }).toList();
  }

  bool get isVideoPost =>
      (videoUrl != null && videoUrl!.isNotEmpty) ||
      mediaItems.any((m) => m.isVideo);

  bool get isMixedMediaPost =>
      mediaItems.any((m) => m.isVideo) && mediaItems.any((m) => m.isImage);

  bool get isEventPost =>
      (postType?.toLowerCase() == 'event') ||
      (postType?.toLowerCase() == 'announcement') ||
      attachedEvent != null ||
      (eventId != null && eventId!.isNotEmpty);

  bool get isAnnouncementPost => postType?.toLowerCase() == 'announcement';

  bool get isPollPost =>
      (postType?.toUpperCase() == 'POLL') ||
      (pollQuestion != null && (pollOptions?.isNotEmpty ?? false));

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
    this.pollId,
    this.pollQuestion,
    this.pollOptions,
    this.pollDuration,
    this.allowMultipleAnswers = false,
    this.hideResultsUntilVote = true,
    this.pollTotalVotes = 0,
    this.hasVoted = false,
    this.myOptionId,
    this.comments = const [],
    this.attachedEvent,
    this.eventId,
    this.postType,
    this.discussionTitle,
    this.category,
    this.videoUrl,
    this.videoMediaId,
    this.imageMediaIds = const [],
    this.mediaUrls,
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
    String? pollId,
    String? pollQuestion,
    List<PollOptionModel>? pollOptions,
    String? pollDuration,
    bool? allowMultipleAnswers,
    int? pollTotalVotes,
    bool? hasVoted,
    String? myOptionId,
    List<CommentModel>? comments,
    EventModel? attachedEvent,
    String? eventId,
    String? postType,
    String? discussionTitle,
    String? category,
    String? videoUrl,
    List<String>? mediaUrls,
    String? videoMediaId,
    List<String>? imageMediaIds,
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
      isRepostedByMe:
          isRepostedByMe ?? (clearRepostInfo ? false : this.isRepostedByMe),
      isOwner: isOwner ?? this.isOwner,
      visibility: visibility ?? this.visibility,
      community: community ?? this.community,
      repostedBy: clearRepostInfo ? null : (repostedBy ?? this.repostedBy),
      repostCaption: clearRepostInfo
          ? null
          : (repostCaption ?? this.repostCaption),
      originalPostId: clearRepostInfo
          ? null
          : (originalPostId ?? this.originalPostId),
      reposterId: clearRepostInfo ? null : (reposterId ?? this.reposterId),
      location: location ?? this.location,
      linkUrl: linkUrl ?? this.linkUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDomain: linkPreviewDomain ?? this.linkPreviewDomain,
      pollId: pollId ?? this.pollId,
      pollQuestion: pollQuestion ?? this.pollQuestion,
      pollOptions: pollOptions ?? this.pollOptions,
      pollDuration: pollDuration ?? this.pollDuration,
      allowMultipleAnswers: allowMultipleAnswers ?? this.allowMultipleAnswers,
      pollTotalVotes: pollTotalVotes ?? this.pollTotalVotes,
      hasVoted: hasVoted ?? this.hasVoted,
      myOptionId: myOptionId ?? this.myOptionId,
      comments: comments ?? this.comments,
      attachedEvent: attachedEvent ?? this.attachedEvent,
      eventId: eventId ?? this.eventId,
      postType: postType ?? this.postType,
      discussionTitle: discussionTitle ?? this.discussionTitle,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      videoMediaId: videoMediaId ?? this.videoMediaId,
      imageMediaIds: imageMediaIds ?? this.imageMediaIds,
      mediaUrls: mediaUrls ?? this.mediaUrls,
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
    final isMe =
        currentUserId.isNotEmpty &&
        (userId == currentUserId ||
            authorObj?['userId']?.toString() == currentUserId);

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

    final isPostOwner =
        (json['isOwner'] as bool?) ?? (json['mine'] as bool?) ?? isMe;

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

    List<String>? parsedMediaUrls;
    if (json['mediaUrls'] is List) {
      parsedMediaUrls = (json['mediaUrls'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['media'] is List) {
      parsedMediaUrls = (json['media'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['orderedMedia'] is List) {
      parsedMediaUrls = (json['orderedMedia'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['mediaUrls'] is String &&
        (json['mediaUrls'] as String).trim().isNotEmpty) {
      final raw = (json['mediaUrls'] as String).trim();
      if (raw.startsWith('[') && raw.endsWith(']')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            parsedMediaUrls = decoded
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      } else if (raw.contains(',')) {
        parsedMediaUrls = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        parsedMediaUrls = [raw];
      }
    }

    String? parsedVideoUrl = json['videoUrl'] as String?;
    if (parsedVideoUrl == null || parsedVideoUrl.trim().isEmpty) {
      if (parsedMediaUrls != null) {
        for (final u in parsedMediaUrls) {
          if (CommunityPostModel.isVideoUrl(u)) {
            parsedVideoUrl = u;
            break;
          }
        }
      }
      if (parsedVideoUrl == null) {
        for (final u in imagesList) {
          if (CommunityPostModel.isVideoUrl(u)) {
            parsedVideoUrl = u;
            break;
          }
        }
      }
    }

    if (parsedMediaUrls == null) {
      final hasVideo =
          parsedVideoUrl != null && parsedVideoUrl.trim().isNotEmpty;
      final trimmedVid = hasVideo ? parsedVideoUrl.trim() : null;
      if (trimmedVid != null && imagesList.contains(trimmedVid)) {
        parsedMediaUrls = List.from(imagesList);
      } else if (trimmedVid != null && imagesList.isNotEmpty) {
        parsedMediaUrls = [trimmedVid, ...imagesList];
      } else if (trimmedVid != null) {
        parsedMediaUrls = [trimmedVid];
      } else if (imagesList.isNotEmpty) {
        parsedMediaUrls = List.from(imagesList);
      }
    }

    final rawEventId = json['eventId']?.toString();
    EventModel? parsedEvent;
    if (json['attachedEvent'] is Map<String, dynamic>) {
      parsedEvent = EventModel.fromJson(
        json['attachedEvent'] as Map<String, dynamic>,
      );
    } else if (json['event'] is Map<String, dynamic>) {
      parsedEvent = EventModel.fromJson(json['event'] as Map<String, dynamic>);
    } else if (json['eventId'] is Map<String, dynamic>) {
      parsedEvent = EventModel.fromJson(
        json['eventId'] as Map<String, dynamic>,
      );
    } else if (json['eventId'] != null && json['title'] != null) {
      parsedEvent = EventModel.fromJson(json);
    }

    String? parsedPollQuestion;
    List<PollOptionModel>? parsedPollOptions;
    String? parsedPollId;
    String? parsedPollDuration;
    int parsedTotalVotes = 0;
    bool parsedHasVoted = false;
    String? parsedMyOptionId;

    if (json['poll'] is Map<String, dynamic>) {
      final pollJson = json['poll'] as Map<String, dynamic>;
      parsedPollId =
          pollJson['pollId']?.toString() ?? pollJson['id']?.toString();
      final durationDays = (pollJson['durationDays'] as num?)?.toInt();
      parsedPollDuration = pollJson['durationDays'] == null
          ? null
          : '$durationDays ${durationDays == 1 ? 'Day' : 'Days'}';
      parsedPollQuestion = pollJson['question'] as String?;
      final rawTotalVotes = pollJson['totalVotes'];
      parsedTotalVotes = rawTotalVotes is num ? rawTotalVotes.toInt() : 0;
      parsedHasVoted = pollJson['hasVoted'] as bool? ?? false;
      parsedMyOptionId = pollJson['myOptionId']?.toString();

      if (pollJson['options'] is List) {
        parsedPollOptions = (pollJson['options'] as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (option) => PollOptionModel.fromJson(
                option,
                myOptionId: parsedMyOptionId,
              ),
            )
            .toList();
      }
    } else if (json['pollQuestion'] != null || json['pollOptions'] != null) {
      parsedPollQuestion = json['pollQuestion'] as String?;
      parsedPollId = json['pollId']?.toString();
      final rawTotalVotes = json['pollTotalVotes'];
      parsedTotalVotes = rawTotalVotes is num ? rawTotalVotes.toInt() : 0;
      parsedHasVoted = json['hasVoted'] as bool? ?? false;
      parsedMyOptionId = json['myOptionId']?.toString();

      if (json['pollOptions'] is List) {
        parsedPollOptions = (json['pollOptions'] as List).map((option) {
          if (option is Map<String, dynamic>) {
            return PollOptionModel.fromJson(
              option,
              myOptionId: parsedMyOptionId,
            );
          }
          if (option is PollOptionModel) return option;
          return PollOptionModel(text: option.toString());
        }).toList();
      }
    }

    if (parsedPollOptions != null && parsedTotalVotes == 0) {
      parsedTotalVotes = parsedPollOptions.fold<int>(
        0,
        (sum, option) => sum + option.votes,
      );
    }
    if (parsedPollOptions != null && !parsedHasVoted) {
      parsedHasVoted = parsedPollOptions.any((option) => option.isVoted);
    }

    return CommunityPostModel(
      id:
          json['postId'] as String? ??
          json['id'] as String? ??
          json['discussionId'] as String? ??
          '',
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
          (json['likeCount'] as num?)?.toInt() ??
          (json['likesCount'] as num?)?.toInt() ??
          (json['likes'] as num?)?.toInt() ??
          (json['reactionCount'] as num?)?.toInt() ??
          0,
      commentsCount:
          (json['commentCount'] as num?)?.toInt() ??
          (json['commentsCount'] as num?)?.toInt() ??
          (json['comments'] as num?)?.toInt() ??
          0,
      sharesCount:
          (json['repostCount'] as num?)?.toInt() ??
          (json['repostsCount'] as num?)?.toInt() ??
          (json['shareCount'] as num?)?.toInt() ??
          (json['sharesCount'] as num?)?.toInt() ??
          (json['shares'] as num?)?.toInt() ??
          ((json['repostedByMe'] == true || json['isRepostedByMe'] == true)
              ? 1
              : 0),
      isLiked:
          json['likedByMe'] as bool? ??
          json['isLiked'] as bool? ??
          json['reactedByMe'] as bool? ??
          false,
      isBookmarked:
          json['savedByMe'] as bool? ?? json['isBookmarked'] as bool? ?? false,
      isFollowing:
          json['isFollowing'] as bool? ??
          json['following'] as bool? ??
          (authorObj?['isFollowing'] as bool?) ??
          (authorObj?['following'] as bool?) ??
          false,
      isRepostedByMe:
          json['repostedByMe'] as bool? ??
          json['isRepostedByMe'] as bool? ??
          false,
      isOwner: isPostOwner,
      visibility: json['visibility'] as String? ?? 'Public',
      community: json['community'] as String? ?? 'All GenLink',
      repostedBy: json['repostedBy'] as String?,
      repostCaption: json['repostCaption'] as String?,
      originalPostId:
          json['originalPostId']?.toString() ??
          ((json['repostedByMe'] == true || json['isRepostedByMe'] == true)
              ? (json['postId']?.toString() ?? json['id']?.toString())
              : null),
      reposterId: json['reposterId']?.toString(),
      postType:
          json['postType'] as String? ??
          (parsedEvent != null
              ? 'event'
              : (parsedPollQuestion != null ? 'POLL' : null)),
      discussionTitle:
          json['discussionTitle'] as String? ?? json['title'] as String?,
      category: json['category'] as String?,
      videoUrl: parsedVideoUrl,
      mediaUrls: parsedMediaUrls,
      attachedEvent: parsedEvent,
      eventId: rawEventId ?? parsedEvent?.id,
      pollId: parsedPollId,
      pollQuestion: parsedPollQuestion,
      pollOptions: parsedPollOptions,
      pollDuration: parsedPollDuration ?? json['pollDuration'] as String?,
      pollTotalVotes: parsedTotalVotes,
      hasVoted: parsedHasVoted,
      myOptionId: parsedMyOptionId,
      location: json['location'] as String? ?? json['locationName'] as String?,
      linkUrl: json['linkUrl'] as String?,
      linkPreviewTitle: json['linkPreviewTitle'] as String?,
      linkPreviewDomain: json['linkPreviewDomain'] as String?,
      videoMediaId: json['videoMediaId']?.toString(),
      imageMediaIds:
          (json['imageMediaIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
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
      'likeCount': likesCount,
      'comments': commentsCount,
      'commentCount': commentsCount,
      'shares': sharesCount,
      'shareCount': sharesCount,
      'sharesCount': sharesCount,
      'repostCount': sharesCount,
      'repostsCount': sharesCount,
      'isLiked': isLiked,
      'likedByMe': isLiked,
      'isBookmarked': isBookmarked,
      'savedByMe': isBookmarked,
      'isFollowing': isFollowing,
      'isRepostedByMe': isRepostedByMe,
      'repostedByMe': isRepostedByMe,
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
      if (mediaUrls != null) 'mediaUrls': mediaUrls,
      'eventId': eventId,
      if (linkUrl != null) 'linkUrl': linkUrl,
      if (linkPreviewTitle != null) 'linkPreviewTitle': linkPreviewTitle,
      if (linkPreviewDomain != null) 'linkPreviewDomain': linkPreviewDomain,
      'imageMediaIds': imageMediaIds,
      if (videoMediaId != null) 'videoMediaId': videoMediaId,
      if (location != null) 'location': location,
      if (attachedEvent != null) 'attachedEvent': attachedEvent!.toJson(),
      if (pollQuestion != null) ...{
        'pollId': pollId,
        'pollQuestion': pollQuestion,
        'pollTotalVotes': pollTotalVotes,
        'hasVoted': hasVoted,
        'myOptionId': myOptionId,
        if (pollOptions != null)
          'pollOptions': pollOptions!.map((option) => option.toJson()).toList(),
      },
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

  bool checkIsOwner(String? currentUserId) {
    if (authorId.isNotEmpty &&
        currentUserId != null &&
        currentUserId.isNotEmpty) {
      return authorId == currentUserId;
    }
    if (userId.isNotEmpty &&
        currentUserId != null &&
        currentUserId.isNotEmpty) {
      return userId == currentUserId;
    }
    return isOwner;
  }

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
    final formattedTime = formatCommunityTimestamp(
      parsedUtc ?? rawDate ?? 'Just now',
    );

    final extractedAuthorId =
        authorObj?['id']?.toString() ??
        authorObj?['userId']?.toString() ??
        json['authorId']?.toString() ??
        json['userId']?.toString() ??
        '';
    final resolvedUserId =
        json['userId'] as String? ??
        authorObj?['userId'] as String? ??
        authorObj?['id'] as String? ??
        extractedAuthorId;

    return CommentModel(
      id: json['commentId'] as String? ?? json['id'] as String? ?? '',
      postId:
          json['postId'] as String? ?? json['discussionId'] as String? ?? '',
      userId: resolvedUserId,
      authorId: extractedAuthorId,
      userName:
          json['userName'] as String? ??
          authorObj?['fullName'] as String? ??
          authorObj?['username'] as String? ??
          'User',
      userAvatar:
          json['userAvatar'] as String? ??
          authorObj?['avatarUrl'] as String? ??
          '',
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      timeAgo: formattedTime.isNotEmpty ? formattedTime : 'Just now',
      createdAt: parsedUtc?.toLocal(),
      updatedAt: parsedUpdatedUtc?.toLocal(),
      likesCount: json['likeCount'] as int? ?? json['likesCount'] as int? ?? 0,
      isLiked: json['likedByMe'] as bool? ?? json['isLiked'] as bool? ?? false,
      parentCommentId:
          json['parentCommentId']?.toString() ??
          json['parent_comment_id']?.toString() ??
          json['parentId']?.toString(),
      isOwner: json['mine'] as bool? ?? json['isOwner'] as bool? ?? false,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map(
                (reply) => CommentModel.fromJson(reply as Map<String, dynamic>),
              )
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
      'replies': replies.map((reply) => reply.toJson()).toList(),
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
