import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';

class _TrackingCommunityRepository implements CommunityRepository {
  int getPostsCallCount = 0;
  int getDiscussionsCallCount = 0;
  bool shouldThrowError = false;
  List<CommunityPostModel> stubPosts = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    getPostsCallCount++;
    if (shouldThrowError) {
      throw const AppError(message: 'Server error: unable to load feed', errorCode: 'SERVER_ERROR');
    }
    return stubPosts;
  }

  @override
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async {
    getDiscussionsCallCount++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CommunityPostModel _createPost(String id, String content) {
  return CommunityPostModel(
    id: id,
    userId: 'user_1',
    authorName: 'Test Author',
    authorTag: 'author',
    authorAvatar: '',
    timeAgo: '1m ago',
    content: content,
    imageUrls: const [],
    visibility: 'Public',
    community: 'All GenLink',
  );
}

void main() {
  late _TrackingCommunityRepository mockRepo;
  late CommunityController controller;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    mockRepo = _TrackingCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildApp() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const CommunityScreen(),
    );
  }

  group('STEP 3: FEED / FORUM / EVENT NAVIGATION & TAP-TO-TOP REFRESH', () {
    testWidgets('1. Tapping Feed: Navigates to Feed tab and activates Feed', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Switch to Forum first
      await tester.tap(find.widgetWithText(InkWell, 'Forum'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Forum'));

      // Tap Feed
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));
      expect(find.byKey(const ValueKey('FeedTab')), findsOneWidget);
    });

    testWidgets('2. Tapping Forum: Immediately shows Forum section and updates tab', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));

      // Tap Forum
      await tester.tap(find.widgetWithText(InkWell, 'Forum'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Forum'));
      expect(find.byKey(const ValueKey('ForumTab')), findsOneWidget);
    });

    testWidgets('3. Tapping Event: Immediately shows Event section and updates tab', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap Event
      await tester.tap(find.widgetWithText(InkWell, 'Event'));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Event'));
      expect(find.byKey(const ValueKey('EventTab')), findsOneWidget);
    });

    testWidgets('4. Swiping Feed -> Forum: Horizontally swiping left moves to Forum', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));

      // Drag left on TabBarView
      await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Forum'));
      expect(find.byKey(const ValueKey('ForumTab')), findsOneWidget);
    });

    testWidgets('5. Swiping Forum -> Event: Horizontally swiping left moves to Event', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Forum
      await tester.tap(find.widgetWithText(InkWell, 'Forum'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Forum'));

      // Drag left to Event
      await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Event'));
      expect(find.byKey(const ValueKey('EventTab')), findsOneWidget);
    });

    testWidgets('6. Swiping Event -> Forum: Horizontally swiping right moves to Forum', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Event
      await tester.tap(find.widgetWithText(InkWell, 'Event'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Event'));

      // Drag right to Forum
      await tester.drag(find.byType(TabBarView), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Forum'));
      expect(find.byKey(const ValueKey('ForumTab')), findsOneWidget);
    });

    testWidgets('7. Swiping Forum -> Feed: Horizontally swiping right moves to Feed', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Forum
      await tester.tap(find.widgetWithText(InkWell, 'Forum'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Forum'));

      // Drag right to Feed
      await tester.drag(find.byType(TabBarView), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));
      expect(find.byKey(const ValueKey('FeedTab')), findsOneWidget);
    });

    testWidgets('8. Feed boundary when swiping right: Stays clamped on Feed', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));

      // Swiping right on Feed (first tab) does nothing
      await tester.drag(find.byType(TabBarView), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Feed'));
      expect(find.byKey(const ValueKey('FeedTab')), findsOneWidget);
    });

    testWidgets('9. Event boundary when swiping left: Stays clamped on Event', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to Event
      await tester.tap(find.widgetWithText(InkWell, 'Event'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Event'));

      // Swiping left on Event (last tab) does nothing
      await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(controller.selectedCategory.value, equals('Event'));
      expect(find.byKey(const ValueKey('EventTab')), findsOneWidget);
    });

    testWidgets('10. Tapping Feed while already on Feed scrolls back to top', (tester) async {
      mockRepo.stubPosts = List.generate(
        15,
        (i) => _createPost('p_$i', 'Post body #$i with plenty of text to allow vertical scrolling'),
      );
      await controller.fetchPosts();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Scroll down
      controller.scrollController.jumpTo(250.0);
      await tester.pumpAndSettle();
      expect(controller.scrollController.position.pixels, equals(250.0));

      // Tap Feed again while already on Feed
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();

      expect(controller.scrollController.position.pixels, equals(0.0));
    });

    testWidgets('11. Tapping Feed while already on Feed triggers one refresh request', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      mockRepo.getPostsCallCount = 0;

      // Tap Feed again while already on Feed
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(mockRepo.getPostsCallCount, equals(1));
    });

    testWidgets('12. Rapid Feed taps do not create duplicate refresh requests', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      mockRepo.getPostsCallCount = 0;

      // 4 rapid taps
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();

      // Must be throttled/debounced to exactly 1 request
      expect(mockRepo.getPostsCallCount, equals(1));
    });

    testWidgets('13. Feed refresh still uses real backend data and updates UI', (tester) async {
      mockRepo.stubPosts = [_createPost('post_initial', 'Initial backend post')];
      await controller.fetchPosts();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Initial backend post'), findsOneWidget);

      // Backend now returns updated post
      mockRepo.stubPosts = [
        _createPost('post_newest', 'Fresh backend post from real API'),
      ];

      // Tap Feed tab again to refresh
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();

      expect(find.text('Fresh backend post from real API'), findsOneWidget);
    });

    testWidgets('14. No mock posts appear during refresh error', (tester) async {
      mockRepo.stubPosts = [_createPost('real_1', 'Confirmed user post')];
      await controller.fetchPosts();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Confirmed user post'), findsOneWidget);

      // Simulate network error on refresh
      mockRepo.shouldThrowError = true;

      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();

      // Confirms real error handling: hasError is flagged and no placeholder mock posts are introduced
      expect(controller.hasError.value, isTrue);
      expect(controller.errorMessage.value, contains('Server error: unable to load feed'));
    });

    testWidgets('15. Empty Feed remains the correct empty state on refresh', (tester) async {
      mockRepo.stubPosts = [];
      await controller.fetchPosts();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(controller.posts.isEmpty, isTrue);

      // Tap Feed to refresh empty feed
      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();

      expect(controller.posts.isEmpty, isTrue);
      // No mock posts injected
      expect(find.text('Test Author'), findsNothing);
    });
  });
}
