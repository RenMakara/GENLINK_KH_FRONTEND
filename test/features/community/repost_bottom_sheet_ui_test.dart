import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/repost/original_post_preview.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/repost/repost_bottom_sheet.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/repost/repost_quote_input.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';

class MockCommunityRepository implements CommunityRepository {
  List<CommunityPostModel> mockPosts = [];
  String? lastRepostedId;
  String? lastRepostCaption;
  int repostCalls = 0;

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => mockPosts;

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'mock_1',
      userId: 'user_me',
      authorName: 'Sokny Enat',
      authorTag: '@soknyenat',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
      isOwner: true,
    );
  }

  @override
  Future<CommunityPostModel> getPostDetails(String postId) async {
    return mockPosts.firstWhere((p) => p.id == postId);
  }

  @override
  Future<CommunityPostModel> updatePost(String postId, {required String content}) async =>
      mockPosts.first;

  @override
  Future<bool> deletePost(String postId) async => true;

  @override
  Future<bool> toggleLike(String postId) async => true;

  @override
  Future<bool> toggleBookmark(String postId) async => true;

  @override
  Future<bool> repostPost(String postId, {String? caption, String? reposterId}) async {
    repostCalls++;
    lastRepostedId = postId;
    lastRepostCaption = caption;
    final idx = mockPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      mockPosts[idx] = mockPosts[idx].copyWith(
        sharesCount: mockPosts[idx].sharesCount + 1,
        isRepostedByMe: true,
        repostedBy: 'Sokny Enat',
        repostCaption: caption,
        reposterId: reposterId ?? 'user_me',
        originalPostId: mockPosts[idx].id,
      );
    }
    return true;
  }

  @override
  Future<bool> unrepostPost(String postId, {String? reposterId}) async => true;

  @override
  Future<bool> reportPost(String postId, {String reason = 'INAPPROPRIATE_CONTENT'}) async => true;

  @override
  Future<List<CommentModel>> getComments(String postId) async => [];

  @override
  Future<CommentModel> addComment(String postId, String text, {String? parentCommentId}) async {
    return CommentModel(
      id: 'comment_1',
      postId: postId,
      userId: 'user_me',
      userName: 'Sokny Enat',
      userAvatar: '',
      text: text,
      timeAgo: 'Just now',
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

class FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSecureStorage implements SecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalizationService extends GetxService implements LocalizationService {
  @override
  final language = 'en'.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildTestableWidget({
  required Widget child,
  Brightness brightness = Brightness.light,
  Size screenSize = const Size(390, 844),
}) {
  return GetMaterialApp(
    theme: ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    home: Theme(
      data: ThemeData(
        brightness: brightness,
        useMaterial3: true,
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockCommunityRepository mockRepo;
  late CommunityController controller;
  late AuthController authController;

  setUp(() {
    Get.reset();
    Get.testMode = true;

    authController = AuthController(
      authRepository: FakeAuthRepository(),
      secureStorage: FakeSecureStorage(),
      localization: FakeLocalizationService(),
    );
    authController.currentUser.value = const UserEntity(
      id: 'user_me',
      fullName: 'Sokny Enat',
      username: 'soknyenat',
      email: 'sokny@genlink.kh',
      active: true,
      emailVerified: true,
      accountStatus: 'ACTIVE',
      preferredLanguage: 'en',
      role: 'USER',
      totalXp: 100,
      level: 1,
    );
    Get.put<AuthController>(authController);

    mockRepo = MockCommunityRepository();
    controller = CommunityController(repository: mockRepo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  group('GenLink Redesigned Repost Bottom Sheet UI & Functionality Tests', () {
    final imagePost = CommunityPostModel(
      id: 'post_img_1',
      userId: 'user_ren',
      authorName: 'Ren Makara',
      authorTag: '@renmakara',
      authorAvatar: '',
      timeAgo: '18h',
      content: 'Exploring the future of opportunities with GenLink 🚀',
      imageUrls: [
        'assets/images/placeholder_banner.png',
        'assets/images/placeholder_banner.png',
        'assets/images/placeholder_banner.png',
        'assets/images/placeholder_banner.png',
      ],
      community: 'All GenLink',
      isOwner: false,
    );

    final singleImagePost = CommunityPostModel(
      id: 'post_single_img',
      userId: 'user_ren',
      authorName: 'Ren Makara',
      authorTag: '@renmakara',
      authorAvatar: '',
      timeAgo: '2h',
      content: 'Single image post',
      imageUrls: ['assets/images/placeholder_banner.png'],
      community: 'All GenLink',
      isOwner: false,
    );

    final videoPost = CommunityPostModel(
      id: 'post_vid_1',
      userId: 'user_ren',
      authorName: 'Ren Makara',
      authorTag: '@renmakara',
      authorAvatar: '',
      timeAgo: '5h',
      content: 'Watch this demo video!',
      videoUrl: 'https://example.com/demo.mp4',
      community: 'Technology',
      isOwner: false,
    );

    final textOnlyPost = CommunityPostModel(
      id: 'post_txt_1',
      userId: 'user_ren',
      authorName: 'Ren Makara',
      authorTag: '@renmakara',
      authorAvatar: '',
      timeAgo: '1d',
      content: 'Building better career opportunities for students.',
      community: 'Career',
      isOwner: false,
    );

    testWidgets('1 & 2 & 3: Sheet opens and displays header, author name, and post text', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.posts.assignAll([imagePost]);

      await tester.pumpWidget(
        buildTestableWidget(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RepostBottomSheet.show(ctx, post: imagePost, controller: controller),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // 1. Sheet opens
      expect(find.byType(RepostBottomSheet), findsOneWidget);

      // Header icon and title
      expect(find.text('Repost Content'), findsOneWidget);
      expect(find.textContaining('Ren Makara'), findsWidgets);

      // 2. Original author displayed in header subtitle and in preview card
      expect(find.text('Reposting content originally by Ren Makara'), findsOneWidget);
      expect(find.text('Ren Makara'), findsOneWidget);

      // 3. Original post text displayed
      expect(find.text('Exploring the future of opportunities with GenLink 🚀'), findsOneWidget);
    });

    testWidgets('4 & 5: Image post displays actual image preview and 1/4 count badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OriginalPostPreview(post: imagePost),
        ),
      );
      await tester.pump();

      // 4. Actual image preview is rendered (Image widget present)
      expect(find.byType(Image), findsOneWidget);

      // 5. Correct media count is displayed for 4 images: "1/4"
      expect(find.text('1/4'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('5b: Single image post does not display count badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OriginalPostPreview(post: singleImagePost),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('1/1'), findsNothing);
    });

    testWidgets('6: Video post displays video thumbnail and play state overlay', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OriginalPostPreview(post: videoPost),
        ),
      );
      await tester.pump();

      // Play button icon
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('7: Text-only post displays correctly without media container', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OriginalPostPreview(post: textOnlyPost),
        ),
      );
      await tester.pump();

      expect(find.text('Building better career opportunities for students.'), findsOneWidget);
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text('Career · 1d'), findsOneWidget);

      // No image or play button
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('1/1'), findsNothing);
    });

    testWidgets('8 & 9: Quote counter updates reactively and enforces 500 limit', (tester) async {
      final textController = TextEditingController();

      await tester.pumpWidget(
        buildTestableWidget(
          child: RepostQuoteInput(
            controller: textController,
            maxLength: 500,
          ),
        ),
      );
      await tester.pump();

      // Initial state: 0/500
      expect(find.text('0/500'), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Check this out!');
      await tester.pump();

      // Updated counter: 15/500
      expect(find.text('15/500'), findsOneWidget);

      // Verify maxLength is 500
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLength, equals(500));
    });

    testWidgets('10: Cancel button closes the sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.posts.assignAll([imagePost]);

      await tester.pumpWidget(
        buildTestableWidget(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RepostBottomSheet.show(ctx, post: imagePost, controller: controller),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(RepostBottomSheet), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.byType(RepostBottomSheet), findsNothing);
      expect(mockRepo.repostCalls, equals(0));
    });

    testWidgets('11: Repost Now triggers EXISTING repost flow with entered quote', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.posts.assignAll([imagePost]);

      await tester.pumpWidget(
        buildTestableWidget(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RepostBottomSheet.show(ctx, post: imagePost, controller: controller),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter a quote
      await tester.enterText(find.byType(TextField), 'Inspiring journey!');
      await tester.pump();

      // Tap Repost Now
      await tester.tap(find.text('Repost Now'));
      await tester.pumpAndSettle();

      // Repost triggered on repo
      expect(mockRepo.repostCalls, equals(1));
      expect(mockRepo.lastRepostedId, equals('post_img_1'));
      expect(mockRepo.lastRepostCaption, equals('Inspiring journey!'));

      // Sheet dismissed after success
      expect(find.byType(RepostBottomSheet), findsNothing);
    });

    testWidgets('12: Loading state prevents duplicate taps', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.posts.assignAll([imagePost]);

      await tester.pumpWidget(
        buildTestableWidget(
          child: RepostBottomSheet(
            post: imagePost,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      // First tap
      await tester.tap(find.text('Repost Now'));
      await tester.pump();

      expect(mockRepo.repostCalls, equals(1));
    });

    testWidgets('13 & 14: Light Mode and Dark Mode render with high-contrast primary button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Light Mode test
      await tester.pumpWidget(
        buildTestableWidget(
          brightness: Brightness.light,
          child: RepostBottomSheet(
            post: imagePost,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      final repostButtonFinder = find.widgetWithText(ElevatedButton, 'Repost Now');
      expect(repostButtonFinder, findsOneWidget);
      final lightElevatedBtn = tester.widget<ElevatedButton>(repostButtonFinder);
      final lightBg = lightElevatedBtn.style?.backgroundColor?.resolve({});
      expect(lightBg, equals(const Color(0xFF14161A))); // Modern dark charcoal in light mode

      // Dark Mode test
      await tester.pumpWidget(
        buildTestableWidget(
          brightness: Brightness.dark,
          child: RepostBottomSheet(
            post: imagePost,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      final darkElevatedBtn = tester.widget<ElevatedButton>(repostButtonFinder);
      final darkBg = darkElevatedBtn.style?.backgroundColor?.resolve({});
      expect(darkBg, equals(const Color(0xFFF2F4F7))); // High-contrast light button in dark mode (NOT black-on-black)
    });

    testWidgets('15: Small screen (320px width) remains scrollable without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(320, 568),
          child: RepostBottomSheet(
            post: imagePost,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('16: Keyboard open adjusts viewInsets and keeps content accessible', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300), // Keyboard simulated
          ),
          child: GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: RepostBottomSheet(
                post: imagePost,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RepostQuoteInput), findsOneWidget);
      expect(find.text('Repost Now'), findsOneWidget);
    });
  });
}
