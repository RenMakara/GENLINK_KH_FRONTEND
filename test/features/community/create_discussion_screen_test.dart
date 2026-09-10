import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/community/domain/models/community_models.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';

class _FakeCommunityRepository implements CommunityRepository {
  final List<ForumTopicModel> discussions = [];
  final Map<String, List<CommentModel>> discussionCommentsStore = {};

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async => CommunityPostModel(
    id: 'mock_1',
    userId: 'user_123',
    authorName: 'Sokha Meng',
    authorTag: '@sokhameng',
    authorAvatar: '',
    timeAgo: 'Just now',
    content: content,
    imageUrls: imageUrls,
    visibility: visibility,
    community: community,
  );

  @override
  Future<List<ForumTopicModel>> getDiscussions({String? category, int page = 1, int limit = 20}) async => discussions;

  @override
  Future<ForumTopicModel> createDiscussion({
    required String title,
    required String content,
    required String category,
    bool anonymous = false,
  }) async {
    final newTopic = ForumTopicModel(
      id: 'test_disc_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'user_123',
      title: title,
      content: content,
      category: category,
      authorName: 'Sokha Meng',
      authorAvatar: 'assets/images/user_profile.png',
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
      isLiked: false,
      isPinned: false,
      isOwner: true,
    );
    discussions.insert(0, newTopic);
    return newTopic;
  }

  @override
  Future<ForumTopicModel> updateDiscussion(
    String discussionId, {
    required String title,
    required String content,
    required String category,
  }) async {
    final updated = ForumTopicModel(
      id: discussionId,
      authorId: 'user_123',
      authorName: 'Sokha Meng',
      authorAvatar: '',
      title: title,
      content: content,
      category: category,
      timeAgo: 'Just now',
      upvotes: 0,
      repliesCount: 0,
      isOwner: true,
    );
    return updated;
  }

  @override
  Future<bool> deleteDiscussion(String discussionId) async => true;

  @override
  Future<bool> toggleDiscussionLike(
    String discussionId, {
    bool isCurrentlyLiked = false,
  }) async => true;

  @override
  Future<List<CommentModel>> getDiscussionComments(String discussionId) async =>
      List<CommentModel>.from(discussionCommentsStore[discussionId] ?? []);

