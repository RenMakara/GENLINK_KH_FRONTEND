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

  group('CreatePostScreen and Global Create Interaction Comprehensive Tests', () {
    testWidgets('1. Test opening Create Post: renders header, quick chips, schedule icon, and toolbar', (tester) async {
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

      // Verify composer hint
      expect(find.text("What's on your mind?"), findsOneWidget);

      // Verify top quick chips exist
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Feeling / Activity'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);

      // Verify "+" button is present in the toolbar
      expect(find.byTooltip('Create'), findsOneWidget);

      // Verify toolbar buttons
      expect(find.byTooltip('Photo / Video'), findsOneWidget);
      expect(find.byTooltip('Event'), findsWidgets);
      expect(find.byTooltip('Feeling / Activity'), findsWidgets);
      expect(find.byTooltip('Video'), findsOneWidget);
    });

    testWidgets('2. Test "+" inside New Post opens Create sheet with Community, Productivity, Financial, and Entertainment categories', (tester) async {
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

      // Tap "+" button in composer toolbar
      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();

      // Verify Global Create sheet opens
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(find.text('What would you like to create?'), findsOneWidget);

      // Verify all 4 categories exist
      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('PRODUCTIVITY'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('ENTERTAINMENT'), findsOneWidget);

      // Verify key creation features exist
      expect(find.text('Post'), findsWidgets);
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
      expect(find.text('Short Content'), findsOneWidget);
    });

    testWidgets('3. Test Location attachment option: attaches location and preserves draft text', (tester) async {
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

      // Type draft text
      await tester.enterText(
        find.byType(TextField).first,
        'Had a great day at university!',
      );
      await tester.pump();
      expect(find.text('Had a great day at university!'), findsOneWidget);

      // Tap Location quick chip
      await tester.tap(find.text('Location').first);
      await tester.pumpAndSettle();

      // Pick a location
      expect(find.text('CADT Innovation Center, Phnom Penh'), findsOneWidget);
      await tester.tap(find.text('CADT Innovation Center, Phnom Penh'));
      await tester.pumpAndSettle();

      // Verify text is still intact
      expect(find.text('Had a great day at university!'), findsOneWidget);

      // Verify location preview badge is attached
      expect(find.text('CADT Innovation Center, Phnom Penh'), findsWidgets);
    });

    testWidgets('4. Test Feeling/Activity attachment option: attaches feeling and preserves draft text', (tester) async {
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

      // Type draft text
      await tester.enterText(
        find.byType(TextField).first,
        'Coding my Flutter project!',
      );
      await tester.pump();

      // Tap Feeling / Activity toolbar button
      await tester.tap(find.byTooltip('Feeling / Activity'));
      await tester.pumpAndSettle();

      // Select feeling "😊 Happy"
      expect(find.text('😊 Happy'), findsOneWidget);
      await tester.tap(find.text('😊 Happy'));
      await tester.pumpAndSettle();

      // Verify text is preserved
      expect(find.text('Coding my Flutter project!'), findsOneWidget);

      // Verify feeling preview badge is attached
      expect(find.text('😊 Happy'), findsWidgets);
    });

    testWidgets('5. Test Tag People attachment option: tags people and preserves draft text', (tester) async {
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

      // Type draft text
      await tester.enterText(
        find.byType(TextField).first,
        'Study session with friends',
      );
      await tester.pump();

      // Tap People quick chip
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();

      // Select "Rathana P."
      expect(find.text('Rathana P.'), findsOneWidget);
      await tester.tap(find.text('Rathana P.'));
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify text is preserved
      expect(find.text('Study session with friends'), findsOneWidget);

      // Verify tagged people preview badge is attached
      expect(find.text('Rathana P.'), findsWidgets);
    });

    testWidgets('6. Test multiple attachments together on the same draft and verify Post button', (tester) async {
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

      // Enter post text
      await tester.enterText(
        find.byType(TextField).first,
        'Campus hackathon launch day!',
      );
      await tester.pump();

      // 1. Attach Location
      await tester.tap(find.text('Location').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('RUPP Campus 1, Phnom Penh'));
      await tester.pumpAndSettle();

      // 2. Attach Feeling
      await tester.tap(find.byTooltip('Feeling / Activity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🤩 Excited'));
      await tester.pumpAndSettle();

      // Verify all items are simultaneously present in draft
      expect(find.text('Campus hackathon launch day!'), findsOneWidget);
      expect(find.text('RUPP Campus 1, Phnom Penh'), findsWidgets);
      expect(find.text('🤩 Excited'), findsWidgets);

      // 3. Tap Post button to submit
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      // Verify post was successfully created with text and location
      expect(repo.createdPost, isNotNull);
      expect(repo.createdPost!.content, 'Campus hackathon launch day!');
    });

    testWidgets('7. Test Light and Dark modes render cleanly without exception', (tester) async {
      final repo = MockCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      // Dark Mode
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

      // Open "+" in Dark Mode
      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('What would you like to create?'), findsOneWidget);

      // Dismiss sheet
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Light Mode
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

      // Open "+" in Light Mode
      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('What would you like to create?'), findsOneWidget);
    });

    testWidgets('8. Test narrow screen (320px) zero layout overflow', (tester) async {
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

      // Tap "+" button on narrow screen
      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('What would you like to create?'), findsOneWidget);
      expect(find.text('Post'), findsWidgets);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);
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

      // Verify Khmer hint text
      expect(find.text('តើអ្នកកំពុងគិតអ្វី?'), findsOneWidget);

      // Open "+" menu
      await tester.tap(find.byTooltip('បង្កើត'));
      await tester.pumpAndSettle();

      expect(find.text('តើអ្នកចង់បង្កើតអ្វី?'), findsOneWidget);
      expect(find.text('សហគមន៍'), findsOneWidget);
      expect(find.text('ប្រកាស'), findsWidgets);
      expect(find.text('ស្តូរី'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsWidgets);
    });
  });
}
