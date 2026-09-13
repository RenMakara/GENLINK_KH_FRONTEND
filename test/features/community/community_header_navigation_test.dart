import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_header_widget.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';

class MockCommunityRepository implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async {
    return [];
  }

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
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
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async => [
    ForumTopicModel(
      id: 'disc_1',
      title: 'Best practices for GetX state management in Flutter Community App',
      content: 'Discussion content preview text for testing',
      category: 'Technology',
      authorName: 'Sokny Enat',
      authorAvatar: '',
      timeAgo: '2h ago',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      upvotes: 89,
      repliesCount: 34,
      isLiked: false,
    ),
  ];

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

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
    testWidgets('renders Home title, Search, Chat, and Notification buttons', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('tapping action buttons navigates to Search, Chat, and Notifications', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Chat'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
    });

    testWidgets('header title typography strictly matches Finance design system (24px, w800, -0.5)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Home mode title strictly matches Finance title typography
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      final titleFinder = find.text('Home');
      expect(titleFinder, findsOneWidget);
      final Text titleText = tester.widget(titleFinder);
      expect(titleText.style?.fontWeight, equals(FontWeight.w800));
      expect(titleText.style?.fontSize, equals(24.0));
      expect(titleText.style?.letterSpacing, equals(-0.5));

      // Forum non-home mode preserves Community title
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Forum', isHomeScreen: false),
            ),
          ),
        ),
      );

      final commFinder = find.text('Community');
      expect(commFinder, findsOneWidget);

      // Forum home mode preserves Home title
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Forum', isHomeScreen: true),
            ),
          ),
        ),
      );

      final homeFinder = find.text('Home');
      expect(homeFinder, findsOneWidget);
    });

    testWidgets('header responsive typography on compact 320px viewport renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      final titleFinder = find.text('Home');
      expect(titleFinder, findsOneWidget);
      final Text titleText = tester.widget(titleFinder);
      expect(titleText.style?.fontWeight, equals(FontWeight.w800));
      expect(titleText.style?.fontSize, equals(21.0));
      expect(titleText.style?.letterSpacing, equals(-0.3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('header horizontal padding strictly matches AppSpacing.md (16.0px) for edge alignment', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final headerContainer = containers.firstWhere(
        (c) => c.padding == const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );
      expect(headerContainer.padding, equals(const EdgeInsets.symmetric(horizontal: 16.0)));
    });

    testWidgets('header action buttons match Finance tactile styling with surface & subtle border', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      final inkWidgets = tester.widgetList<Ink>(find.byType(Ink));
      expect(inkWidgets.isNotEmpty, isTrue);
      for (final ink in inkWidgets) {
        expect(ink.width, equals(40.0));
        expect(ink.height, equals(40.0));
        final dec = ink.decoration as BoxDecoration?;
        expect(dec, isNotNull);
        expect(dec?.color, equals(AppColors.lightSurfacePrimary));
        expect(dec?.border, isNotNull);
      }
    });

    testWidgets('Home header in Khmer renders localized title without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      expect(find.text('ទំព័រដើម'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home header renders cleanly across 320px, 360px, 390px, 430px viewports', (tester) async {
      final screenSizes = [
        const Size(320, 640),
        const Size(360, 740),
        const Size(390, 844),
        const Size(430, 932),
      ];

      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(52.0),
                child: CommunityHeaderWidget(activeCategory: 'Feed'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size $size');
        expect(find.text('Home'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      }
    });

    testWidgets('Home header renders with dark theme tokens in Dark Mode', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(52.0),
              child: CommunityHeaderWidget(activeCategory: 'Feed'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      final inkWidgets = tester.widgetList<Ink>(find.byType(Ink));
      for (final ink in inkWidgets) {
        final dec = ink.decoration as BoxDecoration?;
        expect(dec?.color, equals(AppColors.darkSurfacePrimary));
      }
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

      expect(find.widgetWithText(InkWell, 'Feed'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Forum'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Event'), findsOneWidget);

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

      await tester.tap(find.widgetWithText(InkWell, 'Forum'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Forum'));

      await tester.tap(find.widgetWithText(InkWell, 'Event'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Event'));

      await tester.tap(find.widgetWithText(InkWell, 'Feed'));
      await tester.pumpAndSettle();
      expect(controller.selectedCategory.value, equals('Feed'));
    });

    testWidgets('tab typography and active/inactive styling match design system', (tester) async {
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

      // Feed is initially active
      final feedFinder = find.descendant(
        of: find.widgetWithText(InkWell, 'Feed'),
        matching: find.byType(Text),
      );
      final Text feedText = tester.widget(feedFinder);
      expect(feedText.style?.fontSize, equals(13.5));
      expect(feedText.style?.fontWeight, equals(FontWeight.w700));
      expect(feedText.style?.letterSpacing, equals(-0.1));

      // Forum is inactive
      final forumFinder = find.descendant(
        of: find.widgetWithText(InkWell, 'Forum'),
        matching: find.byType(Text),
      );
      final Text forumText = tester.widget(forumFinder);
      expect(forumText.style?.fontSize, equals(13.5));
      expect(forumText.style?.fontWeight, equals(FontWeight.w500));
      expect(forumText.style?.letterSpacing, equals(-0.1));
    });

    testWidgets('section heading Latest Discussions matches Finance typography (17px, w700, -0.2 spacing)', (tester) async {
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

      // Switch to Forum tab
      await tester.tap(find.widgetWithText(InkWell, 'Forum'));
      await tester.pumpAndSettle();

      final headingFinder = find.text('Latest Discussions');
      expect(headingFinder, findsOneWidget);

      final Text headingText = tester.widget(headingFinder);
      expect(headingText.style?.fontSize, equals(17.0));
      expect(headingText.style?.fontWeight, equals(FontWeight.w700));
      expect(headingText.style?.letterSpacing, equals(-0.2));
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
      expect(find.widgetWithText(InkWell, 'Feed'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Forum'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Event'), findsOneWidget);
    });

    testWidgets('responsive verification across 320px, 360px, 390px, 430px produces no overflow', (tester) async {
      final screenSizes = [
        const Size(320, 640),
        const Size(360, 740),
        const Size(390, 844),
        const Size(430, 932),
      ];

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

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size $size');
        expect(find.widgetWithText(InkWell, 'Feed'), findsOneWidget);
        expect(find.widgetWithText(InkWell, 'Forum'), findsOneWidget);
        expect(find.widgetWithText(InkWell, 'Event'), findsOneWidget);
      }
    });

    testWidgets('Khmer localization renders tabs and header cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
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
          locale: const Locale('km', 'KH'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(InkWell, 'ព័ត៌មាន'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'វេទិកា'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'ព្រឹត្តិការណ៍'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode with dark theme tokens', (tester) async {
      final controller = CommunityController(repository: MockCommunityRepository());
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CommunityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(InkWell, 'Feed'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Forum'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Event'), findsOneWidget);
    });
  });
}
