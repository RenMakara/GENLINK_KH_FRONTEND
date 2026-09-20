import 'package:get/get.dart';
import 'community_models.dart';
import 'community_post_model.dart';

enum SearchCategory {
  all,
  people,
  posts,
  events,
  forum,
  media;

  String get label {
    switch (this) {
      case SearchCategory.all:
        return 'community.searchAll'.tr;
      case SearchCategory.people:
        return 'community.searchPeople'.tr;
      case SearchCategory.posts:
        return 'community.searchPosts'.tr;
      case SearchCategory.events:
        return 'community.searchEvents'.tr;
      case SearchCategory.forum:
        return 'community.searchForum'.tr;
      case SearchCategory.media:
        return 'community.searchMedia'.tr;
    }
  }

  bool get isSupported {
    switch (this) {
      case SearchCategory.all:
      case SearchCategory.people:
      case SearchCategory.posts:
      case SearchCategory.events:
      case SearchCategory.forum:
        return true;
      case SearchCategory.media:
        return false;
    }
  }

  String toApiType() {
    switch (this) {
      case SearchCategory.all:
        return 'ALL';
      case SearchCategory.people:
        return 'PEOPLE';
      case SearchCategory.posts:
        return 'POSTS';
      case SearchCategory.events:
        return 'EVENTS';
      case SearchCategory.forum:
        return 'FORUM';
      case SearchCategory.media:
        return 'MEDIA';
    }
  }

  static SearchCategory fromApiType(String? type) {
    if (type == null) return SearchCategory.all;
    switch (type.toUpperCase()) {
      case 'PEOPLE':
        return SearchCategory.people;
      case 'POSTS':
        return SearchCategory.posts;
      case 'EVENTS':
        return SearchCategory.events;
      case 'FORUM':
        return SearchCategory.forum;
      case 'MEDIA':
        return SearchCategory.media;
      default:
        return SearchCategory.all;
    }
  }
}

class UserSearchResultModel {
  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? universityName;
  final String? bio;
  final String? workStatus;
  final int level;
  final int totalXp;

  const UserSearchResultModel({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.universityName,
    this.bio,
    this.workStatus,
    this.level = 1,
    this.totalXp = 0,
  });

  factory UserSearchResultModel.fromJson(Map<String, dynamic> json) {
    return UserSearchResultModel(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      avatarUrl: json['avatarUrl'] as String?,
      universityName: json['universityName'] as String?,
      bio: json['bio'] as String?,
      workStatus: json['workStatus'] as String?,
      level: json['level'] is num ? (json['level'] as num).toInt() : 1,
      totalXp: json['totalXp'] is num ? (json['totalXp'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'fullName': fullName,
    'avatarUrl': avatarUrl,
    'universityName': universityName,
    'bio': bio,
    'workStatus': workStatus,
    'level': level,
    'totalXp': totalXp,
  };
}

class CombinedSearchResults {
  final String query;
  final SearchCategory category;
  final List<UserSearchResultModel> people;
  final List<CommunityPostModel> posts;
  final List<EventModel> events;
  final List<ForumTopicModel> discussions;
  final int totalPeople;
  final int totalPosts;
  final int totalEvents;
  final int totalDiscussions;

  const CombinedSearchResults({
    required this.query,
    this.category = SearchCategory.all,
    this.people = const [],
    this.posts = const [],
    this.events = const [],
    this.discussions = const [],
    this.totalPeople = 0,
    this.totalPosts = 0,
    this.totalEvents = 0,
    this.totalDiscussions = 0,
  });

  bool get isEmpty =>
      people.isEmpty && posts.isEmpty && events.isEmpty && discussions.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalResults =>
      people.length + posts.length + events.length + discussions.length;

  factory CombinedSearchResults.fromJson(
    Map<String, dynamic> json, {
    String? query,
    SearchCategory? category,
  }) {
    final rawPeople = json['people'] as List<dynamic>? ?? [];
    final rawPosts = json['posts'] as List<dynamic>? ?? [];
    final rawEvents = json['events'] as List<dynamic>? ?? [];
    final rawDiscussions = json['discussions'] as List<dynamic>? ?? [];

    return CombinedSearchResults(
      query: query ?? (json['query'] as String? ?? ''),
      category: category ?? SearchCategory.fromApiType(json['category'] as String?),
      people: rawPeople
          .whereType<Map<String, dynamic>>()
          .map(UserSearchResultModel.fromJson)
          .toList(),
      posts: rawPosts
          .whereType<Map<String, dynamic>>()
          .map(CommunityPostModel.fromJson)
          .toList(),
      events: rawEvents
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList(),
      discussions: rawDiscussions
          .whereType<Map<String, dynamic>>()
          .map(ForumTopicModel.fromJson)
          .toList(),
      totalPeople: json['totalPeople'] is int ? json['totalPeople'] as int : rawPeople.length,
      totalPosts: json['totalPosts'] is int ? json['totalPosts'] as int : rawPosts.length,
      totalEvents: json['totalEvents'] is int ? json['totalEvents'] as int : rawEvents.length,
      totalDiscussions: json['totalDiscussions'] is int
          ? json['totalDiscussions'] as int
          : rawDiscussions.length,
    );
  }
}
