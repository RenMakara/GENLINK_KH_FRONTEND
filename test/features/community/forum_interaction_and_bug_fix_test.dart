import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';

class _MockCommunityRepository implements CommunityRepository {
  final Map<String, List<CommentModel>> discussionCommentsStore = {};

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async => CommunityPostModel(
    id: 'mock_1',
    userId: 'user_1',
    authorName: 'Test',
    authorTag: 'test',
    authorAvatar: '',
    timeAgo: 'now',
    content: content,
    imageUrls: imageUrls,
    visibility: visibility,
    community: community,
  );

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async => throw UnimplementedError();

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async => throw UnimplementedError();

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
  Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async => throw UnimplementedError();

  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;

  @override
  Future<bool> followUser(String userId) async => true;

  @override
  Future<bool> unfollowUser(String userId) async => true;

  @override
  Future<bool> checkIsFollowing(String userId) async => false;

  @override
  Future<bool> toggleDiscussionLike(String discussionId) async => true;

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async =>
      List<CommentModel>.from(discussionCommentsStore[discussionId] ?? []);

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final comment = CommentModel(
      id: 'mock_c_1',
      postId: discussionId,
      userId: 'user_1',
      userName: 'Test User',
      userAvatar: '',
      text: content,
      timeAgo: 'now',
    );
    discussionCommentsStore.putIfAbsent(discussionId, () => []).add(comment);
    return comment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Forum Interaction & Bug Fix Verification', () {
    testWidgets('TEST 1 & 2: Tapping Like button on discussion card toggles like without opening CreateDiscussionScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // Initial first discussion like count is 89
      expect(find.text('89'), findsOneWidget);
      expect(find.byType(CreateDiscussionScreen), findsNothing);

      // Tap on the Like icon of the first discussion card
      final firstLikeIcon = find.byIcon(Icons.favorite_border_rounded).first;
      await tester.tap(firstLikeIcon);
      await tester.pumpAndSettle();

      // Like count should increment to 90
      expect(find.text('90'), findsOneWidget);

      // Verify CreateDiscussionScreen did NOT open
      expect(find.byType(CreateDiscussionScreen), findsNothing);
      expect(find.byType(CommunityScreen), findsOneWidget);

      // Tap on the Like icon again to unlike
      final firstLikedIcon = find.byIcon(Icons.favorite_rounded).first;
      await tester.tap(firstLikedIcon);
      await tester.pumpAndSettle();

      // Like count should decrement back to 89
      expect(find.text('89'), findsOneWidget);

      // Still no CreateDiscussionScreen opened
      expect(find.byType(CreateDiscussionScreen), findsNothing);
    });

    testWidgets('TEST 3: Tapping discussion title/card opens ForumDiscussionScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // Tap on a discussion title
      final titleFinder = find.text('Best practices for GetX state management in Flutter Community App');
      expect(titleFinder, findsOneWidget);
      await tester.tap(titleFinder);
      await tester.pumpAndSettle();

      // Should open ForumDiscussionScreen (Discussion Details)
      expect(find.byType(ForumDiscussionScreen), findsOneWidget);
      expect(find.byType(CreateDiscussionScreen), findsNothing);
    });

    testWidgets('TEST 4: Tapping comments count opens ForumDiscussionScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // Tap on comments row
      final commentsRowFinder = find.byIcon(Icons.chat_bubble_outline_rounded).first;
      await tester.tap(commentsRowFinder);
      await tester.pumpAndSettle();

      // Should open ForumDiscussionScreen
      expect(find.byType(ForumDiscussionScreen), findsOneWidget);
      expect(find.byType(CreateDiscussionScreen), findsNothing);
    });

    testWidgets('TEST 5: CreateDiscussionScreen validates required fields and enables Publish', (tester) async {
      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreateDiscussionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find Publish button
      final publishButtonFinder = find.byType(ElevatedButton);
      expect(publishButtonFinder, findsOneWidget);

      final initialButton = tester.widget<ElevatedButton>(publishButtonFinder);
      expect(initialButton.onPressed, isNull); // Disabled when fields are empty

      // Select Category
      await tester.tap(find.text('community.selectCategory'.tr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();

      // Enter Title
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'New Flutter Topic');
      await tester.pump();

      // Enter Content
      await tester.enterText(textFields.at(1), 'Detailed content about Flutter architecture.');
      await tester.pump();

      final enabledButton = tester.widget<ElevatedButton>(publishButtonFinder);
      expect(enabledButton.onPressed, isNotNull); // Enabled when valid
    });

    testWidgets('TEST 6: Submitting CreateDiscussionScreen adds topic to controller', (tester) async {
      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      final initialLatestCount = controller.forumLatestDiscussions.length;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreateDiscussionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Category
      await tester.tap(find.text('community.selectCategory'.tr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();

      // Enter Title & Content
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Created from Test');
      await tester.pump();

      await tester.enterText(textFields.at(1), 'Content body here.');
      await tester.pump();

      // Tap Publish
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Controller should have 1 more latest discussion at index 0
      expect(controller.forumLatestDiscussions.length, initialLatestCount + 1);
      expect(controller.forumLatestDiscussions.first.title, 'Created from Test');
      expect(controller.forumLatestDiscussions.first.category, 'Technology');
    });
  });
}
