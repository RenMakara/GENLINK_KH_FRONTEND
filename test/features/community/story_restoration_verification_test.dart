import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/demo_stories_data.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';
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

class _MockStoryRepository implements StoryRepository {
  int likeCallCount = 0;

  @override
  Future<List<StoryGroupModel>> getStories() async => [];

  @override
  Future<void> toggleLikeStory(String storyId) async {
    likeCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testUser = UserEntity(
  id: 'current_user_test',
  fullName: 'Current User',
  username: 'currentuser',
  email: 'test@example.com',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 1,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
);

void main() {
  late _MockStoryRepository mockRepo;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);

    final authController = _FakeAuthController();
    authController.currentUser.value = _testUser;
    Get.put<AuthController>(authController, permanent: true);

    mockRepo = _MockStoryRepository();
    final storyController = StoryController(repository: mockRepo);
    Get.put<StoryController>(storyController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Bug Fix and Functionality Restoration Verification', () {
    test('1. Demo story model consistent fields & correct user name and avatar mapping', () {
      final groups = getDemoStoryGroups();
      expect(groups.length, greaterThanOrEqualTo(2));

      // Ren Makara
      final makara = kDemoStories.firstWhere((d) => d.userName == 'Ren Makara');
      expect(makara.userId, 'user_makara');
      expect(makara.avatarUrl, 'assets/images/ren_makara_profile.png');
      expect(makara.author.name, 'Ren Makara');
      expect(makara.author.avatarUrl, 'assets/images/ren_makara_profile.png');
      expect(makara.storyContent, contains('Flutter'));
      expect(makara.createdAt, isA<DateTime>());

      // Heng Chansela
      final chansela = kDemoStories.firstWhere((d) => d.userName == 'Heng Chansela');
      expect(chansela.userId, 'user_chansela');
      expect(chansela.avatarUrl, 'assets/images/heng_chansela_profile.png');
      expect(chansela.author.name, 'Heng Chansela');
      expect(chansela.author.avatarUrl, 'assets/images/heng_chansela_profile.png');
      expect(chansela.storyContent, contains('Hackathon'));
      expect(chansela.createdAt, isA<DateTime>());

      // Converted groups match
      final makaraGroup = groups.firstWhere((g) => g.userName == 'Ren Makara');
      expect(makaraGroup.userAvatar, makara.avatarUrl);
      expect(makaraGroup.author.name, makara.author.name);
      expect(makaraGroup.author.avatarUrl, makara.author.avatarUrl);
      expect(makaraGroup.stories.first.textContent, makara.storyContent);
      expect(makaraGroup.stories.first.id, 'demo_${makara.userId}');
    });

    testWidgets('2. Avatars in StoryTrayWidget have NO initial or text overlays', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: StoryTrayWidget(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check all CircleAvatar widgets inside tray
      final circleAvatars = find.byType(CircleAvatar);
      expect(circleAvatars, findsWidgets);

      for (final element in circleAvatars.evaluate()) {
        final circleAvatarWidget = element.widget as CircleAvatar;
        // Verify child is NOT a text widget displaying initials
        if (circleAvatarWidget.child != null) {
          expect(circleAvatarWidget.child is Text, false,
              reason: 'CircleAvatar must not contain Text initials overlay');
        }
      }
    });

    testWidgets('3. Story Viewer opens for Demo Stories and uses shared StoryViewerScreen', (tester) async {
      final demoGroups = getDemoStoryGroups();

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0, // Ren Makara
            groups: demoGroups,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Shared StoryViewerScreen renders Ren Makara's name
      expect(find.text('Ren Makara'), findsOneWidget);
      expect(find.text(demoGroups[0].stories.first.textContent!), findsOneWidget);

      // Verify no initials in story viewer header CircleAvatar
      final headerAvatars = find.byType(CircleAvatar);
      for (final element in headerAvatars.evaluate()) {
        final avatar = element.widget as CircleAvatar;
        expect(avatar.child is Text, false,
            reason: 'Story header avatar must not overlay initials');
      }
    });

    testWidgets('4. Story Navigation: Tap right advances to next user story (Ren Makara -> Heng Chansela)', (tester) async {
      final demoGroups = getDemoStoryGroups();

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0, // Ren Makara
            groups: demoGroups,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ren Makara'), findsOneWidget);

      // Tap translucent right zone (next story / user)
      final nextZone = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.behavior == HitTestBehavior.translucent).last;
      await tester.tap(nextZone);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // Now viewing Heng Chansela's story!
      expect(find.text('Heng Chansela'), findsOneWidget);
      expect(find.text(demoGroups[1].stories.first.textContent!), findsOneWidget);

      // Tap translucent left zone (previous story / user)
      final prevZone = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.behavior == HitTestBehavior.translucent).first;
      await tester.tap(prevZone);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // Returns to Ren Makara's story!
      expect(find.text('Ren Makara'), findsOneWidget);
    });

    testWidgets('5. Like button works on demo stories with immediate UI update without backend error', (tester) async {
      final demoGroups = getDemoStoryGroups();
      final makaraStory = demoGroups[0].stories.first;
      final initialLikes = makaraStory.likesCount;

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: demoGroups,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // Tap Like button
      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      // Story is liked immediately
      expect(makaraStory.isLiked, true);
      expect(makaraStory.likesCount, initialLikes + 1);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // Verify backend was NOT called for demo story (isolated frontend state)
      expect(mockRepo.likeCallCount, 0);

      // Wait beyond 120ms hardware debounce window
      await Future.delayed(const Duration(milliseconds: 150));

      // Tap Like again to unlike
      await tester.tap(find.byType(StoryInteractiveLikeButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 100));

      expect(makaraStory.isLiked, false);
      expect(makaraStory.likesCount, initialLikes);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('6. Reply button displays "Send a message...", opens reply sheet, and sends reply without crash', (tester) async {
      final demoGroups = getDemoStoryGroups();

      await tester.pumpWidget(
        GetMaterialApp(
          home: StoryViewerScreen(
            initialGroupIndex: 0,
            groups: demoGroups,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Bottom capsule displays "Send a message..."
      expect(find.text('Send a message...'), findsOneWidget);

      // Tap the reply capsule
      await tester.tap(find.text('Send a message...'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Reply sheet opened, displays recipient name and input field
      expect(find.text("Replying to Ren Makara's Story"), findsOneWidget);
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Enter reply text
      await tester.enterText(textFieldFinder, 'Great work Makara!');
      await tester.pump();

      // Submit the reply
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      // Verify toast / confirmation
      expect(find.text('Reply sent '), findsOneWidget);
    });
  });
}
