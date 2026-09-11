import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/story_tray_widget.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';

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

class _MockStoryRepo implements StoryRepository {
  List<StoryGroupModel> mockData = [];
  int fetchCallCount = 0;
  Duration delay = Duration.zero;

  @override
  Future<List<StoryGroupModel>> getStories() async {
    fetchCallCount++;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return mockData;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': {
          'community.yourStory': 'Your Story',
        },
      };
}

const _testUser = UserEntity(
  id: 'user_owner_123',
  fullName: 'Owner User',
  username: 'owner_user',
  email: 'owner@example.com',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 1,
  preferredLanguage: 'ENGLISH',
  role: 'USER',
  active: true,
  avatarUrl: 'assets/images/user_profile.png',
);

Widget _buildTestApp(Widget child) {
  return GetMaterialApp(
    translations: _TestTranslations(),
    locale: const Locale('en'),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockStoryRepo mockRepo;

  setUp(() {
    Get.testMode = true;
    Get.deleteAll(force: true);
    Get.put<LocalStorage>(_MockLocalStorage());

    final authCtrl = _FakeAuthController();
    authCtrl.currentUser.value = _testUser;
    Get.put<AuthController>(authCtrl);

    mockRepo = _MockStoryRepo();
  });

  tearDown(() {
    Get.deleteAll(force: true);
  });

  group('Story Tray Initialization and Restoration Tests', () {
    testWidgets('1. LOADING: shows skeleton loader when loading and storyGroups is empty, no demo users', (tester) async {
      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      controller.isLoading.value = true;
      controller.storyGroups.clear();

      await tester.pumpWidget(_buildTestApp(const StoryTrayWidget()));
      await tester.pump();

      // Skeletons are visible
      final circleAvatars = find.byType(CircleAvatar);
      expect(circleAvatars, findsWidgets);

      // Verify NO demo users appear
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Heng Chansela'), findsNothing);
    });

    testWidgets('2. NO STORIES: empty state shows only the owner "Your Story" entry with add button', (tester) async {
      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      controller.isLoading.value = false;
      controller.storyGroups.assignAll([
        StoryGroupModel(
          userId: 'user_owner_123',
          userName: 'Your Story',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: true,
          stories: [],
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(const StoryTrayWidget()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Only 1 item in tray (the owner\'s entry)
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Your Story'), findsOneWidget);

      // Absolutely NO demo users
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Heng Chansela'), findsNothing);
    });

    testWidgets('3. REAL STORIES: displays only real story users with correct usernames and avatars', (tester) async {
      final now = DateTime.now();
      final realStory = StoryItemModel(
        id: 'real_story_1',
        type: StoryType.text,
        textContent: 'Hello real world',
        timeAgo: '2h',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      controller.isLoading.value = false;
      controller.storyGroups.assignAll([
        StoryGroupModel(
          userId: 'user_owner_123',
          userName: 'Your Story',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: true,
          stories: [],
        ),
        StoryGroupModel(
          userId: 'real_user_456',
          userName: 'Sophea Sok',
          userAvatar: 'assets/images/user_profile.png',
          isOwner: false,
          stories: [realStory],
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(const StoryTrayWidget()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Real user is rendered
      expect(find.text('Sophea Sok'), findsOneWidget);
      expect(find.text('Your Story'), findsOneWidget);

      // Demo users are not rendered
      expect(find.text('Ren Makara'), findsNothing);
      expect(find.text('Heng Chansela'), findsNothing);
    });

    testWidgets('4. NULL/INVALID AVATAR: safe fallback avatar does not crash and displays safely', (tester) async {
      final now = DateTime.now();
      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      controller.isLoading.value = false;
      controller.storyGroups.assignAll([
        StoryGroupModel(
          userId: 'user_owner_123',
          userName: 'Your Story',
          userAvatar: '', // empty avatar
          isOwner: true,
          stories: [],
        ),
        StoryGroupModel(
          userId: 'user_null_avatar',
          userName: 'Null User',
          userAvatar: 'null', // literal "null" string
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 's_null',
              type: StoryType.text,
              textContent: 'Test',
              timeAgo: '10m',
              createdAt: now.subtract(const Duration(minutes: 10)),
            ),
          ],
        ),
        StoryGroupModel(
          userId: 'user_malformed_url',
          userName: 'Bad URL User',
          userAvatar: 'http://not a valid url',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 's_bad',
              type: StoryType.text,
              textContent: 'Bad URL test',
              timeAgo: '5m',
              createdAt: now.subtract(const Duration(minutes: 5)),
            ),
          ],
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(const StoryTrayWidget()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Renders successfully without throwing unhandled exceptions
      expect(find.text('Null User'), findsOneWidget);
      expect(find.text('Bad URL User'), findsOneWidget);

      // Verify CircleAvatar children have NO text initials overlay
      final circleAvatars = find.byType(CircleAvatar);
      for (final el in circleAvatars.evaluate()) {
        final widget = el.widget as CircleAvatar;
        expect(widget.child is Text, isFalse, reason: 'Story avatar must not overlay initials');
      }
    });

    testWidgets('5. DEDUPLICATION: duplicate users or duplicate owner in story groups are deduplicated', (tester) async {
      final now = DateTime.now();
      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      controller.isLoading.value = false;
      controller.storyGroups.assignAll([
        StoryGroupModel(
          userId: 'user_owner_123',
          userName: 'Owner First',
          userAvatar: '',
          isOwner: true,
          stories: [],
        ),
        // Duplicate owner from backend
        StoryGroupModel(
          userId: 'user_owner_123',
          userName: 'Owner Duplicate',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 's_own',
              type: StoryType.text,
              textContent: 'Owner story',
              timeAgo: '1m',
              createdAt: now,
            ),
          ],
        ),
        // Duplicate other user
        StoryGroupModel(
          userId: 'other_user_789',
          userName: 'Chanda Kim',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 's_chanda_1',
              type: StoryType.text,
              textContent: 'Chanda 1',
              timeAgo: '1m',
              createdAt: now,
            ),
          ],
        ),
        StoryGroupModel(
          userId: 'other_user_789',
          userName: 'Chanda Kim Duplicate',
          userAvatar: '',
          isOwner: false,
          stories: [
            StoryItemModel(
              id: 's_chanda_2',
              type: StoryType.text,
              textContent: 'Chanda 2',
              timeAgo: '1m',
              createdAt: now,
            ),
          ],
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(const StoryTrayWidget()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Only one Chanda Kim rendered
      expect(find.text('Chanda Kim'), findsOneWidget);
      expect(find.text('Chanda Kim Duplicate'), findsNothing);
    });

    testWidgets('6. EXPIRATION: stories older than 24h are purged; users with only expired stories do not appear', (tester) async {
      final now = DateTime.now();
      final expiredStory = StoryItemModel(
        id: 's_expired',
        type: StoryType.text,
        textContent: 'Old story',
        timeAgo: '25h',
        createdAt: now.subtract(const Duration(hours: 25)),
      );

      final freshStory = StoryItemModel(
        id: 's_fresh',
        type: StoryType.text,
        textContent: 'Fresh story',
        timeAgo: '1h',
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      controller.isLoading.value = false;
      controller.storyGroups.assignAll([
        StoryGroupModel(
          userId: 'user_owner_123',
          userName: 'Your Story',
          userAvatar: '',
          isOwner: true,
          stories: [expiredStory],
        ),
        StoryGroupModel(
          userId: 'user_expired_only',
          userName: 'Expired User',
          userAvatar: '',
          isOwner: false,
          stories: [expiredStory],
        ),
        StoryGroupModel(
          userId: 'user_active',
          userName: 'Active User',
          userAvatar: '',
          isOwner: false,
          stories: [freshStory],
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(const StoryTrayWidget()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Active user is shown
      expect(find.text('Active User'), findsOneWidget);
      // Expired only user is NOT shown
      expect(find.text('Expired User'), findsNothing);

      // purgeExpiredStories removes expired from controller
      controller.purgeExpiredStories();
      expect(controller.storyGroups.any((g) => g.userId == 'user_expired_only'), isFalse);
    });

    test('7. LIFECYCLE & DISPOSAL: controller handles disposal gracefully without throwing', () async {
      final controller = StoryController(repository: mockRepo);
      Get.put<StoryController>(controller);
      Get.delete<StoryController>(force: true);
      expect(controller.isClosed, isTrue);

      // Calling fetchStories on disposed controller is safe
      await controller.fetchStories();
      controller.purgeExpiredStories();
      controller.markStoryAsViewed('some_id');
      await controller.deleteStory('some_id');
    });

    test('8. IN-FLIGHT GUARD: concurrent fetchStories calls do not duplicate repository requests', () async {
      mockRepo.delay = const Duration(milliseconds: 50);
      final controller = StoryController(repository: mockRepo);

      final f1 = controller.fetchStories();
      final f2 = controller.fetchStories();
      final f3 = controller.fetchStories();

      await Future.wait([f1, f2, f3]);

      // Only 1 repository call was triggered because subsequent calls were in-flight
      expect(mockRepo.fetchCallCount, 1);
    });
  });
}