  @override
  Future<CommentModel> addDiscussionComment(
    String discussionId,
    String content, {
    String? parentCommentId,
  }) async {
    final comment = CommentModel(
      id: 'mock_c_1',
      postId: discussionId,
      userId: 'user_123',
      userName: 'Sokha Meng',
      userAvatar: '',
      text: content,
      timeAgo: 'Just now',
    );
    discussionCommentsStore.putIfAbsent(discussionId, () => []).add(comment);
    return comment;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rxn<UserEntity>(
    const UserEntity(
      id: 'user_123',
      email: 'tester@genlink.kh',
      username: 'tester',
      fullName: 'Sokha Meng',
      avatarUrl: '',
      emailVerified: true,
      accountStatus: 'ACTIVE',
      totalXp: 100,
      level: 2,
      preferredLanguage: 'en',
      role: 'USER',
      active: true,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<AuthController>(_FakeAuthController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestWidget({
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
    ForumTopicModel? initialDiscussion,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: theme ?? AppTheme.light,
      home: CreateDiscussionScreen(initialDiscussion: initialDiscussion),
    );
  }

  group('CreateDiscussionScreen UI & UX Tests', () {
    testWidgets('1. Initial empty form has all fields, placeholders, and disabled Publish button', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Discussion'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      final publishBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(publishBtn.onPressed, isNull);

      expect(find.text('Sokha Meng'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Select a category'), findsOneWidget);

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('What do you want to talk about?'), findsOneWidget);

      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Share your thoughts, question, or idea...'), findsOneWidget);

      expect(find.text('0 / 5000'), findsOneWidget);
    });

    testWidgets('2. Category bottom sheet displays categories and updates selection', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();

      expect(find.text('Technology'), findsWidgets);
      expect(find.text('Campus Life'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Study & Education'), findsOneWidget);
      expect(find.text('Career'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);

      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();

      expect(find.text('Technology'), findsOneWidget);
    });

    testWidgets('3. Form validation activates Publish only when category, non-whitespace title, and non-whitespace content are filled', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      final publishFinder = find.byType(ElevatedButton);

      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Technology').last);
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(publishFinder).onPressed, isNull);

      await tester.enterText(textFields.at(0), '     ');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(publishFinder).onPressed, isNull);

      await tester.enterText(textFields.at(0), 'Clean Architecture in Flutter');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(publishFinder).onPressed, isNull);

      await tester.enterText(textFields.at(1), '     ');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(publishFinder).onPressed, isNull);

      await tester.enterText(textFields.at(1), 'Here are best practices for project structure.');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(publishFinder).onPressed, isNotNull);

      expect(find.text('46 / 5000'), findsOneWidget);
    });

    testWidgets('4. Discard confirmation dialog triggers when unsaved changes exist', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateDiscussionScreen(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(CreateDiscussionScreen), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Draft title');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Your discussion has not been published yet.'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Draft title'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(CreateDiscussionScreen), findsNothing);
    });

    testWidgets('5. Publishing creates discussion, shows success banner, and syncs controller', (tester) async {
      final repo = _FakeCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put(controller);
      final initialCount = controller.forumLatestDiscussions.length;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects').last);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'My Flutter Open Source Project');
      await tester.pump();
      await tester.enterText(textFields.at(1), 'Check out the GitHub repo and star it!');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(controller.forumLatestDiscussions.length, initialCount + 1);
      expect(controller.forumLatestDiscussions.first.title, 'My Flutter Open Source Project');
      expect(controller.forumLatestDiscussions.first.category, 'Projects');
      expect(controller.posts.any((p) => p.discussionTitle == 'My Flutter Open Source Project'), isFalse);
    });

    testWidgets('6. Edit mode pre-fills initial values and updates on submit', (tester) async {
      final repo = _FakeCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put(controller);

      final initial = ForumTopicModel(
        id: 'edit_topic_1',
        authorId: 'user_123',
        authorName: 'Sokha Meng',
        authorAvatar: '',
        title: 'Initial Discussion Title',
        content: 'Initial Discussion Content Body',
        category: 'Study & Education',
        timeAgo: '1h ago',
        upvotes: 5,
        repliesCount: 2,
        isOwner: true,
      );
      repo.discussions.add(initial);
      controller.forumLatestDiscussions.add(initial);

      await tester.pumpWidget(createTestWidget(initialDiscussion: initial));
      await tester.pumpAndSettle();

      expect(find.text('Edit Discussion'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Study & Education'), findsOneWidget);
      expect(find.text('Initial Discussion Title'), findsOneWidget);
      expect(find.text('Initial Discussion Content Body'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Initial Discussion Title'), 'Updated Discussion Title');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(controller.forumLatestDiscussions.firstWhere((d) => d.id == 'edit_topic_1').title, 'Updated Discussion Title');
    });

    testWidgets('7. Khmer localization + Dark Mode renders with Khmer strings without error', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('km', 'KH'),
        theme: AppTheme.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('បង្កើតការពិភាក្សា'), findsOneWidget);
      expect(find.text('បោះពុម្ព'), findsOneWidget);
      expect(find.text('សាធារណៈ'), findsOneWidget);
      expect(find.text('ប្រភេទ'), findsOneWidget);
      expect(find.text('ជ្រើសរើសប្រភេទ'), findsOneWidget);
      expect(find.text('ចំណងជើង'), findsOneWidget);
      expect(find.text('តើអ្នកចង់និយាយអំពីអ្វី?'), findsOneWidget);
      expect(find.text('ខ្លឹមសារ'), findsOneWidget);
      expect(find.text('ចែករំលែកការយល់ឃើញ សំណួរ ឬគំនិតរបស់អ្នក...'), findsOneWidget);
    });

    testWidgets('8. English + Light Mode renders with English strings without error', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('en', 'US'),
        theme: AppTheme.light,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Create Discussion'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Select a category'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('What do you want to talk about?'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Share your thoughts, question, or idea...'), findsOneWidget);
    });

    testWidgets('9. Khmer + Light Mode & English + Dark Mode render without overflow', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('km', 'KH'),
        theme: AppTheme.light,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('en', 'US'),
        theme: AppTheme.dark,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Multi-line Khmer, English, and Mixed language content input and expansion', (tester) async {
      final repo = _FakeCommunityRepository();
      Get.put(CommunityController(repository: repo));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      const mixedTitle = 'តើ Flutter ល្អសម្រាប់ការអភិវឌ្ឍ Mobile Apps ដែរឬទេ?';
      await tester.enterText(textFields.at(0), mixedTitle);
      await tester.pump();
      expect(find.text(mixedTitle), findsOneWidget);

      const longContent = 'Flutter គឺជា UI toolkit របស់ Google ដែលអនុញ្ញាតឱ្យបង្កើតកម្មវិធី Multi-platform យ៉ាងរលូន។\n\n'
          'Key benefits:\n'
          '1. Fast Development with Hot Reload\n'
          '2. High performance Skia/Impeller rendering engine\n'
          '3. Single codebase for iOS, Android, Web & Desktop';
      await tester.enterText(textFields.at(1), longContent);
      await tester.pump();
      expect(find.text(longContent), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
