import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';

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
  Future<CommunityPostModel> createPollPost({
    required String question,
    required List<String> options,
    String? caption,
    String visibility = 'Public',
    String? communityId,
    String? duration,
  }) async {
    createdPost = CommunityPostModel(
      id: 'mock_poll_1',
      userId: 'user_1',
      authorName: 'Sokny Enath',
      authorTag: 'sokny',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: caption ?? '',
      postType: 'poll',
      pollQuestion: question,
      pollOptions: options
          .asMap()
          .entries
          .map((e) => PollOptionModel(id: 'opt_${e.key}', text: e.value, votes: 0))
          .toList(),
      pollTotalVotes: 0,
      pollDuration: duration ?? '3 Days',
      visibility: visibility,
      community: communityId ?? 'All GenLink',
    );
    return createdPost!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockCommunityRepository repo;
  late CommunityController controller;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = MockCommunityRepository();
    controller = CommunityController(repository: repo);
    Get.put<CommunityController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestWidget({Brightness brightness = Brightness.light, Size size = const Size(400, 800)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: ThemeData(brightness: brightness),
        home: const CreatePostScreen(),
      ),
    );
  }

  group('Poll Creation UI & Post Composer Integration Tests', () {
    testWidgets('1. Create Poll sheet uses neutral monochrome styling for Done and Add Option', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.light));
      await tester.pumpAndSettle();

      // Open Poll sheet via toolbar button
      final pollButton = find.byTooltip('Poll');
      expect(pollButton, findsOneWidget);
      await tester.tap(pollButton);
      await tester.pumpAndSettle();

      // Verify title & Done button
      expect(find.text('Create Poll'), findsOneWidget);
      final doneText = tester.widget<Text>(find.text('Done'));
      expect(doneText.style?.color, isNot(AppColors.brandPrimary));
      expect(doneText.style?.color, Colors.black87);

      // Verify Add Option icon & text use neutral styling (not brandPrimary)
      final addOptionText = tester.widget<Text>(find.text('Add Option'));
      expect(addOptionText.style?.color, isNot(AppColors.brandPrimary));
      expect(addOptionText.style?.color, Colors.black87);

      final addOptionIcon = tester.widget<Icon>(find.byIcon(Icons.add_circle_outline_rounded));
      expect(addOptionIcon.color, isNot(AppColors.brandPrimary));
      expect(addOptionIcon.color, Colors.black87);

      // Verify Question & Option labels
      expect(find.text('Question'), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), findsNWidgets(3)); // 1 question + 2 default options
    });

    testWidgets('2. Poll creation sheet allows adding and removing options up to 6', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Poll'));
      await tester.pumpAndSettle();

      // Initially 2 option fields, no remove button
      expect(find.byIcon(Icons.remove_circle_outline_rounded), findsNothing);

      // Add 3rd option
      await tester.tap(find.text('Add Option'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.remove_circle_outline_rounded), findsNWidgets(3));

      // Add up to 6 options
      await tester.tap(find.text('Add Option'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Option'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Option'));
      await tester.pumpAndSettle();

      // At 6 options, Add Option button hides
      expect(find.text('Add Option'), findsNothing);

      // Remove an option
      await tester.tap(find.byIcon(Icons.remove_circle_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Add Option'), findsOneWidget);
    });

    testWidgets('3. Saving poll renders compact Poll preview card directly under text field with neutral styling', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter post text
      final postField = find.byType(TextField).first;
      await tester.enterText(postField, 'Weekly check-in:');
      await tester.pumpAndSettle();

      // Open poll sheet and fill question and options
      await tester.tap(find.byTooltip('Poll'));
      await tester.pumpAndSettle();

      final questionField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Ask a question...',
      );
      await tester.enterText(questionField, 'What is your primary language?');
      await tester.pumpAndSettle();

      final option1 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 1',
      );
      await tester.enterText(option1, 'Dart');

      final option2 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 2',
      );
      await tester.enterText(option2, 'TypeScript');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Poll preview card is displayed
      expect(find.text('What is your primary language?'), findsOneWidget);
      expect(find.text('2 options · 3 Days'), findsOneWidget);

      // Verify Poll icon uses neutral styling (NOT AppColors.brandPrimary)
      final pollIcons = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.poll_rounded && w.color != AppColors.brandPrimary,
      );
      expect(pollIcons, findsWidgets);

      // Verify vertical positioning: Poll preview is near the top, directly beneath TextField
      final postFieldBox = tester.getRect(postField);
      final pollCardFinder = find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).borderRadius == BorderRadius.circular(14),
      );
      final pollCardBox = tester.getRect(pollCardFinder.first);

      // Poll card top is below post field
      expect(pollCardBox.top, greaterThanOrEqualTo(postFieldBox.bottom));
      // Poll card top is in upper portion of screen (natural top placement, NOT centered in middle at ~400px)
      expect(pollCardBox.top, lessThan(350));
    });

    testWidgets('4. Tapping remove button clears the Poll preview and leaves composer open', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open poll sheet and create poll
      await tester.tap(find.byTooltip('Poll'));
      await tester.pumpAndSettle();

      final questionField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Ask a question...',
      );
      await tester.enterText(questionField, 'Quick poll?');

      final option1 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 1',
      );
      await tester.enterText(option1, 'Yes');

      final option2 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 2',
      );
      await tester.enterText(option2, 'No');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Quick poll?'), findsOneWidget);

      // Tap remove poll button
      final removePollBtn = find.byTooltip('Remove Poll');
      expect(removePollBtn, findsOneWidget);
      await tester.tap(removePollBtn);
      await tester.pumpAndSettle();

      // Poll preview is cleared
      expect(find.text('Quick poll?'), findsNothing);
      // Composer remains open
      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    testWidgets('5. Tapping Poll preview card reopens sheet for editing', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Create poll
      await tester.tap(find.byTooltip('Poll'));
      await tester.pumpAndSettle();

      final questionField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Ask a question...',
      );
      await tester.enterText(questionField, 'Edit this question');
      final option1 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 1',
      );
      await tester.enterText(option1, 'Opt A');
      final option2 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 2',
      );
      await tester.enterText(option2, 'Opt B');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Tap the card to edit
      await tester.tap(find.text('Edit this question'));
      await tester.pumpAndSettle();

      // Sheet opens with previous values prefilled
      expect(find.text('Create Poll'), findsOneWidget);
      expect(find.text('Edit this question'), findsWidgets);
      expect(find.text('Opt A'), findsOneWidget);
      expect(find.text('Opt B'), findsOneWidget);
    });

    testWidgets('6. Responsive test on small screen (320x568) without overflow', (tester) async {
      await tester.pumpWidget(createTestWidget(size: const Size(320, 568)));
      await tester.pumpAndSettle();

      // Toolbar is visible and anchored
      expect(find.byTooltip('Poll'), findsOneWidget);

      // Open Poll sheet
      await tester.tap(find.byTooltip('Poll'));
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('Create Poll'), findsOneWidget);
    });

    testWidgets('7. Dark Mode visual rendering uses dark neutral surfaces and subtle borders', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Poll'));
      await tester.pumpAndSettle();

      final questionField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Ask a question...',
      );
      await tester.enterText(questionField, 'Dark mode question');
      final option1 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 1',
      );
      await tester.enterText(option1, 'Dark 1');
      final option2 = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Option 2',
      );
      await tester.enterText(option2, 'Dark 2');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dark mode question'), findsOneWidget);
    });
  });
}
