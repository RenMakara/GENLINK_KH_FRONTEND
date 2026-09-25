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
import 'package:genlink_frontend/features/community/presentation/screens/forum_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';

EventModel _buildEventFixture() {
  return EventModel(
    id: 'event_feed_1',
    title: 'Flutter Workshop 2026',
    organizerName: 'Dara Chan',
    organizerId: 'user_other_1',
    eventType: 'Online',
    mode: 'ONLINE',
    dateString: '25 Jul 2026',
    timeString: '10:00 AM – 12:00 PM',
    category: 'Workshop',
    description: 'A practical Flutter workshop for the GenLink community.',
    attendeesCount: 25,
    status: 'PUBLISHED',
  );
}

ForumTopicModel _buildDiscussionFixture() {
  return ForumTopicModel(
    id: 'discussion_feed_1',
    authorId: 'user_other_2',
    title: 'Best practices for GetX state management in Flutter Community App',
    authorName: 'Sokny Enath',
    category: 'Technology',
    content: 'Share your preferred patterns for organizing GetX controllers.',
    timeAgo: '3h ago',
  );
}

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({
    int page = 1,
    int limit = 10,
  }) async {
    return [
      CommunityPostModel(
        id: 'post_1',
        userId: 'user_other_1',
        authorName: 'Dara Chan',
        authorTag: '@darachan',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Excited for the upcoming Flutter workshop this weekend!',
        imageUrls: const [],
        visibility: 'Public',
        community: 'All GenLink',
      ),
      CommunityPostModel(
        id: 'event_post_1',
        userId: 'user_other_1',
        authorName: 'Dara Chan',
        authorTag: '@darachan',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Join us for a practical Flutter workshop.',
        imageUrls: const [],
        visibility: 'Public',
        community: 'All GenLink',
        attachedEvent: _buildEventFixture(),
        postType: 'EVENT',
      ),
    ];
  }

  @override
  Future<List<EventModel>> getEvents({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    return [_buildEventFixture()];
  }

  @override
  Future<Set<String>> getSavedEventIds() async => const {};

  @override
  Future<List<ForumTopicModel>> getDiscussions({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    return [_buildDiscussionFixture()];
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
  Future<CommunityPostModel> updatePost(
    String postId, {
    required String content,
  }) async {
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
  Future<bool> repostPost(
    String postId, {
    String? caption,
    String? reposterId,
  }) async => true;
  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;
  @override
  Future<bool> reportPost(
    String postId, {
    String reason = 'INAPPROPRIATE_CONTENT',
  }) async => true;
  @override
  Future<List<CommentModel>> getComments(String postId) async => [];
  @override
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
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

  final Set<String> _followedUserIds = {};
  @override
  Future<bool> deleteComment(String postId, String commentId) async => true;
  @override
  Future<bool> followUser(String userId) async {
    _followedUserIds.add(userId);
    return true;
  }

  @override
  Future<bool> unfollowUser(String userId) async {
    _followedUserIds.remove(userId);
    return true;
  }

  @override
  Future<bool> checkIsFollowing(String userId) async =>
      _followedUserIds.contains(userId);
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

  group('Community Feed UI/UX Comprehensive Improvement Tests', () {
    testWidgets(
      '1. Verify Feed renders Stories row without arrows and redundant Post Composer is removed',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        expect(find.byType(StoryTrayWidget), findsOneWidget);
        expect(find.text('Stories >'), findsNothing);

        expect(find.text("What's on your mind?"), findsNothing);
        expect(find.text('Photo'), findsNothing);
        expect(find.text('Video'), findsNothing);
        expect(find.text('Feeling'), findsNothing);
      },
    );

    testWidgets(
      '2. Verify Feed renders a backend Event post with date, title, location, and action',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        expect(find.text('Flutter Workshop 2026'), findsWidgets);
        expect(find.textContaining('25 Jul 2026'), findsWidgets);
        expect(find.text('Online Event'), findsWidgets);
        expect(find.text('View Event'), findsWidgets);
        expect(find.text('Suggested Events'), findsNothing);
        expect(find.text('Trending Discussions'), findsNothing);
      },
    );

    testWidgets(
      '3. Verify Event action opens EventDetailsScreen without immediately registering user',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        expect(controller.events[0].isRsvped, isFalse);

        final eventActions = find.text('View Event');
        expect(eventActions, findsWidgets);
        await tester.tap(eventActions.first);
        await tester.pumpAndSettle();

        expect(controller.events[0].isRsvped, isFalse);
        expect(find.byType(EventDetailsScreen), findsOneWidget);
      },
    );

    testWidgets(
      '4. Verify Feed does not inject discovery panels or fake Event data',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        controller.setCategory('Feed');
        await tester.pumpAndSettle();

        expect(controller.selectedCategory.value, equals('Feed'));
        expect(find.text('Suggested Events'), findsNothing);
        expect(find.text('Trending Discussions'), findsNothing);
        expect(find.text('See all'), findsNothing);
        expect(find.text('Flutter Workshop 2026'), findsWidgets);
      },
    );

    testWidgets(
      '5. Verify tapping a backend Event post opens EventDetailsScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        await tester.tap(find.text('View Event').last);
        await tester.pumpAndSettle();

        expect(find.byType(EventDetailsScreen), findsOneWidget);
      },
    );

    testWidgets(
      '6. Verify discussions remain available through the Forum tab',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        controller.setCategory('Forum');
        await tester.pumpAndSettle();

        expect(controller.selectedCategory.value, equals('Forum'));
        expect(find.text('Latest Discussions'), findsOneWidget);
        expect(
          find.text(
            'Best practices for GetX state management in Flutter Community App',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. Verify tapping a Forum discussion opens ForumDiscussionScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        controller.setCategory('Forum');
        await tester.pumpAndSettle();

        await tester.tap(
          find.text(
            'Best practices for GetX state management in Flutter Community App',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ForumDiscussionScreen), findsOneWidget);
      },
    );

    testWidgets(
      '8. Verify Follow button clear state transitions (+ Follow <-> ✓ Following)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = MockCommunityRepository();
        final controller = CommunityController(repository: repo);
        Get.put<CommunityController>(controller);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Obx(
                  () => PostCardWidget(
                    post: controller.posts.first,
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Follow'), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);

        await tester.tap(find.text('Follow'));
        await tester.pumpAndSettle();

        expect(find.text('Following'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        await tester.tap(find.text('Following'));
        await tester.pumpAndSettle();

        expect(find.text('Follow'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Verify Bookmark button has clear active gold accent state and inactive neutral state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = MockCommunityRepository();
        final controller = CommunityController(repository: repo);
        Get.put<CommunityController>(controller);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Obx(
                  () => PostCardWidget(
                    post: controller.posts.first,
                    controller: controller,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
        await tester.pumpAndSettle();

        final iconFinder = find.byIcon(Icons.bookmark_rounded);
        expect(iconFinder, findsOneWidget);
        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, equals(const Color(0xFFF59E0B)));
      },
    );

    testWidgets(
      '10. Verify Feed in Khmer renders localized strings and without redundant Post composer',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = MockCommunityRepository();
        final controller = CommunityController(repository: repo);
        Get.put<CommunityController>(controller);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('km', 'KH'),
            home: const CommunityScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StoryTrayWidget), findsOneWidget);
        expect(find.text('Flutter Workshop 2026'), findsWidgets);
        expect(find.text('ព្រឹត្តិការណ៍ដែលបានណែនាំ'), findsNothing);
        expect(find.text('ការពិភាក្សាពេញនិយម'), findsNothing);

        expect(find.text('តើអ្នកកំពុងគិតអ្វី?'), findsNothing);
        expect(find.text('រូបថត'), findsNothing);
      },
    );

    testWidgets(
      '11. Verify Feed adapts responsively to small screens (320px)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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

        expect(find.text('Flutter Workshop 2026'), findsWidgets);
        expect(find.text('Suggested Events'), findsNothing);
      },
    );

    testWidgets(
      '12. Verify Feed renders correctly in Light Mode and Dark Mode',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = MockCommunityRepository();
        final controller = CommunityController(repository: repo);
        Get.put<CommunityController>(controller);

        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData.light(),
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const CommunityScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Flutter Workshop 2026'), findsWidgets);
        expect(find.text('Suggested Events'), findsNothing);

        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData.dark(),
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const CommunityScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Flutter Workshop 2026'), findsWidgets);
        expect(find.text('Suggested Events'), findsNothing);
      },
    );
  });
}
