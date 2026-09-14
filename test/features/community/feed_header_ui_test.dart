import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/spacing/app_spacing.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_search_screen.dart';
import 'package:genlink_frontend/features/community/presentation/widgets/community_header_widget.dart';
import 'package:genlink_frontend/features/notification/data/datasources/notification_remote_datasource.dart';
import 'package:genlink_frontend/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:genlink_frontend/features/notification/domain/models/notification_model.dart';
import 'package:genlink_frontend/features/notification/presentation/controllers/notification_controller.dart';

class _MockNotificationRemoteDataSource implements NotificationRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<NotificationModel> stubNotifications = [];

  @override
  Future<List<NotificationModel>> fetchNotifications() async => stubNotifications;
  @override
  Future<bool> markAsRead(String id) async => true;
  @override
  Future<bool> markAllAsRead() async => true;
  @override
  Future<bool> deleteNotification(String id) async => true;
  @override
  Future<void> addNotification(NotificationModel notification) async {}
}

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildFeedHeaderApp({
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
  }) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: locale,
      theme: theme ?? ThemeData.light(),
      home: const Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(52.0),
          child: CommunityHeaderWidget(activeCategory: 'Feed'),
        ),
        body: Center(child: Text('Feed Body')),
      ),
    );
  }

  group('GENLINK HOME FEED HEADER SPECIFICATION TESTS', () {
    testWidgets('1. Header Structure: Renders Home title and exactly Search -> Notification -> Chat', (tester) async {
      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);

      final searchPos = tester.getTopLeft(find.byIcon(Icons.search_rounded));
      final notifPos = tester.getTopLeft(find.byIcon(Icons.notifications_none_rounded));
      final chatPos = tester.getTopLeft(find.byIcon(Icons.sms_outlined));

      expect(searchPos.dx, lessThan(notifPos.dx));
      expect(notifPos.dx, lessThan(chatPos.dx));
    });

    testWidgets('2. Title Typography: Matches Finance screen (fontSize: 24, w800, letterSpacing: -0.5)', (tester) async {
      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      final titleFinder = find.text('Home');
      expect(titleFinder, findsOneWidget);
      final Text titleWidget = tester.widget(titleFinder);

      expect(titleWidget.style?.fontSize, equals(24.0));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.w800));
      expect(titleWidget.style?.letterSpacing, equals(-0.5));
      expect(titleWidget.maxLines, equals(1));
      expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('3. Action Button Treatment: 40x40 area, 20.5px icon, radius 12, subtle border, monochrome', (tester) async {
      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      final inkWidgets = tester.widgetList<Ink>(find.byType(Ink));
      expect(inkWidgets.length, equals(3));

      for (final ink in inkWidgets) {
        expect(ink.width, equals(40.0));
        expect(ink.height, equals(40.0));
        final dec = ink.decoration as BoxDecoration?;
        expect(dec, isNotNull);
        expect(dec?.color, equals(AppColors.lightSurfacePrimary));
        expect(dec?.border, isNotNull);
      }

      final searchIcon = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
      final chatIcon = tester.widget<Icon>(find.byIcon(Icons.sms_outlined));
      final notifIcon = tester.widget<Icon>(find.byIcon(Icons.notifications_none_rounded));

      expect(searchIcon.size, equals(20.5));
      expect(chatIcon.size, equals(20.5));
      expect(notifIcon.size, equals(20.5));

      expect(searchIcon.color, equals(AppColors.lightTextPrimary));
      expect(chatIcon.color, equals(AppColors.lightTextPrimary));
      expect(notifIcon.color, equals(AppColors.lightTextPrimary));
    });

    testWidgets('4. Horizontal Alignment: 16px left and 16px right padding matching AppSpacing.md', (tester) async {
      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final headerContainer = containers.firstWhere(
        (c) => c.padding == const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      );
      expect(headerContainer.padding, equals(const EdgeInsets.symmetric(horizontal: 16.0)));
    });

    testWidgets('5. Light Mode & Dark Mode: Monochrome design system tokens strictly applied', (tester) async {
      // Light Mode
      await tester.pumpWidget(buildFeedHeaderApp(theme: ThemeData.light()));
      await tester.pumpAndSettle();

      Text titleLight = tester.widget(find.text('Home'));
      expect(titleLight.style?.color, equals(AppColors.lightTextPrimary));

      // Dark Mode
      await tester.pumpWidget(buildFeedHeaderApp(theme: ThemeData.dark()));
      await tester.pumpAndSettle();

      Text titleDark = tester.widget(find.text('Home'));
      expect(titleDark.style?.color, equals(AppColors.darkTextPrimary));

      final inkWidgetsDark = tester.widgetList<Ink>(find.byType(Ink));
      for (final ink in inkWidgetsDark) {
        final dec = ink.decoration as BoxDecoration?;
        expect(dec?.color, equals(AppColors.darkSurfacePrimary));
      }
    });

    testWidgets('6. Khmer Localization: Renders ទំព័រដើម title and localized action tooltips without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildFeedHeaderApp(locale: const Locale('km', 'KH')));
      await tester.pumpAndSettle();

      expect(find.text('ទំព័រដើម'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final titleWidget = tester.widget<Text>(find.text('ទំព័រដើម'));
      expect(titleWidget.style?.fontSize, equals(21.0));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.w800));
    });

    testWidgets('7. Responsive Viewports: 320px, 360px, 390px, 430px render cleanly with 0 overflow', (tester) async {
      final screenSizes = [
        const Size(320, 640),
        const Size(360, 740),
        const Size(390, 844),
        const Size(430, 932),
      ];

      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(buildFeedHeaderApp());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed on viewport $size');
        expect(find.text('Home'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
        expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
      }
    });

    testWidgets('8. Notification Badge: Displays unread indicator with high contrast border cutout', (tester) async {
      final mockSource = _MockNotificationRemoteDataSource();
      mockSource.stubNotifications = [
        NotificationModel(
          id: '1',
          type: NotificationType.mention,
          title: 'Unread Alert',
          body: 'Someone mentioned you in Feed',
          senderName: 'Test User',
          timeAgo: 'Now',
          timestamp: DateTime.now(),
          isRead: false,
        ),
      ];

      final notifController = NotificationController(
        repository: NotificationRepositoryImpl(remoteDataSource: mockSource),
      );
      Get.put<NotificationController>(notifController);
      await notifController.fetchNotifications();

      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      expect(notifController.unreadCount, equals(1));

      // Verify notification bell has badge container
      final notifInk = find.ancestor(
        of: find.byIcon(Icons.notifications_none_rounded),
        matching: find.byType(Ink),
      );
      expect(notifInk, findsOneWidget);

      final containers = tester.widgetList<Container>(
        find.descendant(of: notifInk, matching: find.byType(Container)),
      );

      final badgeContainer = containers.firstWhere((c) {
        final dec = c.decoration as BoxDecoration?;
        return dec != null && dec.shape == BoxShape.circle && dec.color == AppColors.danger;
      });

      expect(badgeContainer, isNotNull);
      final badgeDec = badgeContainer.decoration as BoxDecoration;
      expect(badgeDec.color, equals(AppColors.danger));
      expect(badgeDec.border, isNotNull);
      expect(badgeContainer.constraints?.maxWidth, equals(7.5));
    });

    testWidgets('9. Action Navigation: Action buttons are tap-enabled with proper routes', (tester) async {
      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      final searchFinder = find.byIcon(Icons.search_rounded);
      final notifFinder = find.byIcon(Icons.notifications_none_rounded);
      final chatFinder = find.byIcon(Icons.sms_outlined);

      expect(searchFinder, findsOneWidget);
      expect(notifFinder, findsOneWidget);
      expect(chatFinder, findsOneWidget);

      // Search navigation
      await tester.tap(searchFinder);
      await tester.pumpAndSettle();
      expect(find.byType(CommunitySearchScreen), findsOneWidget);
    });

    testWidgets('10. Accessibility: Action buttons provide semantic labels and tooltips', (tester) async {
      await tester.pumpWidget(buildFeedHeaderApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Chat'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);

      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      expect(find.bySemanticsLabel('Chat'), findsOneWidget);
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    });
  });
}
