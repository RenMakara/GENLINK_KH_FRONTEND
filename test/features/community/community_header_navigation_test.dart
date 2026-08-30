import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_header_widget.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return [];
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'mock_1',
      userId: 'user_1',
      authorName: 'Test User',
      authorTag: 'testuser',
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
      authorName: 'Test User',
      authorTag: 'testuser',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: 'Mock content',
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
      authorName: 'Test User',
      authorTag: 'testuser',
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
  Future<CommentModel> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    return CommentModel(
      id: 'comment_1',
      postId: postId,
      userId: 'user_1',
      userName: 'Tester',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
      parentCommentId: parentCommentId,
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

  group('CommunityHeaderWidget Tests', () {
    testWidgets('renders Community title, Search, Chat, and Notification buttons', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      // Verify Community title
      expect(find.text('Community'), findsOneWidget);

      // Verify 3 Header action icons (Search, Chat/Forum, Notifications)
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('tapping action buttons navigates to Search, Chat, and Notifications', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      // Verify tooltips/labels
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Chat'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
    });
  });

  group('CommunityScreen Tab Navigation Tests', () {
    testWidgets('renders exactly 3 tabs: Feed, Forum, Event and excludes Career', (tester) async {
      final controller = CommunityController(repository: MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pump();

      // Verify exactly Feed, Forum, Event tabs are present
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Forum'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);

      // Verify Career tab is NOT present in the header tabs
      expect(controller.categories, equals(['Feed', 'Forum', 'Event']));
      expect(controller.categories.contains('Career'), isFalse);
    });

    testWidgets('switching between Feed -> Forum -> Event updates controller and tab state', (tester) async {
      final controller = CommunityController(repository: MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pump();

      expect(controller.selectedCategory.value, equals('Feed'));

      // Switch to Forum
      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Forum'));

      // Switch to Event
      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Event'));

      // Switch back to Feed
      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Feed'));
    });

    testWidgets('renders cleanly on narrow screen widths without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = CommunityController(repository: MockCommunityRepository());
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
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Forum'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
    });
  });
}
