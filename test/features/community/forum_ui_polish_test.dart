import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/widgets/community_widgets.dart';

class _MockCommunityRepository implements CommunityRepository {
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
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async => [];

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async => ForumTopicModel(
    id: 'mock_disc_1',
    authorId: 'user_me',
    title: title,
    authorName: 'Sokny Enat',
    category: category,
    content: content,
    timeAgo: 'Just now',
    isOwner: true,
  );

  @override
  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
  }) async => ForumTopicModel(
    id: discussionId,
    authorId: 'user_me',
    title: title,
    authorName: 'Sokny Enat',
    category: category,
    content: content,
    timeAgo: 'Just now',
    isOwner: true,
  );

  @override
  Future<bool> deleteDiscussion(String discussionId) async => true;

  @override
  Future<bool> toggleDiscussionLike(String discussionId) async => true;

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async => [];

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async => CommentModel(
    id: 'mock_c_1',
    postId: discussionId,
    userId: 'user_1',
    userName: 'Test',
    userAvatar: '',
    text: content,
    timeAgo: 'now',
  );

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

  group('Forum UI Polish Verification Tests', () {
    testWidgets('1. Verifies Pinned Discussions section is completely removed and Forum starts with Latest Discussions', (tester) async {
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

      // Verify Pinned Discussions is completely gone
      expect(find.text('📌 Pinned Discussions'), findsNothing);
      expect(find.textContaining('📌'), findsNothing);

      // Verify Latest Discussions header exists
      expect(find.text('Latest Discussions'), findsOneWidget);
    });

    testWidgets('2. Verifies latest discussion content is preserved', (tester) async {
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

      // Verify latest authors & topics
      expect(find.textContaining('Rathana P.'), findsOneWidget);
      expect(find.text('How to prepare for junior software engineer interviews in Phnom Penh?'), findsOneWidget);
      expect(find.textContaining('Heng Chansela'), findsOneWidget);
      expect(find.text('Study group for CADT Data Structures and Algorithms exam next week'), findsOneWidget);

      // Verify category badges
      expect(find.text('Career'), findsOneWidget);
      expect(find.text('Study & Education'), findsOneWidget);
    });

    testWidgets('3. Verifies Forum scrollable content has safe bottom padding for bottom navigation', (tester) async {
      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(bottom: 34), // iPhone home indicator
              size: Size(390, 844),
            ),
            child: CommunityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // Locate Forum SingleChildScrollView
      final scrollViews = tester.widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final forumScrollView = scrollViews.firstWhere(
        (sv) => sv.scrollDirection == Axis.vertical && sv.padding != null,
      );

      final padding = forumScrollView.padding as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(120.0));
      expect(padding.left, equals(16.0));
      expect(padding.right, equals(16.0));
    });

    testWidgets('4. Verifies responsive rendering on narrow screens (320px width) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
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
      expect(tester.takeException(), isNull);

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ForumThreadCard), findsWidgets);
      expect(find.text('Latest Discussions'), findsOneWidget);
    });

    testWidgets('5. Verifies ForumThreadCard subtle border styling and non-empty category badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Test Discussion Title',
              author: 'Very Long Author Name That Could Potentially Overflow In Narrow Viewports',
              timeAgo: '1d ago',
              category: 'Very Long Category Name For Responsive Testing',
              replies: 10,
              likes: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Very Long Category Name For Responsive Testing'), findsOneWidget);
      expect(find.textContaining('1d ago'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('10 comments'), findsOneWidget);
    });

    testWidgets('6. Verifies own discussion displays More menu with Edit Discussion, Delete Discussion, and Cancel', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
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

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // First discussion in list is owned by Sokny Enat (authorId: 'user_me', isOwner: true)
      // Tap the More menu (•••) on the first discussion card
      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      expect(moreButtons, findsWidgets);

      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      // Verify Owner actions are present
      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('Delete Discussion'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Close menu
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('7. Verifies other user discussion does NOT show Edit or Delete options', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
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

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // Tap More menu on 2nd discussion (authored by Rathana P., authorId: 'u1')
      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      await tester.tap(moreButtons.at(1));
      await tester.pumpAndSettle();

      // Verify Owner actions are NOT shown
      expect(find.text('Edit Discussion'), findsNothing);
      expect(find.text('Delete Discussion'), findsNothing);

      // Verify Non-owner actions are shown
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('8. Verifies editing own discussion updates title and content in Forum and Feed', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Add a test discussion
      await controller.addDiscussion(
        title: 'test2',
        content: 'Original content description',
        category: 'Career',
      );

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

      // Newly added discussion should be at index 0 with title "test2"
      expect(find.text('test2'), findsOneWidget);

      // Tap More menu on test2 discussion
      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      // Tap Edit Discussion
      await tester.tap(find.text('Edit Discussion'));
      await tester.pumpAndSettle();

      // Verify Edit Discussion screen is open with prefilled data
      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('test2'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Modify title directly via controller updateDiscussion
      final success = await controller.updateDiscussion(
        discussionId: controller.forumLatestDiscussions.first.id,
        title: 'Updated test2 discussion title',
        content: 'Updated content description',
        category: 'Career',
      );
      expect(success, isTrue);

      // Return to forum
      Get.back();
      await tester.pumpAndSettle();

      // Verify updated title appears in Forum
      expect(find.text('Updated test2 discussion title'), findsOneWidget);

      // Switch to Feed tab and verify updated title is synchronized in Feed post and preview
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();
      expect(find.text('Updated test2 discussion title'), findsWidgets);
    });

    testWidgets('9. Verifies deleting own discussion requires confirmation and removes it from Forum and Feed', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Add a test discussion
      final newDisc = await controller.addDiscussion(
        title: 'Discussion To Delete',
        content: 'Content that will be deleted',
        category: 'Technology',
      );

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

      expect(find.text('Discussion To Delete'), findsOneWidget);

      // Open More Menu
      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      // Tap Delete Discussion
      await tester.tap(find.text('Delete Discussion'));
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog
      expect(find.text('Delete Discussion?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this discussion? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Discussion remains
      expect(find.text('Discussion To Delete'), findsOneWidget);

      // Now perform delete
      await controller.deleteDiscussion(newDisc.id);
      await tester.pumpAndSettle();

      // Discussion is removed from Forum
      expect(find.text('Discussion To Delete'), findsNothing);

      // Switch to Feed and verify removed from Feed
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();
      expect(find.text('Discussion To Delete'), findsNothing);
    });

    testWidgets('10. Verifies Like button toggles count and does NOT open Create Discussion screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
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

      // Switch to Forum tab
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      // Initial upvotes for first topic is 89
      expect(find.text('89'), findsOneWidget);

      // Tap Like icon
      final heartIcons = find.byIcon(Icons.favorite_border_rounded);
      await tester.tap(heartIcons.first);
      await tester.pumpAndSettle();

      // Upvotes incremented to 90
      expect(find.text('90'), findsOneWidget);
      // Ensure we are STILL on Forum tab (NOT Create Discussion screen)
      expect(find.text('Latest Discussions'), findsOneWidget);
      expect(find.text('Publish'), findsNothing);
    });

    testWidgets('11. Verifies bilingual rendering: English & Khmer UI labels and user content language preservation', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Add a Khmer discussion and an English discussion
      await controller.addDiscussion(
        title: 'តើ Flutter ល្អសម្រាប់ Mobile App ដែរឬទេ?',
        content: 'ខ្លឹមសារពិភាក្សាជាភាសាខ្មែរ',
        category: 'Technology',
      );
      await controller.addDiscussion(
        title: 'What is the best way to manage state in Flutter?',
        content: 'English content description',
        category: 'Technology',
      );

      // Test Khmer UI
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Forum tab
      await tester.tap(find.text('community.forum'.tr));
      await tester.pumpAndSettle();

      // Verify Khmer UI label
      expect(find.text('ការពិភាក្សាថ្មីៗ'), findsOneWidget);

      // Verify User content is NOT translated (Khmer stays Khmer, English stays English)
      expect(find.text('តើ Flutter ល្អសម្រាប់ Mobile App ដែរឬទេ?'), findsOneWidget);
      expect(find.text('What is the best way to manage state in Flutter?'), findsOneWidget);

      // Switch to English UI
      Get.updateLocale(const Locale('en', 'US'));
      await tester.pumpAndSettle();

      // Verify English UI label
      expect(find.text('Latest Discussions'), findsOneWidget);

      // User content still preserved exactly as written
      expect(find.text('តើ Flutter ល្អសម្រាប់ Mobile App ដែរឬទេ?'), findsOneWidget);
      expect(find.text('What is the best way to manage state in Flutter?'), findsOneWidget);
    });
  });
}
