import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
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
    String? videoUrl,
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

  final List<ForumTopicModel> discussionsStore = [
    ForumTopicModel(
      id: 'disc_1',
      title: 'Best practices for GetX state management in Flutter Community App',
      content: 'Best practices for GetX state management in Flutter Community App content body',
      category: 'Technology',
      authorName: 'Sokny Enat',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      upvotes: 89,
      repliesCount: 34,
      isLiked: false,
    ),
  ];

  @override
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async =>
      List.from(discussionsStore);

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    final newTopic = ForumTopicModel(
      id: 'disc_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'user_1',
      authorName: 'Test User',
      authorAvatar: '',
      title: title,
      content: content,
      category: category,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
    );
    discussionsStore.insert(0, newTopic);
    return newTopic;
  }

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.text('89'), findsOneWidget);
      expect(find.byType(CreateDiscussionScreen), findsNothing);

      final firstLikeIcon = find.byIcon(Icons.favorite_border_rounded).first;
      await tester.tap(firstLikeIcon);
      await tester.pumpAndSettle();

      expect(find.text('90'), findsOneWidget);

      expect(find.byType(CreateDiscussionScreen), findsNothing);
      expect(find.byType(CommunityScreen), findsOneWidget);

      final firstLikedIcon = find.byIcon(Icons.favorite_rounded).first;
      await tester.tap(firstLikedIcon);
      await tester.pumpAndSettle();

      expect(find.text('89'), findsOneWidget);

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      final titleFinder = find.text('Best practices for GetX state management in Flutter Community App');
      expect(titleFinder, findsOneWidget);
      await tester.tap(titleFinder);
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      final commentsRowFinder = find.byIcon(Icons.chat_bubble_outline_rounded).first;
      await tester.tap(commentsRowFinder);
      await tester.pumpAndSettle();

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

      final publishButtonFinder = find.byType(ElevatedButton);
      expect(publishButtonFinder, findsOneWidget);

      final initialButton = tester.widget<ElevatedButton>(publishButtonFinder);
      expect(initialButton.onPressed, isNull);

      await tester.tap(find.text('community.selectCategory'.tr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'New Flutter Topic');
      await tester.pump();

      await tester.enterText(textFields.at(1), 'Detailed content about Flutter architecture.');
      await tester.pump();

      final enabledButton = tester.widget<ElevatedButton>(publishButtonFinder);
      expect(enabledButton.onPressed, isNotNull);
    });

    testWidgets('TEST 6: Submitting CreateDiscussionScreen adds topic to controller', (tester) async {
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

      final initialLatestCount = controller.forumLatestDiscussions.length;

      await tester.tap(find.text('community.selectCategory'.tr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Created from Test');
      await tester.pump();

      await tester.enterText(textFields.at(1), 'Content body here.');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(controller.forumLatestDiscussions.length, initialLatestCount + 1);
      expect(controller.forumLatestDiscussions.first.title, 'Created from Test');
      expect(controller.forumLatestDiscussions.first.category, 'Technology');
    });
  });
}
