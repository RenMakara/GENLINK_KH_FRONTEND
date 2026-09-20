import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_creation_flow.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

class MockCommunityRepository implements CommunityRepository {
  CommunityPostModel? createdPost;

  @override
  Future<List<CommunityPostModel>> getPosts({
    int page = 1,
    int limit = 10,
  }) async => [];

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
    testWidgets(
      'Level 1: Bottom Navigation "+" triggers Post Composer navigation directly',
      (tester) async {
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

        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.byType(BottomNavBar), findsOneWidget);

        final centerBtnFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.add ||
                  widget.icon == Icons.add_rounded ||
                  widget.icon?.codePoint == 0xf489),
        );
        if (centerBtnFinder.evaluate().isNotEmpty) {
          await tester.tap(centerBtnFinder.first);
        } else {
          await tester.tap(find.byType(BottomNavBar));
        }

        await tester.pumpAndSettle();
        expect(centerTapped, isTrue);
      },
    );

    testWidgets(
      'Level 1: Post Composer renders toolbar with media, gif, feeling, event, location and compact "+"',
      (tester) async {
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

        expect(find.text("What's on your mind?"), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(find.text('Public'), findsOneWidget);
        expect(find.byIcon(Icons.schedule_outlined), findsNothing);
        expect(find.text('Post'), findsOneWidget);

        expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
        expect(find.byIcon(Icons.gif_box_outlined), findsOneWidget);
        expect(find.byIcon(Icons.poll_outlined), findsOneWidget);
        expect(
          find.byIcon(Icons.sentiment_satisfied_alt_outlined),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.event_outlined), findsOneWidget);
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Level 2: Tapping "+" inside Post Composer opens compact floating glass menu with creation options',
      (tester) async {
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

        await tester.enterText(
          find.byType(TextField).first,
          'Preserve this draft text during modal open/close',
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(GlobalCreateSheet), findsOneWidget);
        expect(find.text('Create'), findsWidgets);

        // Verify compact glass pill options - exactly the 11 features (excluding Post)
        expect(
          find.descendant(
            of: find.byType(GlobalCreateSheet),
            matching: find.text('Post'),
          ),
          findsNothing,
        );
        expect(find.text('Story'), findsOneWidget);
        expect(find.text('Event'), findsWidgets);
        expect(find.text('Discussion'), findsOneWidget);
        expect(find.text('Goal'), findsOneWidget);
        expect(find.text('To-Do'), findsOneWidget);
        expect(find.text('Habit'), findsOneWidget);
        expect(find.text('Expense'), findsOneWidget);
        expect(find.text('Saving Goal'), findsOneWidget);
        expect(find.text('Budget'), findsOneWidget);
        expect(find.text('Quiz'), findsOneWidget);
        expect(find.text('Challenge'), findsOneWidget);

        // Verify excluded features are removed
        expect(find.text('Poll'), findsNothing);
        expect(find.text('Celebration'), findsNothing);
        expect(find.text('Job'), findsNothing);
        expect(find.text('Document'), findsNothing);
        expect(find.text('Media'), findsNothing);

        // Verify category headers are removed
        expect(find.text('COMMUNITY'), findsNothing);
        expect(find.text('PRODUCTIVITY'), findsNothing);
        expect(find.text('FINANCIAL'), findsNothing);
        expect(find.text('ENTERTAINMENT'), findsNothing);

        // Verify right chevron arrows are present on the 11 options
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(11));

        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();

        expect(find.byType(GlobalCreateSheet), findsNothing);
        expect(
          find.text('Preserve this draft text during modal open/close'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tapping "Event" inside Create menu routes to CreateEventScreen',
      (tester) async {
        final repo = MockCommunityRepository();
        Get.put<CommunityController>(CommunityController(repository: repo));

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const CreatePostScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Event').last);
        await tester.pumpAndSettle();

        expect(find.byType(CreateEventScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping "Discussion" inside Create menu routes to CreateDiscussionScreen',
      (tester) async {
        final repo = MockCommunityRepository();
        Get.put<CommunityController>(CommunityController(repository: repo));

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const CreatePostScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Discussion'));
        await tester.pumpAndSettle();

        expect(find.byType(CreateDiscussionScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Level 1: Bottom Navigation "+" with CommunityCreationFlow.openCreatePost immediately opens CreatePostScreen without GlobalCreateSheet',
      (tester) async {
        final repo = MockCommunityRepository();
        Get.put<CommunityController>(CommunityController(repository: repo));

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Builder(
              builder: (context) {
                return Scaffold(
                  bottomNavigationBar: BottomNavBar(
                    currentIndex: 0,
                    onTap: (_) {},
                    onCenterTap: () =>
                        CommunityCreationFlow.openCreatePost(context),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CreatePostScreen), findsNothing);
        expect(find.byType(GlobalCreateSheet), findsNothing);

        final centerPlusIcon = find.descendant(
          of: find.byType(BottomNavBar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Icon &&
                (w.icon == Icons.add ||
                    w.icon == Icons.add_rounded ||
                    w.icon == CupertinoIcons.plus ||
                    w.icon?.codePoint == 0xf489),
          ),
        );
        expect(centerPlusIcon, findsOneWidget);
        await tester.tap(centerPlusIcon);
        await tester.pumpAndSettle();

        // Verify CreatePostScreen is opened directly
        expect(find.byType(CreatePostScreen), findsOneWidget);
        // Verify GlobalCreateSheet was never opened
        expect(find.byType(GlobalCreateSheet), findsNothing);
      },
    );
  });
}
