import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/data/repositories/story_repository_impl.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/demo_stories_data.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStoryRepository implements StoryRepository {
  final List<StoryGroupModel> Function() onGetStories;

  _MockStoryRepository({required this.onGetStories});

  @override
  Future<List<StoryGroupModel>> getStories() async => onGetStories();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testRealUser = UserEntity(
  id: 'real_user_123',
  fullName: 'Real User Name',
  username: 'realuser',
  email: 'real@example.com',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 1,
  preferredLanguage: 'en',
  role: 'USER',
  active: true,
);

void main() {
  setUp(() {
    Get.testMode = true;
    final authController = _FakeAuthController();
    authController.currentUser.value = _testRealUser;
    Get.put<AuthController>(authController, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story No Demo Users Regression Tests', () {
    test('1. getDemoStoryGroups and kDemoStories are completely empty', () {
      expect(getDemoStoryGroups(), isEmpty);
      expect(kDemoStories, isEmpty);
    });

    test('2. StoryRepositoryImpl fallback getStoryViewers returns empty list (no mock viewers)', () async {
      final repo = StoryRepositoryImpl();
      final viewers = await repo.getStoryViewers('story_1');
      expect(viewers, isEmpty);
      expect(viewers.any((v) => v.userName == 'Heng Chansela' || v.userName == 'Chhaeng Sokuntheara'), false);
    });

    testWidgets('3. StoryTrayWidget shows ONLY create-story slot when no stories exist (empty state)', (tester) async {
      final mockRepo = _MockStoryRepository(onGetStories: () => []);
      final controller = StoryController(repository: mockRepo);
      controller.isLoading.value = false;
      controller.storyGroups.clear();
      Get.put<StoryController>(controller, permanent: true);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: StoryTrayWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 1 item in ListView: the create-story affordance
      expect(find.byType(StoryTrayWidget), findsOneWidget);
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Heng Chansela'), findsNothing);
      expect(find.text('Dary'), findsNothing);
      expect(find.text('MayMay'), findsNothing);
      expect(find.text('AIS Tech Club'), findsNothing);
    });

    testWidgets('4. StoryTrayWidget filters out any demo_ or mock_ groups if injected', (tester) async {
      final mockRepo = _MockStoryRepository(onGetStories: () => [
        StoryGroupModel(
          userId: 'demo_user_1',
          userName: 'Fake Demo User',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 'demo_story_1',
              type: StoryType.text,
              textContent: 'Fake content',
              timeAgo: '1h ago',
              createdAt: DateTime.now(),
            ),
          ],
        ),
        StoryGroupModel(
          userId: 'mock_user_2',
          userName: 'Mock Author',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 'mock_story_2',
              type: StoryType.text,
              textContent: 'Mock content',
              timeAgo: '2h ago',
              createdAt: DateTime.now(),
            ),
          ],
        ),
        StoryGroupModel(
          userId: 'real_friend_456',
          userName: 'Sokha Chan',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 'real_story_456',
              type: StoryType.photo,
              mediaUrl: 'https://example.com/photo.jpg',
              timeAgo: '3h ago',
              createdAt: DateTime.now(),
            ),
          ],
        ),
      ]);

      final controller = StoryController(repository: mockRepo);
      await controller.fetchStories();
      Get.put<StoryController>(controller, permanent: true);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: StoryTrayWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Real user appears
      expect(find.text('Sokha Chan'), findsOneWidget);

      // Demo/mock users do NOT appear
      expect(find.text('Fake Demo User'), findsNothing);
      expect(find.text('Mock Author'), findsNothing);
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Heng Chansela'), findsNothing);
    });

    testWidgets('5. Real user stories and current user own story render without demo users', (tester) async {
      final mockRepo = _MockStoryRepository(onGetStories: () => [
        StoryGroupModel(
          userId: 'real_user_123',
          userName: 'Real User Name',
          userAvatar: '',
          isOwner: true,
          stories: [
            StoryItemModel(
              id: 'my_story_1',
              type: StoryType.text,
              textContent: 'My live story',
              timeAgo: '10m ago',
              createdAt: DateTime.now(),
            ),
          ],
        ),
        StoryGroupModel(
          userId: 'classmate_789',
          userName: 'Bopha Vong',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 'story_789',
              type: StoryType.photo,
              mediaUrl: 'https://example.com/bopha.jpg',
              timeAgo: '45m ago',
              createdAt: DateTime.now(),
            ),
          ],
        ),
      ]);

      final controller = StoryController(repository: mockRepo);
      await controller.fetchStories();
      Get.put<StoryController>(controller, permanent: true);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: StoryTrayWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bopha Vong'), findsOneWidget);
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Heng Chansela'), findsNothing);
    });
  });
}
