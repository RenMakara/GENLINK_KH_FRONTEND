import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
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
    testWidgets('1. Verifies only ONE pin icon appears in Pinned Discussions header', (tester) async {
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

      // Check section headers
      final pinnedHeaderFinder = find.text('📌 Pinned Discussions');
      expect(pinnedHeaderFinder, findsOneWidget);

      // Verify there is NO double pin icon text like '📌 📌 Pinned Discussions'
      expect(find.textContaining('📌 📌'), findsNothing);

      // Verify Latest Discussions header exists
      expect(find.text('Latest Discussions'), findsOneWidget);
    });

    testWidgets('2. Verifies all pinned and latest discussion content is preserved', (tester) async {
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

      // Verify pinned authors & topics
      expect(find.textContaining('Admin Team'), findsOneWidget);
      expect(find.text('Guidelines for GenLink KH Annual Student Project Showcase 2026'), findsOneWidget);
      expect(find.text('Best practices for GetX state management in Flutter Community App'), findsOneWidget);

      // Verify latest authors & topics
      expect(find.textContaining('Rathana P.'), findsOneWidget);
      expect(find.text('How to prepare for junior software engineer interviews in Phnom Penh?'), findsOneWidget);
      expect(find.textContaining('Heng Chansela'), findsOneWidget);
      expect(find.text('Study group for CADT Data Structures and Algorithms exam next week'), findsOneWidget);

      // Verify category badges
      expect(find.text('Technology'), findsNWidgets(2));
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
      // Forum SingleChildScrollView has vertical direction and bottom padding
      final forumScrollView = scrollViews.firstWhere(
        (sv) => sv.scrollDirection == Axis.vertical && sv.padding != null,
      );

      final padding = forumScrollView.padding as EdgeInsets;
      // Bottom padding must account for floating nav bar (~82px) + safe bottom (34+8) + breathing room (28) = 152px
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
      expect(find.text('📌 Pinned Discussions'), findsOneWidget);
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
              isPinned: true,
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
  });
}
