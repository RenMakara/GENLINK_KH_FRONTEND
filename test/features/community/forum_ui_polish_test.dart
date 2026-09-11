import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
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
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async => [
    ForumTopicModel(
      id: 'disc_1',
      title: 'Best practices for GetX state management in Flutter Community App',
      content: 'Best practices for GetX state management in Flutter Community App',
      category: 'Technology',
      authorName: 'Sokny Enat',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '2h ago',
      upvotes: 89,
      repliesCount: 34,
      isLiked: false,
      isOwner: true,
    ),
    ForumTopicModel(
      id: 'disc_2',
      title: 'Flutter 3.x vs React Native in 2025: Real production insights',
      content: 'Flutter 3.x vs React Native in 2025: Real production insights',
      category: 'Technology',
      authorName: 'Heng Chansela',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '4h ago',
      upvotes: 64,
      repliesCount: 19,
      isLiked: true,
    ),
    ForumTopicModel(
      id: 'disc_3',
      title: 'Study group for CADT Data Structures and Algorithms exam next week',
      content: 'Study group for CADT Data Structures and Algorithms exam next week',
      category: 'Study & Education',
      authorName: 'Ren Makara',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '6h ago',
      upvotes: 42,
      repliesCount: 15,
      isLiked: false,
    ),
    ForumTopicModel(
      id: 'disc_4',
      title: 'How I landed my first Flutter Internship in Cambodia: Tips & Roadmap',
      content: 'How I landed my first Flutter Internship in Cambodia: Tips & Roadmap',
      category: 'Career & Jobs',
      authorName: 'Chhaeng Sokuntheara',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: '1d ago',
      upvotes: 112,
      repliesCount: 52,
      isLiked: false,
    ),
  ];

  @override
  Future<ForumTopicModel> getDiscussionDetails(String discussionId) async {
    final list = await getDiscussions();
    final match = list.where((d) => d.id == discussionId);
    if (match.isNotEmpty) return match.first;
    return ForumTopicModel(
      id: discussionId,
      title: 'testt',
      content: 'test',
      category: 'Technology',
      authorName: 'Sokny Enat',
      timeAgo: 'Just now',
      upvotes: 1,
      repliesCount: 0,
      isLiked: false,
      isOwner: true,
    );
  }

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
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.text('📌 Pinned Discussions'), findsNothing);
      expect(find.textContaining('📌'), findsNothing);

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rathana P.'), findsNothing);
      expect(find.text('How to prepare for junior software engineer interviews in Phnom Penh?'), findsNothing);

      expect(find.textContaining('Sokny Enat'), findsOneWidget);
      expect(find.textContaining('Heng Chansela'), findsOneWidget);
      expect(find.text('Study group for CADT Data Structures and Algorithms exam next week'), findsOneWidget);
      expect(find.textContaining('Ren Makara'), findsOneWidget);
      expect(find.textContaining('Chhaeng Sokuntheara'), findsOneWidget);
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
              padding: EdgeInsets.only(bottom: 34),
              size: Size(390, 844),
            ),
            child: CommunityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

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
      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          for (final d in err.diagnostics) {
            debugPrint(d.toString());
          }
        }
      }
      expect(err, isNull);

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
      expect(find.textContaining('1d'), findsOneWidget);
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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      expect(moreButtons, findsWidgets);

      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('Delete Discussion'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      await tester.tap(moreButtons.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Edit Discussion'), findsNothing);
      expect(find.text('Delete Discussion'), findsNothing);

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

      await controller.addDiscussion(
        title: 'test2',
        content: 'Original content description',
        category: 'Career',
      );
      controller.posts.add(CommunityPostModel(
        id: controller.forumLatestDiscussions.first.id,
        userId: 'user_1',
        authorName: 'Sokny Enat',
        authorTag: 'sokny',
        authorAvatar: '',
        timeAgo: 'now',
        content: 'Original content description',
        discussionTitle: 'test2',
        category: 'Career',
      ));

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

      expect(find.text('test2'), findsOneWidget);

      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Discussion'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('test2'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      final success = await controller.updateDiscussion(
        discussionId: controller.forumLatestDiscussions.first.id,
        title: 'Updated test2 discussion title',
        content: 'Updated content description',
        category: 'Career',
      );
      expect(success, isTrue);

      Get.back();
      await tester.pumpAndSettle();

      expect(find.text('Updated test2 discussion title'), findsOneWidget);

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.text('Discussion To Delete'), findsOneWidget);

      final moreButtons = find.byIcon(Icons.more_horiz_rounded);
      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Discussion'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Discussion?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this discussion? This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discussion To Delete'), findsOneWidget);

      await controller.deleteDiscussion(newDisc.id);
      await tester.pumpAndSettle();

      expect(find.text('Discussion To Delete'), findsNothing);

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

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.text('89'), findsOneWidget);

      final heartIcons = find.byIcon(Icons.favorite_border_rounded);
      await tester.tap(heartIcons.first);
      await tester.pumpAndSettle();

      expect(find.text('90'), findsOneWidget);
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

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('community.forum'.tr));
      await tester.pumpAndSettle();

      expect(find.text('ការពិភាក្សាថ្មីៗ'), findsOneWidget);

      expect(find.text('តើ Flutter ល្អសម្រាប់ Mobile App ដែរឬទេ?'), findsOneWidget);
      expect(find.text('What is the best way to manage state in Flutter?'), findsOneWidget);

      Get.updateLocale(const Locale('en', 'US'));
      await tester.pumpAndSettle();

      expect(find.text('Latest Discussions'), findsOneWidget);

      expect(find.text('តើ Flutter ល្អសម្រាប់ Mobile App ដែរឬទេ?'), findsOneWidget);
      expect(find.text('What is the best way to manage state in Flutter?'), findsOneWidget);
    });

    testWidgets('12. Verifies Discussion Detail screen visual hierarchy, header, and welcoming empty comments', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final topic = ForumTopicModel(
        id: 'disc_detail_test',
        authorId: 'author_123',
        authorName: 'Sokny Enat',
        timeAgo: 'Just now',
        category: 'Technology',
        title: 'testt',
        content: 'test',
        upvotes: 1,
        repliesCount: 0,
        isLiked: false,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Sokny Enat'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('testt'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.text('Be the first to start the discussion!'), findsOneWidget);
      expect(find.text('Add a reply...'), findsOneWidget);
    });

    testWidgets('13. Verifies Discussion Detail screen in Khmer mode renders Khmer UI labels and keeps user content in original language', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final topic = ForumTopicModel(
        id: 'disc_km_test',
        authorId: 'author_km',
        authorName: 'Sokny Enat',
        timeAgo: 'Just now',
        category: 'Technology',
        title: 'testt',
        content: 'test',
        upvotes: 1,
        repliesCount: 0,
        isLiked: false,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: ForumDiscussionScreen(discussion: topic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ការពិភាក្សា'), findsOneWidget);
      expect(find.text('Sokny Enat'), findsOneWidget);
      expect(find.text('testt'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
      expect(find.text('មតិយោបល់'), findsOneWidget);
      expect(find.text('មិនទាន់មានមតិយោបល់ទេ'), findsOneWidget);
      expect(find.text('សូមធ្វើជាអ្នកដំបូងដែលចាប់ផ្តើមការពិភាក្សា!'), findsOneWidget);
      expect(find.text('បន្ថែមការឆ្លើយតប...'), findsOneWidget);
    });

    testWidgets('14. Verifies ForumThreadCard visual hierarchy: avatar, author · timestamp, category chip, title, content preview, and reactions', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              title: 'Mastering Flutter Responsive UI',
              content: 'A comprehensive guide on building adaptive screens for Android and iOS devices in Flutter 3.',
              author: 'sokny_enat',
              timeAgo: '2h',
              category: 'Technology',
              replies: 5,
              likes: 12,
              isLiked: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.textContaining('sokny_enat'), findsOneWidget);
      expect(find.textContaining('2h'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Mastering Flutter Responsive UI'), findsOneWidget);
      expect(find.text('A comprehensive guide on building adaptive screens for Android and iOS devices in Flutter 3.'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('5 comments'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('15. Verifies optional content preview: distinct content shows, identical/null/empty content is suppressed', (tester) async {
      // 15a: distinct content
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Discussion Alpha',
              content: 'Unique preview body text here.',
              author: 'user1',
              timeAgo: '5m',
              category: 'General',
              replies: 0,
              likes: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unique preview body text here.'), findsOneWidget);

      // 15b: content identical to title should not be rendered as duplicate body text
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Identical Title And Content',
              content: 'Identical Title And Content',
              author: 'user2',
              timeAgo: '10m',
              category: 'General',
              replies: 0,
              likes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Should find only one widget with that text (the title, not duplicated as preview)
      expect(find.text('Identical Title And Content'), findsOneWidget);

      // 15c: null or empty content
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Title Without Body',
              content: '   ',
              author: 'user3',
              timeAgo: '15m',
              category: 'General',
              replies: 0,
              likes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title Without Body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. Verifies Like button tap isolation: tapping like toggles like without navigating or opening Create Discussion', (tester) async {
      bool likeTapped = false;
      bool cardTapped = false;
      bool commentTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              title: 'Tap Isolation Test',
              author: 'enat',
              timeAgo: '1h',
              category: 'Technology',
              replies: 3,
              likes: 10,
              isLiked: false,
              onLikeTap: () => likeTapped = true,
              onTap: () => cardTapped = true,
              onCommentTap: () => commentTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Like icon
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(likeTapped, isTrue, reason: 'Like tap should be invoked');
      expect(cardTapped, isFalse, reason: 'Card tap must NOT be triggered when tapping Like');
      expect(commentTapped, isFalse, reason: 'Comment tap must NOT be triggered when tapping Like');

      // Now tap the Comment button
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();
      expect(commentTapped, isTrue, reason: 'Comment tap should be invoked');
      expect(cardTapped, isFalse, reason: 'Card tap must NOT be triggered when tapping Comment button');
    });

    testWidgets('17. Verifies responsive rendering at 320px, 360px, 390px, and 430px without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];

      for (final w in widths) {
        tester.view.physicalSize = Size(w, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: SizedBox(
                width: w,
                child: ForumThreadCard(
                  title: 'A rather long discussion title that tests multi-line wrapping and bounds on narrow viewport',
                  content: 'A preview paragraph describing the topic in further detail to verify multi-line height handling.',
                  author: 'very_long_author_username_for_testing',
                  timeAgo: '2026-09-09T17:28:27.047050304Z',
                  category: 'Campus Life & Activities',
                  replies: 128,
                  likes: 950,
                  onMoreTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Must not throw overflow at ${w}px width');
        expect(find.text('Campus Life & Activities'), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('18. Verifies bilingual Khmer, English, and mixed titles render cleanly with natural line height', (tester) async {
      final khmerTitle = 'របៀបរៀបចំខ្លួនសម្រាប់ការសម្ភាសន៍ការងារដំបូង';
      final khmerContent = 'នៅក្នុងការសម្ភាសន៍ការងារ អ្នកគួរតែត្រៀមខ្លួនឱ្យបានល្អនូវចំណុចសំខាន់ៗទាំងនេះ។';
      final mixedTitle = 'គន្លឹះរៀន Flutter & Dart សម្រាប់សិស្ស CADT';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ForumThreadCard(
                    title: khmerTitle,
                    content: khmerContent,
                    author: 'សុខនី',
                    timeAgo: 'Just now',
                    category: 'បច្ចេកវិទ្យា',
                    replies: 2,
                    likes: 15,
                  ),
                  ForumThreadCard(
                    title: mixedTitle,
                    author: 'Dara',
                    timeAgo: '2h',
                    category: 'ការសិក្សា',
                    replies: 0,
                    likes: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(khmerTitle), findsOneWidget);
      expect(find.text(khmerContent), findsOneWidget);
      expect(find.text(mixedTitle), findsOneWidget);
      expect(find.text('បច្ចេកវិទ្យា'), findsOneWidget);
      expect(find.text('ការសិក្សា'), findsOneWidget);
      expect(find.text('2 មតិយោបល់'), findsOneWidget);
    });

    testWidgets('19. Verifies Light Mode and Dark Mode render with proper contrast tokens', (tester) async {
      // Dark theme test
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Dark Mode Thread',
              content: 'Dark mode content preview.',
              author: 'dark_user',
              timeAgo: '1d',
              category: 'Dark Design',
              replies: 4,
              likes: 8,
              isLiked: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // Light theme test
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ForumThreadCard(
              title: 'Light Mode Thread',
              content: 'Light mode content preview.',
              author: 'light_user',
              timeAgo: '1d',
              category: 'Light Design',
              replies: 1,
              likes: 3,
              isLiked: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('20. Verifies More button tap target and callback execution', (tester) async {
      bool moreTapped = false;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: ForumThreadCard(
              title: 'More Menu Button Test',
              author: 'author_user',
              timeAgo: '3d',
              category: 'General',
              replies: 0,
              likes: 0,
              onMoreTap: () => moreTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(moreTapped, isTrue);
    });
  });
}
