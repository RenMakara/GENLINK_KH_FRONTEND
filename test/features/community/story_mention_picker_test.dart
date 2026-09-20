import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/domain/models/story_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/story_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/story_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_creator_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/story_viewer_screen.dart';

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
  final List<StoryGroupModel> _groups;
  final List<StoryMentionUser> _searchUsers;

  _MockStoryRepository({
    List<StoryGroupModel>? groups,
    List<StoryMentionUser>? searchUsers,
  })  : _groups = groups ?? [],
        _searchUsers = searchUsers ?? [];

  @override
  Future<List<StoryGroupModel>> getStories() async => _groups;

  @override
  Future<List<StoryMentionUser>> searchMentionUsers({String query = ''}) async {
    if (query.trim().isEmpty) return _searchUsers;
    return _searchUsers.where((u) => u.matchesQuery(query)).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Story Mention / Tag Picker Tests', () {
    testWidgets(
        'Test 1: Mention sheet does not show hardcoded demo users and displays real users',
        (tester) async {
      final mockRepo = _MockStoryRepository(
        groups: [
          StoryGroupModel(
            userId: 'user_real_1',
            userName: 'Keo Somnang',
            userHandle: 'keosomnang',
            userAvatar: '',
            stories: [],
          ),
        ],
        searchUsers: [
          const StoryMentionUser(
            id: 'user_real_2',
            displayName: 'Chan Vathanaka',
            username: 'cv11',
          ),
        ],
      );

      Get.put<StoryRepository>(mockRepo);
      final storyCtrl = Get.put(StoryController(repository: mockRepo));
      await storyCtrl.fetchStories();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.text,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Mention tool button in creator
      final mentionTool = find.byTooltip('Mention');
      expect(mentionTool, findsOneWidget);
      await tester.tap(mentionTool);
      await tester.pumpAndSettle();

      // Verify the mention sheet title is present
      expect(find.text('Mention Classmate / User'), findsOneWidget);

      // Verify hardcoded demo users are NOT present
      expect(find.text('@SoknyEnat'), findsNothing);
      expect(find.text('@RenMakara'), findsNothing);
      expect(find.text('@HengChansela'), findsNothing);
      expect(find.text('@AUBClass2026'), findsNothing);

      // Verify real users from backend / repository are displayed
      expect(find.text('Keo Somnang'), findsOneWidget);
      expect(find.text('@keosomnang'), findsOneWidget);
      expect(find.text('Chan Vathanaka'), findsOneWidget);
      expect(find.text('@cv11'), findsOneWidget);
    });

    testWidgets('Test 2: Real-time search filters users by name and username',
        (tester) async {
      final mockRepo = _MockStoryRepository(
        searchUsers: [
          const StoryMentionUser(
            id: 'user_1',
            displayName: 'Sophal Meng',
            username: 'sophalm',
          ),
          const StoryMentionUser(
            id: 'user_2',
            displayName: 'Dara Ratana',
            username: 'daratana',
          ),
        ],
      );

      Get.put<StoryRepository>(mockRepo);
      Get.put(StoryController(repository: mockRepo));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.text,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mention'));
      await tester.pumpAndSettle();

      // Initially both real users appear
      expect(find.text('Sophal Meng'), findsOneWidget);
      expect(find.text('Dara Ratana'), findsOneWidget);

      // Type "dara" to filter by name
      final searchField = find.byKey(const Key('mention_search_field'));
      await tester.enterText(searchField, 'dara');
      await tester.pumpAndSettle();

      expect(find.text('Dara Ratana'), findsOneWidget);
      expect(find.text('Sophal Meng'), findsNothing);

      // Filter by username handle
      await tester.enterText(searchField, '@sophalm');
      await tester.pumpAndSettle();

      expect(find.text('Sophal Meng'), findsOneWidget);
      expect(find.text('Dara Ratana'), findsNothing);
    });

    testWidgets(
        'Test 3: Selecting a user adds mention layer and closes mention sheet',
        (tester) async {
      final mockRepo = _MockStoryRepository(
        searchUsers: [
          const StoryMentionUser(
            id: 'user_1',
            displayName: 'Sreynet Ly',
            username: 'sreynet',
          ),
        ],
      );

      Get.put<StoryRepository>(mockRepo);
      Get.put(StoryController(repository: mockRepo));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: StoryCreatorScreen(
            type: StoryType.text,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mention'));
      await tester.pumpAndSettle();

      // Tap on the user tile
      await tester.tap(find.text('Sreynet Ly'));
      await tester.pumpAndSettle();

      // Mention sheet should be closed
      expect(find.text('Mention Classmate / User'), findsNothing);

      // Mention layer should be rendered on canvas
      expect(find.text('@sreynet'), findsOneWidget);
    });

    testWidgets(
        'Test 4: Mention layer in StoryViewerScreen has tap gesture for profile navigation',
        (tester) async {
      final mentionLayer = MovableStoryLayer(
        id: 'layer_mention_test',
        type: LayerType.mention,
        text: '@rathana',
        offset: const Offset(0.5, 0.5),
      );

      final storyItem = StoryItemModel(
        id: 'story_mention_1',
        type: StoryType.photo,
        mediaUrl: 'assets/images/user_profile.png',
        timeAgo: '10m ago',
        createdAt: DateTime.now(),
        layers: [mentionLayer],
      );

      final storyGroup = StoryGroupModel(
        userId: 'author_1',
        userName: 'Author User',
        userHandle: 'authoruser',
        userAvatar: 'assets/images/user_profile.png',
        stories: [storyItem],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/viewer',
          getPages: [
            GetPage(
              name: '/viewer',
              page: () => StoryViewerScreen(
                groups: [storyGroup],
                initialGroupIndex: 0,
              ),
            ),
            GetPage(
              name: '/profile',
              page: () => const Scaffold(body: Text('Profile Screen Target')),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify mention layer is rendered
      expect(find.text('@rathana'), findsOneWidget);

      // Tap on the mention layer
      await tester.tap(find.text('@rathana'));
      await tester.pumpAndSettle();

      // Verify navigation to profile occurred
      expect(find.text('Profile Screen Target'), findsOneWidget);
    });
  });
}
