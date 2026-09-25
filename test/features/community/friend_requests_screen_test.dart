import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/screens/friend_requests_screen.dart';

class FakeCommunityRepository implements CommunityRepository {
  List<FollowUserModel> followersToReturn = [];
  List<FollowUserModel> followingToReturn = [];
  List<FollowUserModel> pendingRequestsToReturn = [];

  final List<String> followedUsers = [];
  final List<String> unfollowedUsers = [];
  final List<String> rejectedUsers = [];

  @override
  Future<List<FollowUserModel>> getFollowers(String userId,
      {int page = 0, int size = 50}) async {
    return followersToReturn;
  }

  @override
  Future<List<FollowUserModel>> getFollowing(String userId,
      {int page = 0, int size = 50}) async {
    return followingToReturn;
  }

  @override
  Future<List<FollowUserModel>> getPendingFollowRequests(
      {int page = 0, int size = 50}) async {
    return pendingRequestsToReturn;
  }

  @override
  Future<bool> followUser(String userId) async {
    followedUsers.add(userId);
    return true;
  }

  @override
  Future<bool> unfollowUser(String userId) async {
    unfollowedUsers.add(userId);
    return true;
  }

  @override
  Future<bool> rejectFollowRequest(String followerUserId) async {
    rejectedUsers.add(followerUserId);
    return true;
  }

  @override
  Future<bool> acceptFollowRequest(String followerUserId) async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeCommunityRepository fakeRepo;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    fakeRepo = FakeCommunityRepository();
  });

  tearDown(() {
    Get.reset();
  });

  Widget createWidgetUnderTest({String? highlightUserId}) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: FriendRequestsScreen(
        repository: fakeRepo,
        currentUserId: 'test-user-id',
        highlightUserId: highlightUserId,
      ),
    );
  }

  testWidgets(
      'renders Followers header with count badge and items with Follow Back / Following',
      (tester) async {
    fakeRepo.followersToReturn = [
      FollowUserModel(
        userId: 'u1',
        fullName: 'Lina Cambodia',
        username: 'lina.cambodia',
        avatarUrl: null,
        isFollowingBack: false,
      ),
      FollowUserModel(
        userId: 'u2',
        fullName: 'Sokha Rith',
        username: 'sokha_rith',
        avatarUrl: null,
        isFollowingBack: true,
      ),
    ];
    fakeRepo.followingToReturn = [
      FollowUserModel(
        userId: 'u2',
        fullName: 'Sokha Rith',
        username: 'sokha_rith',
      ),
    ];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify header title is "Followers" (not "Friend Requests")
    expect(find.text('Followers'), findsOneWidget);
    // Verify count badge shows 2
    expect(find.text('2'), findsOneWidget);

    // Verify user names
    expect(find.text('Lina Cambodia'), findsOneWidget);
    expect(find.text('Sokha Rith'), findsOneWidget);

    // Subtitles:
    expect(find.text('Follows you'), findsOneWidget);
    expect(find.text('You follow each other'), findsOneWidget);

    // Lina is not followed back, so button should show "Follow Back"
    expect(find.widgetWithText(ElevatedButton, 'Follow Back'), findsOneWidget);

    // Sokha is already followed back, so button should show "Following"
    expect(find.widgetWithText(OutlinedButton, 'Following'), findsOneWidget);

    // Verify "Remove" secondary actions exist
    expect(find.widgetWithText(OutlinedButton, 'Remove'), findsNWidgets(2));
  });

  testWidgets('tapping Follow Back toggles to Following and calls repository',
      (tester) async {
    fakeRepo.followersToReturn = [
      FollowUserModel(
        userId: 'u1',
        fullName: 'Lina Cambodia',
        username: 'lina.cambodia',
        isFollowingBack: false,
      ),
    ];
    fakeRepo.followingToReturn = [];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Follow Back'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Following'), findsNothing);

    // Tap Follow Back
    await tester.tap(find.widgetWithText(ElevatedButton, 'Follow Back'));
    await tester.pumpAndSettle();

    // Verify repository was called
    expect(fakeRepo.followedUsers, contains('u1'));

    // Verify button changed to Following
    expect(find.widgetWithText(OutlinedButton, 'Following'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Follow Back'), findsNothing);
  });

  testWidgets('tapping Remove removes the follower item', (tester) async {
    fakeRepo.followersToReturn = [
      FollowUserModel(
        userId: 'u1',
        fullName: 'Lina Cambodia',
        username: 'lina.cambodia',
      ),
    ];
    fakeRepo.followingToReturn = [];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Lina Cambodia'), findsOneWidget);

    // Tap Remove
    await tester.tap(find.widgetWithText(OutlinedButton, 'Remove'));
    await tester.pumpAndSettle();

    // Verify user was removed from list
    expect(find.text('Lina Cambodia'), findsNothing);
    // Now shows empty state
    expect(find.text('No followers yet'), findsOneWidget);
  });

  testWidgets('renders empty state when there are no followers', (tester) async {
    fakeRepo.followersToReturn = [];
    fakeRepo.followingToReturn = [];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No followers yet'), findsOneWidget);
  });
}
