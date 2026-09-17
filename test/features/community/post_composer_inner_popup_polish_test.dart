import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:genlink_frontend/features/community/presentation/screens/create_post_screen.dart';
import 'package:genlink_frontend/features/community/domain/repositories/community_repository.dart';
import 'package:genlink_frontend/features/community/domain/models/community_post_model.dart';
import 'package:genlink_frontend/shared/widgets/global_create_sheet.dart';

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

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
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
      home: const CreatePostScreen(),
    );
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

      final subtitleFinder = find.text('More ways to share and connect.');
      expect(subtitleFinder, findsOneWidget);
      final subtitleWidget = tester.widget<Text>(subtitleFinder);
      expect(subtitleWidget.style?.decoration, anyOf(isNull, equals(TextDecoration.none)));

      // Verify all 7 options exist
      expect(find.text('Poll'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Celebration'), findsOneWidget);
      expect(find.text('Job'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);

      // Verify compact width: popup is constrained between 195 and 215, far less than screen width (390)
      final constrainedBoxFinder = find.byWidgetPredicate((w) {
        return w is ConstrainedBox &&
            w.constraints.maxWidth <= 215.0 &&
            w.constraints.maxWidth >= 190.0 &&
            w.constraints.maxHeight == 340.0;
      });
      expect(constrainedBoxFinder, findsOneWidget);

      // Verify 7 chevron icons are present (one per row)
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(7));

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
      expect(find.text('Poll'), findsOneWidget);
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

      // Verify Khmer text
      expect(find.text('ការស្ទង់មតិ'), findsOneWidget);
      expect(find.text('ការពិភាក្សា'), findsOneWidget);
      expect(find.text('ការអបអរសាទរ'), findsOneWidget);
      expect(find.text('ការងារ'), findsOneWidget);
      expect(find.text('ឯកសារ'), findsOneWidget);
      expect(find.text('មេឌៀ'), findsOneWidget);
      expect(find.text('ព្រឹត្តិការណ៍'), findsWidgets);

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
      expect(find.text('Poll'), findsOneWidget);
      expect(find.text('Event'), findsWidgets);
    });
  });
}
