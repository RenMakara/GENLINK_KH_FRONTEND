import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/poll_widget.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/post_card_widget.dart';

class MockPollCommunityRepository implements CommunityRepository {
  bool shouldFailVote = false;
  bool shouldFailCreate = false;
  int voteCallCount = 0;
  String? lastVotedPostId;
  String? lastVotedOptionId;

  String? createdPollQuestion;
  List<String>? createdPollOptions;
  String? createdPollCaption;

  @override
  Future<CommunityPostModel> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
  }) async {
    if (shouldFailCreate) {
      throw Exception('Simulated poll creation error');
    }
    createdPollQuestion = question;
    createdPollOptions = options;
    createdPollCaption = caption;

    return CommunityPostModel(
      id: 'poll_post_new',
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: '@sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: caption ?? '',
      visibility: visibility,
      postType: 'poll',
      pollQuestion: question,
      pollOptions: options
          .asMap()
          .entries
          .map((e) => PollOptionModel(
                id: 'opt_${e.key + 1}',
                text: e.value,
                votes: 0,
                isVoted: false,
              ))
          .toList(),
      pollTotalVotes: 0,
      hasVoted: false,
      pollDuration: '3 Days',
    );
  }

  @override
  Future<CommunityPostModel> votePoll({
    required String postId,
    required String optionId,
  }) async {
    voteCallCount++;
    lastVotedPostId = postId;
    lastVotedOptionId = optionId;

    if (shouldFailVote) {
      throw Exception('Simulated network vote failure');
    }

    final existing = feedPosts.firstWhereOrNull((p) => p.id == postId);
    if (existing != null) {
      final opts = (existing.pollOptions ?? []).map((o) {
        return o.copyWith(
          votes: o.id == optionId ? o.votes + 1 : o.votes,
          isVoted: o.id == optionId,
        );
      }).toList();
      return existing.copyWith(
        pollOptions: opts,
        pollTotalVotes: existing.pollTotalVotes + 1,
        hasVoted: true,
        myOptionId: optionId,
      );
    }

    return CommunityPostModel(
      id: postId,
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: '@sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: 'Poll',
      postType: 'poll',
      pollQuestion: 'Poll question',
      pollOptions: [
        PollOptionModel(id: optionId, text: 'Option', votes: 1, isVoted: true),
      ],
      pollTotalVotes: 1,
      hasVoted: true,
      myOptionId: optionId,
      pollDuration: '3 Days',
    );
  }

  List<CommunityPostModel> feedPosts = [];

  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async =>
      List<CommunityPostModel>.from(feedPosts);

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'normal_post_1',
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: '@sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      visibility: visibility,
    );
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

  Widget buildTestApp({
    required Widget child,
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('en', 'US'),
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(body: child),
    );
  }

  group('Poll Post Finalization - Comprehensive Test Suite', () {
    testWidgets('1. Poll creation modal sheet opens, validates empty inputs, and limits options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockPollCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      await tester.pumpWidget(
        buildTestApp(child: const CreatePostScreen()),
      );
      await tester.pumpAndSettle();

      // Find Poll toolbar button
      final pollButton = find.byTooltip('Poll');
      expect(pollButton, findsOneWidget);

      await tester.tap(pollButton);
      await tester.pumpAndSettle();

      // Modal sheet should be visible
      expect(find.text('Create Poll'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Add Option'), findsOneWidget);

      // Attempt to submit empty poll -> should show validation error
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a poll question'), findsOneWidget);

      // Enter question
      final questionField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Ask a question...',
      );
      expect(questionField, findsOneWidget);
      await tester.enterText(questionField, 'Best mobile framework?');
      await tester.pumpAndSettle();

      // Attempt to submit with empty options -> should show min options error
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Please provide at least 2 options'), findsOneWidget);

      // Enter identical options -> should show duplicate error
      final optionFields = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText?.startsWith('Option') ?? false),
      );
      expect(optionFields, findsNWidgets(2));

      await tester.enterText(optionFields.at(0), 'Flutter');
      await tester.enterText(optionFields.at(1), 'Flutter');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Poll options must be unique'), findsOneWidget);

      // Add options up to 6
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Add Option'));
        await tester.pumpAndSettle();
      }

      // Max 6 options reached, "Add Option" button should now be hidden
      expect(find.text('Add Option'), findsNothing);

      // Enter valid options for first 2
      final allSixFields = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText?.startsWith('Option') ?? false),
      );
      expect(allSixFields, findsNWidgets(6));

      await tester.enterText(allSixFields.at(0), 'Flutter');
      await tester.enterText(allSixFields.at(1), 'React Native');
      await tester.pumpAndSettle();

      // Remove the 4 extra empty options
      for (int i = 0; i < 4; i++) {
        final removeIcons = find.byIcon(Icons.remove_circle_outline_rounded);
        if (removeIcons.evaluate().isNotEmpty) {
          await tester.tap(removeIcons.first);
          await tester.pumpAndSettle();
        }
      }

      // Save valid poll
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Sheet closes and poll preview card appears on CreatePostScreen
      expect(find.text('Best mobile framework?'), findsOneWidget);
      expect(find.textContaining('2 options'), findsOneWidget);
    });

    testWidgets('2. CreatePostScreen submits poll post via controller.createPollPost', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockPollCommunityRepository();
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);

      final createPostKey = GlobalKey<CreatePostScreenState>();
      await tester.pumpWidget(
        buildTestApp(child: CreatePostScreen(key: createPostKey)),
      );
      await tester.pumpAndSettle();

      // Programmatically set poll
      createPostKey.currentState!.setPollForTesting(
        'Which DB do you use?',
        ['PostgreSQL', 'MongoDB'],
      );
      await tester.pumpAndSettle();

      expect(find.text('Which DB do you use?'), findsOneWidget);

      // Add optional caption
      final textInput = find.byType(TextField).first;
      await tester.enterText(textInput, 'Tech stack poll for 2026');
      await tester.pumpAndSettle();

      // Tap Post button
      final postButton = find.text('Post');
      expect(postButton, findsOneWidget);
      await tester.tap(postButton);
      await tester.pumpAndSettle();

      // Verify repository was invoked with correct poll details
      expect(repo.createdPollQuestion, 'Which DB do you use?');
      expect(repo.createdPollOptions, ['PostgreSQL', 'MongoDB']);
      expect(repo.createdPollCaption, 'Tech stack poll for 2026');
      expect(controller.posts.length, 1);
      expect(controller.posts.first.pollQuestion, 'Which DB do you use?');
    });

    testWidgets('3. Feed rendering: PollWidget displays question, options, percentages, and total votes', (tester) async {
      final options = [
        PollOptionModel(id: 'opt_1', text: 'Option A', votes: 3, isVoted: false),
        PollOptionModel(id: 'opt_2', text: 'Option B', votes: 1, isVoted: false),
      ];

      await tester.pumpWidget(
        buildTestApp(
          child: PollWidget(
            question: 'Sample Feed Poll Question?',
            options: options,
            totalVotes: 4,
            hasVoted: true,
            duration: '3 Days',
            hideResultsUntilVote: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sample Feed Poll Question?'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.textContaining('4 votes'), findsOneWidget);
      expect(find.textContaining('3 Days'), findsOneWidget);
    });

    testWidgets('4. Real voting in PostCardWidget: optimistic update and backend repository sync', (tester) async {
      final repo = MockPollCommunityRepository();
      final post = CommunityPostModel(
        id: 'poll_post_101',
        userId: 'user_1',
        authorName: 'Sokny Enath',
        authorTag: '@sokny',
        authorAvatar: '',
        timeAgo: '2h ago',
        content: 'Community Vote',
        postType: 'poll',
        pollQuestion: 'Favorite Backend?',
        pollOptions: [
          PollOptionModel(id: 'opt_java', text: 'Spring Boot', votes: 5, isVoted: false),
          PollOptionModel(id: 'opt_node', text: 'Node.js', votes: 5, isVoted: false),
        ],
        pollTotalVotes: 10,
        hasVoted: false,
        pollDuration: '2 Days',
      );
      repo.feedPosts = [post];
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);
      controller.posts.assignAll([post]);

      await tester.pumpWidget(
        buildTestApp(
          child: SingleChildScrollView(
            child: PostCardWidget(
              post: post,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unvoted state initially
      expect(find.text('Spring Boot'), findsOneWidget);
      expect(find.text('Node.js'), findsOneWidget);

      // Tap Spring Boot option
      await tester.tap(find.text('Spring Boot'));
      await tester.pump(); // trigger optimistic update

      // Optimistic update should immediately make total votes 11, Spring Boot votes 6
      expect(controller.posts.first.hasVoted, isTrue);
      expect(controller.posts.first.myOptionId, 'opt_java');
      expect(controller.posts.first.pollTotalVotes, 11);

      await tester.pumpAndSettle();

      // Verify backend was called with correct postId and optionId
      expect(repo.voteCallCount, 1);
      expect(repo.lastVotedPostId, 'poll_post_101');
      expect(repo.lastVotedOptionId, 'opt_java');
    });

    testWidgets('5. Duplicate vote prevention: re-tapping selected option is a no-op', (tester) async {
      final repo = MockPollCommunityRepository();
      final post = CommunityPostModel(
        id: 'poll_post_dup',
        userId: 'user_1',
        authorName: 'Sokny Enath',
        authorTag: '@sokny',
        authorAvatar: '',
        timeAgo: '1h ago',
        content: 'Duplicate test',
        postType: 'poll',
        pollQuestion: 'Which color?',
        pollOptions: [
          PollOptionModel(id: 'opt_blue', text: 'Blue', votes: 1, isVoted: true),
          PollOptionModel(id: 'opt_red', text: 'Red', votes: 0, isVoted: false),
        ],
        pollTotalVotes: 1,
        hasVoted: true,
        myOptionId: 'opt_blue',
        pollDuration: '1 Day',
      );
      repo.feedPosts = [post];
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);
      controller.posts.assignAll([post]);

      await tester.pumpWidget(
        buildTestApp(
          child: SingleChildScrollView(
            child: PostCardWidget(
              post: post,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Blue (already voted option)
      await tester.tap(find.text('Blue'));
      await tester.pumpAndSettle();

      // Should NOT make any backend call
      expect(repo.voteCallCount, 0);
      expect(controller.posts.first.pollTotalVotes, 1);
      expect(controller.posts.first.myOptionId, 'opt_blue');
    });

    testWidgets('6. Vote rollback on network error', (tester) async {
      final repo = MockPollCommunityRepository();
      repo.shouldFailVote = true; // force error
      final post = CommunityPostModel(
        id: 'poll_post_fail',
        userId: 'user_1',
        authorName: 'Sokny Enath',
        authorTag: '@sokny',
        authorAvatar: '',
        timeAgo: '10m ago',
        content: 'Rollback test',
        postType: 'poll',
        pollQuestion: 'Will this fail?',
        pollOptions: [
          PollOptionModel(id: 'opt_yes', text: 'Yes', votes: 2, isVoted: false),
          PollOptionModel(id: 'opt_no', text: 'No', votes: 2, isVoted: false),
        ],
        pollTotalVotes: 4,
        hasVoted: false,
        pollDuration: '1 Day',
      );
      repo.feedPosts = [post];
      final controller = CommunityController(repository: repo);
      Get.put<CommunityController>(controller);
      controller.posts.assignAll([post]);

      // Attempt to vote and await expected failure
      await expectLater(
        controller.votePoll('poll_post_fail', 'opt_yes'),
        throwsA(isA<Exception>()),
      );

      // Post in controller must be rolled back to original values
      final rolledBackPost = controller.posts.first;
      expect(rolledBackPost.hasVoted, isFalse);
      expect(rolledBackPost.myOptionId, isNull);
      expect(rolledBackPost.pollTotalVotes, 4);
      expect(rolledBackPost.pollOptions!.first.votes, 2);
    });

    testWidgets('7. Light and Dark mode rendering of PollWidget', (tester) async {
      final options = [
        PollOptionModel(id: 'opt_1', text: 'Dark Mode', votes: 10, isVoted: true),
        PollOptionModel(id: 'opt_2', text: 'Light Mode', votes: 5, isVoted: false),
      ];

      // Light mode
      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.light,
          child: PollWidget(
            question: 'Light theme poll?',
            options: options,
            totalVotes: 15,
            hasVoted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Light theme poll?'), findsOneWidget);

      // Dark mode
      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.dark,
          child: PollWidget(
            question: 'Dark theme poll?',
            options: options,
            totalVotes: 15,
            hasVoted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dark theme poll?'), findsOneWidget);
    });

    testWidgets('8. Khmer localization renders poll labels and vote counts', (tester) async {
      final options = [
        PollOptionModel(id: 'opt_1', text: 'ជម្រើស ក', votes: 1, isVoted: false),
        PollOptionModel(id: 'opt_2', text: 'ជម្រើស ខ', votes: 1, isVoted: false),
      ];

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('km', 'KH'),
          child: PollWidget(
            question: 'តើអ្នកចូលចិត្តភាសាអ្វី?',
            options: options,
            totalVotes: 2,
            hasVoted: true,
            duration: '3 ថ្ងៃ',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('តើអ្នកចូលចិត្តភាសាអ្វី?'), findsOneWidget);
      // Khmer word for votes is 'សំឡេងឆ្នោត'
      expect(find.textContaining('សំឡេងឆ្នោត'), findsOneWidget);
    });
  });
}
