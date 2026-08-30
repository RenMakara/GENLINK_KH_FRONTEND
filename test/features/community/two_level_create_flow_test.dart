import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

class MockCommunityRepository implements CommunityRepository {
  CommunityPostModel? createdPost;

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    createdPost = CommunityPostModel(
      id: 'mock_post_1',
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
    return createdPost!;
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

  final Set<String> followedUsers = {};

  @override
  Future<bool> followUser(String userId) async {
    followedUsers.add(userId);
    return true;
  }

  @override
  Future<bool> unfollowUser(String userId) async {
    followedUsers.remove(userId);
    return true;
  }

  @override
  Future<bool> checkIsFollowing(String userId) async {
    return followedUsers.contains(userId);
  }

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

  group('Two-Level Create Flow Tests', () {
    testWidgets('Level 1: Bottom Navigation "+" triggers Post Composer navigation directly', (tester) async {
      bool centerTapped = false;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            bottomNavigationBar: BottomNavBar(
              currentIndex: 1,
              onTap: (index) {},
              onCenterTap: () {
                centerTapped = true;
                Get.to(
                  () => const CreatePostScreen(),
                  routeName: '/CreatePostScreen',
                  transition: Transition.cupertino,
                );
              },
            ),
          ),
        ),
      );

      // Verify "+" button exists on BottomNavBar
      expect(find.byIcon(Icons.add), findsNothing); // Uses CupertinoIcons.plus
      expect(find.byType(BottomNavBar), findsOneWidget);

      // Tap center "+" button
      final centerBtnFinder = find.byWidgetPredicate(
        (widget) => widget is Icon && (widget.icon == Icons.add || widget.icon?.codePoint == 0xf489),
      );
      if (centerBtnFinder.evaluate().isNotEmpty) {
        await tester.tap(centerBtnFinder.first);
      } else {
        // Fallback tap center of BottomNavBar
        await tester.tap(find.byType(BottomNavBar));
      }

      await tester.pumpAndSettle();
      expect(centerTapped, isTrue);
    });

    testWidgets('Level 1: Post Composer renders toolbar with media, gif, feeling, event, location and compact "+"', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreatePostScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify hint and close button
      expect(find.text("What do you want to talk about?"), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);

      // Verify bottom toolbar icons
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.gif_box_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_satisfied_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('Level 2: Tapping "+" inside Post Composer opens Create sheet with 4 categories and 13 options in compact grid', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreatePostScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Type some text to test state preservation
      await tester.enterText(
        find.byType(TextField).first,
        'Preserve this draft text during modal open/close',
      );
      await tester.pump();

      // Tap "+" button in composer toolbar
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Verify Global Create sheet opens
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(find.text('What would you like to create?'), findsOneWidget);

      // Verify initial visible categories and features
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('Post'), findsWidgets);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);

      // Scroll down to verify Financial and Entertainment categories
      await tester.drag(find.byType(ListView).last, const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.text('Short Content'), findsOneWidget);

      // Close create menu by tapping close button 'X' inside GlobalCreateSheet
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      // Verify sheet is closed and post text is preserved
      expect(find.byType(GlobalCreateSheet), findsNothing);
      expect(find.text('Preserve this draft text during modal open/close'), findsOneWidget);
    });

    testWidgets('Tapping "Post" inside Create menu when already in Post Composer simply closes menu without duplicate push', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreatePostScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "+" in composer toolbar
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalCreateSheet), findsOneWidget);

      // Tap "Post" card in the Community grid
      await tester.tap(find.text('Post').last);
      await tester.pumpAndSettle();

      // Verify sheet closed and we are still on the same CreatePostScreen
      expect(find.byType(GlobalCreateSheet), findsNothing);
      expect(find.byType(CreatePostScreen), findsOneWidget);
    });
  });
}
