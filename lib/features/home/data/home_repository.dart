import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/entities/home_entity.dart';

/// Contract for the home dashboard data.
abstract class HomeRepository {
  Future<HomeEntity> getHome();
}

/// Fetches and maps `GET /api/v1/mobile/home`.
///
/// Kept as a single file (contract + impl + mapper) because home is a
/// read-only aggregate: there is exactly one call and no domain logic.
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<HomeEntity> getHome() {
    return _client.get(
      ApiEndpoints.mobileHome,
      parse: (data) => _mapHome(ApiClient.asMap(data)),
    );
  }

  static HomeEntity _mapHome(Map<String, dynamic> json) {
    return HomeEntity(
      user: _mapUser(_map(json['user'])),
      todayProgress: _mapProgress(_map(json['todayProgress'])),
      dailyChallenge: json['dailyChallenge'] == null
          ? null
          : _mapChallenge(_map(json['dailyChallenge'])),
      financeSnapshot: json['financeSnapshot'] == null
          ? null
          : _mapFinance(_map(json['financeSnapshot'])),
      upcomingEvent: json['upcomingEvent'] == null
          ? null
          : _mapEvent(_map(json['upcomingEvent'])),
      recommendedCommunities:
          ApiClient.asList(json['recommendedCommunities'], _mapCommunity),
      dailyMotivation: json['dailyMotivation'] == null
          ? null
          : _mapMotivation(_map(json['dailyMotivation'])),
      feedPreview: ApiClient.asList(json['feedPreview'], _mapFeed),
    );
  }

  static HomeUser _mapUser(Map<String, dynamic> json) => HomeUser(
        userId: json['userId'] as String? ?? '',
        fullName: json['fullName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        level: (json['level'] as num?)?.toInt() ?? 1,
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      );

  static TodayProgress _mapProgress(Map<String, dynamic> json) =>
      TodayProgress(
        habitsCompletedToday:
            (json['habitsCompletedToday'] as num?)?.toInt() ?? 0,
        habitsTotal: (json['habitsTotal'] as num?)?.toInt() ?? 0,
        tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
        tasksTotal: (json['tasksTotal'] as num?)?.toInt() ?? 0,
      );

  static ChallengePreview _mapChallenge(Map<String, dynamic> json) =>
      ChallengePreview(
        challengeId: json['challengeId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        xpReward: (json['xpReward'] as num?)?.toInt(),
        deadline: json['deadline'] as String?,
      );

  static FinanceSnapshot _mapFinance(Map<String, dynamic> json) =>
      FinanceSnapshot(
        totalBudget: (json['totalBudget'] as num?)?.toDouble(),
        spentAmount: (json['spentAmount'] as num?)?.toDouble(),
        remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
        budgetStatus: json['budgetStatus'] as String?,
        savingTarget: (json['savingTarget'] as num?)?.toDouble(),
        savingCurrent: (json['savingCurrent'] as num?)?.toDouble(),
      );

  static UpcomingEvent _mapEvent(Map<String, dynamic> json) => UpcomingEvent(
        eventId: json['eventId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        dateTime: json['dateTime'] as String?,
        locationName: json['locationName'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
      );

  static CommunitySuggestion _mapCommunity(Map<String, dynamic> json) =>
      CommunitySuggestion(
        communityId: json['communityId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String?,
        category: json['category'] as String?,
        memberCount: (json['memberCount'] as num?)?.toInt(),
        avatarUrl: json['avatarUrl'] as String?,
      );

  static MotivationCard _mapMotivation(Map<String, dynamic> json) =>
      MotivationCard(
        motivationId: json['motivationId'] as String? ?? '',
        title: json['title'] as String?,
        content: json['content'] as String?,
      );

  static FeedPreview _mapFeed(Map<String, dynamic> json) => FeedPreview(
        postId: json['postId'] as String? ?? '',
        authorName: json['authorName'] as String?,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        contentText: json['contentText'] as String?,
        imageUrl: json['imageUrl'] as String?,
        likeCount: (json['likeCount'] as num?)?.toInt(),
        createdAt: json['createdAt'] as String?,
      );

  static Map<String, dynamic> _map(dynamic raw) =>
      (raw as Map?)?.cast<String, dynamic>() ?? const {};
}
