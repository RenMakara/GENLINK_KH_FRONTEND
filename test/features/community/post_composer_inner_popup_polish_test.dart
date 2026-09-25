import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genlink_frontend/app/routes/app_routes.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_event_screen.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_discussion_screen.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/expense_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/saving_goal_feature/saving_goals_create.dart'
    as finance_saving_goal;
import 'package:genlink_frontend/features/productivity/presentation/goals_plan/goal_plan_create.dart'
    as productivity_goal;
import 'package:genlink_frontend/features/productivity/presentation/screens/create_habit_screen.dart';
import 'package:genlink_frontend/features/productivity/presentation/screens/create_task_screen.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

class _FakeExpenseController extends GetxController
    implements ExpenseController {
  @override
  final selectedCurrency = FinanceCurrency.usd.obs;

  @override
  final isCreateSubmitting = false.obs;

  @override
  final isUpdateSubmitting = false.obs;

  @override
  final mutationErrorMessage = RxnString();

  @override
  final listErrorMessage = RxnString();

  @override
  final selectedCategory = RxnString();

  @override
  final expenses = <FinanceExpenseEntity>[].obs;

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBudgetController extends GetxController implements BudgetController {
  @override
  final selectedMonth = 9.obs;

  @override
  final selectedYear = 2026.obs;

  @override
  final selectedCurrency = FinanceCurrency.usd.obs;

  @override
  final isCreateSubmitting = false.obs;

  @override
  final isUpdateSubmitting = false.obs;

  @override
  final mutationErrorMessage = RxnString();

  @override
  final listErrorMessage = RxnString();

  @override
  final budget = Rxn<FinanceBudgetEntity>();

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSavingGoalController extends GetxController
    implements SavingGoalController {
  @override
  final selectedCurrency = FinanceCurrency.usd.obs;

  @override
  final isCreateSubmitting = false.obs;

  @override
  final isUpdateSubmitting = false.obs;

  @override
  final mutationErrorMessage = RxnString();

  @override
  final listErrorMessage = RxnString();

  @override
  final goals = <FinanceSavingGoalEntity>[].obs;

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRepo implements CommunityRepository {
  @override
  Future<List<CommunityPostModel>> getPosts({int page = 1, int limit = 10}) async => [];

  @override
  Future<CommunityPostModel> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'Public',
    String community = 'All GenLink',
  }) async {
    return CommunityPostModel(
      id: 'post_1',
      userId: 'u1',
      authorName: 'User',
      authorTag: 'u',
      authorAvatar: '',
      timeAgo: 'Just now',
      content: content,
      imageUrls: imageUrls,
      visibility: visibility,
      community: community,
    );
  }

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

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put<LocalStorage>(_MockLocalStorage(), permanent: true);
    Get.put<ExpenseController>(_FakeExpenseController(), permanent: true);
    Get.put<BudgetController>(_FakeBudgetController(), permanent: true);
    Get.put<SavingGoalController>(_FakeSavingGoalController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp({
    ThemeMode themeMode = ThemeMode.dark,
    Locale locale = const Locale('en', 'US'),
  }) {
    final repo = _MockRepo();
    Get.put<CommunityController>(CommunityController(repository: repo));

    return GetMaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      translations: AppTranslations(),
      locale: locale,
      getPages: [
        GetPage(
          name: AppRoutes.quizDashboard,
          page: () => const Scaffold(body: Text('Quiz Dashboard Page')),
        ),
      ],
      home: const CreatePostScreen(),
    );
  }

  Future<void> openInnerPopup(WidgetTester tester) async {
    final plusFinder = find.byTooltip('Create');
    expect(plusFinder, findsOneWidget);
    await tester.tap(plusFinder);
    await tester.pumpAndSettle();
    expect(find.byType(GlobalCreateSheet), findsOneWidget);
  }

  group('Post Composer Inner "+" Popup Final Polish Verification', () {
    testWidgets('1-15: Tap "+" opens compact glass popup anchored above with no text decoration', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Find "+" button inside composer toolbar
      final plusFinder = find.byTooltip('Create');
      expect(plusFinder, findsOneWidget);

      final plusRenderBox = tester.renderObject(plusFinder) as RenderBox;
      final plusCenter = plusRenderBox.localToGlobal(plusRenderBox.size.center(Offset.zero));

      // Tap inner "+"
      await tester.tap(plusFinder);
      await tester.pumpAndSettle();

      // Popup is shown
      expect(find.byType(GlobalCreateSheet), findsOneWidget);

      // Verify it is NOT a ModalBottomSheet
      expect(find.byType(BottomSheet), findsNothing);

      // Verify Header typography: NO underline on Create and Subtitle
      final createTextWidgets = tester.widgetList<Text>(find.text('Create'));
      for (final tw in createTextWidgets) {
        expect(tw.style?.decoration, anyOf(isNull, equals(TextDecoration.none)));
      }

      final subtitleFinder = find.text('What would you like to create?');
      expect(subtitleFinder, findsOneWidget);
      final subtitleWidget = tester.widget<Text>(subtitleFinder);
      expect(subtitleWidget.style?.decoration, anyOf(isNull, equals(TextDecoration.none)));

      // Verify NO category headers exist
      expect(find.text('Community'), findsNothing);
      expect(find.text('Productivity'), findsNothing);
      expect(find.text('Finance'), findsNothing);
      expect(find.text('Entertainment'), findsNothing);

      // Verify excluded features are NOT present
      expect(find.text('Poll'), findsNothing);
      expect(find.text('Celebration'), findsNothing);
      expect(find.text('Document'), findsNothing);
      expect(find.text('Media'), findsNothing);
      expect(find.text('Job'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(GlobalCreateSheet),
          matching: find.text('Post'),
        ),
        findsNothing,
      );

      // Verify all 11 options exist
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('To-Do'), findsOneWidget);
      expect(find.text('Habit'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Saving Goal'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);

      // Verify compact width: popup is constrained between 195 and 215, far less than screen width (390)
      final constrainedBoxFinder = find.byWidgetPredicate((w) {
        return w is ConstrainedBox &&
            w.constraints.maxWidth <= 215.0 &&
            w.constraints.maxWidth >= 190.0 &&
            w.constraints.maxHeight == 340.0;
      });
      expect(constrainedBoxFinder, findsOneWidget);

      // Verify 11 chevron icons are present (one per row)
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(11));

      // Verify BackdropFilter with blur exists for glass styling
      expect(find.byType(BackdropFilter), findsWidgets);

      // Verify CustomPaint triangle pointer exists pointing toward "+"
      final customPaintFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString().contains('TrianglePainter'));
      expect(customPaintFinder, findsOneWidget);

      // Verify popup is located above the "+" button
      final popupRenderBox = tester.renderObject(constrainedBoxFinder) as RenderBox;
      final popupBottom = popupRenderBox.localToGlobal(popupRenderBox.size.bottomCenter(Offset.zero));
      expect(popupBottom.dy, lessThanOrEqualTo(plusCenter.dy));

      // Tap 'X' close button in header closes it
      await tester.tap(find.descendant(of: find.byType(GlobalCreateSheet), matching: find.byIcon(Icons.close_rounded)));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalCreateSheet), findsNothing);
    });

    testWidgets('Tapping outside dismisses the popup', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalCreateSheet), findsOneWidget);

      // Tap top of screen outside popup
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalCreateSheet), findsNothing);
    });

    testWidgets('Light Mode renders cleanly without exception', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(find.text('Create'), findsWidgets);
      expect(find.text('Post'), findsWidgets);
    });

    testWidgets('Khmer localization renders properly without overflow or underline', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(locale: const Locale('km', 'KH')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('បង្កើត'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GlobalCreateSheet), findsOneWidget);

      // Verify Khmer subtitle
      expect(find.text('តើអ្នកចង់បង្កើតអ្វី?'), findsOneWidget);

      // Verify excluded items are not present
      expect(find.text('ការស្ទង់មតិ'), findsNothing);
      expect(find.text('ការអបអរសាទរ'), findsNothing);
      expect(find.text('ការងារ'), findsNothing);
      expect(find.text('ឯកសារ'), findsNothing);
      expect(find.text('មេឌៀ'), findsNothing);

      // Verify all 11 items in Khmer (Post excluded from inner popup)
      expect(
        find.descendant(
          of: find.byType(GlobalCreateSheet),
          matching: find.text('ប្រកាស'),
        ),
        findsNothing,
      );
      expect(find.text('ស្តូរី'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsWidgets);
      expect(find.text('ការពិភាក្សា'), findsOneWidget);
      expect(find.text('គោលដៅ'), findsOneWidget);
      expect(find.text('កិច្ចការត្រូវធ្វើ'), findsOneWidget);
      expect(find.text('ទម្លាប់'), findsOneWidget);
      expect(find.text('ការចំណាយ'), findsOneWidget);
      expect(find.text('គោលដៅសន្សំ'), findsOneWidget);
      expect(find.text('ថវិកា'), findsOneWidget);
      expect(find.text('កម្រងសំណួរ'), findsOneWidget);
      expect(find.text('បញ្ហាប្រឈម'), findsOneWidget);

      // Check text decorations
      final kmTitleFinder = find.text('បង្កើត');
      for (final tw in tester.widgetList<Text>(kmTitleFinder)) {
        expect(tw.style?.decoration, anyOf(isNull, equals(TextDecoration.none)));
      }
    });

    testWidgets('Small phone (320x568) does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Create'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);
    });

    testWidgets('17-Step Phone Test Sequence: Text field keeps focus and keyboard remains open throughout inner "+" popup lifecycle', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Open Post Composer
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final focusNode = tester.widget<TextField>(textFieldFinder).focusNode!;

      // 2. Tap the text field
      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();

      // 3. Confirm keyboard is visible & text field has focus
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // 4. Tap inner "+"
      final plusFinder = find.byTooltip('Create');
      expect(plusFinder, findsOneWidget);
      final plusRenderBox = tester.renderObject(plusFinder) as RenderBox;
      final plusCenter = plusRenderBox.localToGlobal(plusRenderBox.size.center(Offset.zero));

      await tester.tap(plusFinder);
      await tester.pumpAndSettle();

      // 5. Confirm popup appears
      expect(find.byType(GlobalCreateSheet), findsOneWidget);

      // 6. Confirm keyboard is STILL visible & focus node STILL has focus
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // 7. Confirm text field has not been replaced
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(textFieldFinder).focusNode, equals(focusNode));

      // 8. Confirm popup is above "+"
      final popupFinder = find.byWidgetPredicate((w) =>
          w is ConstrainedBox &&
          w.constraints.maxWidth <= 215.0 &&
          w.constraints.maxHeight == 340.0);
      final popupRenderBox = tester.renderObject(popupFinder) as RenderBox;
      final popupBottom = popupRenderBox.localToGlobal(popupRenderBox.size.bottomCenter(Offset.zero));
      expect(popupBottom.dy, lessThanOrEqualTo(plusCenter.dy));

      // 9. Confirm popup does not overlap keyboard
      final bottomInset = tester.view.viewInsets.bottom;
      final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(popupBottom.dy, lessThanOrEqualTo(screenHeight - bottomInset));

      // 10. Tap Discussion
      final discussionFinder = find.text('Discussion');
      expect(discussionFinder, findsOneWidget);
      await tester.tap(discussionFinder);
      await tester.pumpAndSettle();

      // 11. Confirm existing Discussion route opens correctly
      expect(find.byType(CreateDiscussionScreen), findsOneWidget);

      // 12. Return to Post Composer
      Get.back();
      await tester.pumpAndSettle();
      expect(find.byType(CreateDiscussionScreen), findsNothing);

      // 13. Confirm normal keyboard behavior still works
      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      // 14. Open inner "+" again
      await tester.tap(plusFinder);
      await tester.pumpAndSettle();
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(focusNode.hasFocus, isTrue);

      // 15. Tap outside popup
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // 16. Confirm popup closes
      expect(find.byType(GlobalCreateSheet), findsNothing);

      // 17. Confirm keyboard remains visible and text field remains focused
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('Tapping "+" again toggles popup closed while keeping keyboard open', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      final focusNode = tester.widget<TextField>(textFieldFinder).focusNode!;

      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      final plusFinder = find.byTooltip('Create');

      // Tap "+" once -> opens popup
      await tester.tap(plusFinder);
      await tester.pumpAndSettle();
      expect(find.byType(GlobalCreateSheet), findsOneWidget);
      expect(focusNode.hasFocus, isTrue);

      // Tap "+" again -> closes popup
      await tester.tap(plusFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(GlobalCreateSheet), findsNothing);
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('inner popup does not contain redundant Post option', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      expect(
        find.descendant(
          of: find.byType(GlobalCreateSheet),
          matching: find.text('Post'),
        ),
        findsNothing,
      );
      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    testWidgets('tapping Story in inner popup closes popup and invokes Story creation picker', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.tap(find.text('Story'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalCreateSheet), findsNothing);
    });

    testWidgets('tapping Event in inner popup opens CreateEventScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.tap(find.text('Event').last);
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventScreen), findsOneWidget);
    });

    testWidgets('tapping Discussion in inner popup opens CreateDiscussionScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.tap(find.text('Discussion'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateDiscussionScreen), findsOneWidget);
    });

    testWidgets('tapping Goal in inner popup opens CreateGoalScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.tap(find.text('Goal'));
      await tester.pumpAndSettle();

      expect(find.byType(productivity_goal.CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping To-Do in inner popup opens CreateTaskScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.tap(find.text('To-Do'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateTaskScreen), findsOneWidget);
    });

    testWidgets('tapping Habit in inner popup opens CreateHabitScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.tap(find.text('Habit'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateHabitScreen), findsOneWidget);
    });

    testWidgets('tapping Expense in inner popup opens AddExpenseScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.drag(find.text('Story'), const Offset(0, -100));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
    });

    testWidgets('tapping Saving Goal in inner popup opens saving goal CreateGoalScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.drag(find.text('Story'), const Offset(0, -120));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saving Goal'));
      await tester.pumpAndSettle();

      expect(find.byType(finance_saving_goal.CreateGoalScreen), findsOneWidget);
    });

    testWidgets('tapping Budget in inner popup opens SetBudgetScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.drag(find.text('Story'), const Offset(0, -160));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(find.byType(SetBudgetScreen), findsOneWidget);
    });

    testWidgets('tapping Quiz in inner popup routes to quizDashboard', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.drag(find.text('Story'), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();

      expect(find.text('Quiz Dashboard Page'), findsOneWidget);
    });

    testWidgets('tapping Challenge in inner popup opens challenge dialog', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await openInnerPopup(tester);
      await tester.drag(find.text('Story'), const Offset(0, -260));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Challenge'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          'Daily challenges are automatically assigned to your Today Hub on the Home dashboard. Complete tasks and habits to earn XP and level up.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
