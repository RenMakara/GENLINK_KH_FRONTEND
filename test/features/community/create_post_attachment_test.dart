import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
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

  group('CreatePostScreen and Global Create Interaction Comprehensive Tests', () {
    testWidgets(
      '1. Test opening Create Post: renders header, schedule icon, and toolbar',
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

        expect(find.text('Public'), findsOneWidget);

        expect(find.byTooltip('Create'), findsOneWidget);

        expect(find.byTooltip('Camera'), findsOneWidget);
        expect(find.byTooltip('Gallery'), findsOneWidget);
        expect(find.byTooltip('GIF'), findsOneWidget);
        expect(find.byTooltip('Poll'), findsOneWidget);
        expect(find.byTooltip('Feeling / Activity'), findsOneWidget);
        expect(find.byTooltip('Event'), findsWidgets);
        expect(find.byTooltip('Location'), findsOneWidget);

        // Verify schedule icon has been removed from header
        expect(find.byIcon(Icons.schedule_outlined), findsNothing);
      },
    );

    testWidgets(
      '2. Test "+" inside New Post opens compact floating glass menu with creation options',
      (tester) async {
        tester.view.physicalSize = const Size(600, 2000);
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
            home: const CreatePostScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Create'));
        await tester.pumpAndSettle();

        expect(find.byType(GlobalCreateSheet), findsOneWidget);
        expect(find.text('Create'), findsWidgets);

        // Verify compact glass pill options exist
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

        // Verify removed categories are absent
        expect(find.text('COMMUNITY'), findsNothing);
        expect(find.text('PRODUCTIVITY'), findsNothing);
        expect(find.text('FINANCIAL'), findsNothing);
        expect(find.text('ENTERTAINMENT'), findsNothing);

        // Verify right-side chevron arrows are present on the 11 options
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(11));
      },
    );

    testWidgets(
      '3. Test Location attachment option: attaches location and preserves draft text',
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
          'Had a great day at university!',
        );
        await tester.pump();
        expect(find.text('Had a great day at university!'), findsOneWidget);

        await tester.tap(find.byTooltip('Location'));
        await tester.pumpAndSettle();

        expect(find.text('CADT Innovation Center, Phnom Penh'), findsOneWidget);
        await tester.tap(find.text('CADT Innovation Center, Phnom Penh'));
        await tester.pumpAndSettle();

        expect(find.text('Had a great day at university!'), findsOneWidget);

        expect(find.text('CADT Innovation Center, Phnom Penh'), findsWidgets);
      },
    );

    testWidgets(
      '4. Test Feeling/Activity attachment option: attaches feeling and preserves draft text',
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
          'Coding my Flutter project!',
        );
        await tester.pump();

        await tester.tap(find.byTooltip('Feeling / Activity'));
        await tester.pumpAndSettle();

        expect(find.text('😊 Happy'), findsOneWidget);
        await tester.tap(find.text('😊 Happy'));
        await tester.pumpAndSettle();

        expect(find.text('Coding my Flutter project!'), findsOneWidget);

        expect(find.text('😊 Happy'), findsWidgets);
      },
    );

    testWidgets(
      '5. Test Audience selector: selects Friends and updates header capsule',
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
          'Study session with friends',
        );
        await tester.pump();

        await tester.tap(find.text('Public'));
        await tester.pumpAndSettle();

        expect(find.text('Friends only'), findsOneWidget);
        await tester.tap(find.text('Friends only'));
        await tester.pumpAndSettle();

        expect(find.text('Study session with friends'), findsOneWidget);

        expect(find.text('Friends only'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Test multiple attachments together on the same draft and verify Post button',
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
          'Campus hackathon launch day!',
        );
        await tester.pump();

        await tester.tap(find.byTooltip('Location'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('RUPP Campus 1, Phnom Penh'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Feeling / Activity'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('🤩 Excited'));
        await tester.pumpAndSettle();

        expect(find.text('Campus hackathon launch day!'), findsOneWidget);
        expect(find.text('RUPP Campus 1, Phnom Penh'), findsWidgets);
        expect(find.text('🤩 Excited'), findsWidgets);

        await tester.tap(find.text('Post'));
        await tester.pumpAndSettle();

        expect(repo.createdPost, isNotNull);
        expect(repo.createdPost!.content, 'Campus hackathon launch day!');
      },
    );

    testWidgets(
      '7. Test Light and Dark modes render cleanly without exception',
      (tester) async {
        final repo = MockCommunityRepository();
        final controller = CommunityController(repository: repo);
        Get.put<CommunityController>(controller);

        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData.dark(),
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const CreatePostScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Create'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(GlobalCreateSheet), findsOneWidget);
        expect(find.text('Story'), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData.light(),
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const CreatePostScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Create'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(GlobalCreateSheet), findsOneWidget);
        expect(find.text('Story'), findsOneWidget);
      },
    );

    testWidgets('8. Test narrow screen (320px) zero layout overflow', (
      tester,
    ) async {
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
          home: const CreatePostScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
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
    });

    testWidgets('9. Test Khmer localization renders properly', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const CreatePostScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text('តើអ្នកកំពុងគិតអ្វី?'), findsOneWidget);

      await tester.tap(find.byTooltip('បង្កើត'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(find.text('ស្តូរី'), findsOneWidget);
      expect(find.text('ការពិភាក្សា'), findsOneWidget);
      expect(find.text('គោលដៅ'), findsOneWidget);
      expect(find.text('កិច្ចការត្រូវធ្វើ'), findsOneWidget);
      expect(find.text('ទម្លាប់'), findsOneWidget);
      expect(find.text('ការចំណាយ'), findsOneWidget);
      expect(find.text('គោលដៅសន្សំ'), findsOneWidget);
      expect(find.text('ថវិកា'), findsOneWidget);
      expect(find.text('កម្រងសំណួរ'), findsOneWidget);
      expect(find.text('បញ្ហាប្រឈម'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsWidgets);
    });
  });
}
