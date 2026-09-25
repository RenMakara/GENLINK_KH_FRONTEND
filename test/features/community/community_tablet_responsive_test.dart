import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_header_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';

class _MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return [
      CommunityPostModel(
        id: 'post-1',
        userId: 'user-1',
        authorName: 'Sokha Chan',
        authorTag: '@sokhachan',
        authorAvatar: '',
        timeAgo: '2 hours ago',
        community: 'RUPP CS 2026',
        isVerified: true,
        content: 'Excited to announce our upcoming Flutter workshop on responsive design for tablets!',
        imageUrls: const [],
        likesCount: 24,
        commentsCount: 5,
        sharesCount: 2,
        isLiked: false,
        isRepostedByMe: false,
        isBookmarked: false,
      ),
      CommunityPostModel(
        id: 'post-2',
        userId: 'user-2',
        authorName: 'Vannak Lim',
        authorTag: '@vannaklim',
        authorAvatar: '',
        timeAgo: '4 hours ago',
        community: 'CADT AI Club',
        isVerified: false,
        content: 'Final post in the feed to verify scrolling above floating bottom navigation bar.',
        imageUrls: const [],
        likesCount: 12,
        commentsCount: 3,
        sharesCount: 1,
        isLiked: true,
        isRepostedByMe: false,
        isBookmarked: true,
      ),
    ];
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async => throw UnimplementedError();

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
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async => [];

  @override
  Future<CommentModel> addDiscussionComment(String discussionId, String text, {String? parentCommentId}) async => throw UnimplementedError();

  @override
  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async => [];

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async => throw UnimplementedError();

  @override
  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async => throw UnimplementedError();

  @override
  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
    bool? anonymous,
  }) async => throw UnimplementedError();

  @override
  Future<bool> deleteDiscussion(String discussionId) async => true;

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

  @override
  Future<bool> reportDiscussion(
    String discussionId, {
    String reason = 'INAPPROPRIATE_CONTENT',
    String? details,
  }) async => true;

  @override
  Future<bool> toggleDiscussionCommentLike(
    String commentId, {
    required bool isCurrentlyLiked,
  }) async => true;

  @override
  Future<bool> deleteDiscussionComment(String commentId) async => true;

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

  Widget buildTestApp({required Size screenSize, double safeBottom = 0.0}) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        padding: EdgeInsets.only(bottom: safeBottom),
      ),
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: const CommunityScreen(),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 1,
            onTap: (_) {},
            onCenterTap: () {},
          ),
        ),
      ),
    );
  }

  group('Community & BottomNav Responsive Breakpoints Tests', () {
    testWidgets('1. Phone viewport (390px wide): Full mobile width, no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(buildTestApp(screenSize: const Size(390, 844), safeBottom: 34.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CommunityHeaderWidget), findsOneWidget);
      expect(find.byType(StoryTrayWidget), findsOneWidget);
      expect(find.byType(PostCardWidget), findsWidgets);
      expect(find.byType(BottomNavBar), findsOneWidget);

      final postCardFinder = find.byType(PostCardWidget).first;
      final postCardSize = tester.getSize(postCardFinder);
      expect(postCardSize.width, lessThanOrEqualTo(390.0));
      expect(postCardSize.width, greaterThan(340.0));
    });

    testWidgets('2. Large Phone viewport (430px wide): Clean mobile layout without overflow', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(buildTestApp(screenSize: const Size(430, 932), safeBottom: 34.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PostCardWidget), findsWidgets);

      final postCardFinder = find.byType(PostCardWidget).first;
      final postCardSize = tester.getSize(postCardFinder);
      expect(postCardSize.width, lessThanOrEqualTo(430.0));
      expect(postCardSize.width, greaterThan(380.0));
    });

    testWidgets('3. iPad / Tablet Portrait (768px wide): Constrained max width, centered tabs, navigation intact', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(buildTestApp(screenSize: const Size(768, 1024), safeBottom: 20.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final postCardFinder = find.byType(PostCardWidget).first;
      final postCardSize = tester.getSize(postCardFinder);
      expect(postCardSize.width, lessThanOrEqualTo(760.0));

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Forum'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavBar), matching: find.byIcon(CupertinoIcons.house)), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavBar), matching: find.byIcon(CupertinoIcons.person_2_fill)), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavBar), matching: find.byIcon(CupertinoIcons.plus)), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavBar), matching: find.byIcon(CupertinoIcons.money_dollar_circle)), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavBar), matching: find.byIcon(CupertinoIcons.person_crop_circle)), findsOneWidget);
    });

    testWidgets('4. Tablet Landscape / Large Tablet (1024px wide): Centered max-width content, floating nav centered', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(buildTestApp(screenSize: const Size(1024, 768), safeBottom: 20.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final postCardFinder = find.byType(PostCardWidget).first;
      final postCardSize = tester.getSize(postCardFinder);
      expect(postCardSize.width, lessThanOrEqualTo(760.0));

      final postCardTopLeft = tester.getTopLeft(postCardFinder);
      expect(postCardTopLeft.dx, greaterThan(100.0));
    });

    testWidgets('5. Safe Area & Scrollability: Feed scrollview has safe bottom padding for floating bottom nav', (tester) async {
      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(buildTestApp(screenSize: const Size(768, 1024), safeBottom: 34.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scrollViews = tester.widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final feedScrollView = scrollViews.firstWhere(
        (sv) => sv.scrollDirection == Axis.vertical && sv.padding != null,
      );

      final padding = feedScrollView.padding as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(120.0));
    });

    testWidgets('shared Community scroll controller tolerates multiple clients', (tester) async {
      final controller = CommunityController(repository: _MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller.scrollController,
                    child: const SizedBox(height: 2000),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller.scrollController,
                    child: const SizedBox(height: 2000),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      controller.scrollController.jumpTo(2000);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
