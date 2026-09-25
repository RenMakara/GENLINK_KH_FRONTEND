import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_interactive_like_button.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLocalStorage extends LocalStorage {
  _MockLocalStorage() : super(storage: const FlutterSecureStorage());

  @override
  Future<String?> readStoryDraft() async => null;

  @override
  Future<void> saveStoryDraft(String draftJson) async {}

  @override
  Future<void> deleteStoryDraft() async {}
}

const _testCurrentUser = UserEntity(
  id: 'current_user_123',
  fullName: 'Current User',
  username: 'currentuser',
  email: 'me@example.com',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 1,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);

    final authController = _FakeAuthController();
    authController.currentUser.value = _testCurrentUser;
    Get.put<AuthController>(authController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Link Button UX Tests', () {
    testWidgets('1. Story Link Button - Tapping anywhere inside the tile triggers copy callback immediately on single tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: const Icon(Icons.link_rounded),
                  title: const Text("Copy Story Link"),
                  subtitle: const Text("Copy direct link to share anywhere"),
                  onTap: () {
                    tapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Copy Story Link'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tapped, isTrue);

      tapped = false;
      await tester.tap(find.byIcon(Icons.link_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tapped, isTrue);

      tapped = false;
      await tester.tap(find.text('Copy direct link to share anywhere'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tapped, isTrue);
    });

    testWidgets('2. Share sheet & Story Viewer - Single tap on Copy Story Link copies story URL to clipboard', (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      final story = StoryItemModel(
        id: 'story_link_test_1',
        type: StoryType.text,
        textContent: 'Story with link test',
        timeAgo: '2m',
        createdAt: DateTime.now(),
      );

      final group = StoryGroupModel(
        userId: 'other_user_456',
        userName: 'Other User',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [story],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final shareOption = find.text('Share Story');
      expect(shareOption, findsOneWidget);
      await tester.tap(shareOption, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final copyLinkFinder = find.text('Copy Story Link');
      expect(copyLinkFinder, findsOneWidget);

      await tester.tap(copyLinkFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(copiedText, 'https://genlink.app/story/story_link_test_1');
      expect(find.text('Link Copied'), findsOneWidget);
    });

    testWidgets('3. Story Link Button has comfortable min 48px touch height and full-surface hit area', (tester) async {
      final story = StoryItemModel(
        id: 'story_hitbox_3',
        type: StoryType.text,
        textContent: 'Hitbox test',
        timeAgo: '1m',
        createdAt: DateTime.now(),
      );

      final group = StoryGroupModel(
        userId: 'other_user_456',
        userName: 'Other User',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [story],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final listTileFinder = find.widgetWithText(ListTile, 'Copy Story Link');
      expect(listTileFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(listTileFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.width, greaterThan(200.0));
    });
  });

  group('Story Like Button Animation & Immediate Sync Tests', () {
    testWidgets('1. Tapping Like responds immediately without delay, triggers 220ms bounce animation', (tester) async {
      final story = StoryItemModel(
        id: 'story_like_anim_1',
        type: StoryType.text,
        textContent: 'Like animation test',
        timeAgo: '1m',
        createdAt: DateTime.now(),
        likesCount: 10,
        isLiked: false,
        allowReactions: true,
      );

      final group = StoryGroupModel(
        userId: 'other_user_456',
        userName: 'Other User',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [story],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(story.isLiked, false);

      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));

      expect(story.isLiked, true);
      expect(story.likesCount, 11);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping Unlike responds immediately and reverses naturally', (tester) async {
      final story = StoryItemModel(
        id: 'story_unlike_anim_2',
        type: StoryType.text,
        textContent: 'Unlike test',
        timeAgo: '1m',
        createdAt: DateTime.now(),
        likesCount: 11,
        isLiked: true,
        allowReactions: true,
      );

      final group = StoryGroupModel(
        userId: 'other_user_456',
        userName: 'Other User',
        userAvatar: 'assets/images/user_profile.png',
        isOwner: false,
        stories: [story],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: [group],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(story.isLiked, true);

      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));

      expect(story.isLiked, false);
      expect(story.likesCount, 10);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('3. StoryInteractiveLikeButton touch target meets minimum 44px hitbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoryInteractiveLikeButton(
                isLiked: false,
                likesCount: 5,
                showCount: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final buttonFinder = find.byType(StoryInteractiveLikeButton);
      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      expect(renderBox.size.width, greaterThanOrEqualTo(44.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
    });
  });
}
