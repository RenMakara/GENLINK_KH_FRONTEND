import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/event_details_screen.dart';

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return [
      CommunityPostModel(
        id: 'post_1',
        userId: 'user_1',
        authorName: 'Sokny Enath',
        authorTag: 'sokny',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Excited for the upcoming Flutter workshop this weekend!',
        imageUrls: const [],
        visibility: 'Public',
        community: 'All GenLink',
      ),
    ];
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'post_new',
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
    );
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: 'Sample post',
      imageUrls: const [],
      visibility: 'Public',
      community: 'All GenLink',
    );
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async {
    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: const [],
      visibility: 'Public',
      community: 'All GenLink',
    );
  }

  @override
  Future<bool> deletePost(String postId) async => true;
  @override
  Future<bool> toggleLike(String postId) async => true;
  @override
  Future<bool> toggleBookmark(String postId) async => true;
  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async => true;
  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;
  @override
  Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'}) async => true;
  @override
  Future<List<CommentModel>> getComments(String postId) async => [];
  @override
  Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async {
    return CommentModel(
      id: 'c1',
      postId: postId,
      userId: 'user_1',
      userName: 'Tester',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
    );
  }
  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;
  @override
  Future<bool> followUser(String userId) async => true;
  @override
  Future<bool> unfollowUser(String userId) async => true;
  @override
  Future<bool> checkIsFollowing(String userId) async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Community Feed Upcoming Events Preview Tests', () {
    testWidgets('1. Verify Upcoming Events preview renders in Feed with real events, date blocks, and locations', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);

      // Verify Real Event Titles from controller
      expect(find.text('Flutter Workshop 2026'), findsOneWidget);
      expect(find.text('AI in Everyday Life'), findsOneWidget);
      expect(find.text('GenLink Hackathon 2026'), findsOneWidget);

      // Verify Date blocks: day & month parsed from dateString
      expect(find.text('25'), findsOneWidget);
      expect(find.text('JUL'), findsWidgets);
      expect(find.text('26'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      // Verify Location and Online indicators
      expect(find.textContaining('ACLEDA University'), findsOneWidget);
      expect(find.text('🌐 Online Event'), findsOneWidget);
      expect(find.textContaining('Diamond Island'), findsOneWidget);

      // Verify Join buttons
      expect(find.text('Join'), findsWidgets);
    });

    testWidgets('2. Verify RSVP / Join button toggles state between Join and Joined', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // First event is not RSVPed initially
      expect(controller.events[0].isRsvped, isFalse);

      // Tap first Join button
      final joinButtons = find.text('Join');
      expect(joinButtons, findsWidgets);
      await tester.tap(joinButtons.first);
      await tester.pumpAndSettle();

      // Controller state should now be RSVPed
      expect(controller.events[0].isRsvped, isTrue);
      expect(find.text('Joined'), findsOneWidget);

      // Tap Joined button to un-RSVP
      await tester.tap(find.text('Joined'));
      await tester.pumpAndSettle();

      // Controller state should revert to not RSVPed
      expect(controller.events[0].isRsvped, isFalse);
      expect(find.text('Joined'), findsNothing);
    });

    testWidgets('3. Verify tapping "See all" navigates directly to the existing Event tab', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));

      // Tap "See all"
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      // Controller category should now be 'Event'
      expect(controller.selectedCategory.value, equals('Event'));
      // Event tab has "Featured Events" and "Filter" button
      expect(find.text('Featured Events'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('4. Verify tapping an Event card opens EventDetailsScreen for that event', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Flutter Workshop event title
      await tester.tap(find.text('Flutter Workshop 2026'));
      await tester.pumpAndSettle();

      // Should open EventDetailsScreen
      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Flutter Workshop 2026'), findsWidgets);
      expect(find.text('ACLEDA University, Phnom Penh'), findsWidgets);
    });

    testWidgets('5. Verify Empty State cleanly hides preview when controller has no events', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      controller.events.clear(); // Clear all events
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Upcoming Events section should not render
      expect(find.text('Upcoming Events'), findsNothing);
      expect(find.text('See all'), findsNothing);
    });
  });
}
